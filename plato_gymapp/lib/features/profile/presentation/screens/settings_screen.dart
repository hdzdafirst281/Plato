import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/designsystem/theme/theme_cubit.dart';
import 'package:plato_gymapp/core/di/injection.dart';
import 'package:plato_gymapp/core/navigation/app_routes.dart';
import 'package:plato_gymapp/core/utils/measurement_units.dart';
import 'package:plato_gymapp/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:plato_gymapp/features/gamification/presentation/bloc/gamification_cubit.dart';
import 'package:plato_gymapp/features/notifications/application/notification_coordinator.dart';
import 'package:plato_gymapp/features/notifications/data/notification_copy.dart';
import 'package:plato_gymapp/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/stats_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/about_screen.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/account_management_screen.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/workout_cubit.dart';
import 'package:plato_gymapp/features/workout/presentation/screens/workout_settings_screen.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _notificationCountLabel(int count) =>
      NotificationCopy.text('settings.fmt_notifications_enabled', {
        'count': '$count',
      }) ??
      '$count ${t.settings.lbl_item_notification.toLowerCase()}';

  void _sendSupportEmail() async {
    final subjectText = t.settings.msg_intent_email_subject;
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support.plato@zenithas.vn',
      query: 'subject=${Uri.encodeComponent(subjectText)}',
    );

    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Không thể mở ứng dụng Email');
    }
  }

  void _showLanguageDialog(BuildContext context) {
    GymDialog.showCustom(
      context: context,
      useRootNavigator: false,
      titleWidget: Text(
        t.settings.title_language_dialog,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.language),
              title: const Text("Tiếng Việt"),
              trailing:
                  TranslationProvider.of(context).flutterLocale.languageCode ==
                      'vi'
                  ? const Icon(Symbols.check, color: Colors.blue)
                  : null,
              onTap: () {
                LocaleSettings.setLocaleRaw("vi");
                getIt<SharedPreferences>().setString('app_lang', 'vi');
                Navigator.of(context, rootNavigator: false).pop();
              },
            ),
            ListTile(
              leading: const Icon(Symbols.language),
              title: const Text("English"),
              trailing:
                  TranslationProvider.of(context).flutterLocale.languageCode ==
                      'en'
                  ? const Icon(Symbols.check, color: Colors.blue)
                  : null,
              onTap: () {
                LocaleSettings.setLocaleRaw("en");
                getIt<SharedPreferences>().setString('app_lang', 'en');
                Navigator.of(context, rootNavigator: false).pop();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
          child: Text(
            t.common.close,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showMeasurementUnitsDialog(
    BuildContext context,
    MeasurementPreferences current,
  ) {
    var draft = current;
    final colorScheme = Theme.of(context).colorScheme;

    GymDialog.showCustom(
      context: context,
      useRootNavigator: false,
      titleWidget: Text(
        t.settings.title_measurement_units,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          Widget unitChoice<T>({
            required String label,
            required Map<T, String> options,
            required T selected,
            required ValueChanged<T> onChanged,
          }) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<T>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: colorScheme.primary,
                      selectedForegroundColor: colorScheme.onPrimary,
                    ),
                    segments: [
                      for (final option in options.entries)
                        ButtonSegment(
                          value: option.key,
                          label: Text(option.value),
                        ),
                    ],
                    selected: {selected},
                    onSelectionChanged: (values) => onChanged(values.first),
                  ),
                ),
              ],
            ),
          );

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.settings.desc_measurement_units,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                unitChoice(
                  label: t.settings.lbl_weight_unit,
                  options: {
                    WeightUnit.kilogram: t.common.unit_kg,
                    WeightUnit.pound: t.common.unit_lb,
                  },
                  selected: draft.weight,
                  onChanged: (value) => setDialogState(
                    () => draft = draft.copyWith(weight: value),
                  ),
                ),
                unitChoice(
                  label: t.settings.lbl_hydration_unit,
                  options: {
                    HydrationUnit.milliliter: t.common.unit_ml,
                    HydrationUnit.liter: t.common.unit_l,
                    HydrationUnit.usGallon: t.common.unit_us_gal,
                  },
                  selected: draft.hydration,
                  onChanged: (value) => setDialogState(
                    () => draft = draft.copyWith(hydration: value),
                  ),
                ),
                unitChoice(
                  label: t.common.distance,
                  options: {
                    DistanceUnit.kilometer: t.common.unit_km,
                    DistanceUnit.meter: t.common.unit_m,
                  },
                  selected: draft.distance,
                  onChanged: (value) => setDialogState(
                    () => draft = draft.copyWith(distance: value),
                  ),
                ),
                unitChoice(
                  label: t.settings.lbl_body_length_unit,
                  options: {
                    BodyLengthUnit.metric: t.common.unit_cm,
                    BodyLengthUnit.imperial: t.common.unit_in,
                  },
                  selected: draft.bodyLength,
                  onChanged: (value) => setDialogState(
                    () => draft = draft.copyWith(bodyLength: value),
                  ),
                ),
                unitChoice(
                  label: t.settings.lbl_food_mass_unit,
                  options: {
                    FoodMassUnit.gram: t.common.unit_g,
                    FoodMassUnit.ounce: t.common.unit_oz,
                  },
                  selected: draft.foodMass,
                  onChanged: (value) => setDialogState(
                    () => draft = draft.copyWith(foodMass: value),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
                      child: Text(
                        t.common.cancel,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await context
                            .read<ProfileCubit>()
                            .updateMeasurementPreferences(draft);
                        if (!context.mounted) return;
                        Navigator.of(context, rootNavigator: false).pop();
                        GymSnackbar.show(
                          context,
                          message: t.settings.msg_measurement_units_saved,
                          icon: Symbols.check_circle,
                          accentColor: colorScheme.primary,
                        );
                      },
                      child: Text(
                        t.common.save,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
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
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fill: isSelected ? 1.0 : 0.0,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notificationService = NotificationCoordinator.instance;
    final currentLang =
        TranslationProvider.of(context).flutterLocale.languageCode == 'vi'
        ? "Tiếng Việt"
        : "English";

    final itemPadding = ResponsiveValue<EdgeInsets>(
      context,
      defaultValue: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      conditionalValues: [
        Condition.largerThan(
          name: MOBILE,
          value: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
        ),
      ],
    ).value;

    final titleStyle = TextStyle(
      color: colorScheme.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    final subtitleStyle = TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontSize: 14,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.settings.title_dialog_main,
        onBackClick: () => context.pop(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // 1. Account Management Hub (Placed at the top per user request)
                BlocSelector<ProfileCubit, ProfileState, bool>(
                  selector: (state) => state.isUserLoggedIn,
                  builder: (context, isLinked) {
                    return ListTile(
                      contentPadding: itemPadding,
                      onTap: () {
                        Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(
                            builder: (_) => const AccountManagementScreen(),
                          ),
                        );
                      },
                      leading: const Icon(Symbols.manage_accounts),
                      title: Text(
                        t.settings.title_account_management,
                        style: titleStyle,
                      ),
                      subtitle: Text(
                        isLinked
                            ? t.settings.msg_auth_linked
                            : t.settings.msg_auth_unlinked,
                        style: TextStyle(
                          color: isLinked
                              ? Theme.of(context).gymColors.success
                              : colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Symbols.chevron_right),
                    );
                  },
                ),

                // 2. Notification & Background Settings
                ListTile(
                  contentPadding: itemPadding,
                  leading: const Icon(Symbols.notifications),
                  title: Text(
                    t.settings.lbl_item_notification,
                    style: titleStyle,
                  ),
                  subtitle: notificationService == null
                      ? Text(
                          _notificationCountLabel(0),
                          style: subtitleStyle.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : ListenableBuilder(
                          listenable: notificationService,
                          builder: (context, _) => Text(
                            _notificationCountLabel(
                              notificationService.enabledCategoryCount,
                            ),
                            style: subtitleStyle.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  trailing: const Icon(Symbols.chevron_right),
                  onTap: () {
                    Navigator.of(context, rootNavigator: false).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),

                // 3. Theme Section
                ListTile(
                  contentPadding: itemPadding,
                  leading: const Icon(Symbols.routine),
                  title: Text(
                    t.settings.title_theme_section,
                    style: titleStyle,
                  ),
                  subtitle: BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, currentThemeMode) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: IntrinsicHeight(
                          child: Row(
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

                // 4. Workout Settings
                ListTile(
                  contentPadding: itemPadding,
                  leading: const Icon(Symbols.exercise),
                  title: Text(
                    t.settings.lbl_item_workout_settings,
                    style: titleStyle,
                  ),
                  subtitle: Text(
                    t.settings.desc_item_workout_settings.split('/').first,
                    style: subtitleStyle,
                  ),
                  trailing: const Icon(Symbols.chevron_right),
                  onTap: () {
                    Navigator.of(context, rootNavigator: false).push(
                      MaterialPageRoute(
                        builder: (_) => const WorkoutSettingsScreen(),
                      ),
                    );
                  },
                ),

                // 5. Measurement Units
                BlocSelector<ProfileCubit, ProfileState, MeasurementPreferences>(
                  selector: (state) => state.userProfile.measurementPreferences,
                  builder: (context, measurementPrefs) {
                    final units = MeasurementFormatter(measurementPrefs);
                    final unitsSummary =
                        '${units.weightUnit} · ${units.hydrationUnit} · '
                        '${units.distanceUnit} · ${units.bodyLengthUnit} · '
                        '${units.foodMassUnit}';
                    return ListTile(
                      contentPadding: itemPadding,
                      leading: const Icon(Symbols.straighten),
                      title: Text(
                        t.settings.title_measurement_units,
                        style: titleStyle,
                      ),
                      subtitle: Text(unitsSummary, style: subtitleStyle),
                      trailing: const Icon(Symbols.chevron_right),
                      onTap: () => _showMeasurementUnitsDialog(
                        context,
                        measurementPrefs,
                      ),
                    );
                  },
                ),

                // 6. Language
                ListTile(
                  contentPadding: itemPadding,
                  leading: const Icon(Symbols.language),
                  title: Text(
                    t.settings.lbl_item_language,
                    style: titleStyle,
                  ),
                  subtitle: Text(currentLang, style: subtitleStyle),
                  trailing: const Icon(Symbols.chevron_right),
                  onTap: () => _showLanguageDialog(context),
                ),

                // 7. Tutorial
                ListTile(
                  contentPadding: itemPadding,
                  leading: SizedBox(
                    width: 24,
                    height: 24,
                    child: OverflowBox(
                      maxWidth: 28,
                      maxHeight: 28,
                      child: SvgPicture.asset(
                        'assets/svg/icons/tutorial.svg',
                        width: 28,
                        height: 28,
                        colorFilter: ColorFilter.mode(
                          colorScheme.onSurfaceVariant,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  title: Text(t.common.tutorial_title, style: titleStyle),
                  subtitle: Text(
                    t.settings.desc_item_tutorial,
                    style: subtitleStyle,
                  ),
                  trailing: const Icon(Symbols.chevron_right),
                  onTap: () => context.push('/profile/${AppRoutes.tutorial}'),
                ),

                // 8. Contact & Help
                ListTile(
                  contentPadding: itemPadding,
                  leading: const Icon(Symbols.mail),
                  title: Text(
                    t.settings.lbl_item_contact,
                    style: titleStyle,
                  ),
                  subtitle: Text(
                    "support.plato@zenithas.vn",
                    style: subtitleStyle,
                  ),
                  trailing: const Icon(Symbols.chevron_right),
                  onTap: _sendSupportEmail,
                ),

                // 9. About Plato (Dedicated screen for Terms, EULA, Version diagnostics, and Social Media)
                ListTile(
                  contentPadding: itemPadding,
                  leading: SvgPicture.asset(
                    'assets/svg/icons/logo_p.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
                  title: Text(
                    t.settings.lbl_item_about,
                    style: titleStyle,
                  ),
                  subtitle: Text(
                    t.settings.desc_item_about,
                    style: subtitleStyle,
                  ),
                  trailing: const Icon(Symbols.chevron_right),
                  onTap: () {
                    Navigator.of(context, rootNavigator: false).push(
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),

                // 10. Logout (If logged in)
                BlocSelector<ProfileCubit, ProfileState, bool>(
                  selector: (state) => state.isUserLoggedIn,
                  builder: (context, isLinked) {
                    if (!isLinked) return const SizedBox.shrink();
                    return ListTile(
                      contentPadding: itemPadding,
                      leading: Icon(Symbols.logout, color: colorScheme.error),
                      title: Text(
                        t.common.logout,
                        style: titleStyle.copyWith(color: colorScheme.error),
                      ),
                      onTap: () => _handleLogout(context),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Brand Logo Footer
                Center(
                  child: GymEntrance(
                    offset: const Offset(0, 6),
                    duration: GymMotion.content,
                    child: AnimatedSwitcher(
                      duration: GymMotion.content,
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/logo/logo_themedark.png'
                            : 'assets/logo/logo_themelight.png',
                        key: ValueKey(Theme.of(context).brightness),
                        height: 36,
                        cacheHeight: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
