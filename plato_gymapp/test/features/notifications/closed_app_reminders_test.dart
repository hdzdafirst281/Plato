import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';
import 'package:plato_gymapp/features/notifications/domain/notification_policy.dart';
import 'package:plato_gymapp/features/notifications/domain/reminder_planner.dart';
import 'package:plato_gymapp/features/notifications/domain/recovery_forecast_service.dart';
import 'package:plato_gymapp/features/notifications/data/notification_copy.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/muscle_exposure_calculator.dart';
import 'package:plato_gymapp/features/workout/domain/recovery_scale.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

const profile = UserProfile(
  targetMacros: Macros(),
  detailedBodyMetrics: BodyMetrics(),
);

List<ReminderCandidate> plan({
  double water = 0,
  DateTime? now,
  DateTime? lastAppOpenedAt,
  List<ScheduledWorkoutEntity> schedules = const [],
  List<WorkoutSession> history = const [],
  int horizonDays = 30,
  String? lastDeliveredRecoverySignature,
  bool recoveryEnabled = true,
  bool streakEnabled = true,
  bool rankEnabled = true,
  Map<String, WorkoutSession> routinesById = const {},
  String Function(List<String>)? compactMuscleNames,
}) {
  final current = now ?? DateTime(2026, 9, 24, 12);
  return ReminderPlanner.build(
    now: current,
    schedules: schedules,
    history: history,
    routinesById: routinesById,
    profile: profile,
    water: water,
    target: 2,
    waterEnabled: true,
    recoveryEnabled: recoveryEnabled,
    streakEnabled: streakEnabled,
    rankEnabled: rankEnabled,
    lastAppOpenedAt: lastAppOpenedAt ?? current,
    horizonDays: horizonDays,
    muscleName: (muscle) => muscle.name,
    compactMuscleNames: compactMuscleNames,
    scheduledTime: (s) => DateTime.fromMillisecondsSinceEpoch(
      s.targetDateMillis,
    ).add(Duration(minutes: s.timeOfDayMinutes ?? 0)),
    routineName: (s) => s,
    lastDeliveredRecoverySignature: lastDeliveredRecoverySignature,
  );
}

WorkoutSession completedWorkout(
  DateTime startedAt, {
  List<MuscleGroup> muscles = const [MuscleGroup.MIDDLE_CHEST],
}) => WorkoutSession(
  id: 'workout-${startedAt.millisecondsSinceEpoch}-${muscles.join(',')}',
  name: 'Workout',
  startTime: startedAt.millisecondsSinceEpoch,
  endTime: startedAt.add(const Duration(hours: 1)).millisecondsSinceEpoch,
  updatedAt: startedAt.millisecondsSinceEpoch,
  sessionPayload: WorkoutSessionPayload(
    exercises: [
      for (final muscle in muscles)
        WorkoutExercise(
          id: 'exercise-${muscle.name}',
          exercise: Exercise(
            id: 'exercise-${muscle.name}',
            name: muscle.name,
            primaryMuscle: muscle,
            type: ExerciseType.REPS_ONLY,
            isDeleted: false,
          ),
          sets: const [ExerciseSet(id: 'set', reps: 5, isCompleted: true)],
        ),
    ],
  ),
);

void main() {
  test(
    'OS receives thirty dated water reminders without tomorrow inheriting progress',
    () {
      final items = plan(
        water: 1,
      ).where((e) => e.kind == ReminderKind.hydration).toList();
      expect(items.length, 30);
      expect(items.map((e) => e.key).toSet().length, 30);
      expect(items.every((e) => e.at.hour == 16 && e.at.minute == 0), isTrue);
      expect(items.first.bodyKey, 'notifications.body_hydration_progress');
      expect(items[1].bodyKey, 'notifications.body_hydration_no_log');
    },
  );
  test(
    'goal cancels only today and reopening after 16 never replays today',
    () {
      expect(
        plan(water: 2).where((e) => e.kind == ReminderKind.hydration).length,
        29,
      );
      final after = plan(
        now: DateTime(2026, 9, 24, 17),
      ).where((e) => e.kind == ReminderKind.hydration).toList();
      expect(after.length, 29);
      expect(after.first.at, DateTime(2026, 9, 25, 16));
    },
  );
  test('tomorrow 10am schedule produces 9:30 OS reminder today', () {
    final items = plan(
      schedules: [
        ScheduledWorkoutEntity(
          id: 's',
          routineId: 'r',
          routineName: 'Routine',
          targetDateMillis: DateTime(2026, 9, 25).millisecondsSinceEpoch,
          timeOfDayMinutes: 600,
          reminderEnabled: true,
          reminderMinutesBefore: 30,
          isCompleted: false,
          isDeleted: false,
          syncStatus: 'PENDING',
          updatedAt: 0,
        ),
      ],
    );
    expect(
      items.singleWhere((e) => e.kind == ReminderKind.workout).at,
      DateTime(2026, 9, 25, 9, 30),
    );
  });
  test('workout and hydration can coexist under the daily cap', () {
    final items = plan();
    final workout = ReminderCandidate(
      key: 'w',
      kind: ReminderKind.workout,
      at: DateTime(2026, 9, 24, 17),
      titleKey: '',
      bodyKey: '',
      route: '',
    );
    final selected = NotificationPolicy.select([
      ...items,
      workout,
    ], now: DateTime(2026, 9, 24, 12));
    expect(selected.any((e) => e.key == 'w'), isTrue);
    expect(
      selected.any(
        (e) =>
            e.kind == ReminderKind.hydration &&
            NotificationPolicy.dayKey(e.at) == '2026-09-24',
      ),
      isTrue,
    );
  });
  test('finite queue keeps nearest days without filtering late hours', () {
    final selected = NotificationPolicy.select(
      plan(),
      now: DateTime(2026, 9, 24, 12),
      pendingLimit: 2,
    );
    expect(selected.map((e) => e.at.day), [24, 25]);
    final late = ReminderCandidate(
      key: 'late',
      kind: ReminderKind.workout,
      at: DateTime(2026, 9, 24, 23),
      titleKey: '',
      bodyKey: '',
      route: '',
    );
    expect(NotificationPolicy.select([late], now: DateTime(2026, 9, 24, 12)), [
      late,
    ]);
  });
  test('streak at risk is scheduled on Sunday at 08:00', () {
    final streak = plan(
      history: [completedWorkout(DateTime(2026, 9, 17, 18))],
    ).singleWhere((e) => e.kind == ReminderKind.streak);
    expect(streak.at, DateTime(2026, 9, 27, 8));
  });
  test('rank ending is scheduled three calendar days earlier at 10:00', () {
    final history = [completedWorkout(DateTime(2026, 8, 20, 18))];
    final now = DateTime(2026, 9, 24, 12);
    final season = RankCalculator.calculateTrueRankAndSeasons(
      history,
      profile,
      now.millisecondsSinceEpoch,
    );
    final end = DateTime.fromMillisecondsSinceEpoch(season.cycleEndTimeMillis);
    final rank = plan(
      now: now,
      history: history,
      horizonDays: 60,
    ).singleWhere((e) => e.kind == ReminderKind.rank);
    expect(rank.at, DateTime(end.year, end.month, end.day - 3, 10));
  });
  test('long inactivity is scheduled once after fourteen days at 20:00', () {
    final inactive = plan(
      now: DateTime(2026, 9, 10, 12),
      lastAppOpenedAt: DateTime(2026, 9, 1, 9),
    ).where((e) => e.kind == ReminderKind.inactivity).toList();
    expect(inactive, hasLength(1));
    expect(inactive.single.at, DateTime(2026, 9, 15, 20));
  });
  test('recovery uses the same normalized scale as the recovery bar', () {
    final now = DateTime(2026, 9, 24, 5);
    final history = [completedWorkout(DateTime(2026, 9, 23, 6))];
    final recovery = plan(
      now: now,
      history: history,
    ).firstWhere((e) => e.kind == ReminderKind.recovery);
    expect(recovery.at, DateTime(2026, 9, 24, 7, 30));
    final snapshot = RecoveryForecastService(
      history,
      at: now,
    ).snapshotAt(recovery.at);
    expect(
      snapshot.muscles[MajorMuscleGroup.CHEST]!.percentage,
      greaterThanOrEqualTo(80),
    );
    expect(recovery.bodyKey, 'notifications.body_recovery_all_ready');
  });
  test('recovery completes after one post-ready fatigue half-life', () {
    final justBelowFull = RecoveryScale.fullRecoveryRawPercentage - .01;
    final fatigueAt90 = RecoveryScale.targetFatigueForDisplayPercentage(90);

    expect(RecoveryScale.readyFatigue, closeTo(24, .0001));
    expect(RecoveryScale.fullRecoveryFatigue, closeTo(12, .0001));
    expect(RecoveryScale.displayPercentageFromRaw(76), 80);
    expect(RecoveryScale.displayPercentageFromRaw(justBelowFull), 99);
    expect(RecoveryScale.aggregateDisplayPercentage(99.49), 99);
    expect(RecoveryScale.aggregateDisplayPercentage(99.5), 100);
    expect(RecoveryScale.aggregateDisplayPercentage(79.99), 79);
    expect(
      RecoveryScale.displayPercentageFromRaw(
        RecoveryScale.fullRecoveryRawPercentage,
      ),
      100,
    );
    expect(
      RecoveryScale.targetFatigueForDisplayPercentage(100),
      closeTo(RecoveryScale.fullRecoveryFatigue, .0001),
    );
    expect(
      fatigueAt90 * fatigueAt90,
      closeTo(
        RecoveryScale.readyFatigue * RecoveryScale.fullRecoveryFatigue,
        .0001,
      ),
    );
    for (final percentage in [80, 90, 95, 99, 100]) {
      expect(
        RecoveryScale.displayPercentageFromRaw(
          100 - RecoveryScale.targetFatigueForDisplayPercentage(percentage),
        ),
        percentage,
      );
    }
  });
  test(
    'recovery advises waiting until evening when some groups are at 50%',
    () {
      final recovery = plan(
        now: DateTime(2026, 9, 24, 5),
        history: [
          completedWorkout(
            DateTime(2026, 9, 23, 23),
            muscles: const [
              MuscleGroup.MIDDLE_CHEST,
              MuscleGroup.LATS,
              MuscleGroup.QUADS,
              MuscleGroup.FRONT_DELTS,
              MuscleGroup.BICEPS,
              MuscleGroup.ABS,
            ],
          ),
        ],
      ).firstWhere((e) => e.kind == ReminderKind.recovery);
      expect(recovery.at, DateTime(2026, 9, 24, 7, 30));
      expect(recovery.bodyKey, 'notifications.body_recovery_ready_later');
      expect(recovery.arguments['muscles'], isNotEmpty);
    },
  );
  test('recovery advises waiting when red groups reach yellow by noon', () {
    final recovery = plan(
      now: DateTime(2026, 9, 24, 5),
      history: [
        completedWorkout(
          DateTime(2026, 9, 24, 4),
          muscles: const [
            MuscleGroup.MIDDLE_CHEST,
            MuscleGroup.LATS,
            MuscleGroup.QUADS,
            MuscleGroup.FRONT_DELTS,
            MuscleGroup.BICEPS,
            MuscleGroup.ABS,
          ],
        ),
      ],
    ).firstWhere((e) => e.kind == ReminderKind.recovery);
    expect(recovery.at, DateTime(2026, 9, 24, 7, 30));
    expect(recovery.titleKey, 'notifications.title_recovery_ready_later');
    expect(recovery.bodyKey, 'notifications.body_recovery_ready_later');
  });
  test('recovery recommends training at the default morning time', () {
    final recovery = plan(
      now: DateTime(2026, 9, 24, 5),
      history: [completedWorkout(DateTime(2026, 9, 20, 6))],
    ).firstWhere((e) => e.kind == ReminderKind.recovery);
    expect(recovery.at, DateTime(2026, 9, 24, 7, 30));
    expect(recovery.titleKey, 'notifications.title_recovery_all_ready');
    expect(recovery.bodyKey, 'notifications.body_recovery_all_ready');
    expect(recovery.arguments, isEmpty);
  });
  test('recovery lists only green groups when recovery is partial', () {
    final recovery = plan(
      now: DateTime(2026, 9, 24, 5),
      history: [completedWorkout(DateTime(2026, 9, 23, 23))],
    ).firstWhere((e) => e.kind == ReminderKind.recovery);
    expect(recovery.at, DateTime(2026, 9, 24, 7, 30));
    expect(recovery.bodyKey, 'notifications.body_recovery_ready');
    expect(recovery.arguments['muscles'], isNot(contains('CHEST')));
    expect(recovery.arguments['muscles'], contains('BACK'));
  });
  test('recovery thresholds classify 39, 40, 79 and 80 correctly', () {
    const majors = [
      MajorMuscleGroup.CHEST,
      MajorMuscleGroup.BACK,
      MajorMuscleGroup.LEGS,
      MajorMuscleGroup.SHOULDERS,
      MajorMuscleGroup.ARMS,
      MajorMuscleGroup.CORE,
    ];
    Map<MajorMuscleGroup, int> scores(int value) => {
      for (final major in majors) major: value,
    };

    expect(
      ReminderPlanner.classifyRecovery(scores(39)),
      RecoveryNotificationState.restToday,
    );
    expect(
      ReminderPlanner.classifyRecovery({
        ...scores(39),
        MajorMuscleGroup.CHEST: 40,
      }),
      RecoveryNotificationState.readyLater,
    );
    expect(
      ReminderPlanner.classifyRecovery({
        ...scores(39),
        MajorMuscleGroup.CHEST: 79,
      }),
      RecoveryNotificationState.readyLater,
    );
    expect(
      ReminderPlanner.classifyRecovery({
        ...scores(39),
        MajorMuscleGroup.CHEST: 80,
      }),
      RecoveryNotificationState.partialReady,
    );
    expect(
      ReminderPlanner.classifyRecovery(scores(80)),
      RecoveryNotificationState.allReady,
    );
  });
  test('routine risk boundaries use exposure and severity', () {
    RoutineRecoveryState classify({
      double redShare = 0,
      double yellowShare = 0,
      double redSeverity = 0,
      double waitSeverity = 0,
      bool dominantCritical = false,
    }) => RecoveryForecastService.classifyRoutineRisk(
      redShare: redShare,
      yellowShare: yellowShare,
      redSeverity: redSeverity,
      waitSeverity: waitSeverity,
      hasDominantCriticalMuscle: dominantCritical,
    );

    expect(classify(redShare: 19.9), RoutineRecoveryState.readyAdjusted);
    expect(classify(redShare: 20), RoutineRecoveryState.readyAdjusted);
    expect(classify(redShare: 20.1), RoutineRecoveryState.nearlyReady);
    expect(classify(redShare: 39.9), RoutineRecoveryState.nearlyReady);
    expect(classify(redShare: 40), RoutineRecoveryState.low);
    expect(classify(redShare: 35, redSeverity: 30), RoutineRecoveryState.low);
    expect(
      classify(redShare: 30, dominantCritical: true),
      RoutineRecoveryState.low,
    );
    expect(
      classify(redShare: 20, yellowShare: 20),
      RoutineRecoveryState.nearlyReady,
    );
    expect(
      classify(yellowShare: 30, waitSeverity: 19.9),
      RoutineRecoveryState.ready,
    );
    expect(
      classify(yellowShare: 30, waitSeverity: 20),
      RoutineRecoveryState.nearlyReady,
    );
    expect(
      classify(redShare: 20, waitSeverity: 20.5),
      RoutineRecoveryState.readyAdjusted,
    );
    expect(
      classify(yellowShare: 20, waitSeverity: 20),
      RoutineRecoveryState.ready,
    );
  });
  test('muscle split ignores warmups and deduplicates secondary majors', () {
    final exercise = WorkoutExercise(
      id: 'split',
      exercise: Exercise(
        id: 'split',
        name: 'Split',
        primaryMuscle: MuscleGroup.MIDDLE_CHEST,
        secondaryMuscles: const [MuscleGroup.BICEPS, MuscleGroup.TRICEPS],
        type: ExerciseType.REPS_ONLY,
        isDeleted: false,
      ),
      sets: const [
        ExerciseSet(id: 'warmup', type: SetType.WARMUP),
        ExerciseSet(id: 'work-1'),
        ExerciseSet(id: 'work-2', type: SetType.SUPERSET),
      ],
    );
    final distribution = MuscleExposureCalculator.distribution([exercise]);
    expect(distribution[MajorMuscleGroup.CHEST], closeTo(75, .001));
    expect(distribution[MajorMuscleGroup.ARMS], closeTo(25, .001));
    expect(
      distribution.entries
          .where(
            (entry) =>
                entry.key != MajorMuscleGroup.CHEST &&
                entry.key != MajorMuscleGroup.ARMS,
          )
          .every((entry) => entry.value == 0),
      isTrue,
    );
  });
  test(
    'all-ready recovery is sent once and then pauses until history changes',
    () {
      final recoveries = plan(
        now: DateTime(2026, 9, 24, 5),
        history: [completedWorkout(DateTime(2026, 9, 20, 6))],
      ).where((e) => e.kind == ReminderKind.recovery).toList();
      expect(recoveries, hasLength(1));
      final signature = recoveries.single.metadata['recoverySignature'];
      final suppressed = plan(
        now: DateTime(2026, 9, 25, 5),
        history: [completedWorkout(DateTime(2026, 9, 20, 6))],
        lastDeliveredRecoverySignature: signature,
      ).where((e) => e.kind == ReminderKind.recovery);
      expect(suppressed, isEmpty);
    },
  );
  test('policy automatically caps OS notifications at four per day', () {
    final at = DateTime(2026, 9, 25, 8);
    final candidates = [
      for (var i = 0; i < 3; i++)
        ReminderCandidate(
          key: 'workout-$i',
          kind: ReminderKind.workout,
          at: at.add(Duration(minutes: i)),
          titleKey: '',
          bodyKey: '',
          route: '',
        ),
      ReminderCandidate(
        key: 'recovery',
        kind: ReminderKind.recovery,
        at: at,
        titleKey: '',
        bodyKey: '',
        route: '',
      ),
      ReminderCandidate(
        key: 'hydration',
        kind: ReminderKind.hydration,
        at: at,
        titleKey: '',
        bodyKey: '',
        route: '',
      ),
      ReminderCandidate(
        key: 'streak',
        kind: ReminderKind.streak,
        at: at,
        titleKey: '',
        bodyKey: '',
        route: '',
      ),
    ];
    final selected = NotificationPolicy.select(
      candidates,
      now: DateTime(2026, 9, 24),
    );
    expect(selected, hasLength(4));
    expect(selected.any((e) => e.kind == ReminderKind.streak), isTrue);
    expect(selected.any((e) => e.kind == ReminderKind.recovery), isFalse);
  });
  test('workout reminder capacity disables only overflowing occurrences', () {
    final now = DateTime(2026, 9, 24, 7);
    final overflow = NotificationPolicy.workoutReminderOverflowTargetDates(
      now: now,
      existingReminderTimes: [
        DateTime(2026, 9, 24, 8),
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 24, 10),
        DateTime(2026, 9, 23, 20),
      ],
      requests: [
        (
          targetDateMillis: DateTime(2026, 9, 24).millisecondsSinceEpoch,
          reminderAt: DateTime(2026, 9, 24, 11),
        ),
        (
          targetDateMillis: DateTime(2026, 9, 25).millisecondsSinceEpoch,
          reminderAt: DateTime(2026, 9, 24, 12),
        ),
        (
          targetDateMillis: DateTime(2026, 9, 26).millisecondsSinceEpoch,
          reminderAt: DateTime(2026, 9, 25, 8),
        ),
      ],
    );

    expect(overflow, {DateTime(2026, 9, 25).millisecondsSinceEpoch});
  });

  test('rank reminder moves earlier when its preferred day is crowded', () {
    final preferred = DateTime(2026, 9, 27, 10);
    final earlier = DateTime(2026, 9, 26, 10);
    final candidates = [
      for (var i = 0; i < 3; i++)
        ReminderCandidate(
          key: 'workout-$i',
          kind: ReminderKind.workout,
          at: DateTime(2026, 9, 27, 8 + i),
          titleKey: '',
          bodyKey: '',
          route: '',
        ),
      ReminderCandidate(
        key: 'rank',
        kind: ReminderKind.rank,
        at: preferred,
        titleKey: '',
        bodyKey: '',
        route: '',
        alternatives: [ReminderDeliveryOption(at: earlier)],
      ),
    ];
    final selected = NotificationPolicy.select(
      candidates,
      now: DateTime(2026, 9, 24),
    );
    expect(selected.singleWhere((item) => item.key == 'rank').at, earlier);
  });

  test('recovery uses an evening preview when its morning is crowded', () {
    final morning = DateTime(2026, 9, 25, 7, 30);
    final preview = DateTime(2026, 9, 24, 20, 30);
    final selected = NotificationPolicy.select([
      for (var i = 0; i < 3; i++)
        ReminderCandidate(
          key: 'workout-$i',
          kind: ReminderKind.workout,
          at: DateTime(2026, 9, 25, 8 + i),
          titleKey: '',
          bodyKey: '',
          route: '',
        ),
      ReminderCandidate(
        key: 'recovery:2026-09-25',
        kind: ReminderKind.recovery,
        at: morning,
        titleKey: 'today-title',
        bodyKey: 'today-body',
        route: '',
        alternatives: [
          ReminderDeliveryOption(
            at: preview,
            titleKey: 'tomorrow-title',
            bodyKey: 'tomorrow-body',
          ),
        ],
      ),
    ], now: DateTime(2026, 9, 24, 12));
    final recovery = selected.singleWhere(
      (item) => item.kind == ReminderKind.recovery,
    );
    expect(recovery.at, preview);
    expect(recovery.titleKey, 'tomorrow-title');
    expect(recovery.bodyKey, 'tomorrow-body');
  });

  test('recovery morning follows recent workout habits', () {
    final recovery = plan(
      now: DateTime(2026, 9, 24, 5),
      history: [
        completedWorkout(DateTime(2026, 9, 20, 10)),
        completedWorkout(DateTime(2026, 9, 21, 10)),
        completedWorkout(DateTime(2026, 9, 22, 10)),
      ],
    ).firstWhere((item) => item.kind == ReminderKind.recovery);
    expect(recovery.at, DateTime(2026, 9, 24, 8));
  });

  test('four user workout reminders are kept and a fifth is rejected', () {
    final selected = NotificationPolicy.select([
      for (var i = 0; i < 5; i++)
        ReminderCandidate(
          key: 'workout-$i',
          kind: ReminderKind.workout,
          at: DateTime(2026, 9, 25, 8, i),
          titleKey: '',
          bodyKey: '',
          route: '',
        ),
    ], now: DateTime(2026, 9, 24));
    expect(selected, hasLength(4));
  });

  test('a scheduled workout absorbs the same-day recovery reminder', () {
    final target = DateTime(2026, 9, 25);
    final items = plan(
      now: DateTime(2026, 9, 24, 5),
      history: [completedWorkout(DateTime(2026, 9, 23, 6))],
      schedules: [
        ScheduledWorkoutEntity(
          id: 'scheduled',
          routineId: 'routine',
          routineName: 'Push',
          targetDateMillis: target.millisecondsSinceEpoch,
          timeOfDayMinutes: 10 * 60,
          reminderEnabled: true,
          reminderMinutesBefore: 30,
          isCompleted: false,
          isDeleted: false,
          syncStatus: 'PENDING',
          updatedAt: 0,
        ),
      ],
    );
    final workout = items.singleWhere((item) => item.sourceId == 'scheduled');
    expect(
      workout.bodyKey,
      startsWith('notifications.body_workout_reminder_recovery_'),
    );
    expect(workout.metadata['recoverySignature'], isNotEmpty);
    expect(
      items.where(
        (item) =>
            item.kind == ReminderKind.recovery &&
            item.metadata['targetDay'] == '2026-09-25',
      ),
      isEmpty,
    );
  });
  test('scheduled workout uses adjusted-ready copy for a small red share', () {
    final now = DateTime(2026, 9, 24, 5);
    final routine = completedWorkout(
      now,
      muscles: const [
        MuscleGroup.MIDDLE_CHEST,
        MuscleGroup.LATS,
        MuscleGroup.QUADS,
        MuscleGroup.FRONT_DELTS,
        MuscleGroup.BICEPS,
        MuscleGroup.ABS,
      ],
    ).copyWith(id: 'full-body', name: 'Full body');
    final items = plan(
      now: now,
      history: [
        completedWorkout(
          now.subtract(const Duration(hours: 1)),
          muscles: const [MuscleGroup.QUADS],
        ),
      ],
      routinesById: {'full-body': routine},
      schedules: [
        ScheduledWorkoutEntity(
          id: 'adjusted',
          routineId: 'full-body',
          routineName: 'Full body',
          targetDateMillis: DateTime(2026, 9, 24).millisecondsSinceEpoch,
          timeOfDayMinutes: 10 * 60,
          reminderEnabled: true,
          reminderMinutesBefore: 30,
          isCompleted: false,
          isDeleted: false,
          syncStatus: 'PENDING',
          updatedAt: 0,
        ),
      ],
    );
    final workout = items.singleWhere((item) => item.sourceId == 'adjusted');
    expect(
      workout.bodyKey,
      'notifications.body_workout_reminder_recovery_adjusted',
    );
    expect(workout.arguments['muscles'], contains('LEGS'));
    expect(
      workout.metadata['recoveryState'],
      RoutineRecoveryState.readyAdjusted.name,
    );
  });
  test('external reminder model contains the six supported types', () {
    expect(ReminderKind.values, [
      ReminderKind.workout,
      ReminderKind.streak,
      ReminderKind.rank,
      ReminderKind.recovery,
      ReminderKind.hydration,
      ReminderKind.inactivity,
    ]);
  });
  test('planned OS reminders expose one contextual action', () {
    final now = DateTime(2026, 9, 24, 7);
    final items = plan(
      now: now,
      history: [completedWorkout(now.subtract(const Duration(days: 3)))],
      schedules: [
        ScheduledWorkoutEntity(
          id: 'action-schedule',
          routineId: 'routine',
          routineName: 'Push',
          targetDateMillis: DateTime(2026, 9, 25).millisecondsSinceEpoch,
          timeOfDayMinutes: 10 * 60,
          reminderEnabled: true,
          reminderMinutesBefore: 30,
          isCompleted: false,
          isDeleted: false,
          syncStatus: 'PENDING',
          updatedAt: 0,
        ),
      ],
    );
    expect(items, isNotEmpty);
    expect(items.every((item) => item.actionLabelKey != null), isTrue);
  });

  test('recovery copy uses the injected compact muscle formatter', () {
    final now = DateTime(2026, 9, 24, 7);
    final items = plan(
      now: now,
      history: [
        completedWorkout(
          now.subtract(const Duration(days: 4)),
          muscles: MuscleGroup.values,
        ),
      ],
      compactMuscleNames: (names) => 'compact:${names.length}',
    );
    final recovery = items.firstWhere(
      (item) => item.kind == ReminderKind.recovery,
    );
    expect(
      recovery.arguments.values.any((value) => value.startsWith('compact:')) ||
          recovery.metadata.values.any((value) => value.startsWith('compact:')),
      isTrue,
    );
  });
  test('category preferences remove candidates before daily allocation', () {
    final now = DateTime(2026, 9, 24, 7);
    final history = [completedWorkout(now.subtract(const Duration(hours: 6)))];
    final items = plan(
      now: now,
      history: history,
      recoveryEnabled: false,
      streakEnabled: false,
      rankEnabled: false,
    );
    expect(items.where((item) => item.kind == ReminderKind.recovery), isEmpty);
    expect(items.where((item) => item.kind == ReminderKind.streak), isEmpty);
    expect(items.where((item) => item.kind == ReminderKind.rank), isEmpty);
  });
  test('policy exposes why a reminder was dropped or moved', () {
    final now = DateTime(2026, 9, 24, 7);
    final at = DateTime(2026, 9, 24, 8);
    final candidates = [
      for (var i = 0; i < 4; i++)
        ReminderCandidate(
          key: 'workout-$i',
          kind: ReminderKind.workout,
          at: at.add(Duration(minutes: i)),
          titleKey: '',
          bodyKey: '',
          route: '',
        ),
      ReminderCandidate(
        key: 'recovery',
        kind: ReminderKind.recovery,
        at: at.add(const Duration(hours: 1)),
        titleKey: '',
        bodyKey: '',
        route: '',
      ),
    ];
    final result = NotificationPolicy.plan(candidates, now: now);
    expect(result.selected, hasLength(4));
    expect(
      result.suppressed.single.reason,
      ReminderSuppressionReason.dailyLimit,
    );
  });
  test(
    'shared forecast ranks a ready routine ahead of a recovering routine',
    () {
      final now = DateTime(2026, 9, 24, 7);
      final history = [
        completedWorkout(
          now.subtract(const Duration(hours: 4)),
          muscles: const [MuscleGroup.MIDDLE_CHEST],
        ),
      ];
      final chest = completedWorkout(
        now,
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ).copyWith(id: 'chest', name: 'Chest');
      final back = completedWorkout(
        now,
        muscles: const [MuscleGroup.LATS],
      ).copyWith(id: 'back', name: 'Back');
      final forecast = RecoveryForecastService(history, at: now);
      final ranked = forecast.rankRoutines([chest, back]);
      expect(ranked.first.routine.id, 'back');
      expect(ranked.first.state, RoutineRecoveryState.ready);
      expect(ranked.last.state, isNot(RoutineRecoveryState.ready));
    },
  );
  test('routine plan keeps two best options when every routine is ready', () {
    final now = DateTime(2026, 9, 24, 7);
    final history = [
      completedWorkout(
        now.subtract(const Duration(days: 5)),
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ),
    ];
    final routines = [
      completedWorkout(
        now,
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ).copyWith(id: 'chest', name: 'Chest'),
      completedWorkout(
        now,
        muscles: const [MuscleGroup.LATS],
      ).copyWith(id: 'back', name: 'Back'),
      completedWorkout(
        now,
        muscles: const [MuscleGroup.QUADS],
      ).copyWith(id: 'legs', name: 'Legs'),
    ];
    final result = RecoveryForecastService(
      history,
      at: now,
    ).planRoutines(routines);
    expect(result.state, RecoveryRoutinePlanState.allReady);
    expect(result.recommended, hasLength(2));
    expect(
      result.recommended.every(
        (item) => item.state == RoutineRecoveryState.ready,
      ),
      isTrue,
    );
    expect(result.cautions, isEmpty);
  });
  test(
    'all-ready routines prioritize muscles trained less in the last month',
    () {
      final now = DateTime(2026, 9, 24, 7);
      final history = [
        completedWorkout(
          now.subtract(const Duration(days: 5)),
          muscles: const [
            MuscleGroup.MIDDLE_CHEST,
            MuscleGroup.MIDDLE_CHEST,
            MuscleGroup.LATS,
            MuscleGroup.LATS,
          ],
        ),
        completedWorkout(
          now.subtract(const Duration(days: 7)),
          muscles: const [MuscleGroup.MIDDLE_CHEST, MuscleGroup.MIDDLE_CHEST],
        ),
        completedWorkout(
          now.subtract(const Duration(days: 9)),
          muscles: const [MuscleGroup.MIDDLE_CHEST, MuscleGroup.MIDDLE_CHEST],
        ),
        completedWorkout(
          now.subtract(const Duration(days: 11)),
          muscles: const [MuscleGroup.MIDDLE_CHEST, MuscleGroup.MIDDLE_CHEST],
        ),
        completedWorkout(
          now.subtract(const Duration(days: 13)),
          muscles: const [MuscleGroup.MIDDLE_CHEST, MuscleGroup.MIDDLE_CHEST],
        ),
      ];
      final chest = completedWorkout(
        now,
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ).copyWith(id: 'a-chest', name: 'Chest');
      final back = completedWorkout(
        now,
        muscles: const [MuscleGroup.LATS],
      ).copyWith(id: 'z-back', name: 'Back');

      final result = RecoveryForecastService(
        history,
        at: now,
      ).planRoutines([chest, back]);

      expect(result.state, RecoveryRoutinePlanState.allReady);
      expect(result.recommended.first.routine.id, 'z-back');
    },
  );
  test(
    'routine plan recommends rest and no routine when all muscles are red',
    () {
      final now = DateTime(2026, 9, 24, 7);
      final history = [
        completedWorkout(
          now.subtract(const Duration(hours: 3)),
          muscles: const [
            MuscleGroup.MIDDLE_CHEST,
            MuscleGroup.LATS,
            MuscleGroup.QUADS,
            MuscleGroup.FRONT_DELTS,
            MuscleGroup.BICEPS,
            MuscleGroup.ABS,
          ],
        ),
      ];
      final routines = [
        completedWorkout(
          now,
          muscles: const [MuscleGroup.MIDDLE_CHEST],
        ).copyWith(id: 'chest', name: 'Chest'),
        completedWorkout(
          now,
          muscles: const [MuscleGroup.LATS],
        ).copyWith(id: 'back', name: 'Back'),
      ];
      final forecast = RecoveryForecastService(history, at: now);

      final result = forecast.planRoutines(routines);

      expect(result.state, RecoveryRoutinePlanState.restToday);
      expect(result.recommended, isEmpty);
      expect(result.cautions, isEmpty);
      expect(forecast.bestAlternativeFor(routines.first, routines), isNull);
    },
  );
  test('routine plan handles zero and one available routine', () {
    final now = DateTime(2026, 9, 24, 7);
    final history = [completedWorkout(now.subtract(const Duration(days: 5)))];
    final routine = completedWorkout(
      now,
      muscles: const [MuscleGroup.LATS],
    ).copyWith(id: 'only', name: 'Only routine');
    final forecast = RecoveryForecastService(history, at: now);

    expect(
      forecast.planRoutines(const []).state,
      RecoveryRoutinePlanState.empty,
    );
    final single = forecast.planRoutines([routine]);
    expect(single.state, RecoveryRoutinePlanState.allReady);
    expect(single.recommended.single.routine.id, 'only');
    expect(single.cautions, isEmpty);
  });
  test('mixed routine plan keeps the safest and highest-risk choices', () {
    final now = DateTime(2026, 9, 24, 7);
    final history = [
      completedWorkout(
        now.subtract(const Duration(hours: 4)),
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ),
    ];
    final chest = completedWorkout(
      now,
      muscles: const [MuscleGroup.MIDDLE_CHEST],
    ).copyWith(id: 'chest', name: 'Chest');
    final back = completedWorkout(
      now,
      muscles: const [MuscleGroup.LATS],
    ).copyWith(id: 'back', name: 'Back');
    final result = RecoveryForecastService(
      history,
      at: now,
    ).planRoutines([chest, back]);
    expect(result.state, RecoveryRoutinePlanState.mixed);
    expect(result.recommended.single.routine.id, 'back');
    expect(result.cautions.single.routine.id, 'chest');
  });
  test('routine plan promotes a recovering routine when it crosses 80%', () {
    final morning = DateTime(2026, 9, 24, 7);
    final history = [
      completedWorkout(
        morning.subtract(const Duration(hours: 4)),
        muscles: const [MuscleGroup.QUADS],
      ),
    ];
    final legs = completedWorkout(
      morning,
      muscles: const [MuscleGroup.QUADS],
    ).copyWith(id: 'legs', name: 'Legs');
    final back = completedWorkout(
      morning,
      muscles: const [MuscleGroup.LATS],
    ).copyWith(id: 'back', name: 'Back');
    final forecast = RecoveryForecastService(history, at: morning);

    final morningPlan = forecast.planRoutines([legs, back], at: morning);
    expect(morningPlan.recommended.single.routine.id, 'back');
    expect(morningPlan.cautions.single.routine.id, 'legs');
    expect(morningPlan.prioritizedSuggestions.first.routine.id, 'legs');

    final readyAt = forecast
        .snapshotAt(morning)
        .muscles[MajorMuscleGroup.LEGS]!
        .readyAt
        .add(const Duration(seconds: 1));
    expect(forecast.nextTransitionAfter(morning), isNotNull);
    final laterPlan = forecast.planRoutines([legs, back], at: readyAt);
    expect(laterPlan.state, RecoveryRoutinePlanState.allReady);
    expect(laterPlan.recommended.map((item) => item.routine.id).toSet(), {
      'legs',
      'back',
    });
    expect(laterPlan.cautions, isEmpty);
  });
  test('mixed plan keeps an unsuitable routine ahead of ready routines', () {
    final now = DateTime(2026, 9, 24, 7);
    final history = [
      completedWorkout(
        now.subtract(const Duration(hours: 4)),
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ),
    ];
    final routines = [
      completedWorkout(
        now,
        muscles: const [MuscleGroup.LATS],
      ).copyWith(id: 'back', name: 'Back'),
      completedWorkout(
        now,
        muscles: const [MuscleGroup.QUADS],
      ).copyWith(id: 'legs', name: 'Legs'),
      completedWorkout(
        now,
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ).copyWith(id: 'chest', name: 'Chest'),
    ];

    final result = RecoveryForecastService(
      history,
      at: now,
    ).planRoutines(routines);

    expect(result.state, RecoveryRoutinePlanState.mixed);
    expect(result.cautions.single.routine.id, 'chest');
    expect(result.recommended, hasLength(1));
    expect(result.prioritizedSuggestions.first.routine.id, 'chest');
    expect(
      result.prioritizedSuggestions.last.state,
      RoutineRecoveryState.ready,
    );
    expect(result.displaySuggestions.first.state, RoutineRecoveryState.ready);
    expect(result.displaySuggestions.last.routine.id, 'chest');
  });
  test('routine plan prioritizes low, then recovering, then ready', () {
    final now = DateTime(2026, 9, 24, 7);
    final history = [
      completedWorkout(
        now.subtract(const Duration(hours: 4)),
        muscles: const [MuscleGroup.QUADS],
      ),
      completedWorkout(
        now.subtract(const Duration(hours: 16)),
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ),
    ];
    final routines = [
      completedWorkout(
        now,
        muscles: const [MuscleGroup.LATS],
      ).copyWith(id: 'ready-back', name: 'Ready back'),
      completedWorkout(
        now,
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ).copyWith(id: 'recovering-chest', name: 'Recovering chest'),
      completedWorkout(
        now,
        muscles: const [MuscleGroup.QUADS],
      ).copyWith(id: 'low-legs', name: 'Low legs'),
    ];

    final result = RecoveryForecastService(
      history,
      at: now,
    ).planRoutines(routines);

    expect(result.state, RecoveryRoutinePlanState.mixed);
    expect(result.prioritizedSuggestions, hasLength(2));
    expect(result.prioritizedSuggestions.first.routine.id, 'low-legs');
    expect(result.prioritizedSuggestions.first.state, RoutineRecoveryState.low);
    expect(result.prioritizedSuggestions.last.routine.id, 'ready-back');
    expect(
      result.prioritizedSuggestions.last.state,
      RoutineRecoveryState.ready,
    );
  });
  test(
    'routine plan prefers a different state before a second low routine',
    () {
      final now = DateTime(2026, 9, 24, 7);
      final history = [
        completedWorkout(
          now.subtract(const Duration(hours: 4)),
          muscles: const [MuscleGroup.QUADS, MuscleGroup.LATS],
        ),
        completedWorkout(
          now.subtract(const Duration(hours: 16)),
          muscles: const [MuscleGroup.MIDDLE_CHEST],
        ),
      ];
      final routines = [
        completedWorkout(
          now,
          muscles: const [MuscleGroup.QUADS],
        ).copyWith(id: 'low-legs', name: 'Low legs'),
        completedWorkout(
          now,
          muscles: const [MuscleGroup.LATS],
        ).copyWith(id: 'low-back', name: 'Low back'),
        completedWorkout(
          now,
          muscles: const [MuscleGroup.MIDDLE_CHEST],
        ).copyWith(id: 'recovering-chest', name: 'Recovering chest'),
      ];

      final result = RecoveryForecastService(
        history,
        at: now,
      ).planRoutines(routines);

      expect(result.prioritizedSuggestions, hasLength(2));
      expect(result.prioritizedSuggestions.map((item) => item.state).toList(), [
        RoutineRecoveryState.nearlyReady,
        RoutineRecoveryState.low,
      ]);
    },
  );
  test('full-body routines expose ready muscles when one group is low', () {
    final now = DateTime(2026, 9, 24, 7);
    final history = [
      completedWorkout(
        now.subtract(const Duration(hours: 4)),
        muscles: const [MuscleGroup.QUADS],
      ),
    ];
    const fullBodyMuscles = [
      MuscleGroup.MIDDLE_CHEST,
      MuscleGroup.LATS,
      MuscleGroup.QUADS,
      MuscleGroup.FRONT_DELTS,
      MuscleGroup.BICEPS,
      MuscleGroup.ABS,
    ];
    final routines = [
      completedWorkout(
        now,
        muscles: fullBodyMuscles,
      ).copyWith(id: 'full-a', name: 'Full body A'),
      completedWorkout(
        now,
        muscles: fullBodyMuscles,
      ).copyWith(id: 'full-b', name: 'Full body B'),
    ];

    final result = RecoveryForecastService(
      history,
      at: now,
    ).planRoutines(routines);

    expect(result.recommended, hasLength(1));
    expect(result.recommended.single.state, RoutineRecoveryState.readyAdjusted);
    expect(result.recommended.single.lowMuscles, [MajorMuscleGroup.LEGS]);
    expect(result.cautions, isEmpty);
    expect(result.distinctRoutineCount, 1);
  });
  test('a tiny secondary muscle no longer dominates routine ranking', () {
    final now = DateTime(2026, 9, 24, 7);
    final history = [
      completedWorkout(
        now.subtract(const Duration(hours: 4)),
        muscles: const [MuscleGroup.BICEPS],
      ),
    ];
    final fivePercentLow = completedWorkout(
      now,
      muscles: [
        ...List.filled(19, MuscleGroup.MIDDLE_CHEST),
        MuscleGroup.BICEPS,
      ],
    ).copyWith(id: 'five-percent-low', name: 'Five percent low');
    final twentyPercentLow = completedWorkout(
      now,
      muscles: [
        ...List.filled(4, MuscleGroup.MIDDLE_CHEST),
        MuscleGroup.BICEPS,
      ],
    ).copyWith(id: 'twenty-percent-low', name: 'Twenty percent low');

    final ranked = RecoveryForecastService(
      history,
      at: now,
    ).rankRoutines([twentyPercentLow, fivePercentLow]);

    expect(ranked.map((item) => item.state).toSet(), {
      RoutineRecoveryState.readyAdjusted,
    });
    expect(ranked.first.routine.id, 'five-percent-low');
    expect(ranked.first.lowerTailPercentage, 100);
    expect(
      ranked.last.lowerTailPercentage,
      lessThan(RecoveryForecastService.restThreshold),
    );
  });
  test(
    'routine readyAt is when the routine turns ready, before every muscle is green',
    () {
      final now = DateTime(2026, 9, 24, 7);
      final history = [
        completedWorkout(
          now.subtract(const Duration(hours: 4)),
          muscles: const [MuscleGroup.MIDDLE_CHEST],
        ),
      ];
      final routine = completedWorkout(
        now,
        muscles: const [
          MuscleGroup.MIDDLE_CHEST,
          MuscleGroup.LATS,
          MuscleGroup.LATS,
          MuscleGroup.LATS,
        ],
      ).copyWith(id: 'quarter-chest', name: 'Quarter chest');
      final forecast = RecoveryForecastService(history, at: now);
      final assessment = forecast.assessRoutine(routine);
      final chestReadyAt = forecast
          .snapshotAt(now)
          .muscles[MajorMuscleGroup.CHEST]!
          .readyAt;

      expect(assessment.state, RoutineRecoveryState.nearlyReady);
      expect(assessment.readyAt, isNotNull);
      expect(assessment.readyAt!.isBefore(chestReadyAt), isTrue);
      expect(
        forecast
            .assessRoutine(
              routine,
              at: assessment.readyAt!.add(const Duration(minutes: 2)),
            )
            .isReady,
        isTrue,
      );
    },
  );
  test(
    'routine coverage gap lists green muscle groups without a safe routine',
    () {
      final now = DateTime(2026, 9, 24, 7);
      final history = [
        completedWorkout(
          now.subtract(const Duration(hours: 4)),
          muscles: const [
            MuscleGroup.MIDDLE_CHEST,
            MuscleGroup.LATS,
            MuscleGroup.QUADS,
          ],
        ),
      ];
      final routines = [
        completedWorkout(
          now,
          muscles: const [MuscleGroup.MIDDLE_CHEST],
        ).copyWith(id: 'chest', name: 'Chest'),
        completedWorkout(
          now,
          muscles: const [MuscleGroup.LATS],
        ).copyWith(id: 'back', name: 'Back'),
        completedWorkout(
          now,
          muscles: const [MuscleGroup.QUADS],
        ).copyWith(id: 'legs', name: 'Legs'),
      ];

      final result = RecoveryForecastService(
        history,
        at: now,
      ).planRoutines(routines);

      expect(result.state, RecoveryRoutinePlanState.noneReady);
      expect(result.uncoveredReadyMuscles.toSet(), {
        MajorMuscleGroup.SHOULDERS,
        MajorMuscleGroup.ARMS,
        MajorMuscleGroup.CORE,
      });
    },
  );
  test('routine plan keeps only two highest-priority cautions', () {
    final now = DateTime(2026, 9, 24, 7);
    final history = [
      completedWorkout(
        now.subtract(const Duration(hours: 4)),
        muscles: const [
          MuscleGroup.MIDDLE_CHEST,
          MuscleGroup.LATS,
          MuscleGroup.QUADS,
        ],
      ),
    ];
    final routines = [
      completedWorkout(
        now,
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ).copyWith(id: 'chest', name: 'Chest'),
      completedWorkout(
        now,
        muscles: const [MuscleGroup.LATS],
      ).copyWith(id: 'back', name: 'Back'),
      completedWorkout(
        now,
        muscles: const [MuscleGroup.QUADS],
      ).copyWith(id: 'legs', name: 'Legs'),
    ];
    final result = RecoveryForecastService(
      history,
      at: now,
    ).planRoutines(routines);
    expect(result.state, RecoveryRoutinePlanState.noneReady);
    expect(result.recommended, isEmpty);
    expect(result.cautions, hasLength(2));
    expect(
      result.cautions.every((item) => item.state != RoutineRecoveryState.ready),
      isTrue,
    );
  });
  test('alternative routine must be materially safer than the current one', () {
    final now = DateTime(2026, 9, 24, 7);
    final history = [
      completedWorkout(
        now.subtract(const Duration(hours: 4)),
        muscles: const [MuscleGroup.MIDDLE_CHEST],
      ),
    ];
    final current = completedWorkout(
      now,
      muscles: const [MuscleGroup.MIDDLE_CHEST],
    ).copyWith(id: 'current', name: 'Current');
    final equivalent = completedWorkout(
      now,
      muscles: const [MuscleGroup.MIDDLE_CHEST],
    ).copyWith(id: 'equivalent', name: 'Equivalent');
    final back = completedWorkout(
      now,
      muscles: const [MuscleGroup.LATS],
    ).copyWith(id: 'back', name: 'Back');
    final forecast = RecoveryForecastService(history, at: now);
    expect(forecast.bestAlternativeFor(current, [current, equivalent]), isNull);
    expect(
      forecast
          .bestAlternativeFor(current, [current, equivalent, back])
          ?.routine
          .id,
      'back',
    );
  });
  test('alternative recovery copy accepts exactly its generated arguments', () {
    for (final locale in AppLocale.values) {
      LocaleSettings.setLocale(locale);
      expect(
        NotificationCopy.text(
          'notifications.body_recovery_routine_alternative',
          const {'muscles': 'Chest', 'alternative': 'Back'},
        ),
        isNotEmpty,
      );
    }
  });
  test(
    'adjusted workout copy renders and obsolete notification keys are gone',
    () {
      for (final locale in AppLocale.values) {
        LocaleSettings.setLocale(locale);
        expect(
          NotificationCopy.text(
            'notifications.body_workout_reminder_recovery_adjusted',
            const {
              'routineName': 'Full body',
              'time': '10:00',
              'muscles': 'Legs',
            },
          ),
          isNotEmpty,
        );
        expect(
          NotificationCopy.text('notifications.body_hydration_completed'),
          isNull,
        );
        expect(
          NotificationCopy.text('notifications.cta_view_progress'),
          isNull,
        );
        expect(
          NotificationCopy.text(
            'notifications.body_recovery_routine_ready_adjusted',
          ),
          isNull,
        );
      }
    },
  );
  test('all external reminder titles render from both generated locales', () {
    for (final locale in AppLocale.values) {
      LocaleSettings.setLocale(locale);
      for (final kind in [
        'workout_reminder',
        'hydration_reminder',
        'streak_at_risk',
        'rank_ending',
        'recovery_ready',
        'recovery_all_ready',
        'recovery_rest_today',
        'recovery_ready_later',
        'inactivity',
      ]) {
        expect(NotificationCopy.text('notifications.title_$kind'), isNotEmpty);
      }
    }
  });
}
