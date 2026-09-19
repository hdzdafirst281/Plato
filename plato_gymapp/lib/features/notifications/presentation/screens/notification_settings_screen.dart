import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:plato_gymapp/features/notifications/application/notification_coordinator.dart';
import 'package:plato_gymapp/features/notifications/data/notification_copy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';

import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/core/di/injection.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/utils/workout_permission_helper.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  bool _isBackgroundWorkoutEnabled = true;
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSettings();
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

  Future<bool> _hasRequiredPermissions() async {
    bool hasNoti = await Permission.notification.isGranted;
    bool hasActivity = true;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 34) {
        hasActivity = await Permission.activityRecognition.isGranted;
      }
    }
    return hasNoti && hasActivity;
  }

  Future<void> _refresh() async {
    final granted = await Permission.notification.isGranted;
    if (mounted) setState(() => _granted = granted);
  }

  void _initSettings() async {
    final prefs = getIt<SharedPreferences>();
    bool isEnabled = prefs.getBool(WorkoutPermissionHelper.isBackgroundWorkoutEnabledKey) ?? false;
    
    if (isEnabled) {
      if (!await _hasRequiredPermissions()) {
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

  Widget _buildCard({required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleStyle = TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold);
    final subtitleStyle = TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14);

    final itemPadding = ResponsiveValue<EdgeInsets>(
      context,
      defaultValue: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      conditionalValues: [
        const Condition.largerThan(name: MOBILE, value: EdgeInsets.symmetric(horizontal: 48, vertical: 12)),
      ],
    ).value;

    final service = NotificationCoordinator.instance;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.settings.title_notification_screen,
        onBackClick: () => context.pop(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(
                  child: SwitchListTile(
                    contentPadding: itemPadding,
                    secondary: Icon(Symbols.directions_run, color: colorScheme.primary, size: 28),
                    title: Text(t.settings.title_bg_workout, style: titleStyle),
                    subtitle: Text(t.settings.desc_bg_workout, style: subtitleStyle),
                    value: _isBackgroundWorkoutEnabled,
                    onChanged: (bool value) async {
                      if (value) {
                        if (!await _hasRequiredPermissions()) {
                           bool hasNoti = await Permission.notification.isGranted;
                           if (!hasNoti) await Permission.notification.request();
                           if (Platform.isAndroid) {
                              final androidInfo = await DeviceInfoPlugin().androidInfo;
                              if (androidInfo.version.sdkInt >= 34) {
                                bool hasActivity = await Permission.activityRecognition.isGranted;
                                if (!hasActivity) await Permission.activityRecognition.request();
                              }
                           }
                           
                           if (!await _hasRequiredPermissions()) {
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
                    activeTrackColor: colorScheme.primary,
                    activeThumbColor: colorScheme.onPrimary,
                  ),
                ),
                
                if (service != null) ...[
                  const SizedBox(height: 24),
                  _buildCard(
                    child: ListenableBuilder(
                      listenable: service,
                      builder: (context, _) => Column(
                        children: [
                          SwitchListTile(
                            contentPadding: itemPadding,
                            secondary: Icon(Symbols.notifications, color: colorScheme.primary, size: 28),
                            title: Text(t.settings.title_notifications_section, style: titleStyle),
                            subtitle: Text(
                              (!_granted && NotificationCopy.available)
                                  ? NotificationCopy.text('notifications.msg_permission_disabled') ?? ''
                                  : t.settings.desc_item_notification,
                              style: subtitleStyle.copyWith(color: (!_granted) ? colorScheme.error : null),
                            ),
                            value: _granted && service.enabled,
                            onChanged: (value) async {
                              if (!await service.setEnabled(value)) await openAppSettings();
                              await _refresh();
                            },
                            activeTrackColor: colorScheme.primary,
                            activeThumbColor: colorScheme.onPrimary,
                          ),
                          if (NotificationCopy.available) ...[
                            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.2), indent: 72),
                            Padding(
                              padding: itemPadding.copyWith(top: 16, bottom: 8),
                              child: Row(
                                children: [
                                  Icon(Symbols.speed, color: colorScheme.onSurfaceVariant, size: 28),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(NotificationCopy.text('notifications.lbl_daily_limit') ?? '', style: titleStyle),
                                        const SizedBox(height: 4),
                                        Text(NotificationCopy.text('notifications.desc_daily_limit') ?? '', style: subtitleStyle),
                                      ],
                                    ),
                                  ),
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      popupMenuTheme: PopupMenuThemeData(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                                        ),
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: colorScheme.outlineVariant),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: service.dailyLimit,
                                          icon: Icon(Symbols.arrow_drop_down, color: colorScheme.primary),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary),
                                          items: [3, 4]
                                              .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                                              .toList(),
                                          onChanged: (n) {
                                            if (n != null) service.setLimit(n);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.2), indent: 72),
                            ListTile(
                              contentPadding: itemPadding.copyWith(top: 8, bottom: 16),
                              leading: Icon(Symbols.dark_mode, color: colorScheme.onSurfaceVariant, size: 28),
                              title: Text(NotificationCopy.text('notifications.lbl_quiet_hours') ?? '', style: titleStyle),
                              subtitle: Text(
                                '${(service.prefs.getInt('notification_quiet_start') ?? 22).toString().padLeft(2, '0')}:${(service.prefs.getInt('notification_quiet_start_minute') ?? 0).toString().padLeft(2, '0')} – ${(service.prefs.getInt('notification_quiet_end') ?? 8).toString().padLeft(2, '0')}:${(service.prefs.getInt('notification_quiet_end_minute') ?? 0).toString().padLeft(2, '0')}',
                                style: subtitleStyle,
                              ),
                              trailing: Icon(Symbols.chevron_right, color: colorScheme.onSurfaceVariant),
                            onTap: () async {
                              final start = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: service.prefs.getInt('notification_quiet_start') ?? 22,
                                  minute: service.prefs.getInt('notification_quiet_start_minute') ?? 0,
                                ),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (start == null || !context.mounted) return;
                              final end = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: service.prefs.getInt('notification_quiet_end') ?? 8,
                                  minute: service.prefs.getInt('notification_quiet_end_minute') ?? 0,
                                ),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (end != null) {
                                await service.setQuietHours(
                                  start.hour,
                                  end.hour,
                                  startMinute: start.minute,
                                  endMinute: end.minute,
                                );
                              }
                            },
                          ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
