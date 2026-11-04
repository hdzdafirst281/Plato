import '../../data/models/user_models.dart';

class OtpExpiredAuthException implements Exception {
  final String message;
  const OtpExpiredAuthException([this.message = 'OTP expired']);
  @override
  String toString() => 'OtpExpiredAuthException: $message';
}

class OtpInvalidAuthException implements Exception {
  final String message;
  const OtpInvalidAuthException([this.message = 'OTP invalid']);
  @override
  String toString() => 'OtpInvalidAuthException: $message';
}

abstract class AuthRepository {
  Stream<UserProfile> get profileUpdateStream;
  
  UserProfile getProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<String?> uploadAvatarToStorage(List<int> imageBytes);
  void dispose();
  
  List<BodyMeasurement> getBodyMeasurements();
  Future<void> recordNewWeightMeasurement(double newWeightKgInput);
  
  bool get isUserLoggedIn;
  String? get currentUserId;
  
  Future<bool> checkEmailExists(String email);
  Future<bool> requestLoginOtp(String email);
  Future<bool> requestLinkOtp(String email);
  Future<bool> updateUserEmail(String newEmail);
  Future<String?> verifyOtpAndRetrieveUserId(String userEmailInputString, String verificationOtpTokenString);
  Future<void> logout();
  Future<bool> deleteUserAccountOnCloud();
  
  Future<void> fetchAndSyncProfileIfLocalIsCorrupted();
  Future<bool> forceSyncProfileFromCloud(String targetUserId);
  UserProfile recalculatePhysiologicalStats(UserProfile baseProfile, {bool keepExistingMacros = false});
  
  int? get otpCooldownTimestamp;
  Future<void> saveOtpCooldownTimestamp(int timestamp);
}
