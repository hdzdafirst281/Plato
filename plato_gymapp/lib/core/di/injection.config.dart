// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/auth_usecases.dart' as _i46;
import '../../features/auth/presentation/bloc/auth_cubit.dart' as _i52;
import '../../features/auth/presentation/bloc/onboarding_cubit.dart' as _i630;
import '../../features/gamification/data/repositories/gamification_repository.dart'
    as _i493;
import '../../features/gamification/domain/usecases/claim_chest_reward_usecase.dart'
    as _i681;
import '../../features/gamification/domain/usecases/claim_quest_reward_usecase.dart'
    as _i826;
import '../../features/gamification/domain/usecases/get_leaderboard_usecase.dart'
    as _i985;
import '../../features/gamification/domain/usecases/refresh_gamification_state_usecase.dart'
    as _i848;
import '../../features/gamification/domain/usecases/refresh_weekly_quests_usecase.dart'
    as _i212;
import '../../features/gamification/domain/usecases/reset_gamification_usecase.dart'
    as _i875;
import '../../features/gamification/presentation/bloc/gamification_cubit.dart'
    as _i207;
import '../../features/gamification/presentation/bloc/rank_cubit.dart' as _i550;
import '../../features/nutrition/data/repositories/nutrition_repository.dart'
    as _i263;
import '../../features/nutrition/presentation/bloc/nutrition_cubit.dart'
    as _i74;
import '../../features/profile/presentation/bloc/profile_cubit.dart' as _i800;
import '../../features/profile/presentation/bloc/stats_cubit.dart' as _i539;
import '../../features/workout/data/repositories/exercise_repository.dart'
    as _i101;
import '../../features/workout/data/repositories/workout_repository.dart'
    as _i956;
import '../../features/workout/presentation/bloc/active_session_cubit.dart'
    as _i111;
import '../../features/workout/presentation/bloc/editor_cubit.dart' as _i479;
import '../../features/workout/presentation/bloc/exercise_library_cubit.dart'
    as _i880;
import '../../features/workout/presentation/bloc/workout_cubit.dart' as _i14;
import '../database/app_database.dart' as _i982;
import '../database/daos.dart' as _i413;
import '../network/supabase_module.dart' as _i374;
import 'app_module.dart' as _i460;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final appModule = _$AppModule();
  final supabaseModule = _$SupabaseModule();
  await gh.singletonAsync<_i460.SharedPreferences>(
    () => appModule.prefs,
    preResolve: true,
  );
  await gh.singletonAsync<_i982.AppDatabase>(
    () => appModule.appDatabase,
    preResolve: true,
  );
  await gh.singletonAsync<_i454.SupabaseClient>(
    () => supabaseModule.supabaseClient,
    preResolve: true,
  );
  gh.lazySingleton<_i263.NutritionRepository>(
      () => _i263.NutritionRepository(gh<_i982.AppDatabase>()));
  gh.lazySingleton<_i101.ExerciseRepository>(
      () => _i101.ExerciseRepository(gh<_i982.AppDatabase>()));
  gh.singleton<_i413.FoodDao>(
      () => appModule.getFoodDao(gh<_i982.AppDatabase>()));
  gh.singleton<_i413.ExerciseDao>(
      () => appModule.getExerciseDao(gh<_i982.AppDatabase>()));
  gh.singleton<_i413.RewardClaimDao>(
      () => appModule.getRewardClaimDao(gh<_i982.AppDatabase>()));
  gh.lazySingleton<_i956.WorkoutRepository>(() => _i956.WorkoutRepository(
        gh<_i982.AppDatabase>(),
        gh<_i454.SupabaseClient>(),
      ));
  gh.lazySingleton<_i787.AuthRepository>(() => _i153.AuthRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i460.SharedPreferences>(),
      ));
  gh.lazySingleton<_i46.VerifyOtpUseCase>(() => _i46.VerifyOtpUseCase(
        gh<_i787.AuthRepository>(),
        gh<_i956.WorkoutRepository>(),
        gh<_i982.AppDatabase>(),
      ));
  gh.factory<_i630.OnboardingCubit>(() => _i630.OnboardingCubit(
        gh<_i787.AuthRepository>(),
        gh<_i956.WorkoutRepository>(),
      ));
  gh.factory<_i550.RankCubit>(() => _i550.RankCubit(
        gh<_i787.AuthRepository>(),
        gh<_i956.WorkoutRepository>(),
      ));
  gh.lazySingleton<_i880.ExerciseLibraryCubit>(
      () => _i880.ExerciseLibraryCubit(gh<_i101.ExerciseRepository>()));
  gh.lazySingleton<_i493.GamificationRepository>(
      () => _i493.GamificationRepository(
            gh<_i982.AppDatabase>(),
            gh<_i454.SupabaseClient>(),
            gh<_i460.SharedPreferences>(),
          ));
  gh.factory<_i74.NutritionCubit>(() => _i74.NutritionCubit(
        gh<_i263.NutritionRepository>(),
        gh<_i413.FoodDao>(),
      ));
  gh.lazySingleton<_i46.LogoutUseCase>(
      () => _i46.LogoutUseCase(gh<_i787.AuthRepository>()));
  gh.lazySingleton<_i46.DeleteAccountUseCase>(
      () => _i46.DeleteAccountUseCase(gh<_i787.AuthRepository>()));
  gh.factory<_i985.GetLeaderboardUseCase>(
      () => _i985.GetLeaderboardUseCase(gh<_i493.GamificationRepository>()));
  gh.factory<_i14.WorkoutCubit>(() => _i14.WorkoutCubit(
        gh<_i956.WorkoutRepository>(),
        gh<_i787.AuthRepository>(),
        gh<_i460.SharedPreferences>(),
        gh<_i493.GamificationRepository>(),
      ));
  gh.factory<_i111.ActiveSessionCubit>(() => _i111.ActiveSessionCubit(
        gh<_i956.WorkoutRepository>(),
        gh<_i493.GamificationRepository>(),
        gh<_i787.AuthRepository>(),
        gh<_i460.SharedPreferences>(),
        gh<_i101.ExerciseRepository>(),
      ));
  gh.factory<_i539.StatsCubit>(
      () => _i539.StatsCubit(gh<_i956.WorkoutRepository>()));
  gh.factory<_i479.EditorCubit>(
      () => _i479.EditorCubit(gh<_i956.WorkoutRepository>()));
  gh.factory<_i52.AuthCubit>(() => _i52.AuthCubit(
        gh<_i787.AuthRepository>(),
        gh<_i46.VerifyOtpUseCase>(),
        gh<_i46.LogoutUseCase>(),
        gh<_i46.DeleteAccountUseCase>(),
      ));
  gh.factory<_i800.ProfileCubit>(() => _i800.ProfileCubit(
        gh<_i787.AuthRepository>(),
        gh<_i493.GamificationRepository>(),
        gh<_i956.WorkoutRepository>(),
      ));
  gh.factory<_i681.ClaimChestRewardUseCase>(() => _i681.ClaimChestRewardUseCase(
        gh<_i493.GamificationRepository>(),
        gh<_i787.AuthRepository>(),
      ));
  gh.factory<_i826.ClaimQuestRewardUseCase>(() => _i826.ClaimQuestRewardUseCase(
        gh<_i493.GamificationRepository>(),
        gh<_i787.AuthRepository>(),
      ));
  gh.factory<_i848.RefreshGamificationStateUseCase>(
      () => _i848.RefreshGamificationStateUseCase(
            gh<_i493.GamificationRepository>(),
            gh<_i787.AuthRepository>(),
          ));
  gh.factory<_i212.RefreshWeeklyQuestsUseCase>(
      () => _i212.RefreshWeeklyQuestsUseCase(
            gh<_i493.GamificationRepository>(),
            gh<_i787.AuthRepository>(),
          ));
  gh.factory<_i875.ResetGamificationUseCase>(
      () => _i875.ResetGamificationUseCase(
            gh<_i493.GamificationRepository>(),
            gh<_i787.AuthRepository>(),
          ));
  gh.factory<_i207.GamificationCubit>(() => _i207.GamificationCubit(
        gh<_i493.GamificationRepository>(),
        gh<_i956.WorkoutRepository>(),
        gh<_i212.RefreshWeeklyQuestsUseCase>(),
        gh<_i826.ClaimQuestRewardUseCase>(),
        gh<_i681.ClaimChestRewardUseCase>(),
        gh<_i848.RefreshGamificationStateUseCase>(),
        gh<_i875.ResetGamificationUseCase>(),
        gh<_i985.GetLeaderboardUseCase>(),
      ));
  return getIt;
}

class _$AppModule extends _i460.AppModule {}

class _$SupabaseModule extends _i374.SupabaseModule {}
