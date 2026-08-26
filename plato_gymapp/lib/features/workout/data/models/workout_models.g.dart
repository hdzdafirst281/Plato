// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseSetImpl _$$ExerciseSetImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseSetImpl(
      id: json['id'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      durationTimeSeconds: (json['time_seconds'] as num?)?.toInt() ?? 0,
      distanceInKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      rpe: (json['rpe'] as num?)?.toInt(),
      isCompleted: json['is_completed'] as bool? ?? false,
      type:
          $enumDecodeNullable(_$SetTypeEnumMap, json['type']) ?? SetType.NORMAL,
      restTimeSeconds: (json['rest_time_seconds'] as num?)?.toInt() ?? 90,
      isPersonalRecord: json['is_personal_record'] as bool? ?? false,
      isWeightPR: json['is_weight_pr'] as bool? ?? false,
      isVolumePR: json['is_volume_pr'] as bool? ?? false,
      is1RmPR: json['is_1rm_pr'] as bool? ?? false,
      isTimePR: json['is_time_pr'] as bool? ?? false,
      isDistancePR: json['is_distance_pr'] as bool? ?? false,
      isStepsPR: json['is_steps_pr'] as bool? ?? false,
      isRepsPR: json['is_reps_pr'] as bool? ?? false,
      timerMode: $enumDecodeNullable(_$TimerModeEnumMap, json['timer_mode']) ??
          TimerMode.STOPWATCH,
    );

Map<String, dynamic> _$$ExerciseSetImplToJson(_$ExerciseSetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weight': instance.weight,
      'reps': instance.reps,
      'time_seconds': instance.durationTimeSeconds,
      'distance_km': instance.distanceInKm,
      'steps': instance.steps,
      'rpe': instance.rpe,
      'is_completed': instance.isCompleted,
      'type': _$SetTypeEnumMap[instance.type]!,
      'rest_time_seconds': instance.restTimeSeconds,
      'is_personal_record': instance.isPersonalRecord,
      'is_weight_pr': instance.isWeightPR,
      'is_volume_pr': instance.isVolumePR,
      'is_1rm_pr': instance.is1RmPR,
      'is_time_pr': instance.isTimePR,
      'is_distance_pr': instance.isDistancePR,
      'is_steps_pr': instance.isStepsPR,
      'is_reps_pr': instance.isRepsPR,
      'timer_mode': _$TimerModeEnumMap[instance.timerMode]!,
    };

const _$SetTypeEnumMap = {
  SetType.NORMAL: 'NORMAL',
  SetType.WARMUP: 'WARMUP',
  SetType.SUPERSET: 'SUPERSET',
  SetType.DROPSET: 'DROPSET',
  SetType.FAILURE: 'FAILURE',
};

const _$TimerModeEnumMap = {
  TimerMode.STOPWATCH: 'STOPWATCH',
  TimerMode.COUNTDOWN: 'COUNTDOWN',
};

_$WorkoutExerciseImpl _$$WorkoutExerciseImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkoutExerciseImpl(
      id: json['id'] as String,
      supersetId: json['superset_id'] as String?,
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      restTimeSeconds: (json['rest_time_seconds'] as num?)?.toInt() ?? 90,
      note: json['note'] as String?,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WorkoutExerciseImplToJson(
        _$WorkoutExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'superset_id': instance.supersetId,
      'exercise': instance.exercise,
      'rest_time_seconds': instance.restTimeSeconds,
      'note': instance.note,
      'sets': instance.sets,
    };

_$WorkoutSessionPayloadImpl _$$WorkoutSessionPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkoutSessionPayloadImpl(
      schemaVersion: json['schema_version'] as String? ?? '1.0',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      muscleDistribution:
          (json['muscle_distribution'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry($enumDecode(_$MajorMuscleGroupEnumMap, k),
                    (e as num).toDouble()),
              ) ??
              const {},
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$WorkoutSessionPayloadImplToJson(
        _$WorkoutSessionPayloadImpl instance) =>
    <String, dynamic>{
      'schema_version': instance.schemaVersion,
      'exercises': instance.exercises,
      'muscle_distribution': instance.muscleDistribution
          .map((k, e) => MapEntry(_$MajorMuscleGroupEnumMap[k]!, e)),
      'notes': instance.notes,
    };

const _$MajorMuscleGroupEnumMap = {
  MajorMuscleGroup.CHEST: 'CHEST',
  MajorMuscleGroup.BACK: 'BACK',
  MajorMuscleGroup.LEGS: 'LEGS',
  MajorMuscleGroup.SHOULDERS: 'SHOULDERS',
  MajorMuscleGroup.ARMS: 'ARMS',
  MajorMuscleGroup.CORE: 'CORE',
  MajorMuscleGroup.FULL_BODY: 'FULL_BODY',
  MajorMuscleGroup.CARDIO: 'CARDIO',
};

_$WorkoutSessionImpl _$$WorkoutSessionImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSessionImpl(
      id: json['id'] as String,
      routineId: json['routine_id'] as String?,
      programName: json['program_name'] as String?,
      name: json['name'] as String,
      startTime: (json['start_time'] as num).toInt(),
      endTime: (json['end_time'] as num?)?.toInt(),
      totalDurationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      totalCaloriesBurned: (json['total_calories'] as num?)?.toInt() ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      rpe: (json['rpe'] as num?)?.toInt(),
      xpEarned: (json['xp_earned'] as num?)?.toInt() ?? 0,
      prCount: (json['pr_count'] as num?)?.toInt() ?? 0,
      syncStatus:
          $enumDecodeNullable(_$SyncStatusEnumMap, json['sync_status']) ??
              SyncStatus.PENDING,
      updatedAt: (json['updated_at'] as num).toInt(),
      isDeleted: json['is_deleted'] as bool? ?? false,
      sessionPayload: WorkoutSessionPayload.fromJson(
          json['payload'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$WorkoutSessionImplToJson(
        _$WorkoutSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'routine_id': instance.routineId,
      'program_name': instance.programName,
      'name': instance.name,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'duration_seconds': instance.totalDurationSeconds,
      'total_calories': instance.totalCaloriesBurned,
      'total_volume': instance.totalVolume,
      'total_sets': instance.totalSets,
      'rpe': instance.rpe,
      'xp_earned': instance.xpEarned,
      'pr_count': instance.prCount,
      'sync_status': _$SyncStatusEnumMap[instance.syncStatus]!,
      'updated_at': instance.updatedAt,
      'is_deleted': instance.isDeleted,
      'payload': instance.sessionPayload,
    };

const _$SyncStatusEnumMap = {
  SyncStatus.PENDING: 'PENDING',
  SyncStatus.SYNCED: 'SYNCED',
};

_$WorkoutProgramImpl _$$WorkoutProgramImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutProgramImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      environment:
          $enumDecode(_$WorkoutEnvironmentEnumMap, json['environment']),
      difficulty: json['difficulty'] as String,
      goal: $enumDecodeNullable(_$WorkoutGoalEnumMap, json['goal']) ??
          WorkoutGoal.STRENGTH,
      routines: (json['routines'] as List<dynamic>)
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$WorkoutProgramImplToJson(
        _$WorkoutProgramImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'environment': _$WorkoutEnvironmentEnumMap[instance.environment]!,
      'difficulty': instance.difficulty,
      'goal': _$WorkoutGoalEnumMap[instance.goal]!,
      'routines': instance.routines,
    };

const _$WorkoutEnvironmentEnumMap = {
  WorkoutEnvironment.GYM: 'GYM',
  WorkoutEnvironment.HOME_BODYWEIGHT: 'HOME_BODYWEIGHT',
  WorkoutEnvironment.HOME_DUMBBELL: 'HOME_DUMBBELL',
};

const _$WorkoutGoalEnumMap = {
  WorkoutGoal.BULK: 'BULK',
  WorkoutGoal.CUT: 'CUT',
  WorkoutGoal.STRENGTH: 'STRENGTH',
};

_$ScheduledWorkoutImpl _$$ScheduledWorkoutImplFromJson(
        Map<String, dynamic> json) =>
    _$ScheduledWorkoutImpl(
      id: json['id'] as String,
      routineId: json['routineId'] as String,
      routineName: json['routineName'] as String,
      targetDateMillis: (json['targetDateMillis'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      colorHex: json['color_hex'] as String?,
      recurrenceGroupId: json['recurrence_group_id'] as String?,
    );

Map<String, dynamic> _$$ScheduledWorkoutImplToJson(
        _$ScheduledWorkoutImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'routineId': instance.routineId,
      'routineName': instance.routineName,
      'targetDateMillis': instance.targetDateMillis,
      'isCompleted': instance.isCompleted,
      'color_hex': instance.colorHex,
      'recurrence_group_id': instance.recurrenceGroupId,
    };
