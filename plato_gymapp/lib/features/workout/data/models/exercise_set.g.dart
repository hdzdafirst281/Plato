// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseSetImpl _$$ExerciseSetImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseSetImpl(
      id: json['id'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
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
    };

const _$SetTypeEnumMap = {
  SetType.NORMAL: 'NORMAL',
  SetType.WARMUP: 'WARMUP',
  SetType.SUPERSET: 'SUPERSET',
  SetType.DROPSET: 'DROPSET',
  SetType.FAILURE: 'FAILURE',
};
