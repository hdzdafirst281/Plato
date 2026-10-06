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
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/worker/background_workout_service.dart';
import '../../application/notification_coordinator.dart';
import '../../data/notification_copy.dart';
import '../../data/notification_preferences.dart';
import 'notification_diagnostics_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _backgroundWorkoutEnabled = false;
  bool _systemPermission = false;
  bool _systemPermissionLoaded = false;
  Future<void> _preferenceUpdates = Future<void>.value();
  int _workoutReminderCount = 0;
  int? _androidSdkInt;
  int _refreshGeneration = 0;

  NotificationCoordinator? get _service => NotificationCoordinator.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backgroundWorkoutEnabled =
        getIt<SharedPreferences>().getBool(
          WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey,
        ) ??
        false;
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<int> _getAndroidSdkInt() async =>
      _androidSdkInt ??= (await DeviceInfoPlugin().androidInfo).version.sdkInt;

  Future<bool> _hasWorkoutPermissions({bool? notificationGranted}) async {
    final notifications =
        notificationGranted ?? await Permission.notification.isGranted;
    if (!Platform.isAndroid) return notifications;
    return notifications &&
        (await _getAndroidSdkInt() < 34 ||
            await Permission.activityRecognition.isGranted);
  }

  Future<void> _refresh() async {
    final generation = ++_refreshGeneration;
    final prefs = getIt<SharedPreferences>();
    final permissionFuture = Permission.notification.isGranted;
    final countFuture = _service?.upcomingWorkoutReminderCount();
    var background =
        prefs.getBool(WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey) ??
        false;
    final permission = await permissionFuture;
    if (background &&
        !await _hasWorkoutPermissions(notificationGranted: permission)) {
      background = false;
      await prefs.setBool(
        WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey,
        false,
      );
      BackgroundWorkoutService().stopService();
    }
    if (!mounted || generation != _refreshGeneration) return;
    setState(() {
      _backgroundWorkoutEnabled = background;
      _systemPermission = permission;
      _systemPermissionLoaded = true;
    });
    final count = await countFuture ?? 0;
    if (!mounted || generation != _refreshGeneration) return;
    if (count != _workoutReminderCount) {
      setState(() => _workoutReminderCount = count);
    }
  }

  Future<void> _setBackgroundWorkout(bool value) async {
    _refreshGeneration++;
    final prefs = getIt<SharedPreferences>();
    if (mounted) setState(() => _backgroundWorkoutEnabled = value);
    if (value && !await _hasWorkoutPermissions()) {
      await Permission.notification.request();
      if (Platform.isAndroid && await _getAndroidSdkInt() >= 34) {
        await Permission.activityRecognition.request();
      }
      if (!await _hasWorkoutPermissions()) {
        if (!mounted) return;
        setState(() {
          _backgroundWorkoutEnabled = false;
          _systemPermission = false;
          _systemPermissionLoaded = true;
        });
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
      if (mounted) {
        setState(() {
          _systemPermission = true;
          _systemPermissionLoaded = true;
        });
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

  Future<void> _updateNotificationPreference(Future<bool> Function() update) {
    // Serialize persistence without disabling or dimming any tile. A second
    // quick tap stays visually responsive and is saved after the first one.
    final operation = _preferenceUpdates.then((_) async {
      try {
        final success = await update();
        if (!success && mounted) await openAppSettings();
      } catch (error) {
        debugPrint('Could not update notification preference: $error');
      }
    });
    _preferenceUpdates = operation;
    return operation;
  }

  String _copy(String key, [Map<String, String> args = const {}]) =>
      NotificationCopy.text(key, args) ?? '';

  String _copyOr(String key, String fallbackKey) =>
      NotificationCopy.text(key) ?? NotificationCopy.text(fallbackKey) ?? '';

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      Card(child: Column(children: children)),
    ],
  );

  Widget _categoryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required NotificationPreferenceKind kind,
  }) {
    final service = _service!;
    return _PreferenceSwitchTile(
      service: service,
      icon: icon,
      title: title,
      subtitle: subtitle,
      valueOf: (current) => current.preferences.enabled(kind),
      onChanged: (next) => _updateNotificationPreference(
        () => service.setPreference(kind, next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    final colors = Theme.of(context).colorScheme;
    final permissionColor = !_systemPermissionLoaded
        ? colors.onSurfaceVariant
        : _systemPermission
        ? colors.primary
        : colors.error;
    return Scaffold(
      appBar: GymTopBar(
        title: t.settings.lbl_item_notification,
        onBackClick: () => context.pop(),
      ),
      body: service == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _section(_copy('notifications.section_general'), [
                  _PreferenceSwitchTile(
                    service: service,
                    icon: Symbols.notifications,
                    title: _copy('notifications.lbl_master'),
                    subtitle: _copy('notifications.desc_master'),
                    valueOf: (current) => current.enabled,
                    onChanged: (value) => _updateNotificationPreference(
                      () => service.setEnabled(value),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    secondary: const Icon(Symbols.directions_run),
                    title: Text(t.settings.title_bg_workout),
                    subtitle: Text(t.settings.desc_bg_workout),
                    value: _backgroundWorkoutEnabled,
                    onChanged: _setBackgroundWorkout,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Symbols.security, color: permissionColor),
                    title: Text(_copy('notifications.lbl_system_permission')),
                    subtitle: _systemPermissionLoaded
                        ? Text(
                            _copy(
                              _systemPermission
                                  ? 'notifications.status_permission_allowed'
                                  : 'notifications.status_permission_blocked',
                            ),
                          )
                        : const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                    trailing: !_systemPermissionLoaded || _systemPermission
                        ? null
                        : TextButton(
                            onPressed: openAppSettings,
                            child: Text(
                              _copy('notifications.btn_open_system_settings'),
                            ),
                          ),
                  ),
                ]),
                _section(_copy('notifications.section_health_schedule'), [
                  ListTile(
                    leading: const Icon(Symbols.calendar_month),
                    title: Text(
                      _copyOr(
                        'notifications.lbl_workout_reminders',
                        'notifications.title_workout_reminder',
                      ),
                    ),
                    subtitle: Text(
                      _workoutReminderCount == 0
                          ? _copy('notifications.msg_workout_reminders_none')
                          : _copy(
                              'notifications.fmt_workout_reminders_active',
                              {'count': '$_workoutReminderCount'},
                            ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/profile/calendar'),
                  ),
                  const Divider(height: 1),
                  _categoryTile(
                    icon: Symbols.water_drop,
                    title: _copy('notifications.lbl_hydration_at_16'),
                    subtitle: _copy('notifications.desc_hydration_reminder'),
                    kind: NotificationPreferenceKind.hydration,
                  ),
                  const Divider(height: 1),
                  _categoryTile(
                    icon: Symbols.monitor_heart,
                    title: _copyOr(
                      'notifications.lbl_recovery_reminders',
                      'notifications.title_recovery_ready',
                    ),
                    subtitle: _copy('notifications.desc_recovery_reminders'),
                    kind: NotificationPreferenceKind.recovery,
                  ),
                ]),
                _section(_copy('notifications.section_progress_motivation'), [
                  _categoryTile(
                    icon: Symbols.local_fire_department,
                    title: _copyOr(
                      'notifications.lbl_streak_reminders',
                      'notifications.title_streak_at_risk',
                    ),
                    subtitle: _copy('notifications.desc_streak_reminders'),
                    kind: NotificationPreferenceKind.streak,
                  ),
                  const Divider(height: 1),
                  _categoryTile(
                    icon: Symbols.emoji_events,
                    title: _copyOr(
                      'notifications.lbl_rank_reminders',
                      'notifications.title_rank_ending',
                    ),
                    subtitle: _copy('notifications.desc_rank_reminders'),
                    kind: NotificationPreferenceKind.rank,
                  ),
                ]),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationDiagnosticsScreen(),
                    ),
                  ),
                  icon: const Icon(Symbols.troubleshoot),
                  label: Text(_copy('notifications.title_diagnostics')),
                ),
              ],
            ),
    );
  }
}

/// Rebuilds only when this tile's selected value changes. Coordinator events
/// such as background reconciliation therefore cannot repaint every switch.
class _PreferenceSwitchTile extends StatefulWidget {
  final NotificationCoordinator service;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool Function(NotificationCoordinator service) valueOf;
  final Future<void> Function(bool value) onChanged;

  const _PreferenceSwitchTile({
    required this.service,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.valueOf,
    required this.onChanged,
  });

  @override
  State<_PreferenceSwitchTile> createState() => _PreferenceSwitchTileState();
}

class _PreferenceSwitchTileState extends State<_PreferenceSwitchTile> {
  late bool _value;
  bool _updatePending = false;

  @override
  void initState() {
    super.initState();
    _value = widget.valueOf(widget.service);
    widget.service.addListener(_syncValue);
  }

  @override
  void didUpdateWidget(covariant _PreferenceSwitchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      oldWidget.service.removeListener(_syncValue);
      widget.service.addListener(_syncValue);
    }
    if (!_updatePending) _value = widget.valueOf(widget.service);
  }

  void _syncValue() {
    if (_updatePending) return;
    final next = widget.valueOf(widget.service);
    if (next == _value || !mounted) return;
    setState(() => _value = next);
  }

  Future<void> _handleChanged(bool next) async {
    if (next == _value || _updatePending) return;
    setState(() {
      _value = next;
      _updatePending = true;
    });
    await widget.onChanged(next);
    _updatePending = false;
    _syncValue();
  }

  @override
  void dispose() {
    widget.service.removeListener(_syncValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    secondary: Icon(widget.icon),
    title: Text(widget.title),
    subtitle: Text(widget.subtitle),
    value: _value,
    onChanged: _handleChanged,
  );
}
