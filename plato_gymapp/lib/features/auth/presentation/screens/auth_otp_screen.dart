import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/bloc/tour/tour_cubit.dart';
import 'package:plato_gymapp/core/di/injection.dart';
import 'package:plato_gymapp/features/gamification/presentation/bloc/gamification_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/workout_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../bloc/auth_cubit.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/navigation/app_routes.dart';

class AuthOtpScreen extends StatefulWidget {
  final AuthFlowType flowType; 
  
  const AuthOtpScreen({super.key, required this.flowType});

  @override
  State<AuthOtpScreen> createState() => _AuthOtpScreenState();
}

class _AuthOtpScreenState extends State<AuthOtpScreen> {
  int _currentStep = 1;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  
  bool _hasNavigated = false;
  String? _emailErrorKey;

  static const int _cooldownDuration = 90;

  String get _screenTitle {
    switch(widget.flowType) {
      case AuthFlowType.login: return t.auth.title_login_sync;
      case AuthFlowType.link: return t.auth.title_link_email;
      case AuthFlowType.switchAccount: return t.auth.title_switch_account;
    }
  }

  String get _screenDesc {
    switch(widget.flowType) {
      case AuthFlowType.login: return t.auth.desc_login_sync_screen;
      case AuthFlowType.link: return t.auth.desc_link_email_screen;
      case AuthFlowType.switchAccount: return t.auth.desc_switch_account_screen;
    }
  }

  IconData get _screenIcon {
    switch(widget.flowType) {
      case AuthFlowType.login: return Symbols.login;
      case AuthFlowType.link: return Symbols.cloud_sync;
      case AuthFlowType.switchAccount: return Symbols.sync_alt;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExistingCooldown();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }

  void _checkExistingCooldown() {
    final repo = getIt<AuthRepository>();
    final lastSentTimestamp = repo.otpCooldownTimestamp;
    if (lastSentTimestamp != null) {
      final lastSent = DateTime.fromMillisecondsSinceEpoch(lastSentTimestamp);
      final secondsPassed = DateTime.now().difference(lastSent).inSeconds;
      if (secondsPassed < _cooldownDuration && secondsPassed >= 0) {
        _startCooldown(seconds: _cooldownDuration - secondsPassed, saveTimestamp: false);
      }
    }
  }

  void _startCooldown({int seconds = _cooldownDuration, bool saveTimestamp = true}) {
    if (saveTimestamp) {
      getIt<AuthRepository>().saveOtpCooldownTimestamp(DateTime.now().millisecondsSinceEpoch);
    }
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }
  
  String _formatCooldown() {
    final minutes = (_cooldownSeconds / 60).floor();
    final seconds = _cooldownSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleBack(bool isLoading) {
    if (_currentStep == 2 && !isLoading) {
      setState(() { _currentStep = 1; _otpController.clear(); });
      context.read<AuthCubit>().clearAuthMessage(); // [DỌN DẸP]
    } else if (!isLoading) {
      context.read<AuthCubit>().clearAuthMessage(); // [DỌN DẸP]
      context.pop();
    }
  }

  Future<bool> _requestOtpAction(String email) async {
    final cubit = context.read<AuthCubit>();
    switch (widget.flowType) {
      case AuthFlowType.login: return await cubit.requestLogin(email);
      case AuthFlowType.link: return await cubit.requestLink(email);
      case AuthFlowType.switchAccount: return await cubit.requestSwitchAccount(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.syncResult != current.syncResult,
      // 🚀 Thêm async vào listener
      listener: (context, state) async {
        if (!_hasNavigated && state.syncResult != null && state.syncResult!.isSuccess) {
          _hasNavigated = true; 
          
          // 1. Đóng bàn phím trước
          FocusManager.instance.primaryFocus?.unfocus(); 
          
          // 🚀 FIX LỖI 2 (Jank): Nhường 150ms cho Main Thread xử lý animation đóng bàn phím Android
          await Future.delayed(const Duration(milliseconds: 150));

          getIt<SharedPreferences>().setBool('isFirstRun', false);

          if (context.mounted) {
            context.read<ProfileCubit>().refreshProfile();
            context.read<GamificationCubit>().refreshStateFromPrefs();
            context.read<WorkoutCubit>().resetWorkoutState();

            if (state.syncResult!.shouldBypassOnboarding) {
              context.read<TourCubit>().completeAllTours();
            }

            // 🚀 FIX LỖI 2 (Crash Router): Loại bỏ GoRouterState.of(context) gây lỗi ProviderNotFound
            if (Navigator.canPop(context)) {
              // Nếu màn hình này được đẩy bằng Navigator.push (Từ Quản lý tài khoản)
              Navigator.pop(context, true);
            } else {
              // Nếu màn hình này là điểm vào đầu tiên (Initial route)
              context.go(AppRoutes.workout);
            }
          }
        }
      },
      builder: (context, state) {
        final isLoading = state.isLoading;
        final authMessage = state.authMessage;
        final isTabletOrLarger = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);

        // [BỔ SUNG AN TOÀN]: Bọc PopScope để dọn dẹp AuthMessage nếu user vuốt thoát trên iOS / Back cứng Android
        return PopScope(
          canPop: !isLoading,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              context.read<AuthCubit>().clearAuthMessage();
            }
          },
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: colorScheme.surface,
                appBar: GymTopBar(
                  title: _screenTitle,
                  backgroundColor: colorScheme.surface,
                  onBackClick: () => _handleBack(isLoading),
                ),
                body: SafeArea(
                  child: isTabletOrLarger
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 120, height: 120,
                                          decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary.withValues(alpha: 0.1)),
                                          child: Icon(_screenIcon, color: colorScheme.primary, size: 64, fill:1.0),
                                        ).animate().fade().scale(),
                                        const SizedBox(height: 32),
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: _currentStep == 1 ? _buildEmailStep(colorScheme, textTheme, isLoading, part: 1) : _buildOtpStep(colorScheme, textTheme, isLoading, part: 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: _currentStep == 1 ? _buildEmailStep(colorScheme, textTheme, isLoading, part: 2) : _buildOtpStep(colorScheme, textTheme, isLoading, part: 2),
                                        ),
                                        if (authMessage != null && authMessage.isNotEmpty) ...[
                                          const SizedBox(height: 24),
                                          _buildMessageBanner(colorScheme, authMessage).animate().fade().slideY(),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveValue<double>(context, defaultValue: 24.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 16.0)]).value, 
                              vertical: 32
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary.withValues(alpha: 0.1)),
                                  child: Icon(_screenIcon, color: colorScheme.primary, size: 50, fill: 1.0),
                                ).animate().fade().scale(),
                                const SizedBox(height: 32),
                                _buildFormContent(colorScheme, textTheme, isLoading, authMessage),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    // [BỔ SUNG AN TOÀN]: Bọc Material để fix lỗi text gạch vàng
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface, 
                          borderRadius: BorderRadius.circular(16),
                          // [BỔ SUNG UI]: Thêm border theo yêu cầu
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              authMessage != null ? t.translateDynamic(authMessage) : t.auth.msg_processing, 
                              style: TextStyle(
                                color: colorScheme.onSurface, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14
                              ), 
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fade(duration: 200.ms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormContent(ColorScheme colorScheme, TextTheme textTheme, bool isLoading, String? authMessage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _currentStep == 1 ? _buildEmailStep(colorScheme, textTheme, isLoading, part: 0) : _buildOtpStep(colorScheme, textTheme, isLoading, part: 0),
        ),
        if (authMessage != null && authMessage.isNotEmpty && !isLoading) ...[
          const SizedBox(height: 24),
          _buildMessageBanner(colorScheme, authMessage).animate().fade().slideY(),
        ],
      ],
    );
  }

  Widget _buildEmailStep(ColorScheme colorScheme, TextTheme textTheme, bool isLoading, {int part = 0}) {
    final textChildren = [
      Text(_screenTitle, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Text(_screenDesc, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
    ];

    final inputChildren = [
      TextField(
        controller: _emailController, keyboardType: TextInputType.emailAddress,
        onChanged: (_) { if (_emailErrorKey != null) setState(() => _emailErrorKey = null); },
        decoration: InputDecoration(labelText: t.auth.label_email_input, prefixIcon: const Icon(Symbols.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
      if (_emailErrorKey != null)
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, bottom: 8),
          child: Row(
            children: [
              Icon(Symbols.error_outline, color: colorScheme.error, size: 14), const SizedBox(width: 4),
              Expanded(child: Text(t.translateDynamic(_emailErrorKey!), style: TextStyle(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
        ).animate().fade(),
      SizedBox(height: _emailErrorKey != null ? 16 : 32),
      SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: (!isLoading && _cooldownSeconds == 0)
              ? () async {
                  FocusScope.of(context).unfocus();
                  final email = _emailController.text.trim();
                  if (email.isEmpty) { setState(() => _emailErrorKey = 'auth.err_empty_email'); HapticFeedback.vibrate(); return; }
                  if (!_isValidEmail(email)) { setState(() => _emailErrorKey = 'auth.err_invalid_email'); HapticFeedback.vibrate(); return; }

                  final isSuccess = await _requestOtpAction(email);
                  if (isSuccess && mounted) { _startCooldown(); setState(() => _currentStep = 2); }
                }
              : null, 
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: FittedBox(
            child: Text(
              _cooldownSeconds > 0 ? t.auth.btn_resend_cooldown(time: _formatCooldown()) : t.auth.btn_send_otp, 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ),
    ];

    return KeyedSubtree(
      key: ValueKey('email_part_$part'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (part == 0 || part == 1) ...textChildren,
          if (part == 0) const SizedBox(height: 32),
          if (part == 0 || part == 2) ...inputChildren,
        ],
      ).animate().fade().slideY(),
    );
  }

  Widget _buildOtpStep(ColorScheme colorScheme, TextTheme textTheme, bool isLoading, {int part = 0}) {
    final double otpBoxHeight = ResponsiveValue<double>(context, defaultValue: 64.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 54.0)]).value;

    final textChildren = [
      Text(t.auth.title_verify_otp, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(t.auth.desc_otp_instruction(arg1: _emailController.text.trim()), style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
    ];

    final inputChildren = [
      SizedBox(
        height: otpBoxHeight,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                final text = _otpController.text;
                final isFocused = text.length == index || (text.length == 6 && index == 5);
                final hasValue = index < text.length;

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                    height: otpBoxHeight, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isFocused ? colorScheme.primary : Colors.transparent, width: 2),
                    ),
                    child: FittedBox(child: Text(hasValue ? text[index] : "", style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: TextField(
                controller: _otpController, keyboardType: TextInputType.number, maxLength: 6, autofocus: true, showCursor: false, enableInteractiveSelection: false, 
                style: const TextStyle(color: Colors.transparent), decoration: const InputDecoration(border: InputBorder.none, counterText: "", fillColor: Colors.transparent, filled: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(t.auth.desc_did_not_get_code, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          GestureDetector(
            onTap: (_cooldownSeconds == 0 && !isLoading)
                ? () async {
                    FocusScope.of(context).unfocus();
                    final isSuccess = await _requestOtpAction(_emailController.text.trim());
                    if (isSuccess && mounted) { _startCooldown(); }
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _cooldownSeconds > 0 ? t.auth.btn_resend_cooldown(time: _formatCooldown()) : (t.auth.btn_click_to_resend),
                style: textTheme.bodyMedium?.copyWith(color: _cooldownSeconds == 0 ? colorScheme.primary : colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: TextButton(
                onPressed: isLoading ? null : () => _handleBack(isLoading),
                style: TextButton.styleFrom(backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: FittedBox(child: Text(t.common.cancel, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.bold))),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (_otpController.text.length == 6 && !isLoading)
                    ? () {
                        FocusScope.of(context).unfocus();
                        context.read<AuthCubit>().verifyOtp(_emailController.text.trim(), _otpController.text);
                      }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: FittedBox(child: Text(t.common.confirm, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ),
            ),
          ),
        ],
      ),
    ];

    return KeyedSubtree(
      key: ValueKey('otp_part_$part'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (part == 0 || part == 1) ...textChildren,
          if (part == 0) const SizedBox(height: 32),
          if (part == 0 || part == 2) ...inputChildren,
        ],
      ).animate().fade().slideY(),
    );
  }

  Widget _buildMessageBanner(ColorScheme colorScheme, String msg) {
    final msgLower = msg.toLowerCase();
    // [CẬP NHẬT ĐIỀU KIỆN LỖI]: Nhận diện chính xác tiền tố "err" từ JSON key
    final isError = msgLower.contains("error") || msgLower.contains("lỗi") || msgLower.contains("err");
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? colorScheme.errorContainer : colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: isError ? colorScheme.error : colorScheme.primary),
      ),
      child: Text(t.translateDynamic(msg), textAlign: TextAlign.center, style: TextStyle(color: isError ? colorScheme.error : colorScheme.primary, fontWeight: FontWeight.w600)),
    );
  }
}