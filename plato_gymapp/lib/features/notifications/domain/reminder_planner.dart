import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/streak_calculator.dart';
import 'notification_policy.dart';
import 'recovery_forecast_service.dart';

typedef RecoveryNotificationState = RecoveryForecastState;

class ReminderPlanner {
  static const majorMuscles = RecoveryForecastService.majorMuscles;

  static List<ReminderCandidate> build({
    required DateTime now,
    required List<ScheduledWorkoutEntity> schedules,
    required List<WorkoutSession> history,
    Map<String, WorkoutSession> routinesById = const {},
    required UserProfile profile,
    required double water,
    required double target,
    required bool waterEnabled,
    bool recoveryEnabled = true,
    bool streakEnabled = true,
    bool rankEnabled = true,
    required DateTime Function(ScheduledWorkoutEntity) scheduledTime,
    required String Function(String) routineName,
    required String Function(MajorMuscleGroup) muscleName,
    String Function(List<String>)? compactMuscleNames,
    required DateTime lastAppOpenedAt,
    bool activeWorkout = false,
    int? activeWorkoutStartedAt,
    int horizonDays = 30,
    Map<String, double> waterByDay = const {},
    String? lastDeliveredRecoverySignature,
  }) {
    final formatMuscles = compactMuscleNames ?? (names) => names.join(', ');
    final result = <ReminderCandidate>[];
    final workouts = <ReminderCandidate>[];
    final horizon = DateTime(now.year, now.month, now.day + horizonDays);
    final validSchedules = schedules
        .where((schedule) => !schedule.isDeleted && !schedule.isCompleted)
        .toList();

    for (final schedule in validSchedules) {
      if (!schedule.reminderEnabled || schedule.timeOfDayMinutes == null) {
        continue;
      }
      final start = scheduledTime(schedule);
      if (activeWorkout && start.isBefore(now.add(const Duration(hours: 3)))) {
        continue;
      }
      final at = start.subtract(
        Duration(minutes: schedule.reminderMinutesBefore),
      );
      if (!at.isAfter(now) || at.isAfter(horizon)) continue;
      workouts.add(
        ReminderCandidate(
          key: 'workout:${schedule.id}',
          kind: ReminderKind.workout,
          at: at,
          titleKey: 'notifications.title_workout_reminder',
          bodyKey: 'notifications.body_workout_reminder',
          arguments: {
            'routineName': routineName(schedule.routineName),
            'time': _formatTime(start),
          },
          route: '/profile/calendar',
          actionLabelKey: 'notifications.cta_view_schedule',
          sourceId: schedule.id,
          metadata: {
            'targetDay': NotificationPolicy.dayKey(start),
            'routineId': schedule.routineId,
          },
        ),
      );
    }

    if (waterEnabled) {
      for (var offset = 0; offset < horizonDays; offset++) {
        final waterAt = DateTime(now.year, now.month, now.day + offset, 16);
        if (!waterAt.isAfter(now)) continue;
        if (activeWorkout && offset == 0) continue;
        final consumed = offset == 0
            ? water
            : waterByDay[NotificationPolicy.dayKey(waterAt)] ?? 0;
        final body = NotificationPolicy.hydrationBody(consumed, target);
        if (body == null) continue;
        result.add(
          ReminderCandidate(
            key: 'hydration:${NotificationPolicy.dayKey(waterAt)}',
            kind: ReminderKind.hydration,
            at: waterAt,
            titleKey: 'notifications.title_hydration_reminder',
            bodyKey: body,
            arguments: consumed <= 0
                ? const {}
                : {
                    'consumed': consumed.toStringAsFixed(2),
                    'target': target.toStringAsFixed(2),
                    if (consumed / target >= .5)
                      'remaining': (target - consumed).toStringAsFixed(2),
                  },
            route: '/nutrition?water=1',
            actionLabelKey: 'notifications.cta_open_water',
          ),
        );
      }
    }

    final inactivityEarliest = lastAppOpenedAt.add(const Duration(days: 14));
    var inactivityAt = DateTime(
      inactivityEarliest.year,
      inactivityEarliest.month,
      inactivityEarliest.day,
      20,
    );
    if (inactivityAt.isBefore(inactivityEarliest)) {
      inactivityAt = DateTime(
        inactivityAt.year,
        inactivityAt.month,
        inactivityAt.day + 1,
        20,
      );
    }
    if (inactivityAt.isAfter(now) && !inactivityAt.isAfter(horizon)) {
      result.add(
        ReminderCandidate(
          key: 'inactivity:${lastAppOpenedAt.millisecondsSinceEpoch}',
          kind: ReminderKind.inactivity,
          at: inactivityAt,
          titleKey: 'notifications.title_inactivity',
          bodyKey: 'notifications.body_inactivity',
          route: '/workout',
          actionLabelKey: 'notifications.cta_choose_workout',
          alternatives: [
            for (var offset = 1; offset <= 2; offset++)
              ReminderDeliveryOption(
                at: DateTime(
                  inactivityAt.year,
                  inactivityAt.month,
                  inactivityAt.day + offset,
                  20,
                ),
              ),
          ],
        ),
      );
    }

    final qualifyingHistory = history
        .where(StreakCalculator.qualifies)
        .toList();
    if (qualifyingHistory.isEmpty) return [...workouts, ...result];

    if (!activeWorkout && recoveryEnabled) {
      final projection = RecoveryForecastService(qualifyingHistory, at: now);
      final historyRevision = projection.historyRevision;
      final preferredMinutes = _preferredMorningMinutes(qualifyingHistory, now);
      var suppressFutureAllReady =
          lastDeliveredRecoverySignature == 'allReady:$historyRevision';
      final recoveryByTargetDay = <String, ReminderCandidate>{};

      for (var offset = 0; offset < horizonDays; offset++) {
        final day = DateTime(now.year, now.month, now.day + offset);
        final recovery = _recoveryForDay(
          day: day,
          now: now,
          projection: projection,
          muscleName: muscleName,
          formatMuscles: formatMuscles,
          preferredMinutes: preferredMinutes,
          historyRevision: historyRevision,
          schedules: validSchedules,
          scheduledTime: scheduledTime,
        );
        if (recovery == null) continue;
        if (recovery.metadata['state'] ==
            RecoveryNotificationState.allReady.name) {
          if (suppressFutureAllReady) break;
          suppressFutureAllReady = true;
        }
        recoveryByTargetDay[recovery.metadata['targetDay']!] = recovery;
      }

      // Enrich every workout with the recovery of that routine. An early
      // workout reminder absorbs the daily recovery guidance. For a later
      // workout, keep the morning guidance only when it can warn about muscles
      // that still need recovery.
      for (final entry in recoveryByTargetDay.entries.toList()) {
        final sameDayWorkouts =
            workouts
                .where((item) => item.metadata['targetDay'] == entry.key)
                .toList()
              ..sort((a, b) => a.at.compareTo(b.at));
        if (sameDayWorkouts.isEmpty) continue;
        final recovery = entry.value;
        final morningEnd = DateTime(
          recovery.at.year,
          recovery.at.month,
          recovery.at.day,
          8,
          30,
        );
        var hasAssessment = false;
        var everyAssessedRoutineReady = true;
        RoutineRecoveryAssessment? warning;
        DateTime? warningAt;
        for (final workout in sameDayWorkouts) {
          final routine = routinesById[workout.metadata['routineId']];
          if (routine == null) continue;
          final assessment = projection.assessRoutine(routine, at: workout.at);
          if (!assessment.isActionable) continue;
          hasAssessment = true;
          if (!assessment.isReady) {
            everyAssessedRoutineReady = false;
            warning ??= assessment;
            warningAt ??= workout.at;
          }
          final relevant = assessment.needsAdjustment
              ? assessment.lowMuscles
              : assessment.isReady
              ? assessment.targetMuscles
              : assessment.lowMuscles.isNotEmpty
              ? assessment.lowMuscles
              : assessment.recoveringMuscles;
          final names = formatMuscles(relevant.map(muscleName).toList());
          final merged = workout.copyWith(
            bodyKey: assessment.needsAdjustment
                ? 'notifications.body_workout_reminder_recovery_adjusted'
                : assessment.isReady
                ? 'notifications.body_workout_reminder_recovery_ready'
                : 'notifications.body_workout_reminder_recovery_low',
            arguments: {...workout.arguments, 'muscles': names},
            metadata: {
              ...workout.metadata,
              'recoverySignature': recovery.metadata['recoverySignature'] ?? '',
              'recoveryState': assessment.state.name,
              'recoveryMuscles': relevant
                  .map((muscle) => muscle.name)
                  .join(','),
            },
          );
          workouts[workouts.indexWhere((item) => item.key == workout.key)] =
              merged;
        }

        if (!hasAssessment) {
          final first = sameDayWorkouts.first;
          final ready = recovery.metadata['readyMuscles'] ?? '';
          final low = recovery.metadata['lowMuscles'] ?? '';
          workouts[workouts.indexWhere(
            (item) => item.key == first.key,
          )] = first.copyWith(
            bodyKey: ready.isNotEmpty
                ? 'notifications.body_workout_reminder_recovery_ready'
                : 'notifications.body_workout_reminder_recovery_low',
            arguments: {
              ...first.arguments,
              'muscles': ready.isNotEmpty ? ready : low,
            },
            metadata: {
              ...first.metadata,
              'recoverySignature': recovery.metadata['recoverySignature'] ?? '',
              'recoveryState': recovery.metadata['state'] ?? '',
            },
          );
          recoveryByTargetDay.remove(entry.key);
          continue;
        }

        final absorbedEarly = sameDayWorkouts.any(
          (workout) => !workout.at.isAfter(morningEnd),
        );
        if (absorbedEarly || (hasAssessment && everyAssessedRoutineReady)) {
          recoveryByTargetDay.remove(entry.key);
          continue;
        }
        if (warning != null) {
          final relevant = warning.lowMuscles.isNotEmpty
              ? warning.lowMuscles
              : warning.recoveringMuscles;
          final alternative = projection.bestAlternativeFor(
            warning.routine,
            routinesById.values,
            at: warningAt,
          );
          final muscles = formatMuscles(relevant.map(muscleName).toList());
          recoveryByTargetDay[entry.key] = recovery.copyWith(
            titleKey: 'notifications.title_recovery_low',
            bodyKey: alternative != null
                ? 'notifications.body_recovery_routine_alternative'
                : warning.state == RoutineRecoveryState.nearlyReady
                ? 'notifications.body_recovery_routine_nearly'
                : 'notifications.body_recovery_routine_low',
            arguments: alternative != null
                ? {
                    'muscles': muscles,
                    'alternative': routineName(alternative.routine.name),
                  }
                : {
                    'muscles': muscles,
                    'routineName': routineName(warning.routine.name),
                  },
            metadata: {
              ...recovery.metadata,
              'routineId': warning.routine.id,
              'routineRecoveryState': warning.state.name,
              if (alternative != null)
                'alternativeRoutineId': alternative.routine.id,
            },
          );
        }
      }

      // A daily all-ready reminder may be suppressed after the first unchanged
      // day, but a scheduled workout still needs recovery context. Enrich any
      // remaining workout directly from the shared forecast.
      for (final workout in workouts.toList()) {
        if (workout.metadata.containsKey('recoveryState')) continue;
        final routine = routinesById[workout.metadata['routineId']];
        RoutineRecoveryAssessment? assessment;
        if (routine != null) {
          assessment = projection.assessRoutine(routine, at: workout.at);
        }
        final snapshot = projection.snapshotAt(workout.at);
        final globalReady = snapshot.ready;
        final relevant = assessment?.needsAdjustment == true
            ? assessment!.lowMuscles
            : assessment?.isReady == true
            ? assessment!.targetMuscles
            : assessment != null
            ? (assessment.lowMuscles.isNotEmpty
                  ? assessment.lowMuscles
                  : assessment.recoveringMuscles)
            : globalReady.isNotEmpty
            ? globalReady
            : [...snapshot.low, ...snapshot.nearlyReady];
        final names = formatMuscles(relevant.map(muscleName).toList());
        final bodyKey = assessment?.needsAdjustment == true
            ? 'notifications.body_workout_reminder_recovery_adjusted'
            : assessment?.isReady == true ||
                  (assessment == null && globalReady.isNotEmpty)
            ? 'notifications.body_workout_reminder_recovery_ready'
            : 'notifications.body_workout_reminder_recovery_low';
        workouts[workouts.indexWhere(
          (item) => item.key == workout.key,
        )] = workout.copyWith(
          bodyKey: bodyKey,
          arguments: {...workout.arguments, 'muscles': names},
          metadata: {
            ...workout.metadata,
            'recoverySignature':
                '${snapshot.state.name}:${snapshot.historyRevision}',
            'recoveryState': assessment?.state.name ?? snapshot.state.name,
            'recoveryMuscles': relevant.map((muscle) => muscle.name).join(','),
          },
        );
      }
      result.addAll(recoveryByTargetDay.values);
    }

    for (var offset = 0; streakEnabled && offset < horizonDays; offset++) {
      final sunday = DateTime(now.year, now.month, now.day + offset, 8);
      if (sunday.weekday != DateTime.sunday || !sunday.isAfter(now)) continue;
      final week = StreakCalculator.weekStart(sunday);
      final streak = StreakCalculator.count(history, sunday);
      final hasSundaySchedule = validSchedules.any(
        (schedule) =>
            schedule.reminderEnabled &&
            schedule.timeOfDayMinutes != null &&
            NotificationPolicy.dayKey(scheduledTime(schedule)) ==
                NotificationPolicy.dayKey(sunday) &&
            scheduledTime(schedule).isAfter(sunday),
      );
      if (streak > 0 &&
          !StreakCalculator.weeks(history, sunday).contains(week) &&
          !hasSundaySchedule &&
          !(activeWorkout && offset == 0)) {
        result.add(
          ReminderCandidate(
            key: 'streak:${NotificationPolicy.dayKey(week)}',
            kind: ReminderKind.streak,
            at: sunday,
            titleKey: 'notifications.title_streak_at_risk',
            bodyKey: 'notifications.body_streak_at_risk',
            arguments: {'weeks': '$streak'},
            route: '/workout',
            actionLabelKey: 'notifications.cta_choose_workout',
            alternatives: [
              ReminderDeliveryOption(
                at: DateTime(sunday.year, sunday.month, sunday.day - 1, 19),
              ),
            ],
          ),
        );
      }
    }

    final season = RankCalculator.calculateTrueRankAndSeasons(
      history,
      profile,
      now.millisecondsSinceEpoch,
    );
    final end = DateTime.fromMillisecondsSinceEpoch(season.cycleEndTimeMillis);
    final rankAt = DateTime(end.year, end.month, end.day - 3, 10);
    if (rankEnabled && rankAt.isAfter(now) && !rankAt.isAfter(horizon)) {
      result.add(
        ReminderCandidate(
          key: 'rank:${season.cycleStartTimeMillis}',
          kind: ReminderKind.rank,
          at: rankAt,
          titleKey: 'notifications.title_rank_ending',
          bodyKey: 'notifications.body_rank_ending',
          arguments: {'date': '${end.day}/${end.month}/${end.year}'},
          route: '/social/rank_screen',
          actionLabelKey: 'notifications.cta_view_rank',
          alternatives: [
            ReminderDeliveryOption(
              at: DateTime(end.year, end.month, end.day - 4, 10),
            ),
            ReminderDeliveryOption(
              at: DateTime(end.year, end.month, end.day - 5, 10),
            ),
          ],
        ),
      );
    }
    final inactivityDays = result
        .where((candidate) => candidate.kind == ReminderKind.inactivity)
        .map((candidate) => NotificationPolicy.dayKey(candidate.at))
        .toSet();
    result.removeWhere(
      (candidate) =>
          candidate.kind == ReminderKind.recovery &&
          candidate.metadata['state'] ==
              RecoveryNotificationState.allReady.name &&
          inactivityDays.contains(NotificationPolicy.dayKey(candidate.at)),
    );
    return [...workouts, ...result];
  }

  static ReminderCandidate? _recoveryForDay({
    required DateTime day,
    required DateTime now,
    required RecoveryForecastService projection,
    required String Function(MajorMuscleGroup) muscleName,
    required String Function(List<String>) formatMuscles,
    required int preferredMinutes,
    required String historyRevision,
    required List<ScheduledWorkoutEntity> schedules,
    required DateTime Function(ScheduledWorkoutEntity) scheduledTime,
  }) {
    final targetDay = NotificationPolicy.dayKey(day);
    final windowEnd = DateTime(day.year, day.month, day.day, 12);
    if (!windowEnd.isAfter(now)) return null;
    var notifyAt = DateTime(
      day.year,
      day.month,
      day.day,
      preferredMinutes ~/ 60,
      preferredMinutes % 60,
    );
    if (!notifyAt.isAfter(now)) {
      if (NotificationPolicy.dayKey(now) != targetDay) return null;
      notifyAt = _ceilToMinute(now.add(const Duration(minutes: 1)));
      if (notifyAt.isAfter(windowEnd)) return null;
    }

    final deliverySnapshot = projection.snapshotAt(notifyAt);
    final noonSnapshot = projection.snapshotAt(windowEnd);
    final atDelivery = {
      for (final entry in deliverySnapshot.muscles.entries)
        entry.key: entry.value.percentage,
    };
    final atNoon = {
      for (final entry in noonSnapshot.muscles.entries)
        entry.key: entry.value.percentage,
    };
    final state = classifyRecovery(atDelivery);
    final green = majorMuscles
        .where(
          (major) =>
              (atDelivery[major] ?? 0) >=
              RecoveryForecastService.readyThreshold,
        )
        .toList();
    final low = majorMuscles
        .where(
          (major) =>
              (atDelivery[major] ?? 0) < RecoveryForecastService.readyThreshold,
        )
        .toList();
    final crossing = <MajorMuscleGroup, DateTime>{};
    for (final major in majorMuscles) {
      final readyAt = deliverySnapshot.muscles[major]!.readyAt;
      if (readyAt.isAfter(notifyAt) && !readyAt.isAfter(windowEnd)) {
        crossing[major] = readyAt;
      }
    }
    final crossingNames = formatMuscles(crossing.keys.map(muscleName).toList());
    final latestCrossing = crossing.values.fold<DateTime?>(
      null,
      (latest, value) =>
          latest == null || value.isAfter(latest) ? value : latest,
    );
    final readyNames = formatMuscles(green.map(muscleName).toList());
    final recoveringNames = formatMuscles(
      majorMuscles
          .where(
            (major) =>
                (atNoon[major] ?? 0) >= RecoveryForecastService.restThreshold &&
                (atDelivery[major] ?? 0) <
                    RecoveryForecastService.readyThreshold,
          )
          .map(muscleName)
          .toList(),
    );

    String titleKey;
    String bodyKey;
    Map<String, String> arguments = const {};
    if (state == RecoveryNotificationState.allReady) {
      titleKey = 'notifications.title_recovery_all_ready';
      bodyKey = 'notifications.body_recovery_all_ready';
    } else if (green.isNotEmpty && latestCrossing != null) {
      titleKey = 'notifications.title_recovery_ready';
      bodyKey = 'notifications.body_recovery_ready_and_next';
      arguments = {
        'readyMuscles': readyNames,
        'recoveringMuscles': crossingNames,
        'time': _formatTime(latestCrossing),
      };
    } else if (green.isNotEmpty) {
      titleKey = 'notifications.title_recovery_ready';
      bodyKey = 'notifications.body_recovery_ready';
      arguments = {'muscles': readyNames};
    } else if (latestCrossing != null) {
      titleKey = 'notifications.title_recovery_ready_later';
      bodyKey = 'notifications.body_recovery_ready_at';
      arguments = {
        'muscles': crossingNames,
        'time': _formatTime(latestCrossing),
      };
    } else if (atNoon.values.every(
      (value) => value < RecoveryForecastService.restThreshold,
    )) {
      titleKey = 'notifications.title_recovery_rest_today';
      bodyKey = 'notifications.body_recovery_rest_today';
    } else {
      titleKey = 'notifications.title_recovery_ready_later';
      bodyKey = 'notifications.body_recovery_ready_later';
      arguments = {'muscles': recoveringNames};
    }

    final signature = '${state.name}:$historyRevision';
    final alternatives = <ReminderDeliveryOption>[];
    final previewAt = DateTime(day.year, day.month, day.day - 1, 20, 30);
    final hasLateSchedule = schedules.any((schedule) {
      final start = scheduledTime(schedule);
      return NotificationPolicy.dayKey(start) ==
              NotificationPolicy.dayKey(previewAt) &&
          start.hour >= 20;
    });
    if (previewAt.isAfter(now) && !hasLateSchedule) {
      final preview = _tomorrowCopy(
        state: state,
        restThroughNoon: atNoon.values.every(
          (value) => value < RecoveryForecastService.restThreshold,
        ),
        readyNames: readyNames,
        crossingNames: crossingNames,
        recoveringNames: recoveringNames,
        latestCrossing: latestCrossing,
      );
      alternatives.add(
        ReminderDeliveryOption(
          at: previewAt,
          titleKey: 'notifications.title_recovery_tomorrow',
          bodyKey: preview.$1,
          arguments: preview.$2,
        ),
      );
    }

    return ReminderCandidate(
      key: 'recovery:$targetDay',
      kind: ReminderKind.recovery,
      at: notifyAt,
      titleKey: titleKey,
      bodyKey: bodyKey,
      arguments: arguments,
      route: '/workout?recovery=1',
      actionLabelKey: 'notifications.cta_view_recovery',
      alternatives: alternatives,
      metadata: {
        'targetDay': targetDay,
        'state': state.name,
        'recoverySignature': signature,
        'historyRevision': historyRevision,
        'readyMuscles': readyNames,
        'lowMuscles': formatMuscles(low.map(muscleName).toList()),
      },
    );
  }

  static (String, Map<String, String>) _tomorrowCopy({
    required RecoveryNotificationState state,
    required bool restThroughNoon,
    required String readyNames,
    required String crossingNames,
    required String recoveringNames,
    required DateTime? latestCrossing,
  }) {
    if (state == RecoveryNotificationState.allReady) {
      return ('notifications.body_recovery_tomorrow_all_ready', const {});
    }
    if (readyNames.isNotEmpty && latestCrossing != null) {
      return (
        'notifications.body_recovery_tomorrow_ready_and_next',
        {
          'readyMuscles': readyNames,
          'recoveringMuscles': crossingNames,
          'time': _formatTime(latestCrossing),
        },
      );
    }
    if (readyNames.isNotEmpty) {
      return (
        'notifications.body_recovery_tomorrow_ready',
        {'muscles': readyNames},
      );
    }
    if (latestCrossing != null) {
      return (
        'notifications.body_recovery_tomorrow_ready_at',
        {'muscles': crossingNames, 'time': _formatTime(latestCrossing)},
      );
    }
    if (restThroughNoon) {
      return ('notifications.body_recovery_tomorrow_rest', const {});
    }
    return (
      'notifications.body_recovery_tomorrow_ready',
      {'muscles': recoveringNames},
    );
  }

  static RecoveryNotificationState classifyRecovery(
    Map<MajorMuscleGroup, int> recoveryByMajor,
  ) => RecoveryForecastService.classify(recoveryByMajor);

  static String recoveryHistoryRevision(List<WorkoutSession> history) =>
      RecoveryForecastService.revisionOf(history);

  static int _preferredMorningMinutes(
    List<WorkoutSession> history,
    DateTime now,
  ) {
    final cutoff = now
        .subtract(const Duration(days: 42))
        .millisecondsSinceEpoch;
    final starts =
        history
            .where(
              (session) =>
                  StreakCalculator.qualifies(session) &&
                  session.startTime >= cutoff &&
                  session.startTime <= now.millisecondsSinceEpoch,
            )
            .map((session) {
              final local = DateTime.fromMillisecondsSinceEpoch(
                session.startTime,
              );
              return local.hour * 60 + local.minute;
            })
            .toList()
          ..sort();
    if (starts.length < 3) return 7 * 60 + 30;
    final median = starts.length.isOdd
        ? starts[starts.length ~/ 2]
        : ((starts[starts.length ~/ 2 - 1] + starts[starts.length ~/ 2]) / 2)
              .round();
    return (median - 120).clamp(6 * 60, 8 * 60 + 30);
  }

  static String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static DateTime _ceilToMinute(DateTime value) {
    if (value.second == 0 && value.millisecond == 0 && value.microsecond == 0) {
      return value;
    }
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute + 1,
    );
  }
}
