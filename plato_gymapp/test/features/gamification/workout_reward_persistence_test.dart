import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';
import 'package:plato_gymapp/features/gamification/data/models/gamification_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plato_gymapp/core/database/app_database.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/data/repositories/workout_repository.dart';
import 'package:plato_gymapp/features/gamification/data/repositories/gamification_repository.dart';
import 'package:plato_gymapp/features/gamification/domain/usecases/claim_quest_reward_usecase.dart';
import 'package:plato_gymapp/features/gamification/domain/usecases/claim_chest_reward_usecase.dart';
import 'package:plato_gymapp/features/gamification/domain/usecases/refresh_gamification_state_usecase.dart';
import 'package:plato_gymapp/features/gamification/domain/usecases/refresh_weekly_quests_usecase.dart';
import 'package:plato_gymapp/features/gamification/domain/usecases/reset_gamification_usecase.dart';
import 'package:plato_gymapp/features/gamification/domain/usecases/get_leaderboard_usecase.dart';
import 'package:plato_gymapp/features/gamification/presentation/bloc/gamification_cubit.dart';

class MemoryAuth extends Fake implements AuthRepository {
  UserProfile profile = const UserProfile(
    targetMacros: Macros(),
    detailedBodyMetrics: BodyMetrics(),
  );
  @override
  UserProfile getProfile() => profile;
  @override
  Future<void> saveProfile(UserProfile value) async {
    profile = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);
  late AppDatabase db;
  late WorkoutRepository workouts;
  late GamificationRepository rewards;
  late SupabaseClient client;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();
    client = SupabaseClient('https://example.supabase.co', 'test-key');
    workouts = WorkoutRepository(db, client);
    rewards = GamificationRepository(
      db,
      client,
      await SharedPreferences.getInstance(),
    );
  });
  tearDown(() async {
    await db.close();
    await client.dispose();
  });

  WorkoutSession session(String id, double weight) => WorkoutSession(
    id: id,
    name: 'Strength',
    startTime: DateTime.now().millisecondsSinceEpoch,
    updatedAt: 1,
    endTime: DateTime.now().millisecondsSinceEpoch,
    sessionPayload: WorkoutSessionPayload(
      exercises: [
        WorkoutExercise(
          id: 'exercise',
          exercise: Exercise(
            id: 'bench',
            name: 'Bench press',
            type: ExerciseType.WEIGHT_REPS,
            isDeleted: false,
          ),
          sets: [
            ExerciseSet(id: 'set', weight: weight, reps: 10, isCompleted: true),
          ],
        ),
      ],
    ),
  );

  test(
    'first persisted reward has consistent PR and XP; resaving preserves PR',
    () async {
      await workouts.saveFinishedWorkout(
        session('previous', 40),
        calculateXp: rewards.calculateXpForSession,
      );
      final result = await workouts.saveFinishedWorkout(
        session('new', 50),
        calculateXp: rewards.calculateXpForSession,
      );
      expect(result.prCount, 1);
      expect(result.xpEarned, 70);
      final stored = (await db.workoutDao.getAllHistory()).singleWhere(
        (s) => s.id == 'new',
      );
      expect(stored.prCount, 1);
      expect(stored.xpEarned, 70);
      final savedAgain = await workouts.saveFinishedWorkout(
        result,
        calculateXp: rewards.calculateXpForSession,
      );
      expect(savedAgain.prCount, 1);
      expect(savedAgain.xpEarned, 70);
    },
  );

  test('level calculations cover exact boundary and multiple levels', () {
    expect(rewards.calculateLevelInfo(999), (1, 999));
    expect(rewards.calculateLevelInfo(1000), (2, 0));
    expect(rewards.calculateLevelInfo(2050), (3, 0));
    expect(rewards.calculateLevelInfo(2100), (3, 50));
  });

  test('overlapping claims and history refresh credit a quest once', () async {
    final history = [session('1', 40), session('2', 40), session('3', 40)];
    final auth = MemoryAuth();
    final cubit = GamificationCubit(
      rewards,
      workouts,
      RefreshWeeklyQuestsUseCase(rewards, auth),
      ClaimQuestRewardUseCase(rewards, auth),
      ClaimChestRewardUseCase(rewards, auth),
      RefreshGamificationStateUseCase(rewards, auth),
      ResetGamificationUseCase(rewards, auth),
      GetLeaderboardUseCase(rewards),
    );
    addTearDown(cubit.close);
    // Drain the initial empty database stream before the scenario.
    await workouts.workoutHistoryStream.first;
    await cubit.refreshWeeklyQuests(history);
    final quest = cubit.state.stats.weeklyQuests.first;
    expect(quest.isCompleted, isTrue);
    await Future.wait([
      cubit.claimQuestReward(quest.id),
      cubit.refreshWeeklyQuests(history),
      cubit.claimQuestReward(quest.id),
    ]);
    expect(auth.profile.experiencePoints, quest.xpReward);
    expect(cubit.state.stats.weeklyQuests.first.claimedReward, isTrue);
    expect(cubit.state.stats.currentXp, quest.xpReward);
  });
}
