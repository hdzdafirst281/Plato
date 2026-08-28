import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/gamification/presentation/bloc/gamification_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/stats_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/account_management_screen.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/workout_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/designsystem/theme/theme_cubit.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/profile_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/workout_permission_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBackgroundWorkoutEnabled = true;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  void _initSettings() async {
    final prefs = getIt<SharedPreferences>();
    bool isEnabled = prefs.getBool(WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey) ?? false;
    
    if (isEnabled) {
      // Double check OS permissions. If they revoked it via OS, sync our toggle to false.
      bool hasNoti = await Permission.notification.isGranted;
      bool hasActivity = true;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 34) {
          hasActivity = await Permission.activityRecognition.isGranted;
        }
      }
      if (!hasNoti || !hasActivity) {
        isEnabled = false;
        await prefs.setBool(WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey, false);
      }
    }
    
    if (mounted) {
      setState(() {
        _isBackgroundWorkoutEnabled = isEnabled;
      });
    }
  }

  void _sendSupportEmail() async {
  final subjectText = t.settings.msg_intent_email_subject;
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'support.plato@zenithas.vn',
    // Sử dụng Uri.encodeComponent để mã hóa khoảng trắng thành '%20' thay vì '+'
    query: 'subject=${Uri.encodeComponent(subjectText)}',
  );
  
  if (!await launchUrl(emailLaunchUri)) {
    debugPrint('Không thể mở ứng dụng Email');
  }
}

  void _launchSocialUrl(String webUrl, {String? nativeUrl}) async {
    if (webUrl.isEmpty) return;

    // 1. Thử mở bằng Native App URL (custom scheme như fb://, instagram://) nếu được cung cấp
    if (nativeUrl != null && nativeUrl.isNotEmpty) {
      final Uri nativeUri = Uri.parse(nativeUrl);
      try {
        if (await launchUrl(nativeUri, mode: LaunchMode.externalApplication)) {
          return; // Thành công mở qua custom scheme
        }
      } catch (e) {
        debugPrint('Lỗi mở nativeUrl: $e');
      }
    }

    // 2. Thử mở Universal Link (ép mở app qua link https, không dùng trình duyệt)
    final Uri webUri = Uri.parse(webUrl);
    try {
      if (await launchUrl(webUri, mode: LaunchMode.externalNonBrowserApplication)) {
        return; // Thành công mở qua app (Universal Link/App Link)
      }
    } catch (e) {
      debugPrint('Lỗi mở externalNonBrowserApplication: $e');
    }

    // 3. Fallback cuối cùng: Mở bằng trình duyệt web
    if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
      debugPrint('Không thể mở liên kết: $webUrl');
    }
  }

  void _showLanguageDialog(BuildContext context) {
    GymDialog.showCustom(
      context: context,
      useRootNavigator: false,
      titleWidget: Text(t.settings.title_language_dialog, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.language),
              title: const Text("Tiếng Việt"),
              trailing: TranslationProvider.of(context).flutterLocale.languageCode == 'vi' ? const Icon(Symbols.check, color: Colors.blue) : null,
              onTap: () {
                LocaleSettings.setLocaleRaw("vi");
                SharedPreferences.getInstance().then((prefs) => prefs.setString('app_lang', 'vi'));
                Navigator.of(context, rootNavigator: false).pop();
              },
            ),
            ListTile(
              leading: const Icon(Symbols.language),
              title: const Text("English"),
              trailing: TranslationProvider.of(context).flutterLocale.languageCode == 'en' ? const Icon(Symbols.check, color: Colors.blue) : null,
              onTap: () {
                LocaleSettings.setLocaleRaw("en");
                SharedPreferences.getInstance().then((prefs) => prefs.setString('app_lang', 'en'));
                Navigator.of(context, rootNavigator: false).pop();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context, rootNavigator: false).pop(), child: Text(t.common.close, style: const TextStyle(fontWeight: FontWeight.bold)))
      ],
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirm = await GymDialog.showDestructive(
      context: context,
      useRootNavigator: false,
      title: t.profile.title_logout_dialog,
      message: t.profile.desc_logout_dialog,
      cancelText: t.common.cancel,
      confirmText: t.common.logout,
    );
    
    if (confirm == true && context.mounted) {
      await context.read<AuthCubit>().logoutUser(); 
      if (context.mounted) {
        // 🚀 CRITIC FIX: Đồng bộ combo dọn RAM giống như màn Delete Account
        context.read<ProfileCubit>().refreshProfile();
        context.read<GamificationCubit>().resetGamification();
        context.read<WorkoutCubit>().resetWorkoutState(); 
        context.read<StatsCubit>().clearStats();
        
        GymSnackbar.show(
          context,
          message: t.profile.msg_logout_success,
          icon: Symbols.check_circle,
          accentColor: Theme.of(context).colorScheme.primary,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentLang = TranslationProvider.of(context).flutterLocale.languageCode == 'vi' ? "Tiếng Việt" : "English";

    // Tối ưu Responsive: Tự động nới lỏng padding trên màn hình Tablet/Desktop
    final itemPadding = ResponsiveValue<EdgeInsets>(
      context,
      defaultValue: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      conditionalValues: [
        Condition.largerThan(name: MOBILE, value: const EdgeInsets.symmetric(horizontal: 48, vertical: 12)),
      ],
    ).value;
    
    final titleStyle = TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold);
    final subtitleStyle = TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.settings.title_dialog_main,
        onBackClick: () => context.pop(),
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          final isLinked = profileState.isUserLoggedIn;

          // Tối ưu Cấp độ 1: Center & ConstrainedBox chống dãn tràn layout trên màn hình rộng
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // 1. Theme Section
                    ListTile(
                      contentPadding: itemPadding,
                      leading: const Icon(Symbols.routine),
                      title: Text(t.settings.title_theme_section, style: titleStyle),
                      subtitle: BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, currentThemeMode) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            // BỌC THÊM INTRINSIC HEIGHT Ở ĐÂY
                            child: IntrinsicHeight(
                              child: Row(
                                // ÉP CÁC BUTTON BÊN TRONG DÃN ĐỀU CHIỀU CAO
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildThemeButton(
                                      context: context,
                                      mode: ThemeMode.system,
                                      currentMode: currentThemeMode,
                                      icon: Symbols.brightness_auto,
                                      label: t.settings.btn_theme_system,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildThemeButton(
                                      context: context,
                                      mode: ThemeMode.light,
                                      currentMode: currentThemeMode,
                                      icon: Symbols.light_mode,
                                      label: t.settings.btn_theme_light,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildThemeButton(
                                      context: context,
                                      mode: ThemeMode.dark,
                                      currentMode: currentThemeMode,
                                      icon: Symbols.dark_mode,
                                      label: t.settings.btn_theme_dark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 1.5. Background Workout Switch
                    SwitchListTile(
                      contentPadding: itemPadding,
                      secondary: const Icon(Symbols.notifications_active),
                      title: Text(t.settings.title_bg_workout, style: titleStyle),
                      subtitle: Text(t.settings.desc_bg_workout, style: subtitleStyle),
                      value: _isBackgroundWorkoutEnabled,
                      onChanged: (bool value) async {
                        if (value) {
                          bool hasNoti = await Permission.notification.isGranted;
                          bool hasActivity = true;
                          if (Platform.isAndroid) {
                            final androidInfo = await DeviceInfoPlugin().androidInfo;
                            if (androidInfo.version.sdkInt >= 34) {
                              hasActivity = await Permission.activityRecognition.isGranted;
                            }
                          }
                          
                          if (!hasNoti || !hasActivity) {
                             if (!hasNoti) await Permission.notification.request();
                             if (Platform.isAndroid && !hasActivity) {
                                final androidInfo = await DeviceInfoPlugin().androidInfo;
                                if (androidInfo.version.sdkInt >= 34) {
                                  await Permission.activityRecognition.request();
                                }
                             }
                             
                             hasNoti = await Permission.notification.isGranted;
                             if (Platform.isAndroid) {
                                final androidInfo = await DeviceInfoPlugin().androidInfo;
                                if (androidInfo.version.sdkInt >= 34) {
                                  hasActivity = await Permission.activityRecognition.isGranted;
                                }
                             }

                             if (!hasNoti || !hasActivity) {
                                if (context.mounted) {
                                  GymDialog.showConfirm(
                                    context: context,
                                    title: t.settings.title_permission_denied,
                                    message: t.settings.msg_permission_permanently_denied,
                                    confirmText: t.common.open_settings,
                                    cancelText: t.common.cancel,
                                  ).then((res) {
                                    if (res == true) {
                                      openAppSettings();
                                    }
                                  });
                                }
                                return;
                             }
                          }
                          
                          setState(() {
                             _isBackgroundWorkoutEnabled = true;
                          });
                          final prefs = getIt<SharedPreferences>();
                          await prefs.setBool(WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey, true);
                        } else {
                          setState(() {
                             _isBackgroundWorkoutEnabled = false;
                          });
                          final prefs = getIt<SharedPreferences>();
                          await prefs.setBool(WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey, false);
                          FlutterBackgroundService().invoke("stopService");
                        }
                      },
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      activeThumbColor: Colors.white,
                    ),

                    // 2. Account Management Hub
                    ListTile(
                      contentPadding: itemPadding,
                      onTap: () {
                        Navigator.of(context, rootNavigator: false).push(MaterialPageRoute(builder: (_) => const AccountManagementScreen()));
                      },
                      leading: Icon(Symbols.manage_accounts),
                      title: Text(t.settings.title_account_management, style: titleStyle),
                      subtitle: Text(
                        isLinked ? t.settings.msg_auth_linked : t.settings.msg_auth_unlinked, 
                        style: TextStyle(color: isLinked ? Theme.of(context).gymColors.success : colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)
                      ),
                      trailing: const Icon(Symbols.chevron_right),
                    ),

                    // 3. Tutorial
                    ListTile(
                      contentPadding: itemPadding,
                      leading: const Icon(Symbols.developer_guide),
                      title: Text(t.common.tutorial_title, style: titleStyle),
                      subtitle: Text(t.settings.desc_item_tutorial, style: subtitleStyle),
                      trailing: const Icon(Symbols.chevron_right),
                      onTap: () => context.push('/profile/${AppRoutes.tutorial}'),
                    ),

                    // 4. Language
                    ListTile(
                      contentPadding: itemPadding,
                      leading: const Icon(Symbols.language),
                      title: Text(t.settings.lbl_item_language, style: titleStyle),
                      subtitle: Text(currentLang, style: subtitleStyle),
                      trailing: const Icon(Symbols.chevron_right),
                      onTap: () => _showLanguageDialog(context),
                    ),

                    // 5. Contact & Help
                    ListTile(
                      contentPadding: itemPadding,
                      leading: const Icon(Symbols.mail),
                      title: Text(t.settings.lbl_item_contact, style: titleStyle),
                      subtitle: Text("support.plato@zenithas.vn", style: subtitleStyle),
                      trailing: const Icon(Symbols.chevron_right),
                      onTap: _sendSupportEmail,
                    ),
                    
                    // 6. Terms of Use
                    ListTile(
                      contentPadding: itemPadding,
                      leading: const Icon(Symbols.description),
                      title: Text(t.onboarding.lbl_terms_link, style: titleStyle),
                      subtitle: Text(t.settings.desc_terms_link, style: subtitleStyle),
                      trailing: const Icon(Symbols.chevron_right),
                      onTap: () => _showTermsDialog(context),
                    ),

                    // 7. EULA Agreement
                    ListTile(
                      contentPadding: itemPadding,
                      leading: const Icon(Symbols.contract),
                      title: Text(t.onboarding.lbl_eula_link, style: titleStyle),
                      subtitle: Text(t.settings.desc_eula_link, style: subtitleStyle),
                      trailing: const Icon(Symbols.chevron_right),
                      onTap: () => _showEulaDialog(context),
                    ),

                    // 8. Version
                    ListTile(
                      contentPadding: itemPadding,
                      leading: const Icon(Symbols.info),
                      title: Text(t.settings.lbl_item_version, style: titleStyle),
                      subtitle: Text("1.1.1", style: subtitleStyle),
                    ),

                    // 9. Đăng xuất
                    if (isLinked) ...[
                      ListTile(
                        contentPadding: itemPadding,
                        leading: Icon(Symbols.logout, color: colorScheme.error),
                        title: Text(t.common.logout, style: titleStyle.copyWith(color: colorScheme.error)),
                        onTap: () => _handleLogout(context),
                      ),
                    ],
                    
                    const SizedBox(height: 32),

                    // 10. SOCIAL LINKS SECTION
                    Center(
                      child: Column(
                        children: [
                          Text(
                            t.common.about_us,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialIcon(
                                FaIcon(FontAwesomeIcons.instagram, size: 22, color: colorScheme.onSurface), 
                                colorScheme, 
                                () => _launchSocialUrl(
                                  'https://www.instagram.com/plato.zenithas/',
                                  nativeUrl: 'instagram://user?username=plato.zenithas',
                                ),
                              ),
                              const SizedBox(width: 20),
                              _buildSocialIcon(
                                FaIcon(FontAwesomeIcons.facebookF, size: 22, color: colorScheme.onSurface), 
                                colorScheme, 
                                () => _launchSocialUrl(
                                  'https://www.facebook.com/profile.php?id=61592005979928',
                                  nativeUrl: 'fb://profile/61592005979928',
                                ),
                              ),
                              const SizedBox(width: 20),
                              _buildSocialIcon(
                                FaIcon(FontAwesomeIcons.threads, size: 22, color: colorScheme.onSurface), 
                                colorScheme, 
                                () => _launchSocialUrl(
                                  'https://www.threads.com/@plato.zenithas',
                                ),
                              ),
                              const SizedBox(width: 20),
                              _buildSocialIcon(
                                FaIcon(FontAwesomeIcons.tiktok, size: 22, color: colorScheme.onSurface), 
                                colorScheme, 
                                () => _launchSocialUrl(
                                  'https://www.tiktok.com/@plato.zenithas?_r=1&_t=ZS-990YzsfNfXO',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeButton({
    required BuildContext context,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = mode == currentMode;

    return OutlinedButton(
      onPressed: () => context.read<ThemeCubit>().changeTheme(mode),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant, 
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(
            icon, 
            size: 22, 
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fill: isSelected ? 1.0 : 0.0, 
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              label,
              // [FIX CORE]: Ép Text không được xuống dòng để IntrinsicHeight tính toán chuẩn xác
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(Widget iconWidget, ColorScheme colorScheme, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        child: Center(
          child: iconWidget,
        ),
      ),
    );
  }
}

List<TextSpan> _buildRichSpans(String text, ColorScheme colorScheme) {
  final String appName = t.app_name;
  final String brandName = t.company_name;
  final List<TextSpan> spans = [];

  final regex = RegExp(r'(\{app\}|\{brand\})');
  final matches = regex.allMatches(text);

  int lastIndex = 0;
  for (final match in matches) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
    }
    final tag = match.group(0);
    if (tag == '{app}') {
      spans.add(TextSpan(text: appName, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)));
    } else if (tag == '{brand}') {
      spans.add(TextSpan(text: brandName, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)));
    }
    lastIndex = match.end;
  }
  if (lastIndex < text.length) {
    spans.add(TextSpan(text: text.substring(lastIndex)));
  }
  return spans;
}

void _showTermsDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  GymDialog.showCustom(
    context: context,
    useRootNavigator: false,
    titleWidget: RichText(
      text: TextSpan(
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: colorScheme.onSurface),
        children: _buildRichSpans(t.onboarding.title_terms(app: "{app}"), colorScheme),
      ),
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTermsSection(t.onboarding.terms_p1_title, [
          t.onboarding.terms_p1_desc1(app: "{app}"),
          t.onboarding.terms_p1_desc2,
          t.onboarding.terms_p1_desc3(app: "{app}"),
        ], colorScheme),
        _buildTermsSection(t.onboarding.terms_p2_title, [
          t.onboarding.terms_p2_desc1,
          t.onboarding.terms_p2_desc2,
          t.onboarding.terms_p2_desc3,
        ], colorScheme),
      ],
    ),
    actions: [TextButton(onPressed: () => Navigator.of(context, rootNavigator: false).pop(), child: Text(t.common.close))],
  );
}

void _showEulaDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  GymDialog.showCustom(
    context: context,
    useRootNavigator: false,
    titleWidget: RichText(
      text: TextSpan(
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface),
        children: _buildRichSpans(t.onboarding.title_eula(app: "{app}"), colorScheme),
      ),
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.onboarding.eula_updated, 
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        RichText(text: TextSpan(
          style: TextStyle(fontSize: 13, height: 1.5, color: colorScheme.onSurfaceVariant),
          children: _buildRichSpans(t.onboarding.eula_intro(app: "{app}", brand: "{brand}"), colorScheme),
        )),
        const SizedBox(height: 16),
        _buildTermsSection(t.onboarding.eula_p1_title, [
          t.onboarding.eula_p1_desc(app: "{app}"),
        ], colorScheme),
        _buildTermsSection(t.onboarding.eula_p2_title, [
          t.onboarding.eula_p2_desc1(app: "{app}"),
          t.onboarding.eula_p2_item1,
          t.onboarding.eula_p2_item2(app: "{app}", brand: "{brand}"),
          t.onboarding.eula_p2_item3,
          t.onboarding.eula_p2_desc2(brand: "{brand}"),
        ], colorScheme),
        _buildTermsSection(t.onboarding.eula_p3_title, [
          t.onboarding.eula_p3_desc1,
          t.onboarding.eula_p3_item1,
          t.onboarding.eula_p3_item2(app: "{app}"),
          t.onboarding.eula_p3_item3,
        ], colorScheme),
        _buildTermsSection(t.onboarding.eula_p4_title, [t.onboarding.eula_p4_desc], colorScheme),
        _buildTermsSection(t.onboarding.eula_p5_title, [
          t.onboarding.eula_p5_item1(app: "{app}"),
          t.onboarding.eula_p5_item2,
          t.onboarding.eula_p5_item3,
        ], colorScheme),
        _buildTermsSection(t.onboarding.eula_p6_title, [t.onboarding.eula_p6_desc], colorScheme),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context, rootNavigator: false).pop(), 
        child: Text(t.common.close, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)))
    ],
  );
}
  
Widget _buildTermsSection(String title, List<String> paragraphs, ColorScheme colorScheme) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 24.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
        const SizedBox(height: 8),
        ...paragraphs.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, height: 1.5, color: colorScheme.onSurfaceVariant),
              children: _buildRichSpans(p, colorScheme),
            ),
          ),
        ))
      ],
    ),
  );
}
