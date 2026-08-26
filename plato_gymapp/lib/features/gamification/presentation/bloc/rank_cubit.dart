import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:plato_gymapp/core/utils/time_manager.dart';

import '../../data/models/gamification_models.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../workout/data/repositories/workout_repository.dart';
import '../../domain/rank_calculator.dart'; 

@injectable
class RankCubit extends Cubit<RankScreenState?> {
  final AuthRepository _authRepo;
  final WorkoutRepository _workoutRepo;

  StreamSubscription? _workoutHistorySubscription;
  StreamSubscription? _profileUpdateSubscription;

  RankCubit(this._authRepo, this._workoutRepo) : super(null) {
    _loadUIState(); // Chạy lần đầu khi khởi tạo

    // LẮNG NGHE TỪ AUTH REPO (Nguồn chân lý)
    _profileUpdateSubscription = _authRepo.profileUpdateStream.listen((_) {
      _loadUIState();
    });

    // LẮNG NGHE TỪ WORKOUT REPO
    _workoutHistorySubscription = _workoutRepo.workoutHistoryStream.listen((_) {
      _loadUIState();
    });
  }

  @override
  Future<void> close() { // ĐÃ FIX LỖI CÚ PHÁP Ở ĐÂY
    _workoutHistorySubscription?.cancel();
    _profileUpdateSubscription?.cancel();
    return super.close();
  }

  // HÀM MỚI: CHỈ RENDER UI, TUYỆT ĐỐI KHÔNG GỌI HÀM SAVE_PROFILE() HAY UPDATE DB
  Future<void> _loadUIState() async {
    final profile = _authRepo.getProfile();
    final workouts = await _workoutRepo.workoutHistoryStream.first;
    
    // 🚀 Lấy True Time
    final trueTimeMillis = await TimeManager.getTrueTimeMillis();
    
    // 🚀 Truyền vào RankCalculator
    final seasonResult = RankCalculator.calculateTrueRankAndSeasons(workouts.cast(), profile, trueTimeMillis);

    emit(RankScreenState(
      currentRankId: profile.activeRankId,
      totalRp: profile.currentRp,          
      cycleStartTimeMillis: seasonResult.cycleStartTimeMillis,
      history: profile.rankAdvancementHistory, 
    ));
  }

  Future<void> refreshRankData() async {
    // Không làm gì cả, SyncManager kéo data thì AuthRepository Stream sẽ tự báo về đây
  }
}