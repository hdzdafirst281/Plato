import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/streak_calculator.dart';
import 'package:plato_gymapp/features/notifications/domain/reminder_planner.dart';
import 'package:plato_gymapp/features/notifications/domain/notification_policy.dart';
import 'package:plato_gymapp/features/notifications/data/notification_copy.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

WorkoutSession workout(
  DateTime at, {
  String id = 'w',
  bool completed = true,
  bool deleted = false,
  int reps = 5,
}) => WorkoutSession(
  id: id,
  name: 'Workout',
  startTime: at.millisecondsSinceEpoch,
  endTime: completed
      ? at.add(const Duration(minutes: 30)).millisecondsSinceEpoch
      : null,
  updatedAt: at.millisecondsSinceEpoch,
  isDeleted: deleted,
  sessionPayload: WorkoutSessionPayload(
    exercises: [
      WorkoutExercise(
        id: 'e',
        exercise: Exercise(
          id: 'e',
          name: 'Exercise',
          type: ExerciseType.REPS_ONLY,
          isDeleted: false,
        ),
        sets: [ExerciseSet(id: 'set', isCompleted: completed, reps: reps)],
      ),
    ],
  ),
);
ScheduledWorkoutEntity schedule({
  int? minutes = 18 * 60,
  bool completed = false,
  bool reminder = true,
}) => ScheduledWorkoutEntity(
  id: 's',
  routineId: 'r',
  routineName: 'Upper',
  targetDateMillis: DateTime(2026, 9, 13).millisecondsSinceEpoch,
  timeOfDayMinutes: minutes,
  reminderEnabled: reminder,
  isCompleted: completed,
  syncStatus: 'PENDING',
  updatedAt: 0,
  isDeleted: false,
);
List<ReminderCandidate> plan({
  DateTime? now,
  List<WorkoutSession> history = const [],
  List<ScheduledWorkoutEntity> schedules = const [],
  double water = 0,
  double target = 2,
  bool active = false,
  bool inactivity = false,
}) => ReminderPlanner.build(
  now: now ?? DateTime(2026, 9, 13, 12),
  history: history,
  schedules: schedules,
  profile: const UserProfile(
    targetMacros: Macros(),
    detailedBodyMetrics: BodyMetrics(),
  ),
  water: water,
  target: target,
  waterEnabled: true,
  scheduledTime: (s) {
    final d = DateTime.fromMillisecondsSinceEpoch(s.targetDateMillis);
    final m = s.timeOfDayMinutes ?? 0;
    return DateTime(d.year, d.month, d.day, m ~/ 60, m % 60);
  },
  routineName: (s) => s,
  activeWorkout: active,
  inactivityEnabled: inactivity,
);
void main() {
  test('legacy schedule keeps nullable time and reminder off', () {
    final s = ScheduledWorkout.fromJson({
      'id': 's',
      'routineId': 'r',
      'routineName': 'r',
      'targetDateMillis': 0,
    });
    expect(s.timeOfDayMinutes, isNull);
    expect(s.reminderEnabled, isFalse);
  });
  test('linked schedule survives session JSON round-trip', () {
    final s = workout(DateTime(2026, 9, 13));
    final linked = s.copyWith(
      sessionPayload: s.sessionPayload.copyWith(
        scheduledWorkoutId: 'scheduled',
      ),
    );
    expect(
      WorkoutSession.fromJson(
        jsonDecode(jsonEncode(linked.toJson())) as Map<String, dynamic>,
      ).sessionPayload.scheduledWorkoutId,
      'scheduled',
    );
  });
  test('qualifying excludes deleted, unfinished and empty workouts', () {
    final d = DateTime(2026, 9, 13);
    expect(StreakCalculator.qualifies(workout(d)), isTrue);
    expect(StreakCalculator.qualifies(workout(d, deleted: true)), isFalse);
    expect(StreakCalculator.qualifies(workout(d, completed: false)), isFalse);
    expect(StreakCalculator.qualifies(workout(d, reps: 0)), isFalse);
  });
  test('weekly streak extends only once and expires on Monday', () {
    final history = [
      workout(DateTime(2026, 8, 31)),
      workout(DateTime(2026, 9, 7)),
      workout(DateTime(2026, 9, 8)),
    ];
    expect(StreakCalculator.count(history, DateTime(2026, 9, 13)), 2);
    expect(StreakCalculator.count(history, DateTime(2026, 9, 20)), 2);
    expect(StreakCalculator.count(history, DateTime(2026, 9, 21)), 0);
  });
  test('future workouts do not qualify for this week', () {
    expect(
      StreakCalculator.count([
        workout(DateTime(2026, 9, 15)),
      ], DateTime(2026, 9, 13)),
      0,
    );
  });
  test('hydration is exactly 16 and never scheduled after the slot', () {
    expect(plan().single.at, DateTime(2026, 9, 13, 16));
    expect(plan(now: DateTime(2026, 9, 13, 16)), isEmpty);
    expect(plan(now: DateTime(2026, 9, 13, 17)), isEmpty);
    expect(plan(water: 2), isEmpty);
  });
  test('a timed workout is reminded 30 minutes before', () {
    final result = plan(schedules: [schedule()]);
    expect(
      result.firstWhere((e) => e.kind == ReminderKind.workout).at,
      DateTime(2026, 9, 13, 17, 30),
    );
  });
  test('date-only, completed and disabled schedules never emit reminders', () {
    for (final s in [
      schedule(minutes: null),
      schedule(completed: true),
      schedule(reminder: false),
    ]) {
      expect(
        plan(schedules: [s]).where((e) => e.kind == ReminderKind.workout),
        isEmpty,
      );
    }
  });
  test(
    'Sunday streak warning requires an existing streak and no workout this week',
    () {
      expect(
        plan(
          history: [workout(DateTime(2026, 9, 6))],
        ).where((e) => e.kind == ReminderKind.streak).length,
        1,
      );
      expect(
        plan(
          history: [workout(DateTime(2026, 9, 7))],
        ).where((e) => e.kind == ReminderKind.streak),
        isEmpty,
      );
    },
  );
  test('a Sunday evening workout reminder replaces streak warning', () {
    expect(
      plan(
        history: [workout(DateTime(2026, 9, 6))],
        schedules: [schedule()],
      ).where((e) => e.kind == ReminderKind.streak),
      isEmpty,
    );
  });
  test(
    'inactivity experiment is disabled by default and limited to two candidates',
    () {
      final history = [workout(DateTime(2026, 8, 31))];
      expect(
        plan(history: history).where((e) => e.kind == ReminderKind.inactivity),
        isEmpty,
      );
      expect(
        plan(
          history: history,
          inactivity: true,
        ).where((e) => e.kind == ReminderKind.inactivity).length,
        lessThanOrEqualTo(2),
      );
    },
  );
  test('all hydration copy variants render in both Sheet locales', () {
    for (final locale in [AppLocale.en, AppLocale.vi]) {
      LocaleSettings.setLocale(locale);
      expect(NotificationCopy.available, isTrue);
      expect(
        NotificationCopy.text('notifications.body_hydration_no_log'),
        isNotEmpty,
      );
      expect(
        NotificationCopy.text('notifications.body_hydration_low', {
          'consumed': '0.5',
          'target': '2',
        }),
        contains('0.5'),
      );
      expect(
        NotificationCopy.text('notifications.body_hydration_progress', {
          'consumed': '1',
          'target': '2',
          'remaining': '1',
        }),
        isNotEmpty,
      );
    }
  });
}
