import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/calendar_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';
import 'package:plato_gymapp/core/di/injection.dart';
import 'package:plato_gymapp/core/utils/workout_permission_helper.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/worker/background_workout_service.dart';
import '../../application/notification_coordinator.dart';
import '../../data/notification_copy.dart';
import '../../data/notification_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _backgroundWorkoutEnabled = false;
  bool _notificationGranted = false;
  bool _activityGranted = false;
  bool _activityRequired = false;
  bool _permissionsLoaded = false;
  Future<void> _preferenceUpdates = Future<void>.value();
  int _workoutReminderCount = 0;
  int? _androidSdkInt;
  int _refreshGeneration = 0;

  bool get _allPermissionsGranted =>
      _notificationGranted && (!_activityRequired || _activityGranted);

  bool get _isPartialPermission =>
      !_allPermissionsGranted &&
      (_notificationGranted || (_activityRequired && _activityGranted));

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
    final notifFuture = Permission.notification.isGranted;
    final countFuture = _service?.remainingTodayWorkoutReminderCount();

    final isAndroid = Platform.isAndroid;
    final sdkInt = isAndroid ? await _getAndroidSdkInt() : 0;
    final activityRequired = isAndroid && sdkInt >= 34;

    final activityFuture = activityRequired
        ? Permission.activityRecognition.isGranted
        : Future.value(true);

    var background =
        prefs.getBool(WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey) ??
        false;

    final notifGranted = await notifFuture;
    final activityGranted = await activityFuture;
    final hasWorkoutPerms =
        notifGranted && (!activityRequired || activityGranted);

    if (background && !hasWorkoutPerms) {
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
      _notificationGranted = notifGranted;
      _activityGranted = activityGranted;
      _activityRequired = activityRequired;
      _permissionsLoaded = true;
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
      final hasPerms = await _hasWorkoutPermissions();
      final notifGranted = await Permission.notification.isGranted;
      final activityGranted = _activityRequired
          ? await Permission.activityRecognition.isGranted
          : true;
      if (!hasPerms) {
        if (!mounted) return;
        setState(() {
          _backgroundWorkoutEnabled = false;
          _notificationGranted = notifGranted;
          _activityGranted = activityGranted;
          _permissionsLoaded = true;
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
          _notificationGranted = notifGranted;
          _activityGranted = activityGranted;
          _permissionsLoaded = true;
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

  Future<void> _handlePermissionAction() async {
    final notifStatus = await Permission.notification.status;
    final activityStatus = _activityRequired
        ? await Permission.activityRecognition.status
        : PermissionStatus.granted;

    final shouldRequestNotif =
        !_notificationGranted && !notifStatus.isPermanentlyDenied;
    final shouldRequestActivity =
        _activityRequired &&
        !_activityGranted &&
        !activityStatus.isPermanentlyDenied;

    if (shouldRequestNotif || shouldRequestActivity) {
      if (shouldRequestNotif) await Permission.notification.request();
      if (shouldRequestActivity) await Permission.activityRecognition.request();
      await _refresh();
      if (_allPermissionsGranted) return;
    }
    await openAppSettings();
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
    return Scaffold(
      appBar: GymTopBar(
        title: t.settings.lbl_item_notification,
        onBackClick: () => context.pop(),
      ),
      body: GymMotionItem(
        stage: 1,
        child: service == null
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
                  _SystemPermissionTile(
                    loaded: _permissionsLoaded,
                    allGranted: _allPermissionsGranted,
                    isPartial: _isPartialPermission,
                    notificationGranted: _notificationGranted,
                    activityGranted: _activityGranted,
                    activityRequired: _activityRequired,
                    onOpenSettings: _handlePermissionAction,
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (_workoutReminderCount > 0) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CalendarScreen(
                              initialScheduleId: 'today',
                            ),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CalendarScreen(),
                          ),
                        );
                      }
                    },
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
              ],
              ),
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

class _SystemPermissionTile extends StatelessWidget {
  final bool loaded;
  final bool allGranted;
  final bool isPartial;
  final bool notificationGranted;
  final bool activityGranted;
  final bool activityRequired;
  final VoidCallback onOpenSettings;

  const _SystemPermissionTile({
    required this.loaded,
    required this.allGranted,
    required this.isPartial,
    required this.notificationGranted,
    required this.activityGranted,
    required this.activityRequired,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final gymColors = Theme.of(context).gymColors;
    final colorScheme = Theme.of(context).colorScheme;

    if (!loaded) {
      return ListTile(
        leading: Icon(Symbols.security, color: colorScheme.onSurfaceVariant),
        title: Text(
          NotificationCopy.text('notifications.lbl_system_permission') ?? '',
        ),
        subtitle: const Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final Color statusColor;
    final String statusKey;

    if (allGranted) {
      statusColor = gymColors.success;
      statusKey = 'notifications.status_permission_allowed';
    } else if (isPartial) {
      statusColor = gymColors.warning;
      statusKey = 'notifications.status_permission_partial';
    } else {
      statusColor = colorScheme.error;
      statusKey = 'notifications.status_permission_blocked';
    }

    final statusText = NotificationCopy.text(statusKey) ?? '';
    final notifLabel =
        NotificationCopy.text('notifications.badge_notification') ?? 'Thông báo';
    final activityLabel =
        NotificationCopy.text('notifications.badge_activity_recognition') ??
        'Hoạt động thể chất';

    return InkWell(
      onTap: allGranted ? null : onOpenSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Symbols.security, color: statusColor),
            title: Text(
              NotificationCopy.text('notifications.lbl_system_permission') ?? '',
            ),
            subtitle: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            trailing: allGranted
                ? null
                : TextButton(
                    onPressed: onOpenSettings,
                    child: Text(
                      NotificationCopy.text('notifications.btn_open_system_settings') ?? '',
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _PermissionBadge(
                      icon: Symbols.notifications,
                      label: notifLabel,
                      granted: notificationGranted,
                      maxWidth: constraints.maxWidth,
                    ),
                    if (activityRequired)
                      _PermissionBadge(
                        icon: Symbols.directions_run,
                        label: activityLabel,
                        granted: activityGranted,
                        maxWidth: constraints.maxWidth,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool granted;
  final double? maxWidth;

  const _PermissionBadge({
    required this.icon,
    required this.label,
    required this.granted,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final gymColors = Theme.of(context).gymColors;
    final colorScheme = Theme.of(context).colorScheme;

    final badgeColor = granted ? gymColors.success : colorScheme.error;
    final badgeBg = badgeColor.withValues(alpha: 0.1);
    final borderColor = badgeColor.withValues(alpha: 0.25);
    final statusText = NotificationCopy.text(
          granted
              ? 'notifications.status_granted'
              : 'notifications.status_denied',
        ) ??
        (granted ? 'Đã cấp' : 'Chưa cấp');

    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Symbols.check_circle : Symbols.cancel,
            size: 13,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: $statusText',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
