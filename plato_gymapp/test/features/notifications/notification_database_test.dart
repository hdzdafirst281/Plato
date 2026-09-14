import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:plato_gymapp/core/database/app_database.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/features/notifications/data/notification_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);
  test(
    'v6 migration preserves legacy schedules without inventing a time or reminder',
    () async {
      final old = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(old.close);
      await old.execute(
        'CREATE TABLE scheduled_workouts_local (id TEXT PRIMARY KEY, routineId TEXT NOT NULL, routineName TEXT NOT NULL, targetDateMillis INTEGER NOT NULL, isCompleted INTEGER NOT NULL, colorHex TEXT, recurrenceGroupId TEXT, syncStatus TEXT NOT NULL, updatedAt INTEGER NOT NULL, isDeleted INTEGER NOT NULL)',
      );
      await old.insert('scheduled_workouts_local', {
        'id': 'old',
        'routineId': 'r',
        'routineName': 'Upper',
        'targetDateMillis': 1234,
        'isCompleted': 0,
        'syncStatus': 'PENDING',
        'updatedAt': 1234,
        'isDeleted': 0,
      });
      await migration6to7.migrate(old);
      final row = (await old.query('scheduled_workouts_local')).single;
      expect(row['targetDateMillis'], 1234);
      expect(row['timeOfDayMinutes'], isNull);
      expect(row['reminderEnabled'], 0);
      expect(row['reminderMinutesBefore'], 30);
      expect(row['completedWorkoutId'], isNull);
      expect(await old.query('notification_records_local'), isEmpty);
    },
  );
  test(
    'new Floor schema stores timed schedules, exact linkage and ledger atomically',
    () async {
      final db = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();
      addTearDown(db.close);
      final schedule = ScheduledWorkoutEntity(
        id: 's',
        routineId: 'r',
        routineName: 'Upper',
        targetDateMillis: 1234,
        timeOfDayMinutes: 1080,
        timeZoneId: 'Asia/Ho_Chi_Minh',
        reminderEnabled: true,
        reminderMinutesBefore: 30,
        isCompleted: false,
        syncStatus: 'PENDING',
        updatedAt: 1,
        isDeleted: false,
      );
      await db.workoutDao.insertScheduledWorkouts([schedule]);
      expect(
        (await db.workoutDao.getScheduledWorkout('s'))!.timeOfDayMinutes,
        1080,
      );
      await db.workoutDao.completeSchedule('s', 'workout', 2);
      final completed = await db.workoutDao.getScheduledWorkout('s');
      expect(completed!.isCompleted, isTrue);
      expect(completed.completedWorkoutId, 'workout');
      final store = NotificationStore(db);
      await store.writeBatch({
        'dedupe': {'seen': true},
        'event': {'shown': false},
      });
      expect(await store.read('dedupe'), {'seen': true});
      expect(await store.read('event'), {'shown': false});
      await db.notificationDao.clear();
      expect(await store.all(''), isEmpty);
    },
  );
}
