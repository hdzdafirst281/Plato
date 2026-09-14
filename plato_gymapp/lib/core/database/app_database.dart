// ignore_for_file: experimental_member_use
import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'entities.dart';
import 'daos.dart';
import 'converters.dart';

part 'app_database.g.dart'; 

@TypeConverters([
  MuscleGroupConverter,
  ExerciseTypeConverter,
  FoodUnitConverter,
  MealTypeConverter,
  WorkoutEnvironmentConverter,
  WorkoutGoalConverter,
  MuscleGroupListConverter,
  EquipmentConverter,
])
@Database(
  version: 7, // 🚀 CẬP NHẬT LÊN VERSION 6
  entities: [
    Exercise, 
    FoodResult, 
    WorkoutProgramEntity, 
    WorkoutSessionEntity, 
    RoutineEntity,
    NutritionDailyEntity,
    ScheduledWorkoutEntity,
    RewardClaimEntity, 
    NotificationRecordEntity,
  ]
)
abstract class AppDatabase extends FloorDatabase {
  NotificationDao get notificationDao;
  ExerciseDao get exerciseDao;
  FoodDao get foodDao;
  WorkoutProgramDao get workoutProgramDao;
  WorkoutDao get workoutDao; 
  NutritionDao get nutritionDao; 
  RewardClaimDao get rewardClaimDao; 
}

// Migration từ v2 lên v3
final migration2to3 = Migration(2, 3, (sqflite.Database database) async {
  await database.execute('ALTER TABLE exercises ADD COLUMN is_custom INTEGER NOT NULL DEFAULT 0');
  await database.execute('ALTER TABLE exercises ADD COLUMN local_image_path TEXT');
});

// Migration từ v3 lên v4
final migration3to4 = Migration(3, 4, (sqflite.Database database) async {
  await database.execute('ALTER TABLE exercises ADD COLUMN user_note TEXT');
});

// Migration từ v4 lên v5
final migration4to5 = Migration(4, 5, (sqflite.Database database) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `reward_claims_local` (
      `id` TEXT NOT NULL, 
      `sourceType` TEXT NOT NULL, 
      `sourceRef` TEXT NOT NULL, 
      `periodKey` TEXT NOT NULL, 
      `actionType` TEXT NOT NULL, 
      `xpAmount` INTEGER NOT NULL, 
      `createdAt` INTEGER NOT NULL, 
      `syncStatus` TEXT NOT NULL, 
      PRIMARY KEY (`id`)
    )
  ''');
});

// 🚀 THÊM MIGRATION MỚI (v5 lên v6) ĐỂ THÊM CỘT IMAGE
final migration5to6 = Migration(5, 6, (sqflite.Database database) async {
  await database.execute('ALTER TABLE exercises ADD COLUMN image TEXT');
});

// Date-only schedules remain date-only; no midnight reminders are introduced.
final migration6to7 = Migration(6, 7, (sqflite.Database database) async {
  await database.execute('CREATE TABLE IF NOT EXISTS notification_records_local (id TEXT NOT NULL, valueJson TEXT NOT NULL, PRIMARY KEY (id))');
  await database.execute('ALTER TABLE scheduled_workouts_local ADD COLUMN timeOfDayMinutes INTEGER');
  await database.execute('ALTER TABLE scheduled_workouts_local ADD COLUMN timeZoneId TEXT');
  await database.execute('ALTER TABLE scheduled_workouts_local ADD COLUMN reminderEnabled INTEGER NOT NULL DEFAULT 0');
  await database.execute('ALTER TABLE scheduled_workouts_local ADD COLUMN reminderMinutesBefore INTEGER NOT NULL DEFAULT 30');
  await database.execute('ALTER TABLE scheduled_workouts_local ADD COLUMN completedWorkoutId TEXT');
});
