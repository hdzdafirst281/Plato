import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';
import 'package:plato_gymapp/core/di/injection.dart';
import 'package:plato_gymapp/features/workout/data/workout_effort_preferences.dart';
import 'package:plato_gymapp/features/workout/data/workout_settings_preferences.dart';
import 'package:plato_gymapp/features/workout/presentation/components/workout_shared_ui.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutSettingsScreen extends StatefulWidget {
  const WorkoutSettingsScreen({super.key});

  @override
  State<WorkoutSettingsScreen> createState() => _WorkoutSettingsScreenState();
}

class _WorkoutSettingsScreenState extends State<WorkoutSettingsScreen> {
  bool _advancedEffortEnabled = false;
  int _defaultRestSeconds = 90;
  bool _keepScreenAwake = false;
  bool _timerSoundEnabled = true;
  bool _confirmFinishEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final prefs = getIt<SharedPreferences>();
    if (!mounted) return;
    setState(() {
      _advancedEffortEnabled = WorkoutEffortPreferences.advancedEnabled(prefs);
      _defaultRestSeconds = WorkoutSettingsPreferences.defaultRestSeconds(
        prefs,
      );
      _keepScreenAwake = WorkoutSettingsPreferences.keepScreenAwake(prefs);
      _timerSoundEnabled = WorkoutSettingsPreferences.timerSoundEnabled(prefs);
      _confirmFinishEnabled = WorkoutSettingsPreferences.confirmFinishEnabled(
        prefs,
      );
    });
  }

  Future<void> _setAdvancedEffort(bool enabled) async {
    setState(() => _advancedEffortEnabled = enabled);
    final prefs = getIt<SharedPreferences>();
    await WorkoutEffortPreferences.setAdvancedEnabled(prefs, enabled);
  }

  Future<void> _setDefaultRestSeconds(int seconds) async {
    setState(() => _defaultRestSeconds = seconds);
    await WorkoutSettingsPreferences.setDefaultRestSeconds(
      getIt<SharedPreferences>(),
      seconds,
    );
  }

  Future<void> _setKeepScreenAwake(bool enabled) async {
    setState(() => _keepScreenAwake = enabled);
    await WorkoutSettingsPreferences.setKeepScreenAwake(
      getIt<SharedPreferences>(),
      enabled,
    );
  }

  Future<void> _setTimerSoundEnabled(bool enabled) async {
    setState(() => _timerSoundEnabled = enabled);
    await WorkoutSettingsPreferences.setTimerSoundEnabled(
      getIt<SharedPreferences>(),
      enabled,
    );
  }

  Future<void> _setConfirmFinishEnabled(bool enabled) async {
    setState(() => _confirmFinishEnabled = enabled);
    await WorkoutSettingsPreferences.setConfirmFinishEnabled(
      getIt<SharedPreferences>(),
      enabled,
    );
  }

  void _showEffortInfo() {
    final colorScheme = Theme.of(context).colorScheme;
    _showDetailsDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.settings.desc_effort_tracking,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _infoCard(
            title: t.settings.title_rpe_info,
            message: t.settings.desc_rpe_info,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _showDefaultRestInfo() {
    final colorScheme = Theme.of(context).colorScheme;
    _showDetailsDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.settings.desc_default_rest_timer,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.settings.info_default_rest_timer,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmFinishInfo() {
    final colorScheme = Theme.of(context).colorScheme;
    _showDetailsDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.settings.desc_confirm_finish,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.settings.info_confirm_finish,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog({
    String? title,
    IconData icon = Symbols.info,
    required Widget content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    GymDialog.showCustom<void>(
      context: context,
      titleWidget: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title ?? t.common.info,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(
            t.common.understood,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required String message,
    Color? color,
  }) {
    final colors = Theme.of(context).colorScheme;
    final accent = color ?? colors.primary;
    return Card(
      elevation: 0,
      color: accent.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTitle(String text) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: Theme.of(context).colorScheme.primary,
      decorationThickness: 1.2,
    ),
  );

  Widget _infoTileContent({
    required Key key,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final subtitleStyle =
        theme.listTileTheme.subtitleTextStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );

    return Semantics(
      button: true,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoTitle(title),
                const SizedBox(height: 2),
                Text(subtitle, style: subtitleStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GymTopBar(
        title: t.settings.lbl_item_workout_settings,
        onBackClick: () => context.pop(),
      ),
      body: GymMotionItem(
        stage: 1,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsetsDirectional.only(
                          start: 16,
                          end: 8,
                        ),
                        leading: const Icon(Symbols.speed),
                        title: _infoTileContent(
                          key: const ValueKey('effort_info_target'),
                          title: t.settings.lbl_scale_rpe,
                          subtitle: t.settings.desc_effort_tracking,
                          onTap: _showEffortInfo,
                        ),
                        trailing: Switch.adaptive(
                          key: const ValueKey('effort_toggle'),
                          value: _advancedEffortEnabled,
                          onChanged: _setAdvancedEffort,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        key: const ValueKey('default_rest_setting'),
                        contentPadding: const EdgeInsetsDirectional.only(
                          start: 16,
                          end: 8,
                        ),
                        leading: const Icon(Symbols.timer),
                        title: _infoTileContent(
                          key: const ValueKey('default_rest_info_target'),
                          title: t.settings.lbl_default_rest_timer,
                          subtitle: t.settings.desc_default_rest_timer,
                          onTap: _showDefaultRestInfo,
                        ),
                        trailing: InkWell(
                          key: const ValueKey('default_rest_control'),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => GymTimerHelper.showRestTimePicker(
                            context,
                            _defaultRestSeconds,
                            _setDefaultRestSeconds,
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 8,
                              top: 12,
                              bottom: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _defaultRestSeconds == 0
                                      ? t.workout.lbl_rest_off
                                      : GymTimerHelper.formatRestTime(
                                          _defaultRestSeconds,
                                        ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Symbols.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        key: const ValueKey('keep_screen_awake_toggle'),
                        contentPadding: const EdgeInsetsDirectional.only(
                          start: 16,
                          end: 8,
                        ),
                        secondary: const Icon(
                          Icons.screen_lock_portrait_outlined,
                        ),
                        title: Text(t.settings.lbl_keep_screen_awake),
                        subtitle: Text(t.settings.desc_keep_screen_awake),
                        value: _keepScreenAwake,
                        onChanged: _setKeepScreenAwake,
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        key: const ValueKey('timer_sound_toggle'),
                        contentPadding: const EdgeInsetsDirectional.only(
                          start: 16,
                          end: 8,
                        ),
                        secondary: const Icon(Icons.volume_up_outlined),
                        title: Text(t.settings.lbl_timer_sound),
                        subtitle: Text(t.settings.desc_timer_sound),
                        value: _timerSoundEnabled,
                        onChanged: _setTimerSoundEnabled,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsetsDirectional.only(
                          start: 16,
                          end: 8,
                        ),
                        leading: const Icon(Icons.task_alt_outlined),
                        title: _infoTileContent(
                          key: const ValueKey('confirm_finish_info_target'),
                          title: t.settings.lbl_confirm_finish,
                          subtitle: t.settings.desc_confirm_finish,
                          onTap: _showConfirmFinishInfo,
                        ),
                        trailing: Switch.adaptive(
                          key: const ValueKey('confirm_finish_toggle'),
                          value: _confirmFinishEnabled,
                          onChanged: _setConfirmFinishEnabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
