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
  Future<void> _pendingStatsUpdate = Future.value();

  // Claims and history refreshes both mutate the reward ledger and XP state.
  // Serialize them so a refresh cannot restore a stale, unclaimed quest.
  Future<void> _updateStats(Future<void> Function() action) {
    final operation = _pendingStatsUpdate.then((_) async {
      if (isClosed) return;
      await action();
      if (!isClosed) emit(state.copyWith(stats: _gamificationRepo.userStats));
    });
    _pendingStatsUpdate = operation.catchError((Object error) {
      debugPrint('Gamification update failed: $error');
    });
    return operation;
  }

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
      refreshWeeklyQuests(historicalSessions).ignore();
    });
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    return super.close();
  }

  Future<void> refreshWeeklyQuests(List<WorkoutSession> completedWorkouts) =>
      _updateStats(() => _refreshWeeklyQuestsUseCase.execute(completedWorkouts));

  Future<void> claimQuestReward(String questId) =>
      _updateStats(() => _claimQuestRewardUseCase.execute(questId));

  Future<void> claimChestReward() =>
      _updateStats(() => _claimChestRewardUseCase.execute());

  Future<void> refreshStateFromPrefs() =>
      _updateStats(() => _refreshGamificationStateUseCase.execute());

  Future<void> refreshGamificationState() async {
    await refreshStateFromPrefs();
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

  Future<void> resetGamification() =>
      _updateStats(() => _resetGamificationUseCase.execute());
}
