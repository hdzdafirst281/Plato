import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';
import 'package:plato_gymapp/features/gamification/data/repositories/gamification_repository.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plato_gymapp/core/database/app_database.dart';

class FakeAppDatabase extends Fake implements AppDatabase {}
class FakeSupabaseClient extends Fake implements SupabaseClient {}

WorkoutSession makeSession({
  required String id,
  required DateTime startTime,
  required int completedSetsCount,
  int prCount = 0,
  int xpEarned = 0,
}) {
  return WorkoutSession(
    id: id,
    name: 'Test Workout',
    startTime: startTime.millisecondsSinceEpoch,
    endTime: startTime.add(const Duration(minutes: 45)).millisecondsSinceEpoch,
    updatedAt: startTime.millisecondsSinceEpoch,
    prCount: prCount,
    xpEarned: xpEarned,
    sessionPayload: WorkoutSessionPayload(
      exercises: [
        WorkoutExercise(
          id: 'ex-$id',
          exercise: Exercise(
            id: 'ex-1',
            name: 'Bench Press',
            primaryMuscle: MuscleGroup.MIDDLE_CHEST,
            type: ExerciseType.REPS_ONLY,
            isDeleted: false,
          ),
          sets: List.generate(
            completedSetsCount,
            (i) => ExerciseSet(id: 'set-$id-$i', reps: 10, isCompleted: true),
          ),
        ),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RankCalculator RP rate limit (40 RP/day)', () {
    test('single session with >40 completed sets is capped at 40 RP', () {
      final day1 = DateTime(2026, 10, 20, 10, 0);
      final sessions = [
        makeSession(id: 'w1', startTime: day1, completedSetsCount: 55),
      ];

      final totalRp = RankCalculator.calculateCappedRp(sessions);
      expect(totalRp, equals(RankConfig.dailyRpCap)); // 40
    });

    test('multiple sessions on the same calendar day are capped at 40 RP total', () {
      final day1Morning = DateTime(2026, 10, 20, 8, 0);
      final day1Evening = DateTime(2026, 10, 20, 18, 0);
      final sessions = [
        makeSession(id: 'w1', startTime: day1Morning, completedSetsCount: 25),
        makeSession(id: 'w2', startTime: day1Evening, completedSetsCount: 30),
      ];

      final totalRp = RankCalculator.calculateCappedRp(sessions);
      expect(totalRp, equals(40)); // 25 + 30 = 55, capped at 40
    });

    test('sessions across different calendar days each earn up to 40 RP', () {
      final day1 = DateTime(2026, 10, 20, 10, 0);
      final day2 = DateTime(2026, 10, 21, 10, 0);
      final sessions = [
        makeSession(id: 'w1', startTime: day1, completedSetsCount: 35),
        makeSession(id: 'w2', startTime: day2, completedSetsCount: 35),
      ];

      final totalRp = RankCalculator.calculateCappedRp(sessions);
      expect(totalRp, equals(70)); // 35 + 35
    });

    test('calculateSessionRp allocates remaining daily capacity chronologically', () {
      final day1Morning = DateTime(2026, 10, 20, 8, 0);
      final day1Afternoon = DateTime(2026, 10, 20, 14, 0);
      final day1Evening = DateTime(2026, 10, 20, 20, 0);

      final w1 = makeSession(id: 'w1', startTime: day1Morning, completedSetsCount: 25);
      final w2 = makeSession(id: 'w2', startTime: day1Afternoon, completedSetsCount: 25);
      final w3 = makeSession(id: 'w3', startTime: day1Evening, completedSetsCount: 15);
      final all = [w1, w2, w3];

      // w1 is first, earns all 25 RP
      expect(RankCalculator.calculateSessionRp(w1, all), equals(25));
      // w2 has 25 prior sets, capacity is 40 - 25 = 15
      expect(RankCalculator.calculateSessionRp(w2, all), equals(15));
      // w3 has 50 prior sets >= 40, capacity is 0
      expect(RankCalculator.calculateSessionRp(w3, all), equals(0));
    });

    test('isRpCapReached correctly determines status', () {
      final day1 = DateTime(2026, 10, 20);
      final belowCap = [
        makeSession(id: 'w1', startTime: DateTime(2026, 10, 20, 9), completedSetsCount: 39),
      ];
      final atCap = [
        makeSession(id: 'w1', startTime: DateTime(2026, 10, 20, 9), completedSetsCount: 40),
      ];
      expect(RankCalculator.isRpCapReached(day1, belowCap), isFalse);
      expect(RankCalculator.isRpCapReached(day1, atCap), isTrue);
    });

    test('calculateTrueRankAndSeasons produces capped active points', () {
      final anchor = DateTime(2026, 10, 1, 10, 0);
      final day2 = DateTime(2026, 10, 2, 10, 0);
      final sessions = [
        makeSession(id: 'w1', startTime: anchor, completedSetsCount: 60),
        makeSession(id: 'w2', startTime: day2, completedSetsCount: 50),
      ];
      const profile = UserProfile(
        id: 'u1',
        displayName: 'Test',
        experiencePoints: 0,
        targetMacros: Macros(),
        detailedBodyMetrics: BodyMetrics(),
      );
      final result = RankCalculator.calculateTrueRankAndSeasons(
        sessions,
        profile,
        day2.millisecondsSinceEpoch + 1000,
      );

      // Day 1 capped at 40, Day 2 capped at 40 -> total 80 RP
      expect(result.currentCycleRankPoints, equals(80));
    });
  });

  group('GamificationRepository XP rate limit (300 XP/day)', () {
    late GamificationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = GamificationRepository(
        FakeAppDatabase(),
        FakeSupabaseClient(),
        prefs,
      );
    });

    test('single workout XP is capped at 300 XP', () {
      final session = makeSession(
        id: 'w1',
        startTime: DateTime(2026, 10, 20, 10, 0),
        completedSetsCount: 10,
        prCount: 20, // 50 + 20 * 20 = 450 XP raw
      );

      final xp = repo.calculateXpForSession(session);
      expect(xp, equals(GamificationRepository.dailyXpCap)); // 300
    });

    test('subsequent workouts on same day respect remaining cap', () {
      final day = DateTime(2026, 10, 20, 10, 0);
      final w1 = makeSession(
        id: 'w1',
        startTime: day,
        completedSetsCount: 10,
        prCount: 7, // 50 + 140 = 190 XP
        xpEarned: 190,
      );

      final w2 = makeSession(
        id: 'w2',
        startTime: day.add(const Duration(hours: 4)),
        completedSetsCount: 10,
        prCount: 5, // 50 + 100 = 150 XP raw, remaining = 300 - 190 = 110
      );

      final xp2 = repo.calculateXpForSession(w2, [w1]);
      expect(xp2, equals(110)); // Capped at remaining 110 XP

      final w3 = makeSession(
        id: 'w3',
        startTime: day.add(const Duration(hours: 8)),
        completedSetsCount: 5,
        prCount: 0,
      );
      final xp3 = repo.calculateXpForSession(w3, [w1, w2.copyWith(xpEarned: 110)]);
      expect(xp3, equals(0)); // 190 + 110 = 300, remaining = 0
    });
  });
}
