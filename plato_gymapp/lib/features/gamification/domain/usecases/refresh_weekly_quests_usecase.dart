import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../../workout/data/models/workout_models.dart';

@injectable
class RefreshWeeklyQuestsUseCase {
  final GamificationRepository _gamificationRepo;
  final AuthRepository _authRepo;

  RefreshWeeklyQuestsUseCase(this._gamificationRepo, this._authRepo);

  Future<void> execute(List<WorkoutSession> completedWorkouts) async {
    try {
      final currentProfile = _authRepo.getProfile();

      // Hàm này trả về lượng XP cần thu hồi.
      // Nếu thao tác xóa là từ máy này (WorkoutCubit đã trừ XP trước), hàm này sẽ trả về 0 -> Không có Race Condition.
      final xpToRollback = await _gamificationRepo.calculateWeeklyStats(
        workoutsList: completedWorkouts,
        userProfileData: currentProfile,
      );

      if (xpToRollback > 0) {
        // 🚀 CƠ CHẾ SAFE FALLBACK (Trường hợp DB tự xoá do đồng bộ từ Cloud):
        // Chờ 300ms nhường luồng cho ProfileCubit lưu xong RP (nếu có),
        // sau đó mới đọc lại Profile mới nhất và trừ XP để đảm bảo không ghi đè dữ liệu.
        await Future.delayed(const Duration(milliseconds: 300));
        
        final latestProfile = _authRepo.getProfile();
        int newXp = latestProfile.experiencePoints - xpToRollback;
        final profileToUpdate = latestProfile.copyWith(experiencePoints: newXp > 0 ? newXp : 0);
        
        await _authRepo.saveProfile(profileToUpdate);
        _gamificationRepo.updateStatsAfterXpGain(profileToUpdate);
      } else {
        // Luồng chuẩn: Cập nhật giao diện bình thường không đụng chạm SharedPreferences
        _gamificationRepo.updateStatsAfterXpGain(currentProfile);
      }
    } catch (e) {
      debugPrint("⚠️ [RefreshWeeklyQuestsUseCase] Lỗi Refresh Quests: $e");
    }
  }
}
