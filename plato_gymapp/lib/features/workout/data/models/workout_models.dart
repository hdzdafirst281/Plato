import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart'; 

part 'workout_models.freezed.dart';
part 'workout_models.g.dart';

@freezed
class ExerciseSet with _$ExerciseSet {
  const factory ExerciseSet({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'weight') @Default(0) double weight,
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
    @JsonKey(name: 'timer_mode') @Default(TimerMode.STOPWATCH) TimerMode timerMode,
  }) = _ExerciseSet;

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => _$ExerciseSetFromJson(json);
}

@freezed
class WorkoutExercise with _$WorkoutExercise {
  const WorkoutExercise._(); 
  const factory WorkoutExercise({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'superset_id') String? supersetId, 
    @JsonKey(name: 'exercise') required Exercise exercise, 
    @JsonKey(name: 'rest_time_seconds') @Default(90) int restTimeSeconds,
    @JsonKey(name: 'note') String? note,
    @JsonKey(name: 'sets') @Default([]) List<ExerciseSet> sets,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default([]) List<ExerciseSet> previousSets,
  }) = _WorkoutExercise;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => _$WorkoutExerciseFromJson(json);

  double calculateWorkload() {
    return sets.where((s) => s.isCompleted).fold(0.0, (sum, s) => sum + (s.weight * s.reps));
  }
}

@freezed
class WorkoutSessionPayload with _$WorkoutSessionPayload {
  const factory WorkoutSessionPayload({
    @JsonKey(name: 'schema_version') @Default('1.0') String schemaVersion,
    @JsonKey(name: 'exercises') @Default([]) List<WorkoutExercise> exercises,
    @JsonKey(name: 'muscle_distribution') @Default({}) Map<MajorMuscleGroup, double> muscleDistribution,
    @JsonKey(name: 'notes') String? notes,
  }) = _WorkoutSessionPayload;

  factory WorkoutSessionPayload.fromJson(Map<String, dynamic> json) => _$WorkoutSessionPayloadFromJson(json);
}

@freezed
class WorkoutSession with _$WorkoutSession {
  const WorkoutSession._();
  const factory WorkoutSession({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'routine_id') String? routineId,
    @JsonKey(name: 'program_name') String? programName,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'start_time') required int startTime,
    @JsonKey(name: 'end_time') int? endTime,
    @JsonKey(name: 'duration_seconds') @Default(0) int totalDurationSeconds,
    @JsonKey(name: 'total_calories') @Default(0) int totalCaloriesBurned,
    @JsonKey(name: 'total_volume') @Default(0.0) double totalVolume,
    @JsonKey(name: 'total_sets') @Default(0) int totalSets,
    @JsonKey(name: 'rpe') int? rpe,
    @JsonKey(name: 'xp_earned') @Default(0) int xpEarned,
    @JsonKey(name: 'pr_count') @Default(0) int prCount,
    @JsonKey(name: 'sync_status') @Default(SyncStatus.PENDING) SyncStatus syncStatus,
    @JsonKey(name: 'updated_at') required int updatedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'payload') required WorkoutSessionPayload sessionPayload,
  }) = _WorkoutSession;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);
  List<WorkoutExercise> get exercises => sessionPayload.exercises;
}

@freezed
class WorkoutProgram with _$WorkoutProgram {
  const factory WorkoutProgram({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'description') required String description,
    @JsonKey(name: 'environment') required WorkoutEnvironment environment,
    @JsonKey(name: 'difficulty') required String difficulty,
    @JsonKey(name: 'goal') @Default(WorkoutGoal.STRENGTH) WorkoutGoal goal,
    @JsonKey(name: 'routines') required List<WorkoutSession> routines,
  }) = _WorkoutProgram;

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) => _$WorkoutProgramFromJson(json);
}

@freezed
class ScheduledWorkout with _$ScheduledWorkout {
  const factory ScheduledWorkout({
    required String id,
    required String routineId,
    required String routineName,
    required int targetDateMillis,
    @Default(false) bool isCompleted,
    @JsonKey(name: 'color_hex') String? colorHex,
    @JsonKey(name: 'recurrence_group_id') String? recurrenceGroupId,
  }) = _ScheduledWorkout;

  factory ScheduledWorkout.fromJson(Map<String, dynamic> json) => _$ScheduledWorkoutFromJson(json);
}