import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/workout_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthFlowType;

import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/screens/auth_otp_screen.dart';
// ĐÃ THÊM: Import các Cubit cần dọn dẹp
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

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  void _pushAuthScreen(BuildContext context, AuthFlowType flowType) {
    Navigator.of(context, rootNavigator: false)
        .push(
          MaterialPageRoute(builder: (_) => AuthOtpScreen(flowType: flowType)),
        )
        .then((_) {
          if (context.mounted) {
            context.read<ProfileCubit>().refreshProfile();
            context.read<GamificationCubit>().refreshStateFromPrefs();
          }
        });
  }

  void _handleDeleteAccount(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    // 1. Lấy email hiện tại từ Supabase
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;

    // 2. Xác định từ khóa yêu cầu
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: StatefulBuilder(
        builder: (context, setState) {
          final isMatch =
              inputText.trim().toLowerCase() ==
              expectedConfirmationText.trim().toLowerCase();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.profile.desc_delete_account),
              const SizedBox(height: 16),

              Text(
                currentUserEmail != null
                    ? t.auth.btn_confirm_delete_email
                    : t.auth.btn_confirm_delete_guest,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                autofocus: true,
                keyboardType: currentUserEmail != null
                    ? TextInputType.emailAddress
                    : TextInputType.text,
                decoration: InputDecoration(
                  hintText: expectedConfirmationText,
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.error, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    inputText = value;
                  });
                },
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
                    onPressed: isMatch
                        ? () => Navigator.pop(context, true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      disabledBackgroundColor: colorScheme.error.withValues(
                        alpha: 0.2,
                      ),
                      disabledForegroundColor: colorScheme.error.withValues(
                        alpha: 0.5,
                      ),
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

  // --- WIDGET BUILDER CHO CÁC KHỐI BUTTON ---
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDestructive
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
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
                    color: isDestructive
                        ? colorScheme.error.withValues(alpha: 0.1)
                        : colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // [FIX UI]: Xử lý tràn text (Level 2)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDestructive
                              ? colorScheme.error
                              : colorScheme.onSurface,
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
                          color: isDestructive
                              ? colorScheme.error.withValues(alpha: 0.8)
                              : colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isDestructive)
                  Icon(
                    Symbols.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
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

    // [FIX UI]: Tự động scale Avatar cho thiết bị siêu nhỏ
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
          final bool hasAvatar =
              profile.avatarBase64 != null && profile.avatarBase64!.isNotEmpty;
          final currentUserEmail =
              Supabase.instance.client.auth.currentUser?.email;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveValue<double>(
                    context,
                    defaultValue: 24.0,
                    conditionalValues: [
                      Condition.largerThan(name: MOBILE, value: 48.0),
                    ],
                  ).value,
                  vertical: 24.0,
                ),
                children: [
                  // === KHU VỰC HIỂN THỊ THÔNG TIN USER ===
                  Column(
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        // Padding chính là độ dày của viền (4px)
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Màu nền của Container ngoài sẽ đóng vai trò là màu viền
                          color: isLinked
                              ? Theme.of(context).gymColors.success
                              : colorScheme.outlineVariant,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme
                                .surfaceContainerHighest, // Màu nền phía sau khi hiển thị Icon
                          ),
                          // Sử dụng antiAlias để viền ảnh tròn mượt mà, không bị mẻ cạnh (pixelated)
                          clipBehavior: Clip.antiAlias,
                          child: hasAvatar
                              ? Image.memory(
                                  base64Decode(profile.avatarBase64!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Symbols.person,
                                        size: avatarSize * 0.5,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                )
                              : Icon(
                                  Symbols.person,
                                  size: avatarSize * 0.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isLinked
                              ? Theme.of(
                                  context,
                                ).gymColors.success.withValues(alpha: 0.1)
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.1,
                                ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isLinked && currentUserEmail != null
                              ? currentUserEmail
                              : t.settings.msg_auth_unlinked,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isLinked
                                ? Theme.of(context).gymColors.success
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // === KHU VỰC CÁC CHỨC NĂNG ===
                  if (!isLinked) ...[
                    _buildActionCard(
                      context,
                      icon: Symbols.cloud_upload,
                      iconColor: colorScheme.primary,
                      title: t.auth.title_link_email,
                      subtitle: t.auth.desc_link_email,
                      onTap: () => _pushAuthScreen(context, AuthFlowType.link),
                    ),
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
                      icon: Symbols.mark_email_read,
                      iconColor: colorScheme.primary,
                      title: t.auth.btn_change_email,
                      subtitle: t.auth.desc_change_email,
                      onTap: () => _pushAuthScreen(context, AuthFlowType.link),
                    ),
                    _buildActionCard(
                      context,
                      icon: Symbols.switch_account,
                      iconColor: colorScheme.primary,
                      title: t.auth.title_switch_account,
                      subtitle: t.auth.desc_switch_account,
                      onTap: () =>
                          _pushAuthScreen(context, AuthFlowType.switchAccount),
                    ),
                  ],

                  const SizedBox(height: 16),

                  _buildActionCard(
                    context,
                    icon: Symbols.delete_forever,
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
