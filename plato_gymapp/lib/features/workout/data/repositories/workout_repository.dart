import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:injectable/injectable.dart';
import 'package:plato_gymapp/core/database/app_database.dart';
import 'package:plato_gymapp/core/worker/sync_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/daos.dart';
import '../../../../core/database/entities.dart';
import '../../../../core/database/enums.dart';

import '../models/workout_models.dart';

@lazySingleton
class WorkoutRepository {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  WorkoutDao get _workoutDao => _db.workoutDao;
  WorkoutProgramDao get _workoutProgramDao => _db.workoutProgramDao;
  ExerciseDao get _exerciseDao => _db.exerciseDao;

  static const _uuid = Uuid();

  // FIX 1: Cờ báo hủy tiến trình (Cancel Token) để ngắt việc sinh lịch
  final Set<String> _cancelledGroups = {};

  WorkoutRepository(this._db, this._supabase);

  // --- HÀM STRIP PAYLOAD KHI ĐẨY LÊN ---
  Map<String, dynamic> _stripWorkoutPayload(Map<String, dynamic> fullPayload) {
    final exercises =
        (fullPayload['exercises'] as List?)?.map((ex) {
          final sets =
              (ex['sets'] as List?)?.map((set) {
                final cleanedSet = Map<String, dynamic>.from(set);

                // FIX TẬN GỐC: Chỉ xóa rác, TUYỆT ĐỐI GIỮ LẠI CÁC TRƯỜNG LOGIC QUAN TRỌNG KỂ CẢ KHI = 0
                cleanedSet.removeWhere((key, value) {
                  if (key == 'reps' ||
                      key == 'weight' ||
                      key == 'time_seconds' ||
                      key == 'type' ||
                      key == 'rest_time_seconds' ||
                      key == 'distance_km' ||
                      key == 'steps') {
                    return false; // Kim bài miễn tử: KHÔNG ĐƯỢC XÓA
                  }
                  return value == false ||
                      value == 0 ||
                      value == 0.0 ||
                      value == null;
                });

                // Cứu cánh: Ép lại giá trị nếu lỡ bị bộ lọc nào đó làm mất
                if (!cleanedSet.containsKey('rest_time_seconds')) {
                  cleanedSet['rest_time_seconds'] =
                      set['rest_time_seconds'] ?? 0;
                }

                return cleanedSet;
              }).toList() ??
              [];

          // Khởi tạo Exercise Map chuẩn
          final cleanedEx = <String, dynamic>{
            'id': ex['id'],
            'exercise_id': (ex['exercise'] != null && ex['exercise'] is Map)
                ? ex['exercise']['id']
                : ex['exercise_id'],
            'sets': sets,
          };

          // FIX: Xử lý Superset (Giữ nguyên nếu có dữ liệu, KHÔNG gán null để tránh lỗi Supabase)
          if (ex.containsKey('superset_id') && ex['superset_id'] != null) {
            cleanedEx['superset_id'] = ex['superset_id'];
          }

          // FIX QUAN TRỌNG: Ép cứng giá trị rest_time_seconds vào Payload (User chỉnh 0 thì lưu 0)
          cleanedEx['rest_time_seconds'] = ex['rest_time_seconds'] ?? 90;

          return cleanedEx;
        }).toList() ??
        [];

    return {
      'schema_version': fullPayload['schema_version'] ?? '1.0',
      'muscle_distribution': fullPayload['muscle_distribution'] ?? {},
      'notes': fullPayload['notes'],
      'exercises': exercises,
    };
  }

  // FIX: TẠO SEQUENTIAL ID ĐỂ BẢO TOÀN THỨ TỰ KHI "ORDER BY id ASC"
  // Thay thế 8 ký tự đầu của UUID bằng timestamp + index để đảm bảo thứ tự thời gian/vòng lặp
  String _generateSequentialId([int indexOffset = 0]) {
    final seconds =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) + indexOffset;
    final timeHex = seconds.toRadixString(16).padLeft(8, '0');
    final baseUuid = _uuid.v4();
    return '$timeHex${baseUuid.substring(8)}';
  }

  // =====================================================================
  // 1 & 2. STREAMS
  // =====================================================================

  Stream<List<WorkoutSession>> get routinesStream =>
      _workoutDao.watchAllRoutines().map(
        (entities) =>
            entities.map((e) => _routineEntityToDomainModel(e)).toList(),
      );

  Stream<List<WorkoutProgram>> get exploreProgramsStream =>
      _workoutProgramDao.watchAllPrograms().map(
        (entities) =>
            entities.map((e) => _programEntityToDomainModel(e)).toList(),
      );

  Stream<List<WorkoutSession>> get workoutHistoryStream => _workoutDao
      .watchAllHistory()
      .map((entities) => entities.map((e) => _entityToDomainModel(e)).toList());

  Stream<List<ScheduledWorkout>> get scheduledWorkoutsStream =>
      _workoutDao.watchAllScheduledWorkouts().map(
        (entities) => entities
            .map(
              (e) => ScheduledWorkout(
                id: e.id,
                routineId: e.routineId,
                routineName: e.routineName,
                targetDateMillis: e.targetDateMillis,
                isCompleted: e.isCompleted,
                colorHex: e.colorHex,
                recurrenceGroupId: e.recurrenceGroupId,
              ),
            )
            .toList(),
      );

  List<String>? prSummary;

  // --- SCHEDULE LOGIC (Lên lịch lặp lại) ---
  Future<void> scheduleWorkout(
    String routineId,
    String routineName,
    DateTime startDate, {
    int repeatType = 0,
    List<int>? selectedWeekdays,
    int occurrences = 1,
    int intervalDays = 1,
    String? colorHex,
    String? recurrenceGroupId,
  }) async {
    List<DateTime> datesToSchedule = [];

    // Chuẩn hoá StartDate về 00:00:00 để tránh lệch giờ
    final baseDate = DateTime(startDate.year, startDate.month, startDate.day);

    if (repeatType == 0) {
      datesToSchedule.add(baseDate);
    } else if (repeatType == 1) {
      for (int i = 0; i < occurrences; i++) {
        datesToSchedule.add(baseDate.add(Duration(days: i)));
      }
    } else if (repeatType == 2 &&
        selectedWeekdays != null &&
        selectedWeekdays.isNotEmpty) {
      DateTime current = baseDate;
      int weeksAdded = 0;

      while (weeksAdded < occurrences) {
        bool addedAnyThisWeek = false;
        for (int i = 0; i < 7; i++) {
          final testDate = current.add(Duration(days: i));
          if (selectedWeekdays.contains(testDate.weekday)) {
            if (!testDate.isBefore(baseDate)) {
              datesToSchedule.add(testDate);
              addedAnyThisWeek = true;
            }
          }
        }
        if (addedAnyThisWeek) weeksAdded++;
        current = current.add(const Duration(days: 7));

        if (current.difference(baseDate).inDays > 730) break;
      }
    } else if (repeatType == 3) {
      int safeInterval = intervalDays > 0 ? intervalDays : 1;
      for (int i = 0; i < occurrences; i++) {
        datesToSchedule.add(baseDate.add(Duration(days: i * safeInterval)));
      }
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    int batchCount = 0;

    for (var date in datesToSchedule) {
      if (recurrenceGroupId != null &&
          _cancelledGroups.contains(recurrenceGroupId)) {
        break;
      }

      final entity = ScheduledWorkoutEntity(
        id: const Uuid().v4(),
        routineId: routineId,
        routineName: routineName,
        targetDateMillis: date.millisecondsSinceEpoch,
        isCompleted: false,
        colorHex: colorHex,
        recurrenceGroupId: recurrenceGroupId,
        syncStatus: SyncStatus.PENDING.name,
        updatedAt: currentTime,
        isDeleted: false,
      );
      await _workoutDao.insertScheduledWorkout(entity);

      batchCount++;
      if (batchCount % 10 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    if (recurrenceGroupId != null) _cancelledGroups.remove(recurrenceGroupId);
  }

  Future<void> deleteScheduledWorkout(String id) async {
    await _workoutDao.deleteScheduledWorkout(id);
  }

  Future<void> deleteScheduledWorkoutGroup(String groupId) async {
    _cancelledGroups.add(groupId);
    await Future.delayed(const Duration(milliseconds: 50));
    await _workoutDao.deleteScheduledWorkoutGroup(groupId);
  }

  // --- MAPPING ENTITIES ---

  WorkoutProgram _programEntityToDomainModel(WorkoutProgramEntity entity) {
    List<WorkoutSession> parsedRoutines = [];
    try {
      final List<dynamic> decodedList = jsonDecode(entity.routinesJson);
      parsedRoutines = decodedList.map((jsonObj) {
        final rEntity = RoutineEntity(
          id: jsonObj['id'] ?? _uuid.v4(),
          name: jsonObj['name'] ?? '',
          programName: entity.name,
          payloadJson:
              jsonObj['payloadJson'] ??
              (jsonObj['payload'] != null
                  ? jsonEncode(jsonObj['payload'])
                  : '{"schemaVersion":"1.0","exercises":[]}'),
          syncStatus: SyncStatus.SYNCED.name,
          updatedAt: jsonObj['updatedAt'] ?? entity.updatedAt,
          isDeleted: false,
        );
        return _routineEntityToDomainModel(rEntity);
      }).toList();
    } catch (e) {
      debugPrint("🚨 Lỗi parse routinesJson: $e");
    }

    return WorkoutProgram(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      environment: entity.environment,
      difficulty: entity.difficulty,
      goal: entity.goal,
      routines: parsedRoutines,
    );
  }

  WorkoutSessionEntity _domainToEntity(WorkoutSession session) {
    return WorkoutSessionEntity(
      id: session.id,
      routineId: session.routineId,
      programName: session.programName,
      name: session.name,
      startTime: session.startTime,
      endTime: session.endTime,
      durationSeconds: session.totalDurationSeconds,
      totalCaloriesBurned: session.totalCaloriesBurned,
      totalVolume: session.totalVolume,
      totalSets: session.totalSets,
      rpe: session.rpe,
      xpEarned: session.xpEarned,
      prCount: session.prCount,
      payloadJson: jsonEncode(session.sessionPayload.toJson()),
      syncStatus: session.syncStatus.name,
      updatedAt: session.updatedAt,
      isDeleted: session.isDeleted,
    );
  }

  WorkoutSession _entityToDomainModel(WorkoutSessionEntity entity) {
    return WorkoutSession(
      id: entity.id,
      routineId: entity.routineId,
      programName: entity.programName,
      name: entity.name,
      startTime: entity.startTime,
      endTime: entity.endTime,
      totalDurationSeconds: entity.durationSeconds,
      totalCaloriesBurned: entity.totalCaloriesBurned,
      totalVolume: entity.totalVolume,
      totalSets: entity.totalSets,
      rpe: entity.rpe,
      xpEarned: entity.xpEarned,
      prCount: entity.prCount,
      sessionPayload: WorkoutSessionPayload.fromJson(
        jsonDecode(entity.payloadJson),
      ),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == entity.syncStatus,
      ),
      updatedAt: entity.updatedAt,
      isDeleted: entity.isDeleted,
    );
  }

  WorkoutSession _routineEntityToDomainModel(RoutineEntity entity) {
    return WorkoutSession(
      id: entity.id,
      routineId: null,
      programName: entity.programName,
      name: entity.name,
      startTime: 0,
      endTime: null,
      totalDurationSeconds: 0,
      totalCaloriesBurned: 0,
      totalVolume: 0.0,
      totalSets: 0,
      rpe: null,
      xpEarned: 0,
      prCount: 0,
      sessionPayload: WorkoutSessionPayload.fromJson(
        jsonDecode(entity.payloadJson),
      ),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == entity.syncStatus,
        orElse: () => SyncStatus.PENDING,
      ),
      updatedAt: entity.updatedAt,
      isDeleted: entity.isDeleted,
    );
  }

  // =====================================================================
  // 3. SUPABASE ACTIONS (Đồng bộ)
  // =====================================================================

  Future<PostAuthSyncResult> handlePostAuthSync(
    String authenticatedUserId,
  ) async {
    try {
      final countOfLocalWorkoutSessions = await _workoutDao
          .getLocalWorkoutCount();

      final checkRemoteHistory = await _supabase
          .from('workout_history')
          .select('id')
          .eq('user_id', authenticatedUserId)
          .limit(1);
      final checkRemoteRoutines = await _supabase
          .from('routines')
          .select('id')
          .eq('user_id', authenticatedUserId)
          .limit(1);

      final hasHistory = checkRemoteHistory.isNotEmpty;
      final hasRoutines = checkRemoteRoutines.isNotEmpty;
      final hasRemoteDataOnCloud = hasHistory || hasRoutines;

      if (!hasRemoteDataOnCloud && countOfLocalWorkoutSessions == 0) {
        return PostAuthSyncResult.NEW_USER_PUSHED;
      }

      final remoteWorkoutsList = hasHistory
          ? await _supabase
                .from('workout_history')
                .select()
                .eq('user_id', authenticatedUserId)
          : [];
      final remoteRoutinesList = hasRoutines
          ? await _supabase
                .from('routines')
                .select()
                .eq('user_id', authenticatedUserId)
          : [];

      final mappedWorkoutEntities = await Future.wait(
        remoteWorkoutsList.map((dto) => _dtoToWorkoutEntity(dto)),
      );
      final mappedRoutineEntities = await Future.wait(
        remoteRoutinesList.map((dto) => _dtoToRoutineEntity(dto)),
      );

      if (countOfLocalWorkoutSessions == 0 && hasRemoteDataOnCloud) {
        await _workoutDao.replaceLocalWithRemote(
          mappedWorkoutEntities,
          mappedRoutineEntities,
        );
        return PostAuthSyncResult.OLD_USER_RESTORED;
      }

      final pendingLocalWorkouts = await _workoutDao.getPendingSyncSessions();
      if (pendingLocalWorkouts.isNotEmpty) {
        final dtosToPush = pendingLocalWorkouts.map((local) {
          final safePayload = _safeDecodeJson(local.payloadJson);
          return {
            'id': local.id,
            'user_id': authenticatedUserId,
            'routine_id': local.routineId,
            'program_name': local.programName,
            'name': local.name,
            'start_time': DateTime.fromMillisecondsSinceEpoch(
              local.startTime,
            ).toUtc().toIso8601String(),
            'end_time': local.endTime != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    local.endTime!,
                  ).toUtc().toIso8601String()
                : null,
            'duration_seconds': local.durationSeconds,
            'total_calories_burned': local.totalCaloriesBurned,
            'total_volume': local.totalVolume,
            'total_sets': local.totalSets,
            'rpe': local.rpe,
            'xp_earned': local.xpEarned,
            'pr_count': local.prCount,
            'payload': _stripWorkoutPayload(safePayload),
            'is_deleted': local.isDeleted,
          };
        }).toList();

        await _supabase.from('workout_history').upsert(dtosToPush);
        await _workoutDao.markWorkoutsAsSynced(
          pendingLocalWorkouts.map((e) => e.id).toList(),
        );
      }

      final pendingLocalRoutines = await _workoutDao.getPendingSyncRoutines();
      if (pendingLocalRoutines.isNotEmpty) {
        final dtosToPushRoutines = pendingLocalRoutines
            .map(
              (local) => {
                'id': local.id,
                'user_id': authenticatedUserId,
                'name': local.name,
                'program_name': local.programName,
                'payload': _safeDecodeJson(local.payloadJson),
                'updated_at': DateTime.fromMillisecondsSinceEpoch(
                  local.updatedAt,
                ).toUtc().toIso8601String(),
                'is_deleted': local.isDeleted,
              },
            )
            .toList();

        await _supabase.from('routines').upsert(dtosToPushRoutines);
        await _workoutDao.markRoutinesAsSynced(
          pendingLocalRoutines.map((e) => e.id).toList(),
        );
      }

      for (var entity in mappedWorkoutEntities) {
        await _workoutDao.insertOrUpdate(entity);
      }
      for (var entity in mappedRoutineEntities) {
        await _workoutDao.insertOrUpdateRoutine(entity);
      }

      return !hasRemoteDataOnCloud
          ? PostAuthSyncResult.NEW_USER_PUSHED
          : PostAuthSyncResult.DATA_MERGED;
    } catch (e) {
      debugPrint("🚨 Lỗi khi đồng bộ PostAuth: $e");
      return PostAuthSyncResult.ERROR;
    }
  }

  Map<String, dynamic> _safeParsePayload(dynamic rawPayload) {
    if (rawPayload == null) return {};
    if (rawPayload is Map<String, dynamic>) return rawPayload;
    if (rawPayload is String) return _safeDecodeJson(rawPayload);
    return {};
  }

  Map<String, dynamic> _safeDecodeJson(String jsonStr) {
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  int _safeInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  double _safeDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int _safeTime(dynamic timeValue) {
    if (timeValue == null) return DateTime.now().millisecondsSinceEpoch;
    if (timeValue is int) return timeValue;
    if (timeValue is String) {
      try {
        return DateTime.parse(timeValue).millisecondsSinceEpoch;
      } catch (_) {
        return DateTime.now().millisecondsSinceEpoch;
      }
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  // THÊM MỚI: Cập nhật thư mục của Routine khi kéo thả
  Future<void> updateRoutineFolder(
    String routineId,
    String newFolderName,
  ) async {
    final currentRoutines = await _workoutDao.getAllRoutines();
    final existingRoutine = currentRoutines
        .where((r) => r.id == routineId)
        .firstOrNull;
    if (existingRoutine == null) return;

    final updatedEntity = RoutineEntity(
      id: routineId,
      name: existingRoutine.name,
      programName: newFolderName,
      payloadJson: existingRoutine.payloadJson,
      syncStatus: SyncStatus.PENDING.name, // Đánh dấu để Sync lên Supabase
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isDeleted: false,
    );
    await _workoutDao.insertOrUpdateRoutine(updatedEntity);
  }

  // ✅ BẢN VÁ LỖI CRASH (POST-AUTH HISTORY HYDRATION)
  Future<WorkoutSessionEntity> _dtoToWorkoutEntity(
    Map<String, dynamic> dto,
  ) async {
    final strippedPayload = _safeParsePayload(dto['payload']);
    final allExercises = await _exerciseDao.getAllExercises();
    final exerciseMap = {for (var e in allExercises) e.id: e};

    final hydratedExercises = ((strippedPayload['exercises'] as List?) ?? [])
        .map((ex) {
          // Đảm bảo an toàn tuyệt đối khi lấy exercise_id
          final String safeExerciseId =
              ex['exercise_id']?.toString() ??
              (ex['exercise'] is Map
                  ? ex['exercise']['id']?.toString()
                  : null) ??
              _uuid.v4();

          final exerciseInfo = exerciseMap[safeExerciseId];

          return {
            'id': ex['id']?.toString() ?? _uuid.v4(),
            'superset_id': ex['superset_id']?.toString(),
            'rest_time_seconds': ex['rest_time_seconds'] ?? 90,
            'exercise': exerciseInfo != null
                ? exerciseInfo.toJson()
                : {
                    'id': safeExerciseId,
                    'name': 'Bài tập không khả dụng',
                    'type': 'WEIGHT_REPS',
                    'is_deleted': false,
                    'is_custom': false,
                    'secondary_muscles': [],
                  },
            'sets': ex['sets'] ?? [],
          };
        })
        .toList();

    final fullPayload = {
      'schema_version': strippedPayload['schema_version'] ?? '1.0',
      'muscle_distribution': strippedPayload['muscle_distribution'] ?? {},
      'notes': strippedPayload['notes'],
      'exercises': hydratedExercises,
    };

    return WorkoutSessionEntity(
      id: dto['id']?.toString() ?? _uuid.v4(),
      routineId: dto['routine_id']?.toString(),
      programName: dto['program_name']?.toString() ?? '',
      name: dto['name']?.toString() ?? 'Session',
      startTime: _safeTime(dto['start_time']),
      endTime: dto['end_time'] != null ? _safeTime(dto['end_time']) : null,
      durationSeconds: _safeInt(dto['duration_seconds']),
      totalCaloriesBurned: _safeInt(dto['total_calories_burned']),
      totalVolume: _safeDouble(dto['total_volume']),
      totalSets: _safeInt(dto['total_sets']),
      rpe: dto['rpe'] != null ? _safeInt(dto['rpe']) : null,
      xpEarned: _safeInt(dto['xp_earned']),
      prCount: _safeInt(dto['pr_count']),
      payloadJson: jsonEncode(fullPayload),
      syncStatus: SyncStatus.SYNCED.name,
      updatedAt: _safeTime(dto['updated_at']),
      isDeleted: dto['is_deleted'] == true,
    );
  }

  // ✅ BẢN VÁ LỖI CRASH (POST-AUTH ROUTINE HYDRATION)
  Future<RoutineEntity> _dtoToRoutineEntity(Map<String, dynamic> dto) async {
    final strippedPayload = _safeParsePayload(dto['payload']);
    final allExercises = await _exerciseDao.getAllExercises();
    final exerciseMap = {for (var e in allExercises) e.id: e};

    final hydratedExercises = ((strippedPayload['exercises'] as List?) ?? [])
        .map((ex) {
          final String safeExerciseId =
              ex['exercise_id']?.toString() ??
              (ex['exercise'] is Map
                  ? ex['exercise']['id']?.toString()
                  : null) ??
              _uuid.v4();

          final exerciseInfo = exerciseMap[safeExerciseId];

          return {
            'id': ex['id']?.toString() ?? _uuid.v4(),
            'exercise': exerciseInfo != null
                ? exerciseInfo.toJson()
                : {
                    'id': safeExerciseId,
                    'name': 'Bài tập không khả dụng',
                    'type':
                        'WEIGHT_REPS', // FIX: Fallback về type hợp lệ của Enum
                    'is_deleted': false,
                    'is_custom': false,
                    'secondary_muscles': [],
                  },
            'sets': ex['sets'] ?? [],
          };
        })
        .toList();

    final fullPayload = {
      'schema_version': strippedPayload['schema_version'] ?? '1.0',
      'exercises': hydratedExercises,
    };

    return RoutineEntity(
      id: dto['id']?.toString() ?? _uuid.v4(),
      name: dto['name']?.toString() ?? 'Routine',
      programName: dto['program_name']?.toString() ?? '',
      payloadJson: jsonEncode(fullPayload),
      syncStatus: SyncStatus.SYNCED.name,
      updatedAt: _safeTime(dto['updated_at']),
      isDeleted: dto['is_deleted'] == true,
    );
  }

  // ✅ HÀM MỚI: HYDRATE (CHỮA LÀNH) ROUTINE DATA TRƯỚC KHI TẬP
  Future<WorkoutSession> hydrateRoutine(WorkoutSession session) async {
    final allExercises = await _exerciseDao.getAllExercises();
    final exerciseMap = {for (var e in allExercises) e.id: e};

    final hydratedExercises = session.exercises.map((ex) {
      final freshEx = exerciseMap[ex.exercise.id];
      if (freshEx != null) {
        return ex.copyWith(exercise: freshEx);
      }
      return ex;
    }).toList();

    return session.copyWith(
      sessionPayload: session.sessionPayload.copyWith(
        exercises: hydratedExercises,
      ),
    );
  }

  Future<void> createRoutine(
    String routineName,
    String targetFolderName,
    List<WorkoutExercise> exercisesList,
  ) async {
    final newRoutine = RoutineEntity(
      id: _generateSequentialId(), // FIX: Thay _uuid bằng sequence
      name: routineName,
      programName: targetFolderName,
      payloadJson: jsonEncode(
        WorkoutSessionPayload(
          schemaVersion: "1.0",
          exercises: exercisesList,
        ).toJson(),
      ),
      syncStatus: SyncStatus.PENDING.name,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isDeleted: false,
    );
    await _workoutDao.insertOrUpdateRoutine(newRoutine);
  }

  Future<void> updateRoutine(
    String routineId,
    String updatedRoutineName,
    List<WorkoutExercise> updatedExercisesList,
  ) async {
    final currentRoutines = await _workoutDao.getAllRoutines();
    final existingRoutine = currentRoutines
        .where((r) => r.id == routineId)
        .firstOrNull;
    if (existingRoutine == null) return;

    final oldPayload = WorkoutSessionPayload.fromJson(
      jsonDecode(existingRoutine.payloadJson),
    );
    final newPayload = oldPayload.copyWith(exercises: updatedExercisesList);

    final updatedEntity = RoutineEntity(
      id: routineId,
      name: updatedRoutineName,
      programName: existingRoutine.programName,
      payloadJson: jsonEncode(newPayload.toJson()),
      syncStatus: SyncStatus.PENDING.name,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isDeleted: false,
    );
    await _workoutDao.insertOrUpdateRoutine(updatedEntity);
  }

  Future<void> deleteRoutine(String routineIdToDelete) async {
    await _workoutDao.softDeleteRoutine(
      routineIdToDelete,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> duplicateRoutine(String originalRoutineIdToDuplicate) async {
    final currentRoutines = await _workoutDao.getAllRoutines();
    final originalRoutine = currentRoutines
        .where((r) => r.id == originalRoutineIdToDuplicate)
        .firstOrNull;
    if (originalRoutine == null) return;

    final oldPayload = WorkoutSessionPayload.fromJson(
      jsonDecode(originalRoutine.payloadJson),
    );
    final duplicatedExercisesList = oldPayload.exercises.map((
      workoutExerciseItem,
    ) {
      return workoutExerciseItem.copyWith(
        id: _uuid.v4(),
        sets: workoutExerciseItem.sets
            .map((setItem) => setItem.copyWith(id: _uuid.v4()))
            .toList(),
      );
    }).toList();

    final duplicatedRoutineEntity = RoutineEntity(
      id: _generateSequentialId(), // FIX: Duplicate cũng cần tuần tự nối tiếp
      name:
          "${t.translateDynamic(originalRoutine.name)}${t.workout.label_copy_suffix}",
      programName: originalRoutine.programName,
      payloadJson: jsonEncode(
        oldPayload.copyWith(exercises: duplicatedExercisesList).toJson(),
      ),
      syncStatus: SyncStatus.PENDING.name,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isDeleted: false,
    );
    await _workoutDao.insertOrUpdateRoutine(duplicatedRoutineEntity);
  }

  Future<void> renameFolder(String oldFolderName, String newFolderName) async {
    final currentRoutines = await _workoutDao.getAllRoutines();
    final routinesAffected = currentRoutines
        .where((r) => r.programName == oldFolderName)
        .toList();

    for (var routineItem in routinesAffected) {
      final renamedRoutine = RoutineEntity(
        id: routineItem.id,
        name: routineItem.name,
        programName: newFolderName,
        payloadJson: routineItem.payloadJson,
        syncStatus: SyncStatus.PENDING.name,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        isDeleted: false,
      );
      await _workoutDao.insertOrUpdateRoutine(renamedRoutine);
    }
  }

  Future<void> deleteFolder(String targetFolderName) async {
    final currentRoutines = await _workoutDao.getAllRoutines();
    final routinesAffected = currentRoutines
        .where((r) => r.programName == targetFolderName)
        .toList();
    for (var routineItem in routinesAffected) {
      await _workoutDao.softDeleteRoutine(
        routineItem.id,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Future<void> addRoutineToFolder(String targetFolderName) async {
    final initializedRoutine = RoutineEntity(
      id: _generateSequentialId(), // FIX
      name: "Buổi tập mới",
      programName: targetFolderName,
      payloadJson: jsonEncode(
        WorkoutSessionPayload(schemaVersion: "1.0", exercises: []).toJson(),
      ),
      syncStatus: SyncStatus.PENDING.name,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isDeleted: false,
    );
    await _workoutDao.insertOrUpdateRoutine(initializedRoutine);
  }

  Future<void> saveProgramRoutines(WorkoutProgram programObjectToSave) async {
    final currentRoutines = await _workoutDao.getAllRoutines();
    if (currentRoutines.any(
      (r) => r.programName == programObjectToSave.name && !r.isDeleted,
    )) {
      return;
    }

    final namingCounterMap = <String, int>{};
    final routinesNameFrequencyMap = <String, int>{};
    for (var routine in programObjectToSave.routines) {
      routinesNameFrequencyMap[routine.name] =
          (routinesNameFrequencyMap[routine.name] ?? 0) + 1;
    }

    final currentSystemTimeMillis = DateTime.now().millisecondsSinceEpoch;

    // Đánh index để hàm _generateSequentialId tự động offset ID
    int routineIndex = 0;

    for (var routineItem in programObjectToSave.routines) {
      final countCurrentUses = (namingCounterMap[routineItem.name] ?? 0) + 1;
      namingCounterMap[routineItem.name] = countCurrentUses;
      final finalizedRoutineName =
          (routinesNameFrequencyMap[routineItem.name]! > 1)
          ? "${routineItem.name} $countCurrentUses"
          : routineItem.name;

      final generatedRoutineEntity = RoutineEntity(
        id: _generateSequentialId(
          routineIndex,
        ), // FIX LỖI Ở ĐÂY: Bảo toàn 100% thứ tự insert
        name: finalizedRoutineName,
        programName: programObjectToSave.name,
        payloadJson: jsonEncode(routineItem.sessionPayload.toJson()),
        syncStatus: SyncStatus.PENDING.name,
        updatedAt: currentSystemTimeMillis,
        isDeleted: false,
      );
      await _workoutDao.insertOrUpdateRoutine(generatedRoutineEntity);

      routineIndex++;
    }
  }

  Future<void> updateSessionRpe(String sessionIdTarget, int newRpeValue) async {
    final history = await _workoutDao.getAllHistory();
    final targetSessionData = history
        .where((h) => h.id == sessionIdTarget)
        .firstOrNull;
    if (targetSessionData == null) return;

    final updatedEntity = WorkoutSessionEntity(
      id: targetSessionData.id,
      routineId: targetSessionData.routineId,
      programName: targetSessionData.programName,
      name: targetSessionData.name,
      startTime: targetSessionData.startTime,
      endTime: targetSessionData.endTime,
      durationSeconds: targetSessionData.durationSeconds,
      totalCaloriesBurned: targetSessionData.totalCaloriesBurned,
      totalVolume: targetSessionData.totalVolume,
      totalSets: targetSessionData.totalSets,
      rpe: newRpeValue,
      xpEarned: targetSessionData.xpEarned,
      prCount: targetSessionData.prCount,
      payloadJson: targetSessionData.payloadJson,
      syncStatus: SyncStatus.PENDING.name,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isDeleted: targetSessionData.isDeleted,
    );
    await _workoutDao.insertOrUpdate(updatedEntity);
  }

  Future<WorkoutSession> saveFinishedWorkout(
    WorkoutSession completedSessionData,
  ) async {
    final exercisesEvaluatedWithPRsList = await _checkPersonalRecords(
      completedSessionData.exercises,
    );

    int cumulativePrCountCalculated = 0;
    List<String> unlockedPrNamesList = [];

    for (var workoutExerciseItem in exercisesEvaluatedWithPRsList) {
      bool containsAnyPrRecord = workoutExerciseItem.sets.any(
        (set) =>
            set.isPersonalRecord ||
            set.isWeightPR ||
            set.isVolumePR ||
            set.is1RmPR,
      );
      if (containsAnyPrRecord) {
        cumulativePrCountCalculated += 1;
        unlockedPrNamesList.add(workoutExerciseItem.exercise.name);
      }
    }

    if (cumulativePrCountCalculated > 0) prSummary = unlockedPrNamesList;

    final computedMuscleDistributionMap = _calculateMuscleDistribution(
      exercisesEvaluatedWithPRsList,
    );
    double cumulativelyCalculatedVolume = 0.0;
    for (var ex in exercisesEvaluatedWithPRsList) {
      for (var set in ex.sets) {
        if (set.isCompleted) {
          cumulativelyCalculatedVolume += (set.weight * set.reps);
        }
      }
    }

    final cumulativelyCalculatedTotalSets = exercisesEvaluatedWithPRsList.fold(
      0,
      (sum, item) => sum + item.sets.where((s) => s.isCompleted).length,
    );
    final totalDurationInMinutesCalculated =
        completedSessionData.totalDurationSeconds / 60.0;
    final estimatedCaloriesBurnedCalculated =
        ((totalDurationInMinutesCalculated * 5.0) +
                (cumulativelyCalculatedVolume * 0.02))
            .toInt();

    final finalizedSessionDataToStore = completedSessionData.copyWith(
      sessionPayload: completedSessionData.sessionPayload.copyWith(
        exercises: exercisesEvaluatedWithPRsList,
        muscleDistribution: computedMuscleDistributionMap,
      ),
      prCount: cumulativePrCountCalculated,
      totalCaloriesBurned: estimatedCaloriesBurnedCalculated,
      totalVolume: cumulativelyCalculatedVolume,
      totalSets: cumulativelyCalculatedTotalSets,
      syncStatus: SyncStatus.PENDING,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _workoutDao.insertOrUpdate(
      _domainToEntity(finalizedSessionDataToStore),
    );

    SyncManager.syncNow(pushOnly: true, criticalWorkoutsOnly: true).ignore();

    return finalizedSessionDataToStore;
  }

  void dismissPrDialog() => prSummary = null;

  Future<void> deleteWorkout(String workoutIdToDelete) async {
    await _workoutDao.softDelete(
      workoutIdToDelete,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<List<WorkoutExercise>> _checkPersonalRecords(
    List<WorkoutExercise> currentlyEvaluatedExercisesList,
  ) async {
    final historyEntities = await _workoutDao.getAllHistory();
    final entireWorkoutHistoryData = historyEntities
        .map((e) => _entityToDomainModel(e))
        .toList();

    return currentlyEvaluatedExercisesList.map((workoutExerciseItem) {
      final matchingHistorySetsList = entireWorkoutHistoryData
          .expand((history) => history.exercises)
          .where((ex) => ex.exercise.name == workoutExerciseItem.exercise.name)
          .expand((ex) => ex.sets)
          .where((set) => set.isCompleted)
          .toList();

      if (matchingHistorySetsList.isEmpty) {
        return workoutExerciseItem.copyWith(
          sets: workoutExerciseItem.sets
              .map(
                (setItem) => setItem.copyWith(
                  isPersonalRecord: false,
                  isWeightPR: false,
                  isVolumePR: false,
                  is1RmPR: false,
                ),
              )
              .toList(),
        );
      }

      double highestHistoricalWeightRecord = matchingHistorySetsList
          .map((e) => e.weight)
          .reduce(max);
      double highestHistoricalVolumeRecord = matchingHistorySetsList
          .map((e) => e.weight * e.reps)
          .reduce(max);
      double highestHistorical1RmRecord = matchingHistorySetsList
          .map((e) => _calculate1RM(e.weight, e.reps))
          .reduce(max);
      int highestHistoricalTimeRecord = matchingHistorySetsList
          .map((e) => e.durationTimeSeconds)
          .reduce(max);
      double highestHistoricalDistanceRecord = matchingHistorySetsList
          .map((e) => e.distanceInKm)
          .reduce(max);
      int highestHistoricalStepsRecord = matchingHistorySetsList
          .map((e) => e.steps)
          .reduce(max);
      int highestHistoricalRepsRecord = matchingHistorySetsList
          .map((e) => e.reps)
          .reduce(max);

      final setsEvaluatedForPrList = workoutExerciseItem.sets.map((
        currentSetData,
      ) {
        if (!currentSetData.isCompleted) {
          return currentSetData.copyWith(isPersonalRecord: false);
        }

        bool isAnyPrFlagActive = false,
            isWeightPrFlagActive = false,
            isVolumePrFlagActive = false,
            is1RmPrFlagActive = false;

        switch (workoutExerciseItem.exercise.type) {
          case ExerciseType.WEIGHT_REPS:
            isWeightPrFlagActive =
                currentSetData.weight > highestHistoricalWeightRecord;
            isVolumePrFlagActive =
                (currentSetData.weight * currentSetData.reps) >
                highestHistoricalVolumeRecord;
            is1RmPrFlagActive =
                _calculate1RM(currentSetData.weight, currentSetData.reps) >
                highestHistorical1RmRecord;
            isAnyPrFlagActive =
                isWeightPrFlagActive ||
                isVolumePrFlagActive ||
                is1RmPrFlagActive;
            break;
          case ExerciseType.TIME_ONLY:
            isAnyPrFlagActive =
                currentSetData.durationTimeSeconds >
                highestHistoricalTimeRecord;
            break;
          case ExerciseType.CARDIO_DISTANCE:
            isAnyPrFlagActive =
                currentSetData.distanceInKm > highestHistoricalDistanceRecord;
            break;
          case ExerciseType.CARDIO_STEPS:
            isAnyPrFlagActive =
                currentSetData.steps > highestHistoricalStepsRecord;
            break;
          case ExerciseType.REPS_ONLY:
            isAnyPrFlagActive =
                currentSetData.reps > highestHistoricalRepsRecord;
            break;
        }

        return currentSetData.copyWith(
          isPersonalRecord: isAnyPrFlagActive,
          isWeightPR: isWeightPrFlagActive,
          isVolumePR: isVolumePrFlagActive,
          is1RmPR: is1RmPrFlagActive,
        );
      }).toList();

      return workoutExerciseItem.copyWith(sets: setsEvaluatedForPrList);
    }).toList();
  }

  double _calculate1RM(double weightValue, int repsCount) {
    if (weightValue <= 0 || repsCount <= 0) return 0.0;
    if (repsCount == 1) return weightValue;
    return weightValue * (1 + repsCount / 30.0);
  }

  Map<MajorMuscleGroup, double> _calculateMuscleDistribution(
    List<WorkoutExercise> exercisesListForCalculation,
  ) {
    final computedRawScoresMap = <MajorMuscleGroup, double>{};

    for (var workoutExerciseItem in exercisesListForCalculation) {
      final countOfCompletedSets = workoutExerciseItem.sets
          .where((s) => s.isCompleted)
          .length;
      if (countOfCompletedSets > 0) {
        final primaryMajor = workoutExerciseItem.exercise.primaryMuscle?.major;
        if (primaryMajor != null) {
          computedRawScoresMap[primaryMajor] =
              (computedRawScoresMap[primaryMajor] ?? 0.0) +
              (3.0 * countOfCompletedSets);
        }
        workoutExerciseItem.exercise.secondaryMuscles?.forEach((
          secondaryMuscle,
        ) {
          computedRawScoresMap[secondaryMuscle.major] =
              (computedRawScoresMap[secondaryMuscle.major] ?? 0.0) +
              (1.0 * countOfCompletedSets);
        });
      }
    }

    final totalRawScoreCalculated = computedRawScoresMap.values.fold(
      0.0,
      (sum, val) => sum + val,
    );
    final finalPercentageDistributionMap = <MajorMuscleGroup, double>{};

    if (totalRawScoreCalculated > 0) {
      for (var majorMuscleGroup in MajorMuscleGroup.values) {
        final score = computedRawScoresMap[majorMuscleGroup] ?? 0.0;
        if (score > 0) {
          finalPercentageDistributionMap[majorMuscleGroup] =
              (score / totalRawScoreCalculated) * 100.0;
        }
      }
    }
    return finalPercentageDistributionMap;
  }
}
