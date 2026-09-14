import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import '../application/notification_coordinator.dart';
import '../data/notification_copy.dart';

class WaterNotificationToggle extends StatelessWidget {
  const WaterNotificationToggle({super.key});
  @override
  Widget build(BuildContext context) {
    final service = NotificationCoordinator.instance;
    if (service == null || !NotificationCopy.available)
      return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => SwitchListTile.adaptive(
        title: Text(
          NotificationCopy.text('notifications.lbl_hydration_at_16')!,
        ),
        subtitle: Text(
          NotificationCopy.text(
            service.enabled
                ? 'notifications.desc_hydration_reminder'
                : 'notifications.msg_category_disabled',
          )!,
        ),
        value: service.waterEnabled,
        onChanged: (value) async {
          if (!await service.setWaterEnabled(value) && context.mounted)
            await openAppSettings();
        },
      ),
    );
  }
}

class NotificationSettingsControls extends StatefulWidget {
  const NotificationSettingsControls({super.key});
  @override
  State<NotificationSettingsControls> createState() =>
      _NotificationSettingsControlsState();
}

class _NotificationSettingsControlsState
    extends State<NotificationSettingsControls>
    with WidgetsBindingObserver {
  bool _granted = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  Future<void> _refresh() async {
    final granted = await Permission.notification.isGranted;
    if (mounted) setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationCoordinator.instance;
    if (service == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => Column(
        children: [
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(t.settings.title_notifications_section),
            subtitle: !_granted && NotificationCopy.available
                ? Text(
                    NotificationCopy.text(
                      'notifications.msg_permission_disabled',
                    )!,
                  )
                : null,
            value: _granted && service.enabled,
            onChanged: (value) async {
              if (!await service.setEnabled(value)) await openAppSettings();
              await _refresh();
            },
          ),
          if (NotificationCopy.available) ...[
            ListTile(
              title: Text(
                NotificationCopy.text('notifications.lbl_daily_limit')!,
              ),
              subtitle: Text(
                NotificationCopy.text('notifications.desc_daily_limit')!,
              ),
              trailing: DropdownButton<int>(
                value: service.dailyLimit,
                items: [3, 4]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                    .toList(),
                onChanged: (n) {
                  if (n != null) service.setLimit(n);
                },
              ),
            ),
            ListTile(
              title: Text(
                NotificationCopy.text('notifications.lbl_quiet_hours')!,
              ),
              subtitle: Text(
                '${(service.prefs.getInt('notification_quiet_start') ?? 22).toString().padLeft(2, '0')}:${(service.prefs.getInt('notification_quiet_start_minute') ?? 0).toString().padLeft(2, '0')} – ${(service.prefs.getInt('notification_quiet_end') ?? 8).toString().padLeft(2, '0')}:${(service.prefs.getInt('notification_quiet_end_minute') ?? 0).toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final start = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour:
                        service.prefs.getInt('notification_quiet_start') ?? 22,
                    minute:
                        service.prefs.getInt(
                          'notification_quiet_start_minute',
                        ) ??
                        0,
                  ),
                );
                if (start == null || !context.mounted) return;
                final end = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: service.prefs.getInt('notification_quiet_end') ?? 8,
                    minute:
                        service.prefs.getInt('notification_quiet_end_minute') ??
                        0,
                  ),
                );
                if (end != null)
                  await service.setQuietHours(
                    start.hour,
                    end.hour,
                    startMinute: start.minute,
                    endMinute: end.minute,
                  );
              },
            ),
          ],
        ],
      ),
    );
  }
}
