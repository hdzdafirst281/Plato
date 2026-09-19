import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/features/notifications/domain/notification_policy.dart';

ReminderCandidate c(String key, ReminderKind kind, int hour, {int day = 13}) =>
    ReminderCandidate(
      key: key,
      kind: kind,
      at: DateTime(2026, 9, day, hour),
      titleKey: '',
      bodyKey: '',
      route: '',
    );
void main() {
  test('finite OS queue does not let distant workouts starve today', () {
    final result = NotificationPolicy.select([
      c('today-water', ReminderKind.hydration, 16),
      for (var day = 14; day < 25; day++) c('workout-$day', ReminderKind.workout, 10, day: day),
    ], now: DateTime(2026, 9, 13, 8), pendingLimit: 3);
    expect(result.map((c) => c.key), ['today-water', 'workout-14', 'workout-15']);
  });
  final now = DateTime(2026, 9, 13, 8);
  test('hydration uses actual progress and stops at target', () {
    expect(
      NotificationPolicy.hydrationBody(0, 2),
      'notifications.body_hydration_no_log',
    );
    expect(
      NotificationPolicy.hydrationBody(.9, 2),
      'notifications.body_hydration_low',
    );
    expect(
      NotificationPolicy.hydrationBody(1, 2),
      'notifications.body_hydration_progress',
    );
    expect(NotificationPolicy.hydrationBody(2, 2), isNull);
    expect(NotificationPolicy.hydrationBody(3, 2), isNull);
    expect(NotificationPolicy.hydrationBody(0, 0), isNull);
    expect(NotificationPolicy.hydrationBody(double.nan, 2), isNull);
  });
  test('workout at 17 suppresses hydration at 16 without rescheduling', () {
    final result = NotificationPolicy.select([
      c('water', ReminderKind.hydration, 16),
      c('workout', ReminderKind.workout, 17),
    ], now: now);
    expect(result.map((e) => e.key), ['workout']);
  });
  test('default daily cap includes earlier slots after reopening', () {
    final result = NotificationPolicy.select(
      [
        c('workout', ReminderKind.workout, 20),
        c('water', ReminderKind.hydration, 16),
        c('rank', ReminderKind.rank, 12),
      ],
      now: now,
      committed: [c('past', ReminderKind.streak, 7)],
    );
    expect(result.length, 2);
    expect(result.map((e) => e.key), containsAll(['workout', 'rank']));
  });
  test('hard cap four and at most three explicit workout reminders', () {
    final result = NotificationPolicy.select(
      [
        for (var hour = 8; hour < 22; hour++)
          c('$hour', ReminderKind.workout, hour),
      ],
      now: now,
      dailyLimit: 99,
    );
    expect(result.length, 3);
  });
  test('quiet hours are dropped, not shifted', () {
    expect(
      NotificationPolicy.select([c('quiet', ReminderKind.rank, 23)], now: now),
      isEmpty,
    );
  });
  test('quiet hours preserve selected minutes at both boundaries', () {
    final beforeStart = ReminderCandidate(
      key: 'before',
      kind: ReminderKind.workout,
      at: DateTime(2026, 9, 13, 21, 29),
      titleKey: '',
      bodyKey: '',
      route: '',
    );
    final atStart = ReminderCandidate(
      key: 'start',
      kind: ReminderKind.workout,
      at: DateTime(2026, 9, 13, 21, 30),
      titleKey: '',
      bodyKey: '',
      route: '',
    );
    expect(
      NotificationPolicy.select(
        [beforeStart, atStart],
        now: now,
        quietStart: 21,
        quietStartMinute: 30,
      ).map((e) => e.key),
      ['before'],
    );
    expect(
      NotificationPolicy.select(
        [c('end', ReminderKind.workout, 8)],
        now: DateTime(2026, 9, 13, 7),
        quietEndMinute: 30,
      ),
      isEmpty,
    );
  });
  test('recovery never competes with a workout on same day', () {
    expect(
      NotificationPolicy.select([
        c('recovery', ReminderKind.recovery, 9),
        c('workout', ReminderKind.workout, 20),
      ], now: now).map((e) => e.key),
      ['workout'],
    );
  });
  test('duplicate logical keys are suppressed', () {
    expect(
      NotificationPolicy.select([
        c('water', ReminderKind.hydration, 16),
        c('water', ReminderKind.hydration, 16),
      ], now: now).length,
      1,
    );
  });
  test('one hydration per day even with different logical keys', () {
    expect(
      NotificationPolicy.select([
        c('a', ReminderKind.hydration, 12),
        c('b', ReminderKind.hydration, 16),
      ], now: now).length,
      1,
    );
  });
  test('budget does not bleed into tomorrow', () {
    final committed = [
      c('a', ReminderKind.workout, 9),
      c('b', ReminderKind.rank, 12),
      c('c', ReminderKind.hydration, 16),
    ];
    expect(
      NotificationPolicy.select(
        [c('tomorrow', ReminderKind.hydration, 16, day: 14)],
        now: now,
        committed: committed,
      ).length,
      1,
    );
  });
}
