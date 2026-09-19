import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../domain/notification_policy.dart';
import 'notification_copy.dart';

class LocalNotificationGateway {
  final plugin = FlutterLocalNotificationsPlugin();
  static const channelId = 'plato_reminders_v1';
  String zoneId = 'UTC';
  bool exactWorkoutTiming = false;
  Future<void> requestWorkoutTimingPermission() async {
    if (!Platform.isAndroid) return;
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.canScheduleExactNotifications() != true) {
      await android?.requestExactAlarmsPermission();
    }
  }

  bool _timezoneInitialized = false;
  Future<void> updateTimezone() async {
    if (!_timezoneInitialized) {
      tzdata.initializeTimeZones();
      _timezoneInitialized = true;
    }
    // Never silently schedule against UTC if the platform lookup fails.
    final name = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(name));
    zoneId = name;
    if (Platform.isAndroid) {
      exactWorkoutTiming =
          await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.canScheduleExactNotifications() ??
          false;
    }
  }

  static bool owns(int id) => id >= 100000 && id < 2000000000;
  Future<bool> schedule(
    int id,
    ReminderCandidate candidate,
    String scope,
  ) async {
    final title = NotificationCopy.text(candidate.titleKey);
    final body = NotificationCopy.text(candidate.bodyKey, candidate.arguments);
    if (title == null || body == null) return false;
    Future<void> deliver(AndroidScheduleMode mode) => plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(candidate.at, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          NotificationCopy.text('notifications.title_settings')!,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_stat_plato',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBanner: false,
          presentSound: false,
        ),
      ),
      androidScheduleMode: mode,
      payload: jsonEncode({
        'v': 1,
        'scope': scope,
        'key': candidate.key,
        'route': candidate.route,
        'sourceId': candidate.sourceId,
      }),
    );
    try {
      await deliver(
        candidate.kind == ReminderKind.workout && exactWorkoutTiming
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on PlatformException catch (error) {
      if (error.code != 'exact_alarms_not_permitted') rethrow;
      await deliver(AndroidScheduleMode.inexactAllowWhileIdle);
    }
    return true;
  }

  Future<List<PendingNotificationRequest>> pending() =>
      plugin.pendingNotificationRequests();
  Future<void> cancel(int id) => plugin.cancel(id: id);
  Future<void> clearOwned() async {
    for (final active in await plugin.getActiveNotifications()) {
      final id = active.id;
      if (id != null && owns(id)) await cancel(id);
    }
    for (final pending in await pending()) {
      if (owns(pending.id)) await cancel(pending.id);
    }
  }
}
