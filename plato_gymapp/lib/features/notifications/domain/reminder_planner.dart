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
  }) {
    final result = <ReminderCandidate>[];
    final horizon = now.add(const Duration(days: 14));
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
    final waterBody = NotificationPolicy.hydrationBody(water, target);
    final waterAt = DateTime(now.year, now.month, now.day, 16);
    // Do not replenish today's reminder after a workout overlapping 16:00.
    final overlapsWater = activeWorkout;
    if (waterEnabled &&
        waterBody != null &&
        !overlapsWater &&
        waterAt.isAfter(now)) {
      result.add(
        ReminderCandidate(
          key: 'hydration:${NotificationPolicy.dayKey(now)}',
          kind: ReminderKind.hydration,
          at: waterAt,
          titleKey: 'notifications.title_hydration_reminder',
          bodyKey: waterBody,
          arguments: water <= 0
              ? {}
              : water / target < .5
              ? {
                  'consumed': water.toStringAsFixed(2),
                  'target': target.toStringAsFixed(2),
                }
              : {
                  'consumed': water.toStringAsFixed(2),
                  'target': target.toStringAsFixed(2),
                  'remaining': (target - water).toStringAsFixed(2),
                },
          route: '/nutrition?water=1',
        ),
      );
    }
    if (history.isEmpty) return result;
    final week = StreakCalculator.weekStart(now);
    final streak = StreakCalculator.count(history, now);
    final sunday = DateTime(week.year, week.month, week.day + 6, 17);
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
    if (!activeWorkout &&
        streak > 0 &&
        !StreakCalculator.weeks(history, now).contains(week) &&
        !hasSundaySchedule) {
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
