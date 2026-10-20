import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';
import 'package:plato_gymapp/core/di/injection.dart';
import 'package:plato_gymapp/core/utils/workout_permission_helper.dart';
import 'package:plato_gymapp/core/worker/background_workout_service.dart';
import 'package:plato_gymapp/features/workout/data/workout_effort_preferences.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutSettingsScreen extends StatefulWidget {
  const WorkoutSettingsScreen({super.key});

  @override
  State<WorkoutSettingsScreen> createState() => _WorkoutSettingsScreenState();
}

class _WorkoutSettingsScreenState extends State<WorkoutSettingsScreen>
    with WidgetsBindingObserver {
  bool _advancedEffortEnabled = false;
  EffortInputScale _effortInputScale = EffortInputScale.rpe;
  bool _backgroundWorkoutEnabled = false;
  int? _androidSdkInt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPreferences();
    }
  }

  Future<int> _getAndroidSdkInt() async =>
      _androidSdkInt ??= (await DeviceInfoPlugin().androidInfo).version.sdkInt;

  Future<bool> _hasWorkoutPermissions() async {
    final notifications = await Permission.notification.isGranted;
    if (!Platform.isAndroid) return notifications;
    return notifications &&
        (await _getAndroidSdkInt() < 34 ||
            await Permission.activityRecognition.isGranted);
  }

  void _loadPreferences() {
    final prefs = getIt<SharedPreferences>();
    final bgEnabled =
        prefs.getBool(WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey) ??
        false;
    if (!mounted) return;
    setState(() {
      _advancedEffortEnabled = WorkoutEffortPreferences.advancedEnabled(prefs);
      _effortInputScale = WorkoutEffortPreferences.inputScale(prefs);
      _backgroundWorkoutEnabled = bgEnabled;
    });
  }

  Future<void> _setAdvancedEffort(bool enabled) async {
    setState(() => _advancedEffortEnabled = enabled);
    final prefs = getIt<SharedPreferences>();
    await WorkoutEffortPreferences.setAdvancedEnabled(prefs, enabled);
  }

  Future<void> _setEffortScale(EffortInputScale scale) async {
    setState(() => _effortInputScale = scale);
    final prefs = getIt<SharedPreferences>();
    await WorkoutEffortPreferences.setInputScale(prefs, scale);
  }

  Future<void> _setBackgroundWorkout(bool value) async {
    final prefs = getIt<SharedPreferences>();
    if (mounted) setState(() => _backgroundWorkoutEnabled = value);
    if (value && !await _hasWorkoutPermissions()) {
      await Permission.notification.request();
      if (Platform.isAndroid && await _getAndroidSdkInt() >= 34) {
        await Permission.activityRecognition.request();
      }
      if (!await _hasWorkoutPermissions()) {
        if (!mounted) return;
        setState(() => _backgroundWorkoutEnabled = false);
        final open = await GymDialog.showConfirm(
          context: context,
          title: t.settings.title_permission_denied,
          message: t.settings.msg_permission_permanently_denied,
          confirmText: t.common.open_settings,
          cancelText: t.common.cancel,
        );
        if (open == true) await openAppSettings();
        return;
      }
    }
    final saved = await prefs.setBool(
      WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey,
      value,
    );
    if (!value) BackgroundWorkoutService().stopService();
    if (!saved && mounted) {
      setState(() => _backgroundWorkoutEnabled = !value);
    }
  }

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: GymTopBar(
        title: t.settings.title_workout_settings,
        onBackClick: () => context.pop(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _section(t.settings.section_effort_tracking, [
                SwitchListTile.adaptive(
                  secondary: const Icon(Symbols.speed),
                  title: Text(t.settings.lbl_effort_tracking),
                  subtitle: Text(t.settings.desc_effort_tracking),
                  value: _advancedEffortEnabled,
                  onChanged: _setAdvancedEffort,
                ),
                if (_advancedEffortEnabled) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.settings.lbl_effort_scale,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.settings.desc_effort_scale,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<EffortInputScale>(
                            segments: [
                              ButtonSegment(
                                value: EffortInputScale.rpe,
                                label: Text(t.settings.lbl_scale_rpe),
                                icon: const Icon(Symbols.timer),
                              ),
                              ButtonSegment(
                                value: EffortInputScale.rir,
                                label: Text(t.settings.lbl_scale_rir),
                                icon: const Icon(Symbols.fitness_center),
                              ),
                            ],
                            selected: {_effortInputScale},
                            onSelectionChanged: (values) {
                              _setEffortScale(values.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Symbols.info, color: colorScheme.primary),
                    title: Text(
                      _effortInputScale == EffortInputScale.rpe
                          ? t.settings.title_rpe_info
                          : t.settings.title_rir_info,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _effortInputScale == EffortInputScale.rpe
                            ? t.settings.desc_rpe_info
                            : t.settings.desc_rir_info,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
              _section(t.settings.title_workout_bg, [
                SwitchListTile.adaptive(
                  secondary: const Icon(Symbols.directions_run),
                  title: Text(t.settings.title_bg_workout),
                  subtitle: Text(t.settings.desc_bg_workout),
                  value: _backgroundWorkoutEnabled,
                  onChanged: _setBackgroundWorkout,
                ),
              ]),
              _section(t.settings.title_workout_guide, [
                ListTile(
                  leading: Icon(
                    Symbols.auto_awesome,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    t.settings.title_workout_guide,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      t.settings.desc_workout_guide,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
