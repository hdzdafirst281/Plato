import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plato_gymapp/core/utils/time_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../database/app_database.dart';
import '../../features/auth/data/models/user_models.dart';
import '../database/entities.dart';
import '../di/injection.dart';

// --- BIẾN TOÀN CỤC ---
const String lastSyncTimestampKey = 'global_last_sync_time';
const String syncUserIdKey = 'global_sync_user_id';

// --- HÀM TIỆN ÍCH (Pure Function - An toàn cho Isolate) ---
Map<String, dynamic> _stripWorkoutPayload(Map<String, dynamic> fullPayload) {
  final exercises = (fullPayload['exercises'] as List<dynamic>?)?.map((ex) {
    final sets = (ex['sets'] as List<dynamic>?)?.map((set) {
      final cleanedSet = Map<String, dynamic>.from(set);
      cleanedSet.removeWhere((key, value) {
        if (key == 'reps' || key == 'weight' || key == 'time_seconds' || 
            key == 'type' || key == 'rest_time_seconds' || 
            key == 'distance_km' || key == 'steps') {
          return false; 
        }
        return value == false || value == 0 || value == 0.0 || value == null;
      });

      if (!cleanedSet.containsKey('rest_time_seconds')) {
         cleanedSet['rest_time_seconds'] = set['rest_time_seconds'] ?? 0;
      }
      return cleanedSet;
    }).toList() ?? [];

    final cleanedEx = <String, dynamic>{
      'id': ex['id'],
      'exercise_id': (ex['exercise'] != null && ex['exercise'] is Map) 
          ? ex['exercise']['id'] 
          : ex['exercise_id'],
      'sets': sets,
    };

    if (ex.containsKey('superset_id') && ex['superset_id'] != null) {
      cleanedEx['superset_id'] = ex['superset_id'];
    }

    cleanedEx['rest_time_seconds'] = ex['rest_time_seconds'] ?? 90;
    return cleanedEx;
  }).toList() ?? [];

  return {
    'schema_version': fullPayload['schema_version'] ?? '1.0',
    'muscle_distribution': fullPayload['muscle_distribution'] ?? {},
    'notes': fullPayload['notes'],
    'exercises': exercises,
  };
}

Future<List<WorkoutSessionEntity>> _parseRemoteSessionsInIsolate(Map<String, dynamic> args) async {
  return await Isolate.run(() {
    final List<dynamic> response = args['response'];
    final Map<String, dynamic> exerciseMap = args['exercise_map'];
    
    return response.map((data) {
      final strippedPayload = data['payload'] as Map<String, dynamic>? ?? {};
      
      final hydratedExercises = ((strippedPayload['exercises'] as List?) ?? []).map((ex) {
        final String safeExerciseId = ex['exercise_id']?.toString() 
                                     ?? (ex['exercise'] is Map ? ex['exercise']['id']?.toString() : null) 
                                     ?? const Uuid().v4();

        final exerciseInfo = exerciseMap[safeExerciseId];

        return {
          'id': ex['id']?.toString() ?? const Uuid().v4(), 
          'superset_id': ex['superset_id']?.toString(), 
          'rest_time_seconds': ex['rest_time_seconds'] ?? 90, 
          'exercise': exerciseInfo ?? {
                  'id': safeExerciseId, 'name': 'Bài tập không khả dụng', 
                  'type': 'NORMAL', 'is_deleted': false, 'is_custom': false, 'secondary_muscles': [],
                },
          'sets': ex['sets'] ?? [],
        };
      }).toList();

      final fullPayload = {
        'schema_version': strippedPayload['schema_version'] ?? '1.0',
        'muscle_distribution': strippedPayload['muscle_distribution'] ?? {},
        'notes': strippedPayload['notes'],
        'exercises': hydratedExercises,
      };

      return WorkoutSessionEntity(
        id: data['id'], routineId: data['routine_id'], programName: data['program_name'], name: data['name'] ?? "Buổi tập mới",
        startTime: DateTime.parse(data['start_time']).millisecondsSinceEpoch,
        endTime: data['end_time'] != null ? DateTime.parse(data['end_time']).millisecondsSinceEpoch : null,
        durationSeconds: data['duration_seconds'] ?? 0, totalCaloriesBurned: data['total_calories_burned'] ?? 0,
        totalVolume: (data['total_volume'] as num?)?.toDouble() ?? 0.0, totalSets: data['total_sets'] ?? 0,
        rpe: data['rpe'], xpEarned: data['xp_earned'] ?? 0, prCount: data['pr_count'] ?? 0,
        payloadJson: jsonEncode(fullPayload), 
        syncStatus: 'SYNCED',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        isDeleted: data['is_deleted'] == true,
      );
    }).toList();
  });
}

// ==========================================
// CORE SYNC LOGIC (ĐÃ REFACTOR PHÂN LUỒNG PUSH/PULL)
// ==========================================
Future<bool> _executeCoreSyncLogic({
  String? forceUserId, 
  bool isBackground = false,
  bool pushOnly = false,
  bool pullOnly = false,
  bool criticalWorkoutsOnly = false,
}) async {
  AppDatabase? backgroundDb; 
  
  try {
    debugPrint(isBackground ? "⏳ Bắt đầu Sync (NGẦM)..." : "⚡ Bắt đầu Sync (TRỰC TIẾP) | PushOnly: $pushOnly | PullOnly: $pullOnly");

    if (isBackground) {
      await dotenv.load(fileName: ".env"); 
      await Supabase.initialize(url: dotenv.env['SUPABASE_URL']!, publishableKey: dotenv.env['SUPABASE_ANON_KEY']!);
    }
    
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();

    if (!pushOnly) {
      await TimeManager.syncWithServer();
    }
      
    if (isBackground) await prefs.reload(); 
    
    final AppDatabase database;
    if (isBackground) {
      backgroundDb = await $FloorAppDatabase
          .databaseBuilder('plato_app_database.db')
          .addMigrations([migration2to3, migration3to4, migration4to5, migration5to6]) 
          .build();
      database = backgroundDb;
    } else {
      database = getIt<AppDatabase>(); 
    }
    
    final workoutDao = database.workoutDao;
    final rewardClaimDao = database.rewardClaimDao;

    final currentUserId = forceUserId ?? supabase.auth.currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) return true;

    final previousUserId = prefs.getString(syncUserIdKey);
    if (previousUserId != null && previousUserId != currentUserId) {
      debugPrint("🔄 Phát hiện đổi tài khoản. Chuyển sang FULL PULL SYNC.");
      await prefs.remove(lastSyncTimestampKey);
    }
    await prefs.setString(syncUserIdKey, currentUserId);

    final lastSyncTimeMillis = prefs.getInt(lastSyncTimestampKey) ?? 0;
    final lastSyncIsoStr = DateTime.fromMillisecondsSinceEpoch(lastSyncTimeMillis).toUtc().toIso8601String();
    bool isSyncSuccessful = true; 

    // =====================================
    // LUỒNG PUSH (Lên Cloud)
    // =====================================
    if (!pullOnly) {
      // --- STEP 1: PUSH PROFILE ---
      if (!criticalWorkoutsOnly) {
        try {
          final profileStr = prefs.getString('USER_PROFILE');
          if (profileStr != null) {
            final profile = UserProfile.fromJson(jsonDecode(profileStr));
            final mappedUser = {
              'id': currentUserId, 'name': profile.displayName, 'gender': profile.gender.name,
              'age': profile.userAge, 'height_cm': profile.heightInCm, 'weight_kg': profile.weightInKg,
              'body_fat': profile.bodyFatPercentage,
              'current_rank_id': profile.activeRankId, 'current_rp': profile.currentRp,
              'workout_preferences': {
                'workout_goal': profile.workoutGoal.name, 'experience_level': profile.experienceLevel,
                'activity_level': profile.activityLevel.name, 'days_available': profile.trainingDaysPerWeek,
                'environment': profile.environment.name,
              },
              'health_profile': { 'injuries': profile.reportedInjuries, 'dietary_restrictions': profile.dietaryRestrictions, },
              'current_targets': {
                'nutrition_goal': profile.nutritionGoal.name, 'target_weight_kg': profile.targetGoalWeightKg,
                'diet_plan': profile.dietPlan, 'tdee': profile.calculatedTdee,
                'target_macros': profile.targetMacros.toJson(), 'is_custom_macros': profile.isCustomMacros,
                'weekly_goal_rate': profile.weeklyGoalRate,
              },
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            };
            await supabase.from('users').upsert(mappedUser);
          }
        } catch (e) { debugPrint("⚠️ Lỗi PUSH Profile: $e"); isSyncSuccessful = false; }
      }

      // --- STEP 2: PUSH WORKOUTS ---
      try {
        final pendingWorkouts = await workoutDao.getPendingSyncSessions();
        if (pendingWorkouts.isNotEmpty) {
          final toDelete = pendingWorkouts.where((e) => e.isDeleted).map((e) => e.id).toList();
          final toUpsert = pendingWorkouts.where((e) => !e.isDeleted).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          if (toDelete.isNotEmpty) {
            await supabase.from('workout_history').delete().inFilter('id', toDelete);
            await workoutDao.deleteHistoryByIds(toDelete);
          }

          if (toUpsert.isNotEmpty) {
            final mappedDtos = await Isolate.run(() {
              return toUpsert.map((w) {
                final payload = _stripWorkoutPayload(jsonDecode(w.payloadJson));
                int safeXp = w.xpEarned > 0 ? w.xpEarned : (50 + (w.prCount * 20));
                return {
                  'id': w.id, 'user_id': currentUserId, 'routine_id': w.routineId,
                  'program_name': w.programName, 'name': w.name, 
                  'start_time': DateTime.fromMillisecondsSinceEpoch(w.startTime).toUtc().toIso8601String(),
                  'end_time': w.endTime != null ? DateTime.fromMillisecondsSinceEpoch(w.endTime!).toUtc().toIso8601String() : null, 
                  'duration_seconds': w.durationSeconds, 'total_calories_burned': w.totalCaloriesBurned, 
                  'total_volume': w.totalVolume, 'total_sets': w.totalSets, 'rpe': w.rpe, 
                  'pr_count': w.prCount, 'payload': payload, 'xp_earned': safeXp, 
                };
              }).toList();
            });

            await supabase.from('workout_history').upsert(mappedDtos);
            await workoutDao.markWorkoutsAsSynced(toUpsert.map((e) => e.id).toList());
          }
        }
      } catch (e) { debugPrint("⚠️ Lỗi PUSH Workouts: $e"); isSyncSuccessful = false; }

      // --- STEP 3: PUSH REWARDS LEDGER ---
      if (!criticalWorkoutsOnly) {
        try {
          final pendingClaims = await rewardClaimDao.getPendingSyncClaims();
          if (pendingClaims.isNotEmpty) {
            final mappedClaims = pendingClaims.map((c) => {
              'id': c.id, 'user_id': currentUserId, 'source_type': c.sourceType,
              'source_ref': c.sourceRef, 'period_key': c.periodKey, 'action_type': c.actionType,
              'xp_amount': c.xpAmount, 'created_at': DateTime.fromMillisecondsSinceEpoch(c.createdAt).toUtc().toIso8601String(),
            }).toList();

            await supabase.from('reward_claims_ledger').upsert(mappedClaims);
            await rewardClaimDao.markClaimsAsSynced(pendingClaims.map((c) => c.id).toList());
          }
        } catch (e) { debugPrint("⚠️ Lỗi PUSH Reward Ledger: $e"); isSyncSuccessful = false; }
      }
    }

    // =====================================
    // LUỒNG PULL (Về Local)
    // =====================================
    if (!pushOnly) {
      // --- STEP 4: PULL GAMIFICATION PROFILE ---
      try {
        final serverProfile = await supabase.from('users').select('xp').eq('id', currentUserId).maybeSingle();
        final historyResponse = await supabase.from('user_rank_history').select('new_rank_id, event_type, created_at').eq('user_id', currentUserId).order('created_at', ascending: false);

        if (serverProfile != null) {
          final profileStr = prefs.getString('USER_PROFILE');
          if (profileStr != null) {
            final localProfile = UserProfile.fromJson(jsonDecode(profileStr));
            List<RankTimelineItem> parsedHistory = [];
            for (var row in historyResponse as List) {
              String mappedReason = 'REASON_MAINTAINED';
              if (row['event_type'] == 'PROMOTION') mappedReason = 'REASON_PROMOTED';
              if (row['event_type'] == 'DEMOTION') mappedReason = 'REASON_DEMOTED';
              parsedHistory.add(RankTimelineItem(rankId: row['new_rank_id'] as int, achievedAtMillis: DateTime.parse(row['created_at']).millisecondsSinceEpoch, unlockReasonDescription: mappedReason));
            }
            
            final updatedProfile = localProfile.copyWith(experiencePoints: serverProfile['xp'] ?? localProfile.experiencePoints, rankAdvancementHistory: parsedHistory);
            if (!isBackground) {
              await getIt<AuthRepository>().saveProfile(updatedProfile); 
            } else {
              await prefs.setString('USER_PROFILE', jsonEncode(updatedProfile.toJson()));
            }
          }
        }
      } catch (e) { debugPrint("⚠️ Lỗi PULL Gamification Profile: $e"); isSyncSuccessful = false; }

      // --- STEP 4.5: PULL REWARDS ---
      try {
        final ledgerResponse = await supabase.from('reward_claims_ledger').select().eq('user_id', currentUserId).gt('created_at', lastSyncIsoStr);
        if ((ledgerResponse as List).isNotEmpty) {
          final remoteClaims = ledgerResponse.map((row) {
            return RewardClaimEntity(
              id: row['id']?.toString() ?? const Uuid().v4(),
              sourceType: row['source_type'] ?? 'UNKNOWN', sourceRef: row['source_ref'] ?? 'UNKNOWN',
              periodKey: row['period_key'] ?? 'UNKNOWN', actionType: row['action_type'] ?? 'CLAIMED',
              xpAmount: row['xp_amount'] ?? 0, createdAt: DateTime.parse(row['created_at']).millisecondsSinceEpoch,
              syncStatus: 'SYNCED',
            );
          }).toList();
          await rewardClaimDao.insertClaims(remoteClaims);
        }
      } catch (e) { debugPrint("⚠️ Lỗi PULL Reward Ledger: $e"); isSyncSuccessful = false; }

      // --- STEP 5: PULL WORKOUTS ---
      try {
        final response = await supabase.from('workout_history').select().eq('user_id', currentUserId).gt('updated_at', lastSyncIsoStr); 
        if ((response as List).isNotEmpty) {
          final allExercises = await database.exerciseDao.getAllExercises();
          final exerciseMap = {for (var e in allExercises) e.id: e.toJson()}; 

          final remoteSessions = await _parseRemoteSessionsInIsolate({'response': response, 'exercise_map': exerciseMap});
          if (remoteSessions.isNotEmpty) await workoutDao.insertHistory(remoteSessions); 
        }
      } catch (e) { debugPrint("⚠️ Lỗi PULL Workout: $e"); isSyncSuccessful = false; }
    }

    // --- CẬP NHẬT LAST SYNC TIME (Chỉ update nếu có Pull) ---
    if (isSyncSuccessful && !pushOnly) {
      await prefs.setInt(lastSyncTimestampKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint("✅ Lưu mốc thời gian Delta Sync thành công.");
    }

    return isSyncSuccessful;
  } catch (e) {
    debugPrint("🚨 Lỗi nghiêm trọng tại SyncManager: $e");
    return false;
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final refreshToken = inputData?['refresh_token'] as String?;
    await dotenv.load(fileName: ".env"); 

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await Supabase.initialize(url: dotenv.env['SUPABASE_URL']!, publishableKey: dotenv.env['SUPABASE_ANON_KEY']!);
        await Supabase.instance.client.auth.setSession(refreshToken);
      } catch (e) { debugPrint("⚠️ Lỗi setSession Isolate: $e"); }
    }
    return await _executeCoreSyncLogic(forceUserId: inputData?['user_id'], isBackground: true);
  });
}

class SyncManager {
  static bool _isSyncing = false; 

  static void initialize() {
    Workmanager().initialize(callbackDispatcher);
  }

  // ĐÃ SỬA: Thêm pushOnly, pullOnly và trả về Future<bool>
  static Future<bool> syncNow({
    String? forceUserId, 
    bool pushOnly = false, 
    bool pullOnly = false,
    bool criticalWorkoutsOnly = false,
  }) async {
    if (_isSyncing) {
      debugPrint("⏳ Sync đang chạy, bỏ qua request mới.");
      return false;
    }
    _isSyncing = true;
    try {
      return await _executeCoreSyncLogic(
        forceUserId: forceUserId, 
        isBackground: false, 
        pushOnly: pushOnly, 
        pullOnly: pullOnly,
        criticalWorkoutsOnly: criticalWorkoutsOnly,
      );
    } finally {
      _isSyncing = false;
    }
  }

  static void scheduleBackgroundSync({String? forceUserId, String? refreshToken}) {
    Workmanager().registerOneOffTask(
      "gym_sync_task", "GymDataSync",
      inputData: { 
        // ignore: use_null_aware_elements
        if (forceUserId != null) 'user_id': forceUserId, 
        // ignore: use_null_aware_elements
        if (refreshToken != null) 'refresh_token': refreshToken, 
      },
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  // =========================================================
  // WIPE DỮ LIỆU LOCAL AN TOÀN (BẢO VỆ MASTER DATA)
  // =========================================================
  static Future<void> clearAllLocalUserData() async {
    debugPrint("🧹 [WIPE] Bắt đầu dọn dẹp dữ liệu cá nhân cục bộ...");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('USER_PROFILE');
    await prefs.remove('BODY_MEASUREMENTS');
    await prefs.remove('WORKOUT_FOLDER_ORDER');
    await prefs.remove(lastSyncTimestampKey);
    await prefs.remove(syncUserIdKey);

    try {
      final database = getIt<AppDatabase>();
      
      // 🚀 FIX: Thay thế toàn bộ RAW EXECUTE bằng DAO để kích hoạt Stream Update!
      
      // BƯỚC 1: Xóa các bảng có khả năng chứa cấu trúc bài tập
      await database.workoutDao.deleteAllHistory();
      await database.workoutDao.deleteAllRoutines();
      await database.workoutDao.deleteAllScheduledWorkouts();
      
      // BƯỚC 2: Xóa các dữ liệu cá nhân khác
      await database.rewardClaimDao.deleteAllClaims();
      await database.nutritionDao.deleteAllNutrition();
      
      // BƯỚC 3: Xóa bài tập do user tự tạo
      await database.exerciseDao.deleteAllCustomExercises();
      await database.exerciseDao.clearAllUserNotes(); // Reset note bài hệ thống
      
      debugPrint("✅ [WIPE] Hoàn tất xóa dữ liệu cá nhân. Master Data an toàn.");
    } catch (e) {
      debugPrint("🚨 [WIPE ERROR] Lỗi khi dọn dẹp SQLite: $e");
    }
  }
}
