import 'dart:async';
import 'package:flutter/material.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
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
  bool _busy = false;
  String? _lastScope;
  final service = NotificationCoordinator.instance;
  @override
  void initState() {
    super.initState();
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
    _drain();
  }

  @override
  void dispose() {
    service?.removeListener(_drain);
    AppRouter.router.routeInformationProvider.removeListener(_routeChanged);
    super.dispose();
  }

  Future<void> _drain() async {
    if (_lastScope != service?.scope) {
      GymTopNotification.clear();
      _lastScope = service?.scope;
    }
    if (GymTopNotification.isShowing) {
      await GymTopNotification.whenIdle;
      if (mounted) _drain();
      return;
    }
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
      while (mounted && scope == service!.scope) {
        final rankResultPending = (await service!.store.all(
          'event:rank_result:',
        )).values.any((event) => event['shown'] != true);
        if (rankResultPending) return;
        final events =
            (await service!.store.all('event:')).entries
                .where(
                  (e) =>
                      e.value['shown'] != true &&
                      e.value['cardOnly'] != true &&
                      !e.key.startsWith('event:rank_result:') &&
                      !e.key.startsWith('event:hydration_completed:'),
                )
                .toList()
              ..sort(
                (a, b) =>
                    (a.value['at'] as int).compareTo(b.value['at'] as int),
              );
        if (events.isEmpty || !mounted || scope != service!.scope) return;
        final event = events.first;
        if (DateTime.now().millisecondsSinceEpoch - (event.value['at'] as int) >
            const Duration(days: 1).inMilliseconds) {
          await service!.store.write(event.key, {
            ...event.value,
            'shown': true,
          });
          continue;
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
        final root =
            AppRouter.router.routerDelegate.navigatorKey.currentContext;
        if (root == null || !root.mounted || scope != service!.scope) return;
        final text = lines.join('\n\n');
        final seconds = (5 + text.length ~/ 80).clamp(5, 9).toInt();
        Future<void>? presentedWrite;
        final shown = await GymTopNotification.show(
          root,
          icon: Icons.celebration_outlined,
          accentColor: Theme.of(root).colorScheme.primary,
          semanticLabel: text,
          customBody: Text(text, textAlign: TextAlign.left),
          actionLabel: NotificationCopy.text(
            'workout.tooltip_view_details',
          ),
          onAction: () => AppRouter.router.go(event.value['route'] as String),
          duration: Duration(seconds: seconds),
          haptic: false,
          onPresented: () {
            presentedWrite = service!.store.write(event.key, {
              ...event.value,
              'presentedAt': DateTime.now().millisecondsSinceEpoch,
            });
          },
        );
        if (!shown || scope != service!.scope) return;
        await presentedWrite;
        await service!.store.write(event.key, {
          ...event.value,
          'presentedAt': DateTime.now().millisecondsSinceEpoch,
          'acknowledgedAt': DateTime.now().millisecondsSinceEpoch,
          'shown': true,
        });
      }
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
        child: Stack(children: [widget.child, const _RankResultDialogHost()]),
      );
}

class _RankResultDialogHost extends StatefulWidget {
  const _RankResultDialogHost();

  @override
  State<_RankResultDialogHost> createState() => _RankResultDialogHostState();
}

class _RankResultDialogHostState extends State<_RankResultDialogHost>
    with WidgetsBindingObserver {
  NotificationCoordinator? _service;
  bool _showing = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = NotificationCoordinator.instance;
    _service?.addListener(_schedule);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule();
  }

  void _schedule() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) unawaited(_showLatest());
    });
  }

  Future<void> _showLatest() async {
    final service = _service;
    if (_showing ||
        service == null ||
        !mounted ||
        !NotificationCopy.available ||
        service.activeWorkout ||
        AppRouter.isTourActive.value ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    if (GymTopNotification.isShowing) {
      await GymTopNotification.whenIdle;
      _schedule();
      return;
    }
    final entries =
        (await service.store.all(
            'event:rank_result:',
          )).entries.where((entry) => entry.value['shown'] != true).toList()
          ..sort(
            (a, b) => (b.value['at'] as int).compareTo(a.value['at'] as int),
          );
    if (entries.isEmpty || !mounted) return;

    _showing = true;
    final latest = entries.first;
    final event = latest.value;
    final part = (event['parts'] as List).first as Map;
    final rankId = event['rankId'] as int? ?? 1;
    final rank = RankConfig.getRankById(rankId);
    final rankName = t.translateDynamic(rank.nameKey);
    final title = NotificationCopy.text(part['title'] as String) ?? rankName;
    final bodyKey = part['body'] as String;
    final body = bodyKey == rank.nameKey
        ? ''
        : NotificationCopy.text(bodyKey, {
                ...Map<String, String>.from(part['args'] as Map),
                'rankName': rankName,
              }) ??
              '';
    final accent = Color(rank.colorHex);
    await service.store.write(latest.key, {
      ...event,
      'presentedAt': DateTime.now().millisecondsSinceEpoch,
    });
    final root = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (!mounted || root == null || !root.mounted) {
      _showing = false;
      return;
    }

    final viewRank = await GymDialog.showCustom<bool>(
      context: root,
      barrierDismissible: false,
      titleWidget: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(root).textTheme.titleLarge,
      ),
      content: Semantics(
        liveRegion: true,
        label: [
          title,
          rankName,
          body,
        ].where((value) => value.isNotEmpty).join('. '),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 132,
              height: 132,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                _rankBadgeAsset(rankId),
                fit: BoxFit.contain,
                semanticLabel: rankName,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              rankName,
              textAlign: TextAlign.center,
              style: Theme.of(
                root,
              ).textTheme.headlineMedium?.copyWith(color: accent),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(root).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(root).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(root, rootNavigator: true).pop(false),
          child: Text(t.common.close),
        ),
        FilledButton(
          onPressed: () => Navigator.of(root, rootNavigator: true).pop(true),
          child: Text(
            NotificationCopy.text('notifications.cta_view_rank') ?? '',
          ),
        ),
      ],
    );

    final acknowledgedAt = DateTime.now().millisecondsSinceEpoch;
    for (final entry in entries) {
      await service.store.write(entry.key, {
        ...entry.value,
        'shown': true,
        'acknowledgedAt': acknowledgedAt,
      });
    }
    _showing = false;
    service.requestReconcile();
    if (viewRank == true) AppRouter.router.go('/social/rank_screen');
    _schedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service?.removeListener(_schedule);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

String _rankBadgeAsset(int rankId) => switch (rankId) {
  1 => 'assets/badges/bronze1.webp',
  2 => 'assets/badges/bronze2.webp',
  3 => 'assets/badges/silver1.webp',
  4 => 'assets/badges/silver2.webp',
  5 => 'assets/badges/gold1.webp',
  6 => 'assets/badges/gold2.webp',
  7 => 'assets/badges/gold3.webp',
  8 => 'assets/badges/diamond.webp',
  _ => 'assets/badges/bronze1.webp',
};

/// Inline acknowledgment: the same event is not also shown as a top banner.
class InlineAchievementFeedback extends StatefulWidget {
  final String eventKey;
  final bool omitLevel;
  const InlineAchievementFeedback({
    super.key,
    required this.eventKey,
    this.omitLevel = false,
  });

  @override
  State<InlineAchievementFeedback> createState() =>
      _InlineAchievementFeedbackState();
}

class _InlineAchievementFeedbackState extends State<InlineAchievementFeedback> {
  NotificationCoordinator? _service;
  Future<Map<String, dynamic>?>? _event;

  @override
  void initState() {
    super.initState();
    _service = NotificationCoordinator.instance;
    _event = _service?.store.read(widget.eventKey);
    _service?.addListener(_reload);
  }

  @override
  void didUpdateWidget(InlineAchievementFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventKey != widget.eventKey) _reload();
  }

  void _reload() {
    if (!mounted || _service == null) return;
    setState(() => _event = _service!.store.read(widget.eventKey));
  }

  @override
  void dispose() {
    _service?.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    if (service == null || !NotificationCopy.available)
      return const SizedBox.shrink();
    final scope = service.scope;
    return FutureBuilder(
      future: _event,
      builder: (context, snapshot) {
        final event = snapshot.data;
        if (event == null || scope != service.scope)
          return const SizedBox.shrink();
        final parts = (event['parts'] as List).where(
          (part) =>
              !widget.omitLevel ||
              part['title'] != 'gamification.msg_level_up_base',
        );
        if (parts.isEmpty) return const SizedBox.shrink();
        return _MarkEventVisible(
          service: service,
          eventKey: widget.eventKey,
          event: event,
          scope: scope,
          child: Semantics(
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
          ),
        );
      },
    );
  }
}

/// Marks an event as acknowledged when its owning UI already communicates the
/// result. This keeps compact feedback inside the existing component instead
/// of rendering a second notification card.
class NotificationEventMarker extends StatefulWidget {
  final String eventKey;

  const NotificationEventMarker({super.key, required this.eventKey});

  @override
  State<NotificationEventMarker> createState() =>
      _NotificationEventMarkerState();
}

class _NotificationEventMarkerState extends State<NotificationEventMarker> {
  NotificationCoordinator? _service;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = NotificationCoordinator.instance;
    _service?.addListener(_scheduleMark);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleMark());
  }

  @override
  void didUpdateWidget(NotificationEventMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventKey != widget.eventKey) _scheduleMark();
  }

  void _scheduleMark() => unawaited(_mark());

  Future<void> _mark() async {
    final service = _service;
    if (_busy || service == null || !mounted) return;
    _busy = true;
    try {
      final event = await service.store.read(widget.eventKey);
      if (event == null || event['shown'] == true) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      await service.store.write(widget.eventKey, {
        ...event,
        'presentedAt': now,
        'acknowledgedAt': now,
        'shown': true,
      });
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _service?.removeListener(_scheduleMark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _MarkEventVisible extends StatefulWidget {
  final NotificationCoordinator service;
  final String eventKey;
  final Map<String, dynamic> event;
  final String scope;
  final Widget child;
  const _MarkEventVisible({
    required this.service,
    required this.eventKey,
    required this.event,
    required this.scope,
    required this.child,
  });

  @override
  State<_MarkEventVisible> createState() => _MarkEventVisibleState();
}

class _MarkEventVisibleState extends State<_MarkEventVisible> {
  ScrollPosition? _position;
  bool _marked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (_position != next) {
      _position?.removeListener(_check);
      _position = next?..addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_marked || !mounted || widget.event['shown'] == true) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        widget.scope != widget.service.scope) {
      return;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.height <= 0) return;
    final topLeft = box.localToGlobal(Offset.zero);
    final rect = topLeft & box.size;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    final visible = rect.intersect(screen);
    if (visible.isEmpty || visible.height / rect.height < .5) return;
    _marked = true;
    unawaited(
      widget.service.store.write(widget.eventKey, {
        ...widget.event,
        'shown': true,
      }),
    );
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
