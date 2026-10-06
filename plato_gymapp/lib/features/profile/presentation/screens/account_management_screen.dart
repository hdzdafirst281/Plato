import 'dart:async';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_shake_wrapper.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/workout_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthFlowType, AuthState;

import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/screens/auth_otp_screen.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../gamification/presentation/bloc/gamification_cubit.dart';
import '../../../nutrition/presentation/bloc/nutrition_cubit.dart';
import '../../../workout/presentation/bloc/active_session_cubit.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/stats_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plato_gymapp/core/di/injection.dart';
import 'package:plato_gymapp/core/navigation/app_routes.dart';
import 'package:plato_gymapp/core/bloc/tour/tour_cubit.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isRequestingOtp = false;
  bool _isEmailInitialized = false;
  String? _localErrorKey;
  int _errorTrigger = 0;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  static const int _cooldownDuration = 90;

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().clearAuthMessage();
    _checkExistingCooldown();
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
      if (!mounted) {
        timer.cancel();
        return;
      }
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

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

  Future<void> _handleLinkChangeEmail(String currentEmail, bool isLinked) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() { _localErrorKey = 'auth.err_empty_email'; _errorTrigger++; });
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() { _localErrorKey = 'auth.err_invalid_email'; _errorTrigger++; });
      return;
    }
    
    if (isLinked && email.toLowerCase() == currentEmail.toLowerCase()) {
      setState(() { _localErrorKey = 'Email mới phải khác email hiện tại.'; _errorTrigger++; });
      return;
    }

    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      setState(() { _localErrorKey = 'auth.err_no_internet'; _errorTrigger++; });
      return;
    }
    
    FocusScope.of(context).unfocus();
    setState(() {
      _localErrorKey = null;
      _isRequestingOtp = true;
    });
    if (context.mounted) {
      context.read<AuthCubit>().clearAuthMessage();
    }
    
    final isSuccess = await context.read<AuthCubit>().requestLink(email);
    
    if (mounted) {
      setState(() {
        _isRequestingOtp = false;
        if (!isSuccess) _errorTrigger++;
      });
      if (isSuccess) {
        _startCooldown();
        
        await Navigator.of(context, rootNavigator: false)
            .push(
              MaterialPageRoute(builder: (_) => AuthOtpScreen(flowType: AuthFlowType.link, initialEmail: email, startAtOtpStep: true)),
            );
        if (context.mounted) {
          context.read<ProfileCubit>().refreshProfile();
          context.read<GamificationCubit>().refreshStateFromPrefs();
          _checkExistingCooldown();
        }
      }
    }
  }

  Future<void> _pushAuthScreen(BuildContext context, AuthFlowType flowType) async {
    await Navigator.of(context, rootNavigator: false)
        .push(
          MaterialPageRoute(builder: (_) => AuthOtpScreen(flowType: flowType)),
        );
    if (context.mounted) {
      context.read<ProfileCubit>().refreshProfile();
      context.read<GamificationCubit>().refreshStateFromPrefs();
    }
  }

  void _handleDeleteAccount(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
    final expectedConfirmationText = currentUserEmail ?? 'DELETE';
    String inputText = "";

    final confirm = await GymDialog.showCustom<bool>(
      context: context,
      useRootNavigator: false,
      titleWidget: Row(
        children: [
          Icon(Symbols.warning, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.profile.title_delete_account,
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.error, fontSize: 20),
            ),
          ),
        ],
      ),
      content: StatefulBuilder(
        builder: (context, setState) {
          final isMatch = inputText.trim().toLowerCase() == expectedConfirmationText.trim().toLowerCase();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.profile.desc_delete_account),
              const SizedBox(height: 16),
              Text(
                currentUserEmail != null ? t.auth.btn_confirm_delete_email : t.auth.btn_confirm_delete_guest,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                keyboardType: currentUserEmail != null ? TextInputType.emailAddress : TextInputType.text,
                decoration: InputDecoration(
                  hintText: expectedConfirmationText,
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => setState(() => inputText = value),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(t.common.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isMatch ? () => Navigator.pop(context, true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      disabledBackgroundColor: colorScheme.error.withValues(alpha: 0.2),
                      disabledForegroundColor: colorScheme.error.withValues(alpha: 0.5),
                    ),
                    child: Text(t.profile.btn_delete_confirm),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [],
    );

    if (confirm == true && context.mounted) {
      final success = await context.read<AuthCubit>().deleteAccount();
      if (context.mounted) {
        if (success) {
          context.read<ProfileCubit>().refreshProfile();
          context.read<GamificationCubit>().resetGamification();
          context.read<ActiveSessionCubit>().cancelWorkout();
          await context.read<NutritionCubit>().resetNutritionState();
          if (context.mounted) {
            context.read<WorkoutCubit>().resetWorkoutState();
            context.read<StatsCubit>().clearStats();
            context.read<TourCubit>().resetAllTours();
          }

          final prefs = getIt<SharedPreferences>();
          await prefs.setBool('isFirstRun', true);

          if (context.mounted) {
            Navigator.pop(context);
            context.go(AppRoutes.onboarding);

            GymSnackbar.show(
              context,
              message: t.profile.msg_delete_success,
              icon: Symbols.check_circle,
              accentColor: Theme.of(context).colorScheme.primary,
            );
          }
        } else {
          GymSnackbar.show(
            context,
            message: t.auth.err_network_delete_failed,
            icon: Symbols.error,
            accentColor: Theme.of(context).colorScheme.error,
          );
        }
      }
    }
  }

  Widget _buildActionCard(
    BuildContext context, {
    IconData? icon,
    String? svgAsset,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    assert(icon != null || svgAsset != null);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDestructive ? colorScheme.error.withValues(alpha: 0.5) : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), offset: const Offset(0, 4), blurRadius: 10),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDestructive ? colorScheme.error.withValues(alpha: 0.1) : colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: svgAsset != null
                      ? SvgPicture.asset(svgAsset, colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn), width: 24, height: 24)
                      : Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDestructive ? colorScheme.error : colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDestructive ? colorScheme.error.withValues(alpha: 0.8) : colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isDestructive)
                  Icon(Symbols.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarSize = ResponsiveValue<double>(
      context,
      defaultValue: 80.0,
      conditionalValues: [Condition.largerThan(name: MOBILE, value: 100.0)],
    ).value;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.settings.title_account_management,
        onBackClick: () => Navigator.pop(context),
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          final isLinked = profileState.isUserLoggedIn;
          final profile = profileState.userProfile;
          final bool hasAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
          final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;

          if (isLinked && currentUserEmail != null && !_isEmailInitialized) {
            _emailController.text = currentUserEmail;
            _isEmailInitialized = true;
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveValue<double>(
                    context,
                    defaultValue: 24.0,
                    conditionalValues: [Condition.largerThan(name: MOBILE, value: 48.0)],
                  ).value,
                  vertical: 24.0,
                ),
                children: [
                  Column(
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLinked ? Theme.of(context).gymColors.success : colorScheme.outlineVariant,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasAvatar
                              ? Image.network(
                                  profile.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Symbols.person, size: avatarSize * 0.5, color: colorScheme.onSurfaceVariant),
                                )
                              : Icon(Symbols.person, size: avatarSize * 0.5, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AutoSizeText(
                        profile.displayName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        minFontSize: 16,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isLinked
                              ? Theme.of(context).gymColors.success.withValues(alpha: 0.1)
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isLinked && currentUserEmail != null ? currentUserEmail : t.settings.msg_auth_unlinked,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isLinked ? Theme.of(context).gymColors.success : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      final authMessage = authState.authMessage;
                      final isApiError = authMessage != null && authMessage.isNotEmpty && (authMessage.toLowerCase().contains("error") || authMessage.toLowerCase().contains("lỗi") || authMessage.toLowerCase().contains("err") || authMessage.toLowerCase().contains("tồn tại"));
                      final isError = _localErrorKey != null || isApiError;
                      final errorMessage = _localErrorKey != null 
                          ? (_localErrorKey!.contains('.') ? t.translateDynamic(_localErrorKey!) : _localErrorKey!) 
                          : (isApiError ? t.translateDynamic(authMessage) : "");
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.auth.lbl_email_input,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GymShakeWrapper(
                            hasError: isError,
                            shakeKey: ValueKey(_errorTrigger),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (val) {
                                if (_localErrorKey != null) {
                                  setState(() => _localErrorKey = null);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'example@gmail.com',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: isError ? colorScheme.error : colorScheme.outline, width: isError ? 1.5 : 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: isError ? colorScheme.error : colorScheme.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                suffixIconConstraints: const BoxConstraints(minHeight: 52, maxHeight: 52),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 1.5, top: 1.5, bottom: 1.5),
                                  child: ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _emailController,
                                    builder: (context, value, child) {
                                      return SizedBox(
                                        height: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: (_isRequestingOtp || _cooldownSeconds > 0) ? null : () => _handleLinkChangeEmail(currentUserEmail ?? "", isLinked),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.primary,
                                            foregroundColor: colorScheme.onPrimary,
                                            disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                                            disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.horizontal(
                                                left: Radius.circular(12),
                                                right: Radius.circular(14.5),
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            minimumSize: const Size(0, 0),
                                          ),
                                          child: _isRequestingOtp 
                                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                                              : Text(
                                                  _cooldownSeconds > 0
                                                      ? _formatCooldown()
                                                      : (isLinked ? t.auth.btn_change_email : t.common.confirm),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isError)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(Symbols.error_outline, color: colorScheme.error, size: 14), 
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(errorMessage, style: TextStyle(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  if (!isLinked) ...[
                    _buildActionCard(
                      context,
                      icon: Symbols.login,
                      iconColor: colorScheme.primary,
                      title: t.auth.title_login_sync,
                      subtitle: t.auth.desc_login_sync,
                      onTap: () => _pushAuthScreen(context, AuthFlowType.login),
                    ),
                  ],

                  if (isLinked) ...[
                    _buildActionCard(
                      context,
                      icon: Symbols.switch_account,
                      iconColor: colorScheme.primary,
                      title: t.auth.title_switch_account,
                      subtitle: t.auth.desc_switch_account,
                      onTap: () => _pushAuthScreen(context, AuthFlowType.switchAccount),
                    ),
                  ],

                  const SizedBox(height: 16),

                  _buildActionCard(
                    context,
                    svgAsset: 'assets/svg/icons/permanent_delete.svg',
                    iconColor: colorScheme.error,
                    title: t.profile.btn_delete_account,
                    subtitle: t.profile.desc_delete_account_short,
                    isDestructive: true,
                    onTap: () => _handleDeleteAccount(context),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
