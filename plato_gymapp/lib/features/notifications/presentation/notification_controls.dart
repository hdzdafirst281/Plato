import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          NotificationCopy.text(
            service.enabled
                ? 'notifications.desc_hydration_reminder'
                : 'notifications.msg_category_disabled',
          )!,
        ),
        contentPadding: EdgeInsets.zero,
        value: service.waterEnabled,
        onChanged: (value) async {
          if (!await service.setWaterEnabled(value) && context.mounted)
            await openAppSettings();
        },
      ),
    );
  }
}


