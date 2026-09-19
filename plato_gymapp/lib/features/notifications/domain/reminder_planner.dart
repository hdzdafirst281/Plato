import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/streak_calculator.dart';
import 'notification_policy.dart';

class ReminderPlanner {
  static List<ReminderCandidate> build({
    required DateTime now,
    required List<ScheduledWorkoutEntity> schedules,
    required List<WorkoutSession> history,
    required UserProfile profile,
    required double water,
    required double target,
    required bool waterEnabled,
    required DateTime Function(ScheduledWorkoutEntity) scheduledTime,
    required String Function(String) routineName,
    bool inactivityEnabled = false,
    bool activeWorkout = false,
    int? activeWorkoutStartedAt,
    int horizonDays = 30,
    Map<String, double> waterByDay = const {},
  }) {
    final result = <ReminderCandidate>[];
    final horizon = DateTime(now.year, now.month, now.day + horizonDays);
    for (final schedule in schedules) {
      if (!schedule.reminderEnabled ||
          schedule.isCompleted ||
          schedule.isDeleted ||
          schedule.timeOfDayMinutes == null)
        continue;
      final start = scheduledTime(schedule);
      // A currently active workout suppresses reminders within that workout window.
      if (activeWorkout && start.isBefore(now.add(const Duration(hours: 3))))
        continue;
      final at = start.subtract(
        Duration(minutes: schedule.reminderMinutesBefore),
      );
      if (!at.isAfter(now) || at.isAfter(horizon)) continue;
      result.add(
        ReminderCandidate(
          key: 'workout:${schedule.id}',
          kind: ReminderKind.workout,
          at: at,
          titleKey: 'notifications.title_workout_reminder',
          bodyKey: 'notifications.body_workout_reminder',
          arguments: {
            'routineName': routineName(schedule.routineName),
            'time':
                '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
          },
          route: '/profile/calendar',
          sourceId: schedule.id,
        ),
      );
    }
    // Hand each day's reminder to the OS in advance; today's progress must
    // never be copied into tomorrow. Future logs, when present, remain authoritative.
    if (waterEnabled)
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
                ? {}
                : {
                    'consumed': consumed.toStringAsFixed(2),
                    'target': target.toStringAsFixed(2),
                    if (consumed / target >= .5)
                      'remaining': (target - consumed).toStringAsFixed(2),
                  },
            route: '/nutrition?water=1',
          ),
        );
      }
    if (history.isEmpty) return result;
    // Evaluate upcoming Sundays against the known history. A workout this
    // week protects this Sunday, but next Sunday can still put the streak at risk.
    for (var offset = 0; offset < horizonDays; offset++) {
      final sunday = DateTime(now.year, now.month, now.day + offset, 17);
      if (sunday.weekday != DateTime.sunday || !sunday.isAfter(now)) continue;
      final week = StreakCalculator.weekStart(sunday);
      final streak = StreakCalculator.count(history, sunday);
      final hasSundaySchedule = schedules.any(
        (s) =>
            !s.isDeleted &&
            !s.isCompleted &&
            s.reminderEnabled &&
            s.timeOfDayMinutes != null &&
            NotificationPolicy.dayKey(scheduledTime(s)) ==
                NotificationPolicy.dayKey(sunday) &&
            scheduledTime(s).isAfter(sunday),
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
    if (end.isBefore(horizon.add(const Duration(days: 2)))) {
      result.add(
        ReminderCandidate(
          key: 'rank:${season.cycleStartTimeMillis}',
          kind: ReminderKind.rank,
          at: end.subtract(const Duration(hours: 48)),
          titleKey: 'notifications.title_rank_ending',
          bodyKey: 'notifications.body_rank_ending',
          arguments: {'date': '${end.day}/${end.month}/${end.year}'},
          route: '/social/rank_screen',
        ),
      );
    }
    if (inactivityEnabled &&
        !activeWorkout &&
        !schedules.any(
          (s) =>
              !s.isCompleted && !s.isDeleted && scheduledTime(s).isAfter(now),
        )) {
      final valid = history.where(StreakCalculator.qualifies).toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      if (valid.isNotEmpty) {
        final last = DateTime.fromMillisecondsSinceEpoch(valid.first.startTime);
        for (final days in [14, 28]) {
          final at = DateTime(last.year, last.month, last.day + days, 10);
          if (at.isBefore(horizon))
            result.add(
              ReminderCandidate(
                key: 'inactivity:${valid.first.id}:$days',
                kind: ReminderKind.inactivity,
                at: at,
                titleKey: 'notifications.title_inactivity',
                bodyKey: 'notifications.body_inactivity',
                route: '/workout',
              ),
            );
        }
      }
    }
    return result;
  }
}
