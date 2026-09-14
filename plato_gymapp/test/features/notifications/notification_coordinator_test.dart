import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:plato_gymapp/core/database/app_database.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/data/repositories/workout_repository.dart';
import 'package:plato_gymapp/features/notifications/application/notification_coordinator.dart';
import 'package:plato_gymapp/features/notifications/data/local_notification_gateway.dart';
import 'package:plato_gymapp/features/notifications/domain/notification_policy.dart';
import 'reminder_planner_test.dart' as fixtures;

class FakeGateway extends LocalNotificationGateway {
  final scheduled = <int, ReminderCandidate>{};
  int scheduleCalls = 0;
  @override
  Future<void> updateTimezone() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    zoneId = 'Asia/Ho_Chi_Minh';
  }

  @override
  Future<bool> schedule(int id, ReminderCandidate c, String scope) async {
    scheduled[id] = c;
    scheduleCalls++;
    return true;
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
  }

  @override
  Future<List<PendingNotificationRequest>> pending() async => scheduled.keys
      .map((id) => PendingNotificationRequest(id, null, null, null))
      .toList();
  @override
  Future<void> clearOwned() async {
    scheduled.clear();
  }
}

class FakeAuth extends Fake implements AuthRepository {
  @override
  UserProfile getProfile() => const UserProfile(
    targetMacros: Macros(),
    detailedBodyMetrics: BodyMetrics(),
  );
}

Future<void> saveWorkout(AppDatabase db, WorkoutSession w) =>
    db.workoutDao.insertOrUpdate(
      WorkoutSessionEntity(
        id: w.id,
        routineId: w.routineId,
        programName: w.programName,
        name: w.name,
        startTime: w.startTime,
        endTime: w.endTime,
        durationSeconds: 1800,
        totalCaloriesBurned: 0,
        totalVolume: 0,
        totalSets: 1,
        rpe: null,
        xpEarned: 0,
        prCount: 0,
        payloadJson: jsonEncode(w.sessionPayload.toJson()),
        syncStatus: 'PENDING',
        updatedAt: w.updatedAt,
        isDeleted: false,
      ),
    );
Future<void> saveWater(AppDatabase db, String date, double liters) =>
    db.nutritionDao.insertOrUpdateDailyNutrition(
      NutritionDailyEntity(
        dateId: date,
        waterConsumedLiters: liters,
        breakfastJson: '[]',
        lunchJson: '[]',
        dinnerJson: '[]',
        snackJson: '[]',
        syncStatus: 'PENDING',
        updatedAt: 0,
        isDeleted: false,
      ),
    );
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SharedPreferences prefs;
  late FakeGateway gateway;
  late NotificationCoordinator service;
  late DateTime now;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'notification_water': true,
      'notification_scope': 'test',
    });
    prefs = await SharedPreferences.getInstance();
    db = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();
    gateway = FakeGateway();
    now = DateTime(2026, 9, 13, 15);
    service = NotificationCoordinator(
      db,
      prefs,
      WorkoutRepository(
        db,
        SupabaseClient('https://example.supabase.co', 'test'),
      ),
      FakeAuth(),
      gateway: gateway,
      clock: () async => now,
      permissionGranted: () async => true,
    );
  });
  tearDown(() async {
    service.dispose();
    await db.close();
  });
  test('reconciliation updates water content and cancels at goal', () async {
    await service.reconcileNow();
    expect(
      gateway.scheduled.values.single.bodyKey,
      'notifications.body_hydration_no_log',
    );
    await saveWater(db, '2026-09-13', 1.5);
    await service.reconcileNow();
    expect(
      gateway.scheduled.values.single.bodyKey,
      'notifications.body_hydration_progress',
    );
    await saveWater(db, '2026-09-13', 2.5);
    await service.reconcileNow();
    expect(gateway.scheduled, isEmpty);
  });
  test('same snapshot and pending OS request are not rescheduled', () async {
    await service.reconcileNow();
    await service.reconcileNow();
    expect(gateway.scheduleCalls, 1);
    service.dispose();
    service = NotificationCoordinator(
      db,
      prefs,
      WorkoutRepository(
        db,
        SupabaseClient('https://example.supabase.co', 'test'),
      ),
      FakeAuth(),
      gateway: gateway,
      clock: () async => now,
      permissionGranted: () async => true,
    );
    await service.reconcileNow();
    expect(gateway.scheduleCalls, 1);
  });
  test(
    'reaching target cancels an OS-delayed water reminder after 16',
    () async {
      await service.reconcileNow();
      now = DateTime(2026, 9, 13, 16, 1);
      await saveWater(db, '2026-09-13', 2.5);
      await service.reconcileNow();
      expect(gateway.scheduled, isEmpty);
      await saveWater(db, '2026-09-13', 1);
      await service.reconcileNow();
      expect(gateway.scheduleCalls, 1);
    },
  );
  test('already scheduled hydration does not replay after 16:00', () async {
    await service.reconcileNow();
    gateway.scheduled.clear();
    now = DateTime(2026, 9, 13, 16, 1);
    await service.reconcileNow();
    expect(gateway.scheduled, isEmpty);
    expect(gateway.scheduleCalls, 1);
  });
  test(
    'OS opt-out clears reminders without changing water preference',
    () async {
      await service.reconcileNow();
      await service.setEnabled(false);
      expect(gateway.scheduled, isEmpty);
      expect(service.waterEnabled, isTrue);
    },
  );
  test(
    'one saved workout emits only one event under concurrent calls',
    () async {
      await service.reconcileNow();
      final w = fixtures.workout(now, id: 'finished');
      await saveWorkout(db, w);
      await Future.wait([service.recordWorkout(w), service.recordWorkout(w)]);
      expect((await service.store.all('event:completed:')).length, 1);
    },
  );
  test(
    'hydration goal celebration stays once after lowering and restoring intake',
    () async {
      await Future.wait([
        service.waterChanged('2026-09-13', 2, 2.5),
        service.waterChanged('2026-09-13', 2, 2.5),
      ]);
      await service.waterChanged('2026-09-13', 2.5, 1);
      await service.waterChanged('2026-09-13', 1, 2.5);
      expect((await service.store.all('event:hydration_completed:')).length, 1);
    },
  );
  test(
    'reset clears schedules and personal events and changes payload scope',
    () async {
      await service.reconcileNow();
      await service.waterChanged('2026-09-13', 2, 2.5);
      final oldScope = service.scope;
      await service.reset();
      expect(gateway.scheduled, isEmpty);
      expect(await service.store.all(''), isEmpty);
      expect(service.scope, isNot(oldScope));
      expect(service.waterEnabled, isFalse);
    },
  );
  test(
    'first cycle after a new-user baseline produces a rank result',
    () async {
      await service.reconcileNow();
      final first = fixtures.workout(now, id: 'first');
      await saveWorkout(db, first);
      await service.reconcileNow();
      now = now.add(const Duration(days: 45, seconds: 2));
      await service.reconcileNow();
      expect((await service.store.all('event:rank_result:')).length, 1);
      await service.reconcileNow();
      expect((await service.store.all('event:rank_result:')).length, 1);
    },
  );
}
