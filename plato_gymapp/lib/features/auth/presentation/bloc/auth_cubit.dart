import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../data/models/user_models.dart';

part 'auth_cubit.freezed.dart';

enum AuthFlowType { login, link, switchAccount }

class AuthSyncResult {
  final bool isSuccess;
  final bool shouldBypassOnboarding;

  const AuthSyncResult({
    required this.isSuccess,
    required this.shouldBypassOnboarding,
  });
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    UserProfile? userProfile,
    @Default(false) bool showWeeklyWeightReminder,
    @Default(false) bool isLoading,
    String? authMessage,
    AuthSyncResult? syncResult,
    AuthFlowType? currentFlow, 
  }) = _AuthState;
}

@injectable
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepo;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final LogoutUseCase _logoutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;

  AuthCubit(
    this._authRepo,
    this._verifyOtpUseCase,
    this._logoutUseCase,
    this._deleteAccountUseCase,
  ) : super(const AuthState()) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final profile = _authRepo.getProfile();
    emit(state.copyWith(userProfile: profile));
    _checkWeeklyWeightReminder();
  }

  void _checkWeeklyWeightReminder() {
    final profile = _authRepo.getProfile();
    final history = _authRepo.getBodyMeasurements();
    
    final startDateMillis = profile.goalStartTimestampMillis;
    if (startDateMillis == null) return;

    final currentMillis = DateTime.now().millisecondsSinceEpoch;
    const oneWeekInMillis = 7 * 24 * 3600 * 1000;

    if (currentMillis - startDateMillis < oneWeekInMillis) return;

    final latestUpdateMillis = history.isEmpty 
        ? startDateMillis 
        : history.reduce((a, b) => a.recordTimestampMillis > b.recordTimestampMillis ? a : b).recordTimestampMillis;

    if (currentMillis - latestUpdateMillis > oneWeekInMillis) {
      emit(state.copyWith(showWeeklyWeightReminder: true));
    }
  }

  void dismissWeeklyWeightReminder() {
    emit(state.copyWith(showWeeklyWeightReminder: false));
  }

  void clearAuthMessage() {
    emit(state.copyWith(authMessage: null));
  }

  // ==========================================
  // --- STATE MACHINE CHO 3 LUỒNG AUTH ---
  // ==========================================

  // 1. YÊU CẦU ĐĂNG NHẬP
  Future<bool> requestLogin(String email) async {
    emit(state.copyWith(isLoading: true, currentFlow: AuthFlowType.login, authMessage: null));
    final exists = await _authRepo.checkEmailExists(email);
    if (!exists) {
      emit(state.copyWith(isLoading: false, authMessage: 'auth.err_account_not_found'));
      return false;
    }
    final isSuccess = await _authRepo.requestLoginOtp(email);
    emit(state.copyWith(isLoading: false, authMessage: isSuccess ? 'auth.msg_otp_sent_success' : 'auth.err_otp_sent_failed'));
    return isSuccess;
  }

  // 2. YÊU CẦU LIÊN KẾT / ĐỔI EMAIL
  Future<bool> requestLink(String email) async {
    emit(state.copyWith(isLoading: true, currentFlow: AuthFlowType.link, authMessage: null));
    final exists = await _authRepo.checkEmailExists(email);
    if (exists) {
      emit(state.copyWith(isLoading: false, authMessage: 'auth.err_email_in_use'));
      return false;
    }

    bool isSuccess;
    if (_authRepo.isUserLoggedIn) {
      isSuccess = await _authRepo.updateUserEmail(email); 
    } else {
      isSuccess = await _authRepo.requestLinkOtp(email); 
    }
    
    emit(state.copyWith(isLoading: false, authMessage: isSuccess ? 'auth.msg_otp_sent_success' : 'auth.err_otp_sent_failed'));
    return isSuccess;
  }

  // 3. YÊU CẦU CHUYỂN TÀI KHOẢN
  Future<bool> requestSwitchAccount(String email) async {
    emit(state.copyWith(isLoading: true, currentFlow: AuthFlowType.switchAccount, authMessage: null));
    
    // [BỔ SUNG]: Kiểm tra email chuyển đổi không trùng với email hiện tại
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;
    if (currentEmail != null && currentEmail.toLowerCase() == email.trim().toLowerCase()) {
      emit(state.copyWith(isLoading: false, authMessage: 'auth.err_same_email'));
      return false;
    }

    final exists = await _authRepo.checkEmailExists(email);
    if (!exists) {
      emit(state.copyWith(isLoading: false, authMessage: 'auth.err_target_account_not_found'));
      return false;
    }
    final isSuccess = await _authRepo.requestLoginOtp(email);
    emit(state.copyWith(isLoading: false, authMessage: isSuccess ? 'auth.msg_otp_sent_success' : 'auth.err_otp_sent_failed'));
    return isSuccess;
  }

  // --- XÁC NHẬN OTP & PHÂN LUỒNG XỬ LÝ DỮ LIỆU CHUẨN XÁC ---
  Future<void> verifyOtp(String email, String otpCode) async {
    emit(state.copyWith(isLoading: true, syncResult: null, authMessage: 'auth.msg_verifying')); 
    
    final currentUserId = await _verifyOtpUseCase(
      email: email, 
      otpCode: otpCode, 
      isSwitchAccount: state.currentFlow == AuthFlowType.switchAccount, 
      isLinkAccount: state.currentFlow == AuthFlowType.link,
      onProgress: (msg) => emit(state.copyWith(authMessage: msg)),
    );

    if (currentUserId != null) {
      emit(state.copyWith(
        isLoading: false, 
        userProfile: _authRepo.getProfile(),
        syncResult: const AuthSyncResult(isSuccess: true, shouldBypassOnboarding: true)
      ));
    } else {
      emit(state.copyWith(isLoading: false, authMessage: 'auth.err_verify_failed'));
    }
  }

  // ==========================================
  // --- CÁC HÀM XÓA/THOÁT TÀI KHOẢN ---
  // ==========================================

  Future<void> logoutUser() async {
    emit(state.copyWith(isLoading: true, authMessage: 'auth.msg_backing_up_and_logout'));
    
    await _logoutUseCase(
      onProgress: (msg) => emit(state.copyWith(authMessage: msg)),
    );
    
    emit(state.copyWith(isLoading: false, userProfile: null, currentFlow: null, authMessage: null));
  }

  Future<bool> deleteAccount() async {
    emit(state.copyWith(isLoading: true, authMessage: 'auth.msg_deleting_cloud_data'));
    
    final success = await _deleteAccountUseCase(
      onProgress: (msg) => emit(state.copyWith(authMessage: msg)),
    );
    
    if (success) {
      emit(state.copyWith(isLoading: false, userProfile: null, currentFlow: null, authMessage: 'auth.msg_delete_account_success'));
      return true;
    } else {
      emit(state.copyWith(isLoading: false, authMessage: 'auth.err_network_delete_failed'));
      return false;
    }
  }
}