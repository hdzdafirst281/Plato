import 'package:floor/floor.dart';
import 'entities.dart';

// ==========================================
// 1. EXERCISE DAO
// ==========================================
@dao
abstract class ExerciseDao {
  @Query('SELECT * FROM exercises WHERE is_deleted = 0')
  Future<List<Exercise>> getAllExercises();

  @Query('SELECT * FROM exercises WHERE is_deleted = 0')
  Stream<List<Exercise>> watchAllExercises();

  @Query('SELECT * FROM exercises WHERE name LIKE :query AND is_deleted = 0')
  Future<List<Exercise>> searchExercisesLocal(String query);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAll(List<Exercise> exercises);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertExercise(Exercise exercise);

  @Query('DELETE FROM exercises WHERE id IN (:ids)')
  Future<void> deleteExercisesByIds(List<String> ids);

  @Query('DELETE FROM exercises WHERE id = :id AND is_custom = 1')
  Future<void> deleteCustomExerciseById(String id);

  @Query('DELETE FROM exercises WHERE is_custom = 1')
  Future<void> deleteAllCustomExercises();

  @Query('UPDATE exercises SET user_note = :note WHERE id = :id')
  Future<void> updateUserNote(String id, String note);

  @Query('UPDATE exercises SET user_note = NULL')
  Future<void> clearAllUserNotes();
}

// ==========================================
// 2. FOOD DAO
// ==========================================
@dao
abstract class FoodDao {
  @Query('SELECT * FROM foods')
  Future<List<FoodResult>> getAllFoods();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrReplaceFood(FoodResult food);

  @Query('DELETE FROM foods WHERE id = :id')
  Future<void> deleteFoodById(String id);
}

@dao
abstract class NutritionDao {
  @Query('SELECT * FROM nutrition_daily_local WHERE dateId = :date AND isDeleted = 0')
  Future<NutritionDailyEntity?> getDailyNutritionByDate(String date);

  @Query('SELECT * FROM nutrition_daily_local WHERE dateId = :date AND isDeleted = 0')
  Stream<NutritionDailyEntity?> watchDailyNutritionByDate(String date);

  @Query('SELECT * FROM nutrition_daily_local WHERE isDeleted = 0 ORDER BY dateId DESC')
  Future<List<NutritionDailyEntity>> getAllNutritionHistory();

  @Query('DELETE FROM nutrition_daily_local')
  Future<void> deleteAllNutrition();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrUpdateDailyNutrition(NutritionDailyEntity entity);
}

// ==========================================
// 3. WORKOUT PROGRAM DAO
// ==========================================
@dao
abstract class WorkoutProgramDao {
  @Query('SELECT * FROM workout_programs_local')
  Future<List<WorkoutProgramEntity>> getAllPrograms();

  @Query('SELECT * FROM workout_programs_local')
  Stream<List<WorkoutProgramEntity>> watchAllPrograms();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertPrograms(List<WorkoutProgramEntity> programs);

  @Query('DELETE FROM workout_programs_local WHERE id IN (:ids)')
  Future<void> deleteProgramsByIds(List<String> ids);
}

// ==========================================
// 4. WORKOUT DAO (LỊCH SỬ & BUỔI TẬP CUSTOM)
// ==========================================
@dao
abstract class WorkoutDao {
  // --- SCHEDULED WORKOUTS (Lịch tập tương lai) ---
  @Query('SELECT * FROM scheduled_workouts_local WHERE isDeleted = 0')
  Stream<List<ScheduledWorkoutEntity>> watchAllScheduledWorkouts();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertScheduledWorkout(ScheduledWorkoutEntity entity);

  @Query('DELETE FROM scheduled_workouts_local WHERE id = :id')
  Future<void> deleteScheduledWorkout(String id);

  // FIX: Lệnh xoá toàn bộ chuỗi Group ID
  @Query('DELETE FROM scheduled_workouts_local WHERE recurrenceGroupId = :groupId')
  Future<void> deleteScheduledWorkoutGroup(String groupId);

  // --- ROUTINES (Buổi tập tự tạo) ---
  @Query('SELECT * FROM routines_local WHERE isDeleted = 0 ORDER BY id ASC')
  Stream<List<RoutineEntity>> watchAllRoutines();

  @Query('SELECT * FROM routines_local WHERE isDeleted = 0 ORDER BY id ASC')
  Future<List<RoutineEntity>> getAllRoutines();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrUpdateRoutine(RoutineEntity entity);

  @Query("UPDATE routines_local SET isDeleted = 1, updatedAt = :time, syncStatus = 'PENDING' WHERE id = :id")
  Future<void> softDeleteRoutine(String id, int time);

  @Query("SELECT * FROM routines_local WHERE syncStatus = 'PENDING'")
  Future<List<RoutineEntity>> getPendingSyncRoutines();

  @Query("UPDATE routines_local SET syncStatus = 'SYNCED' WHERE id IN (:ids)")
  Future<void> markRoutinesAsSynced(List<String> ids);

  @Query('DELETE FROM routines_local')
  Future<void> deleteAllRoutines();

  @Query('DELETE FROM scheduled_workouts_local')
  Future<void> deleteAllScheduledWorkouts();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertRoutines(List<RoutineEntity> routines);

  // --- WORKOUT SESSIONS (Lịch sử tập luyện) ---
  @Query('SELECT * FROM workout_history_local WHERE isDeleted = 0')
  Stream<List<WorkoutSessionEntity>> watchAllHistory();

  @Query('SELECT * FROM workout_history_local WHERE isDeleted = 0')
  Future<List<WorkoutSessionEntity>> getAllHistory();

  @Query('SELECT COUNT(*) FROM workout_history_local')
  Future<int?> getLocalWorkoutCount();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrUpdate(WorkoutSessionEntity entity);

  @Query("UPDATE workout_history_local SET isDeleted = 1, updatedAt = :time, syncStatus = 'PENDING' WHERE id = :id")
  Future<void> softDelete(String id, int time);

  @Query("SELECT * FROM workout_history_local WHERE syncStatus = 'PENDING'")
  Future<List<WorkoutSessionEntity>> getPendingSyncSessions();

  @Query("UPDATE workout_history_local SET syncStatus = 'SYNCED' WHERE id IN (:ids)")
  Future<void> markWorkoutsAsSynced(List<String> ids);

  @Query('DELETE FROM workout_history_local')
  Future<void> deleteAllHistory();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertHistory(List<WorkoutSessionEntity> history);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSessions(List<WorkoutSessionEntity> sessions);

  @Query('DELETE FROM workout_history_local WHERE id IN (:ids)')
  Future<void> deleteHistoryByIds(List<String> ids);

  // --- TRANSACTIONS (Đồng bộ đa thiết bị) ---
  @transaction
  Future<void> replaceLocalWithRemote(List<WorkoutSessionEntity> history, List<RoutineEntity> routines) async {
    await deleteAllHistory();
    await deleteAllRoutines();
    await insertHistory(history);
    await insertRoutines(routines);
  }
}

// ==========================================
// 5. REWARD CLAIM DAO (GAMIFICATION LEDGER)
// ==========================================
@dao
abstract class RewardClaimDao {
  // Lấy toàn bộ lịch sử trong 1 tuần (để Repository tổng hợp xem user đã nhận gì chưa)
  @Query('SELECT * FROM reward_claims_local WHERE periodKey = :periodKey ORDER BY createdAt ASC')
  Future<List<RewardClaimEntity>> getClaimsByPeriod(String periodKey);

  // Thêm mới 1 giao dịch nhận hoặc thu hồi
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertClaim(RewardClaimEntity entity);

  // Sync: Lấy các giao dịch chưa được đẩy lên Server
  @Query("SELECT * FROM reward_claims_local WHERE syncStatus = 'PENDING'")
  Future<List<RewardClaimEntity>> getPendingSyncClaims();

  // Sync: Đánh dấu là đã đồng bộ thành công
  @Query("UPDATE reward_claims_local SET syncStatus = 'SYNCED' WHERE id IN (:ids)")
  Future<void> markClaimsAsSynced(List<String> ids);

  // Sync (Pull): Lưu dữ liệu Ledger kéo từ Server về đè lên Local
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertClaims(List<RewardClaimEntity> claims);

  // Xóa toàn bộ Ledger (Dùng khi user đổi tài khoản hoặc Logout)
  @Query('DELETE FROM reward_claims_local')
  Future<void> deleteAllClaims();
}