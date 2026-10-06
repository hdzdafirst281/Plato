import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../domain/notification_policy.dart';
import 'notification_copy.dart';

class LocalNotificationGateway {
  final plugin = FlutterLocalNotificationsPlugin();
  static const channelId = 'plato_reminders_v2';
  static final _singlePulse = Int64List.fromList([0, 180]);
  static const openActionId = 'open';
  String zoneId = 'UTC';

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
    final actionLabel = candidate.actionLabelKey == null
        ? null
        : NotificationCopy.text(candidate.actionLabelKey!);
    Future<void> deliver(AndroidScheduleMode mode) => plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(candidate.at, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          NotificationCopy.text('settings.title_notifications_section')!,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_stat_plato',
          playSound: false,
          enableVibration: true,
          vibrationPattern: _singlePulse,
          styleInformation: BigTextStyleInformation(body),
          actions: actionLabel == null
              ? const <AndroidNotificationAction>[]
              : [
                  AndroidNotificationAction(
                    openActionId,
                    actionLabel,
                    showsUserInterface: true,
                  ),
                ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentBanner: false,
          presentSound: false,
          categoryIdentifier: actionLabel == null
              ? null
              : categoryId(candidate.kind),
        ),
      ),
      androidScheduleMode: mode,
      payload: jsonEncode({
        'v': 2,
        'scope': scope,
        'key': candidate.key,
        'route': candidate.route,
        'sourceId': candidate.sourceId,
        'kind': candidate.kind.name,
      }),
    );
    await deliver(AndroidScheduleMode.inexactAllowWhileIdle);
    return true;
  }

  Future<List<PendingNotificationRequest>> pending() =>
      plugin.pendingNotificationRequests();
  Future<List<ActiveNotification>> active() => plugin.getActiveNotifications();

  Future<void> showTestNow() async {
    final title = NotificationCopy.text('notifications.title_diagnostics');
    final body = NotificationCopy.text('notifications.msg_test_scheduled');
    if (title == null || body == null) return;
    await plugin.show(
      id: 1999999998,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          NotificationCopy.text('settings.title_notifications_section')!,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_stat_plato',
          playSound: false,
          enableVibration: true,
          vibrationPattern: _singlePulse,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(presentSound: false),
      ),
    );
  }

  Future<void> scheduleTest(String scope) async {
    final now = DateTime.now();
    await schedule(
      1999999997,
      ReminderCandidate(
        key: 'diagnostic-test:${now.millisecondsSinceEpoch}',
        kind: ReminderKind.recovery,
        at: now.add(const Duration(minutes: 1)),
        titleKey: 'notifications.title_diagnostics',
        bodyKey: 'notifications.msg_test_scheduled',
        route: '/workout?recovery=1',
        actionLabelKey: 'workout.tooltip_view_details',
      ),
      scope,
    );
  }

  static String categoryId(ReminderKind kind) => 'plato_${kind.name}';

  static List<DarwinNotificationCategory> darwinCategories() {
    final keys = <ReminderKind, String>{
      ReminderKind.workout: 'notifications.cta_view_schedule',
      ReminderKind.hydration: 'notifications.cta_open_water',
      ReminderKind.recovery: 'notifications.cta_view_recovery',
      ReminderKind.streak: 'notifications.cta_view_progress',
      ReminderKind.rank: 'notifications.cta_view_rank',
      ReminderKind.inactivity: 'notifications.cta_choose_workout',
    };
    final fallback =
        NotificationCopy.text('workout.tooltip_view_details') ?? '';
    return [
      for (final entry in keys.entries)
        DarwinNotificationCategory(
          categoryId(entry.key),
          actions: [
            DarwinNotificationAction.plain(
              openActionId,
              NotificationCopy.text(entry.value) ?? fallback,
            ),
          ],
        ),
    ];
  }

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
