import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/worker/sync_manager.dart';
import '../../../workout/data/repositories/workout_repository.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class VerifyOtpUseCase {
  final AuthRepository _authRepo;
  final WorkoutRepository _workoutRepo;
  final AppDatabase _db;

  VerifyOtpUseCase(this._authRepo, this._workoutRepo, this._db);

  /// Trả về null nếu thất bại, trả về String userId nếu thành công
  Future<String?> call({
    required String email,
    required String otpCode,
    required bool isSwitchAccount,
    required bool isLinkAccount,
    required Function(String messageKey) onProgress,
  }) async {
    if (isSwitchAccount) {
      onProgress('auth.msg_backing_up_current');
      final pushSuccess = await SyncManager.syncNow(pushOnly: true);
      if (!pushSuccess) {
        debugPrint("⚠️ Lỗi backup trước khi chuyển tài khoản, vẫn tiếp tục.");
      }
      await SyncManager.clearAllLocalUserData();
    }

    final currentUserId = await _authRepo.verifyOtpAndRetrieveUserId(email, otpCode);

    if (currentUserId != null) {
      onProgress('auth.msg_verify_success');

      if (isLinkAccount) {
        onProgress('auth.msg_syncing_to_cloud');
        await SyncManager.syncNow(pushOnly: true);
      } else if (!isSwitchAccount && !isLinkAccount) {
        // LUỒNG LOGIN
        onProgress('auth.msg_merging_cloud_data');
        await _authRepo.fetchAndSyncProfileIfLocalIsCorrupted();
        
        try {
          await _db.database.execute('DELETE FROM reward_claims_local');
        } catch (e) {
          debugPrint("⚠️ Dọn dẹp rác Guest Ledger thất bại: $e");
        }

        await _workoutRepo.handlePostAuthSync(currentUserId);
        await SyncManager.syncNow(pullOnly: true);
      } else if (isSwitchAccount) {
        onProgress('auth.msg_pulling_cloud_data');
        await _authRepo.fetchAndSyncProfileIfLocalIsCorrupted();
        await SyncManager.syncNow(pullOnly: true);
      }
      return currentUserId;
    }
    return null;
  }
}

@lazySingleton
class LogoutUseCase {
  final AuthRepository _authRepo;

  LogoutUseCase(this._authRepo);

  Future<void> call({required Function(String messageKey) onProgress}) async {
    onProgress('auth.msg_backing_up_and_logout');
    
    final pushSuccess = await SyncManager.syncNow(pushOnly: true);
    if (!pushSuccess) {
      debugPrint("⚠️ Cảnh báo: Không thể backup dữ liệu lên Cloud. Vẫn tiến hành xóa Local và Đăng xuất.");
    }
    
    await SyncManager.clearAllLocalUserData();
    await _authRepo.logout();
  }
}

@lazySingleton
class DeleteAccountUseCase {
  final AuthRepository _authRepo;

  DeleteAccountUseCase(this._authRepo);

  Future<bool> call({required Function(String messageKey) onProgress}) async {
    onProgress('auth.msg_deleting_cloud_data');
    
    final success = await _authRepo.deleteUserAccountOnCloud();
    
    if (success) {
      await SyncManager.clearAllLocalUserData();
      await _authRepo.logout();
      return true;
    }
    return false;
  }
}
