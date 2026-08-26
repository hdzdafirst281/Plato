import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../data/repositories/gamification_repository.dart';
import '../../data/models/gamification_models.dart';
import '../../../workout/data/models/workout_models.dart';
import '../../../workout/data/repositories/workout_repository.dart';
import '../../domain/usecases/refresh_weekly_quests_usecase.dart';
import '../../domain/usecases/claim_quest_reward_usecase.dart';
import '../../domain/usecases/claim_chest_reward_usecase.dart';
import '../../domain/usecases/refresh_gamification_state_usecase.dart';
import '../../domain/usecases/reset_gamification_usecase.dart';
import '../../domain/usecases/get_leaderboard_usecase.dart';

part 'gamification_cubit.freezed.dart';

@freezed
class GamificationState with _$GamificationState {
  const factory GamificationState({
    required UserGamificationStats stats,
    @Default(null) List<LeaderboardEntry>? leaderboard,
    @Default(false) bool isLeaderboardLoading,
  }) = _GamificationState;
}

@injectable
class GamificationCubit extends Cubit<GamificationState> {
  final GamificationRepository _gamificationRepo;
  final WorkoutRepository _workoutRepo; 
  final RefreshWeeklyQuestsUseCase _refreshWeeklyQuestsUseCase;
  final ClaimQuestRewardUseCase _claimQuestRewardUseCase;
  final ClaimChestRewardUseCase _claimChestRewardUseCase;
  final RefreshGamificationStateUseCase _refreshGamificationStateUseCase;
  final ResetGamificationUseCase _resetGamificationUseCase;
  final GetLeaderboardUseCase _getLeaderboardUseCase;

  StreamSubscription? _historySubscription;

  GamificationCubit(
    this._gamificationRepo, 
    this._workoutRepo,
    this._refreshWeeklyQuestsUseCase,
    this._claimQuestRewardUseCase,
    this._claimChestRewardUseCase,
    this._refreshGamificationStateUseCase,
    this._resetGamificationUseCase,
    this._getLeaderboardUseCase,
  ) : super(GamificationState(stats: _gamificationRepo.userStats)) {
    
    _historySubscription = _workoutRepo.workoutHistoryStream.listen((historicalSessions) {
      refreshWeeklyQuests(historicalSessions);
    });
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    return super.close();
  }

  Future<void> refreshWeeklyQuests(List<WorkoutSession> completedWorkouts) async {
    await _refreshWeeklyQuestsUseCase.execute(completedWorkouts);
    emit(state.copyWith(stats: _gamificationRepo.userStats));
  }

  Future<void> claimQuestReward(String questId) async {
    await _claimQuestRewardUseCase.execute(questId);
    emit(state.copyWith(stats: _gamificationRepo.userStats));
  }

  Future<void> claimChestReward() async {
    await _claimChestRewardUseCase.execute();
    emit(state.copyWith(stats: _gamificationRepo.userStats));
  }

  Future<void> refreshStateFromPrefs() async {
    await _refreshGamificationStateUseCase.execute();
    emit(state.copyWith(stats: _gamificationRepo.userStats));
  }

  Future<void> refreshGamificationState() async {
    await _refreshGamificationStateUseCase.execute();
    emit(state.copyWith(stats: _gamificationRepo.userStats));
    await loadLeaderboard(forceRefresh: true); // Automatically load leaderboard on state refresh
  }

  Future<void> loadLeaderboard({bool forceRefresh = false}) async {
    emit(state.copyWith(isLeaderboardLoading: true));
    try {
      final leaderboard = await _getLeaderboardUseCase.execute(forceRefresh: forceRefresh);
      emit(state.copyWith(
        leaderboard: leaderboard,
        isLeaderboardLoading: false,
      ));
    } catch (e) {
      debugPrint("Lỗi tải leaderboard trong Cubit: $e");
      emit(state.copyWith(isLeaderboardLoading: false));
    }
  }

  Future<void> resetGamification() async {
    await _resetGamificationUseCase.execute();
    emit(state.copyWith(stats: _gamificationRepo.userStats));
  }
}