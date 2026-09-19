// Explicit development entry point, never imported by production main.dart.
// flutter run -d <device> -t tool/notification_device_probe.dart
// Close with HOME, then `adb shell am kill vn.zenithas.plato` (not force-stop).
// Inspect `adb shell dumpsys notification --noredact` for id 99999 after 2 minutes.
// Run again with --dart-define=PROBE_CLEANUP=true to remove only this probe.
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:plato_gymapp/core/worker/sync_manager.dart';
import 'package:plato_gymapp/features/notifications/application/notification_background_worker.dart';
import 'package:plato_gymapp/features/notifications/data/local_notification_gateway.dart';
import 'package:plato_gymapp/features/notifications/domain/notification_policy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gateway = LocalNotificationGateway();
  await gateway.plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_plato'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );
  const id = 99999; // Outside production's owned ID range.
  await gateway.cancel(id);
  if (const bool.fromEnvironment('PROBE_CLEANUP')) {
    runApp(
      const MaterialApp(
        home: Scaffold(body: Text('Notification probe cleared')),
      ),
    );
    return;
  }
  await Permission.notification.request();
  await gateway.updateTimezone();
  final at = DateTime.now().add(const Duration(minutes: 2));
  await gateway.schedule(
    id,
    ReminderCandidate(
      key: 'device-probe',
      kind: ReminderKind.workout,
      at: at,
      titleKey: 'notifications.title_workout_reminder',
      bodyKey: 'notifications.body_workout_reminder',
      arguments: {
        'routineName': 'Plato background delivery probe',
        'time': '$at',
      },
      route: '/profile/calendar',
    ),
    'device-probe',
  );
  await SyncManager.initialize();
  await NotificationBackgroundWorker.register();
  // A due one-off request exercises the same headless handler without bypassing
  // WorkManager's own periodic eligibility check via `jobscheduler run -f`.
  await Workmanager().registerOneOffTask(
    '${NotificationBackgroundWorker.taskName}.probe',
    NotificationBackgroundWorker.taskName,
    initialDelay: const Duration(seconds: 30),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
  final pending = await gateway.pending();
  debugPrint(
    'PROBE_READY id=$id at=$at timezone=${gateway.zoneId} exact=${gateway.exactWorkoutTiming} pending=${pending.any((p) => p.id == id)}',
  );
  runApp(
    MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Text(
            'Scheduled probe $id for $at.\nPress Home and kill the background process without force-stop.\nNo workout or nutrition data was changed.',
          ),
        ),
      ),
    ),
  );
}
