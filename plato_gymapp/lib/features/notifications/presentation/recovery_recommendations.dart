import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/workout/domain/streak_calculator.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/editor_cubit.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/workout_cubit.dart';
import 'package:plato_gymapp/features/workout/presentation/components/workout_section_header.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';

import '../data/notification_copy.dart';
import '../domain/recovery_forecast_service.dart';

class RecoveryRecommendations extends StatefulWidget {
  final WorkoutSession? routine;
  const RecoveryRecommendations({super.key, this.routine});

  @override
  State<RecoveryRecommendations> createState() =>
      _RecoveryRecommendationsState();
}

class _RecoveryRecommendationsState extends State<RecoveryRecommendations> {
  Timer? _refreshTimer;
  DateTime? _scheduledRefreshAt;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _copy(String key, [Map<String, String> args = const {}]) =>
      NotificationCopy.text(key, args) ?? '';

  String _muscleName(MajorMuscleGroup muscle) =>
      t.translateDynamic('muscles.${muscle.name.toLowerCase()}');

  String _copyWithFallback(String key, String fallback) =>
      NotificationCopy.text(key) ?? fallback;

  void _showDetailsDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    GymDialog.showCustom<void>(
      context: context,
      titleWidget: Row(
        children: [
          Icon(Symbols.info, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.common.info,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copyWithFallback(
              'notifications.desc_recovery_routine_details',
              t.workout.desc_warn_muscle_info_general,
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _detailZone(
            context,
            color: Theme.of(context).gymColors.success,
            icon: Symbols.check_circle,
            title: _copyWithFallback(
              'notifications.title_recovery_routine_ready_detail',
              t.workout.title_warn_muscle_zone_green,
            ),
            body: _copyWithFallback(
              'notifications.desc_recovery_routine_ready_detail',
              t.workout.desc_warn_muscle_zone_green,
            ),
          ),
          const SizedBox(height: 10),
          _detailZone(
            context,
            color: Theme.of(context).gymColors.warning,
            icon: Symbols.schedule,
            title: _copyWithFallback(
              'notifications.title_recovery_routine_recovering_detail',
              t.workout.title_warn_muscle_zone_yellow,
            ),
            body: _copyWithFallback(
              'notifications.desc_recovery_routine_recovering_detail',
              t.workout.desc_warn_muscle_zone_yellow,
            ),
          ),
          const SizedBox(height: 10),
          _detailZone(
            context,
            color: colors.error,
            icon: Symbols.bedtime,
            title: _copyWithFallback(
              'notifications.title_recovery_routine_rest_detail',
              t.workout.title_warn_muscle_zone_red,
            ),
            body: _copyWithFallback(
              'notifications.desc_recovery_routine_rest_detail',
              t.workout.desc_warn_muscle_zone_red,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(t.common.understood),
        ),
      ],
    );
  }

  Widget _detailZone(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String title,
    required String body,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 21, fill: 1),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Color _stateColor(BuildContext context, RoutineRecoveryState state) {
    final theme = Theme.of(context);
    return switch (state) {
      RoutineRecoveryState.ready => theme.gymColors.success,
      RoutineRecoveryState.nearlyReady => theme.gymColors.warning,
      RoutineRecoveryState.low ||
      RoutineRecoveryState.unavailable => theme.colorScheme.error,
    };
  }

  void _scheduleNextRefresh(DateTime? transition) {
    if (_scheduledRefreshAt == transition) return;
    _scheduledRefreshAt = transition;
    _refreshTimer?.cancel();
    if (transition == null) return;
    final delay = transition
        .add(const Duration(seconds: 1))
        .difference(DateTime.now());
    _refreshTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted) return;
      _scheduledRefreshAt = null;
      setState(() {});
    });
  }

  Future<void> _openRoutine(BuildContext context, WorkoutSession value) async {
    final editor = context.read<EditorCubit>();
    final previousRoutine = widget.routine;
    editor.setRoutineToEdit(value);
    try {
      await context.push('/workout/create_routine', extra: true);
    } finally {
      if (context.mounted && !editor.isClosed) {
        editor.setRoutineToEdit(previousRoutine);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!NotificationCopy.available) {
      _scheduleNextRefresh(null);
      return const SizedBox.shrink();
    }
    final historySource = context.select<WorkoutCubit, List<WorkoutSession>>(
      (cubit) => cubit.state.historicalWorkoutSessionsList,
    );
    final routines = context.select<WorkoutCubit, List<WorkoutSession>>(
      (cubit) => cubit.state.userCustomRoutinesList,
    );
    final history = historySource.where(StreakCalculator.qualifies).toList();
    if (history.isEmpty) {
      _scheduleNextRefresh(null);
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final forecast = _RecoveryForecastCache.forHistory(history);
    final snapshot = forecast.snapshotAt(now);
    _scheduleNextRefresh(forecast.nextTransitionAfter(now));

    if (widget.routine != null) {
      if (snapshot.state == RecoveryForecastState.restToday) {
        return _RecoveryMessageCard(
          icon: Symbols.bedtime,
          color: Theme.of(context).colorScheme.error,
          title: _copy('notifications.title_recovery_rest_today'),
          body: _copy('notifications.body_recovery_rest_today'),
        );
      }
      final assessment = forecast.assessRoutine(widget.routine!, at: now);
      if (!assessment.isActionable) {
        return const SizedBox.shrink();
      }
      if (assessment.state == RoutineRecoveryState.ready) {
        return _RecoveryMessageCard(
          icon: Symbols.check_circle,
          color: Theme.of(context).gymColors.success,
          title: t.translateDynamic(widget.routine!.name),
          body: _copy('notifications.body_recovery_routine_ready', {
            'routineName': t.translateDynamic(widget.routine!.name),
          }),
        );
      }
      final affected = assessment.lowMuscles.isNotEmpty
          ? assessment.lowMuscles
          : assessment.recoveringMuscles;
      final alternative = forecast.bestAlternativeFor(
        widget.routine!,
        routines,
        at: now,
      );
      final bodyKey = alternative != null
          ? 'notifications.body_recovery_routine_alternative'
          : assessment.state == RoutineRecoveryState.nearlyReady
          ? 'notifications.body_recovery_routine_nearly'
          : 'notifications.body_recovery_routine_low';
      final muscles = affected.map(_muscleName).join(', ');
      final args = alternative != null
          ? {
              'muscles': muscles,
              'alternative': t.translateDynamic(alternative.routine.name),
            }
          : {
              'muscles': muscles,
              'routineName': t.translateDynamic(widget.routine!.name),
            };
      final accent = _stateColor(
        context,
        alternative?.state ?? assessment.state,
      );
      return _RoutineRecommendationTile(
        icon: alternative == null ? Symbols.monitor_heart : Symbols.swap_horiz,
        color: accent,
        title: alternative == null
            ? _copy('notifications.title_recovery_low')
            : t.translateDynamic(alternative.routine.name),
        body: _copy(bodyKey, args),
        semanticActionLabel: _copy(
          alternative == null
              ? 'notifications.cta_choose_workout'
              : 'notifications.cta_view_routine',
        ),
        onTap: alternative == null
            ? () => context.go('/workout?recovery=1')
            : () => _openRoutine(context, alternative.routine),
      );
    }

    if (routines.isEmpty) {
      _scheduleNextRefresh(null);
      return const SizedBox.shrink();
    }
    final plan = forecast.planRoutines(routines, at: now, maxSuggestions: 2);
    if (plan.state == RecoveryRoutinePlanState.restToday) {
      return _RecoveryMessageCard(
        icon: Symbols.bedtime,
        color: Theme.of(context).colorScheme.error,
        title: _copy('notifications.title_recovery_rest_today'),
        body: _copy('notifications.body_recovery_rest_today'),
      );
    }
    if (plan.state == RecoveryRoutinePlanState.empty) {
      return const SizedBox.shrink();
    }
    final suggestions = [
      ...plan.recommended,
      ...plan.cautions,
    ].take(2).toList(growable: false);
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final moreRoutineNote = routines.length == 1
        ? _moreRoutineNote(
            context,
            snapshot: snapshot,
            assessment: suggestions.first,
          )
        : null;
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkoutSectionHeader(
            title: _copy('notifications.title_recovery_recommendation'),
            trailing: Semantics(
              button: true,
              label: t.common.info,
              child: IconButton(
                tooltip: t.common.info,
                onPressed: () => _showDetailsDialog(context),
                icon: Icon(Symbols.info, color: colors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < suggestions.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            _suggestionTile(context, suggestions[index]),
          ],
          if (moreRoutineNote != null) ...[
            const SizedBox(height: 10),
            moreRoutineNote,
          ],
        ],
      ),
    );
  }

  Widget? _moreRoutineNote(
    BuildContext context, {
    required RecoveryForecastSnapshot snapshot,
    required RoutineRecoveryAssessment assessment,
  }) {
    final readyMuscles = snapshot.ready;
    final shouldSuggestReadyMuscles =
        assessment.state != RoutineRecoveryState.ready &&
        readyMuscles.isNotEmpty;
    final message = shouldSuggestReadyMuscles
        ? NotificationCopy.text(
            'notifications.msg_add_routine_for_ready_muscles',
            {'muscles': readyMuscles.map(_muscleName).join(', ')},
          )
        : NotificationCopy.text('notifications.msg_add_routine_variety');
    if (message == null || message.trim().isEmpty) {
      return null;
    }
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: message,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Symbols.add_circle, size: 19, color: colors.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionTile(
    BuildContext context,
    RoutineRecoveryAssessment assessment,
  ) {
    final ready = assessment.state == RoutineRecoveryState.ready;
    final nearly = assessment.state == RoutineRecoveryState.nearlyReady;
    final affected = assessment.lowMuscles.isNotEmpty
        ? assessment.lowMuscles
        : assessment.recoveringMuscles;
    final body = ready
        ? _copy('notifications.body_recovery_routine_ready', {
            'routineName': t.translateDynamic(assessment.routine.name),
          })
        : _copy(
            nearly
                ? 'notifications.body_recovery_routine_nearly'
                : 'notifications.body_recovery_routine_low',
            {
              'muscles': affected.map(_muscleName).join(', '),
              'routineName': t.translateDynamic(assessment.routine.name),
            },
          );
    return _RoutineRecommendationTile(
      icon: ready
          ? Symbols.check_circle
          : nearly
          ? Symbols.schedule
          : Symbols.do_not_disturb_on,
      color: _stateColor(context, assessment.state),
      title: t.translateDynamic(assessment.routine.name),
      body: body,
      semanticActionLabel: _copy('notifications.cta_view_routine'),
      onTap: () => _openRoutine(context, assessment.routine),
    );
  }
}

class _RecoveryMessageCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _RecoveryMessageCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RecoveryIconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _RecoveryIconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 22, fill: 1),
  );
}

class _RoutineRecommendationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String semanticActionLabel;
  final VoidCallback onTap;

  const _RoutineRecommendationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.semanticActionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      label: '$title. $body. $semanticActionLabel',
      child: Material(
        color: color.withValues(alpha: .07),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: color.withValues(alpha: .24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _RecoveryIconBadge(icon: icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        body,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Symbols.chevron_right, color: color, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecoveryForecastCache {
  static String? _revision;
  static RecoveryForecastService? _service;

  static RecoveryForecastService forHistory(List<WorkoutSession> history) {
    final revision = RecoveryForecastService.revisionOf(history);
    if (_revision == revision && _service != null) return _service!;
    _revision = revision;
    _service = RecoveryForecastService(history);
    return _service!;
  }
}
