import 'dart:async';
import 'package:flutter/material.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_notification.dart';
import 'package:plato_gymapp/core/navigation/app_router.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/active_session_cubit.dart';
import '../application/notification_coordinator.dart';
import '../data/notification_copy.dart';

class NotificationFeedbackHost extends StatefulWidget {
  final Widget child;
  const NotificationFeedbackHost({super.key, required this.child});
  @override
  State<NotificationFeedbackHost> createState() =>
      _NotificationFeedbackHostState();
}

class _NotificationFeedbackHostState extends State<NotificationFeedbackHost> {
  Timer? _timer;
  bool _busy = false;
  String? _lastScope;
  final service = NotificationCoordinator.instance;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _drain());
    service?.addListener(_drain);
    AppRouter.router.routeInformationProvider.addListener(_routeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final active = context.read<ActiveSessionCubit>().state.activeWorkout;
      service?.activeWorkout = active != null;
      service?.activeScheduleId = active?.sessionPayload.scheduledWorkoutId;
      service?.requestReconcile();
    });
  }

  void _routeChanged() {
    service?.visibleRoute = AppRouter.router.routeInformationProvider.value.uri
        .toString();
    service?.foreground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    service?.requestReconcile();
  }

  @override
  void dispose() {
    _timer?.cancel();
    service?.removeListener(_drain);
    AppRouter.router.routeInformationProvider.removeListener(_routeChanged);
    super.dispose();
  }

  Future<void> _drain() async {
    if (_lastScope != service?.scope) {
      GymTopNotification.clear();
      _lastScope = service?.scope;
    }
    if (GymTopNotification.isShowing) return;
    final route = AppRouter.router.routeInformationProvider.value.uri
        .toString();
    if (route.contains('workout_rewards')) return;
    if (_busy ||
        service == null ||
        !mounted ||
        !NotificationCopy.available ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        service!.activeWorkout ||
        AppRouter.isTourActive.value)
      return;
    _busy = true;
    try {
      final scope = service!.scope;
      final events =
          (await service!.store.all('event:')).entries
              .where(
                (e) =>
                    e.value['shown'] != true &&
                    e.value['cardOnly'] != true &&
                    !(route.startsWith('/nutrition') &&
                        e.key.startsWith('event:hydration_completed:')),
              )
              .toList()
            ..sort(
              (a, b) => (a.value['at'] as int).compareTo(b.value['at'] as int),
            );
      if (events.isEmpty || !mounted || scope != service!.scope) return;
      final event = events.first;
      // Never replay stale celebrations after a long absence.
      if (DateTime.now().millisecondsSinceEpoch - (event.value['at'] as int) >
          const Duration(days: 1).inMilliseconds) {
        await service!.store.write(event.key, {...event.value, 'shown': true});
        return;
      }
      final lines = <String>[];
      for (final part in event.value['parts'] as List) {
        final title = NotificationCopy.text(part['title'] as String);
        final body =
            part['literalBody'] as String? ??
            NotificationCopy.text(
              part['body'] as String,
              Map<String, String>.from(part['args'] as Map),
            );
        if (title == null || body == null) return;
        lines.add('$title\n$body');
      }
      final root = AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (root == null || !root.mounted || scope != service!.scope) return;
      await service!.store.write(event.key, {...event.value, 'shown': true});
      if (!root.mounted || scope != service!.scope) return;

      final rankId = event.value['rankId'] as int?;
      GymTopNotification.show(
        root,
        icon: Icons.celebration_outlined,
        accentColor: rankId == null
            ? null
            : Color(RankConfig.getRankById(rankId).colorHex),
        customBody: InkWell(
          onTap: () => AppRouter.router.go(event.value['route'] as String),
          child: Text(lines.join('\n\n'), textAlign: TextAlign.center),
        ),
        duration: const Duration(seconds: 5),
      );
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<ActiveSessionCubit, ActiveSessionState>(
        listenWhen: (a, b) => a.activeWorkout?.id != b.activeWorkout?.id,
        listener: (context, state) {
          service?.activeWorkout = state.activeWorkout != null;
          service?.activeScheduleId =
              state.activeWorkout?.sessionPayload.scheduledWorkoutId;
          service?.requestReconcile();
        },
        child: widget.child,
      );
}

class RankResultCard extends StatefulWidget {
  const RankResultCard({super.key});
  @override
  State<RankResultCard> createState() => _RankResultCardState();
}

class _RankResultCardState extends State<RankResultCard> {
  @override
  Widget build(BuildContext context) {
    final service = NotificationCoordinator.instance;
    if (service == null || !NotificationCopy.available)
      return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => FutureBuilder(
        future: service.store.all('event:rank_result:'),
        builder: (context, snapshot) {
          final entries =
              snapshot.data?.entries
                  .where(
                    (e) =>
                        e.value['cardOnly'] == true && e.value['shown'] != true,
                  )
                  .toList() ??
              [];
          entries.sort(
            (a, b) => (b.value['at'] as int).compareTo(a.value['at'] as int),
          );
          if (entries.isEmpty) return const SizedBox.shrink();
          final latest = entries.first;
          final part = (latest.value['parts'] as List).first;
          return Card(
            child: ListTile(
              title: Text(NotificationCopy.text(part['title'] as String) ?? ''),
              subtitle: Text(
                NotificationCopy.text(part['body'] as String, {
                      ...Map<String, String>.from(part['args'] as Map),
                      if (part['rankNameKey'] != null)
                        'rankName': t.translateDynamic(
                          part['rankNameKey'] as String,
                        ),
                    }) ??
                    '',
              ),
              trailing: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close),
                onPressed: () async {
                  for (final entry in entries) {
                    await service.store.write(entry.key, {
                      ...entry.value,
                      'shown': true,
                    });
                  }
                  if (mounted) setState(() {});
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Inline acknowledgment: the same event is not also shown as a top banner.
class InlineAchievementFeedback extends StatelessWidget {
  final String eventKey;
  final bool omitLevel;
  const InlineAchievementFeedback({
    super.key,
    required this.eventKey,
    this.omitLevel = false,
  });
  @override
  Widget build(BuildContext context) {
    final service = NotificationCoordinator.instance;
    if (service == null || !NotificationCopy.available)
      return const SizedBox.shrink();
    final scope = service.scope;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => FutureBuilder(
        future: service.store.read(eventKey),
        builder: (context, snapshot) {
          final event = snapshot.data;
          if (event == null || scope != service.scope)
            return const SizedBox.shrink();
          final parts = (event['parts'] as List).where(
            (part) =>
                !omitLevel || part['title'] != 'gamification.msg_level_up_base',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted &&
                TickerMode.valuesOf(context).enabled &&
                WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.resumed &&
                scope == service.scope &&
                event['shown'] != true) {
              service.store.write(eventKey, {...event, 'shown': true});
            }
          });
          if (parts.isEmpty) return const SizedBox.shrink();
          return Semantics(
            liveRegion: event['shown'] != true,
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final part in parts)
                      ListTile(
                        leading: const Icon(Icons.celebration_outlined),
                        title: Text(
                          NotificationCopy.text(part['title'] as String) ?? '',
                        ),
                        subtitle: Text(
                          NotificationCopy.text(
                                part['body'] as String,
                                Map<String, String>.from(part['args'] as Map),
                              ) ??
                              '',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
