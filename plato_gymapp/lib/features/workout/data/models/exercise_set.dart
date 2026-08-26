import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/database/enums.dart';

part 'exercise_set.freezed.dart';
part 'exercise_set.g.dart';

@freezed
class ExerciseSet with _$ExerciseSet {
  const factory ExerciseSet({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'weight') @Default(0.0) double weight,
    @JsonKey(name: 'reps') @Default(0) int reps,
    @JsonKey(name: 'time_seconds') @Default(0) int durationTimeSeconds,
    @JsonKey(name: 'distance_km') @Default(0.0) double distanceInKm,
    @JsonKey(name: 'steps') @Default(0) int steps,
    @JsonKey(name: 'rpe') int? rpe,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'type') @Default(SetType.NORMAL) SetType type,
    @JsonKey(name: 'rest_time_seconds') @Default(90) int restTimeSeconds,
    @JsonKey(name: 'is_personal_record') @Default(false) bool isPersonalRecord,
    @JsonKey(name: 'is_weight_pr') @Default(false) bool isWeightPR,
    @JsonKey(name: 'is_volume_pr') @Default(false) bool isVolumePR,
    @JsonKey(name: 'is_1rm_pr') @Default(false) bool is1RmPR,
    @JsonKey(name: 'is_time_pr') @Default(false) bool isTimePR,
    @JsonKey(name: 'is_distance_pr') @Default(false) bool isDistancePR,
    @JsonKey(name: 'is_steps_pr') @Default(false) bool isStepsPR,
    @JsonKey(name: 'is_reps_pr') @Default(false) bool isRepsPR,
  }) = _ExerciseSet;

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => _$ExerciseSetFromJson(json);
}