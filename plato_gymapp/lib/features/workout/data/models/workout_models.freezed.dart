// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExerciseSet _$ExerciseSetFromJson(Map<String, dynamic> json) {
  return _ExerciseSet.fromJson(json);
}

/// @nodoc
mixin _$ExerciseSet {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'weight')
  double get weight => throw _privateConstructorUsedError;
  @JsonKey(name: 'reps')
  int get reps => throw _privateConstructorUsedError;
  @JsonKey(name: 'time_seconds')
  int get durationTimeSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'distance_km')
  double get distanceInKm => throw _privateConstructorUsedError;
  @JsonKey(name: 'steps')
  int get steps => throw _privateConstructorUsedError;
  @JsonKey(name: 'rpe')
  int? get rpe => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_completed')
  bool get isCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'type')
  SetType get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'rest_time_seconds')
  int get restTimeSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_personal_record')
  bool get isPersonalRecord => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_weight_pr')
  bool get isWeightPR => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_volume_pr')
  bool get isVolumePR => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_1rm_pr')
  bool get is1RmPR => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_time_pr')
  bool get isTimePR => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_distance_pr')
  bool get isDistancePR => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_steps_pr')
  bool get isStepsPR => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_reps_pr')
  bool get isRepsPR => throw _privateConstructorUsedError;
  @JsonKey(name: 'timer_mode')
  TimerMode get timerMode => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExerciseSetCopyWith<ExerciseSet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseSetCopyWith<$Res> {
  factory $ExerciseSetCopyWith(
          ExerciseSet value, $Res Function(ExerciseSet) then) =
      _$ExerciseSetCopyWithImpl<$Res, ExerciseSet>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'weight') double weight,
      @JsonKey(name: 'reps') int reps,
      @JsonKey(name: 'time_seconds') int durationTimeSeconds,
      @JsonKey(name: 'distance_km') double distanceInKm,
      @JsonKey(name: 'steps') int steps,
      @JsonKey(name: 'rpe') int? rpe,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'type') SetType type,
      @JsonKey(name: 'rest_time_seconds') int restTimeSeconds,
      @JsonKey(name: 'is_personal_record') bool isPersonalRecord,
      @JsonKey(name: 'is_weight_pr') bool isWeightPR,
      @JsonKey(name: 'is_volume_pr') bool isVolumePR,
      @JsonKey(name: 'is_1rm_pr') bool is1RmPR,
      @JsonKey(name: 'is_time_pr') bool isTimePR,
      @JsonKey(name: 'is_distance_pr') bool isDistancePR,
      @JsonKey(name: 'is_steps_pr') bool isStepsPR,
      @JsonKey(name: 'is_reps_pr') bool isRepsPR,
      @JsonKey(name: 'timer_mode') TimerMode timerMode});
}

/// @nodoc
class _$ExerciseSetCopyWithImpl<$Res, $Val extends ExerciseSet>
    implements $ExerciseSetCopyWith<$Res> {
  _$ExerciseSetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? weight = null,
    Object? reps = null,
    Object? durationTimeSeconds = null,
    Object? distanceInKm = null,
    Object? steps = null,
    Object? rpe = freezed,
    Object? isCompleted = null,
    Object? type = null,
    Object? restTimeSeconds = null,
    Object? isPersonalRecord = null,
    Object? isWeightPR = null,
    Object? isVolumePR = null,
    Object? is1RmPR = null,
    Object? isTimePR = null,
    Object? isDistancePR = null,
    Object? isStepsPR = null,
    Object? isRepsPR = null,
    Object? timerMode = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      reps: null == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      durationTimeSeconds: null == durationTimeSeconds
          ? _value.durationTimeSeconds
          : durationTimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      distanceInKm: null == distanceInKm
          ? _value.distanceInKm
          : distanceInKm // ignore: cast_nullable_to_non_nullable
              as double,
      steps: null == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as int,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SetType,
      restTimeSeconds: null == restTimeSeconds
          ? _value.restTimeSeconds
          : restTimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      isPersonalRecord: null == isPersonalRecord
          ? _value.isPersonalRecord
          : isPersonalRecord // ignore: cast_nullable_to_non_nullable
              as bool,
      isWeightPR: null == isWeightPR
          ? _value.isWeightPR
          : isWeightPR // ignore: cast_nullable_to_non_nullable
              as bool,
      isVolumePR: null == isVolumePR
          ? _value.isVolumePR
          : isVolumePR // ignore: cast_nullable_to_non_nullable
              as bool,
      is1RmPR: null == is1RmPR
          ? _value.is1RmPR
          : is1RmPR // ignore: cast_nullable_to_non_nullable
              as bool,
      isTimePR: null == isTimePR
          ? _value.isTimePR
          : isTimePR // ignore: cast_nullable_to_non_nullable
              as bool,
      isDistancePR: null == isDistancePR
          ? _value.isDistancePR
          : isDistancePR // ignore: cast_nullable_to_non_nullable
              as bool,
      isStepsPR: null == isStepsPR
          ? _value.isStepsPR
          : isStepsPR // ignore: cast_nullable_to_non_nullable
              as bool,
      isRepsPR: null == isRepsPR
          ? _value.isRepsPR
          : isRepsPR // ignore: cast_nullable_to_non_nullable
              as bool,
      timerMode: null == timerMode
          ? _value.timerMode
          : timerMode // ignore: cast_nullable_to_non_nullable
              as TimerMode,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseSetImplCopyWith<$Res>
    implements $ExerciseSetCopyWith<$Res> {
  factory _$$ExerciseSetImplCopyWith(
          _$ExerciseSetImpl value, $Res Function(_$ExerciseSetImpl) then) =
      __$$ExerciseSetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'weight') double weight,
      @JsonKey(name: 'reps') int reps,
      @JsonKey(name: 'time_seconds') int durationTimeSeconds,
      @JsonKey(name: 'distance_km') double distanceInKm,
      @JsonKey(name: 'steps') int steps,
      @JsonKey(name: 'rpe') int? rpe,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'type') SetType type,
      @JsonKey(name: 'rest_time_seconds') int restTimeSeconds,
      @JsonKey(name: 'is_personal_record') bool isPersonalRecord,
      @JsonKey(name: 'is_weight_pr') bool isWeightPR,
      @JsonKey(name: 'is_volume_pr') bool isVolumePR,
      @JsonKey(name: 'is_1rm_pr') bool is1RmPR,
      @JsonKey(name: 'is_time_pr') bool isTimePR,
      @JsonKey(name: 'is_distance_pr') bool isDistancePR,
      @JsonKey(name: 'is_steps_pr') bool isStepsPR,
      @JsonKey(name: 'is_reps_pr') bool isRepsPR,
      @JsonKey(name: 'timer_mode') TimerMode timerMode});
}

/// @nodoc
class __$$ExerciseSetImplCopyWithImpl<$Res>
    extends _$ExerciseSetCopyWithImpl<$Res, _$ExerciseSetImpl>
    implements _$$ExerciseSetImplCopyWith<$Res> {
  __$$ExerciseSetImplCopyWithImpl(
      _$ExerciseSetImpl _value, $Res Function(_$ExerciseSetImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? weight = null,
    Object? reps = null,
    Object? durationTimeSeconds = null,
    Object? distanceInKm = null,
    Object? steps = null,
    Object? rpe = freezed,
    Object? isCompleted = null,
    Object? type = null,
    Object? restTimeSeconds = null,
    Object? isPersonalRecord = null,
    Object? isWeightPR = null,
    Object? isVolumePR = null,
    Object? is1RmPR = null,
    Object? isTimePR = null,
    Object? isDistancePR = null,
    Object? isStepsPR = null,
    Object? isRepsPR = null,
    Object? timerMode = null,
  }) {
    return _then(_$ExerciseSetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      reps: null == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      durationTimeSeconds: null == durationTimeSeconds
          ? _value.durationTimeSeconds
          : durationTimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      distanceInKm: null == distanceInKm
          ? _value.distanceInKm
          : distanceInKm // ignore: cast_nullable_to_non_nullable
              as double,
      steps: null == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as int,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SetType,
      restTimeSeconds: null == restTimeSeconds
          ? _value.restTimeSeconds
          : restTimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      isPersonalRecord: null == isPersonalRecord
          ? _value.isPersonalRecord
          : isPersonalRecord // ignore: cast_nullable_to_non_nullable
              as bool,
      isWeightPR: null == isWeightPR
          ? _value.isWeightPR
          : isWeightPR // ignore: cast_nullable_to_non_nullable
              as bool,
      isVolumePR: null == isVolumePR
          ? _value.isVolumePR
          : isVolumePR // ignore: cast_nullable_to_non_nullable
              as bool,
      is1RmPR: null == is1RmPR
          ? _value.is1RmPR
          : is1RmPR // ignore: cast_nullable_to_non_nullable
              as bool,
      isTimePR: null == isTimePR
          ? _value.isTimePR
          : isTimePR // ignore: cast_nullable_to_non_nullable
              as bool,
      isDistancePR: null == isDistancePR
          ? _value.isDistancePR
          : isDistancePR // ignore: cast_nullable_to_non_nullable
              as bool,
      isStepsPR: null == isStepsPR
          ? _value.isStepsPR
          : isStepsPR // ignore: cast_nullable_to_non_nullable
              as bool,
      isRepsPR: null == isRepsPR
          ? _value.isRepsPR
          : isRepsPR // ignore: cast_nullable_to_non_nullable
              as bool,
      timerMode: null == timerMode
          ? _value.timerMode
          : timerMode // ignore: cast_nullable_to_non_nullable
              as TimerMode,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseSetImpl implements _ExerciseSet {
  const _$ExerciseSetImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'weight') this.weight = 0,
      @JsonKey(name: 'reps') this.reps = 0,
      @JsonKey(name: 'time_seconds') this.durationTimeSeconds = 0,
      @JsonKey(name: 'distance_km') this.distanceInKm = 0.0,
      @JsonKey(name: 'steps') this.steps = 0,
      @JsonKey(name: 'rpe') this.rpe,
      @JsonKey(name: 'is_completed') this.isCompleted = false,
      @JsonKey(name: 'type') this.type = SetType.NORMAL,
      @JsonKey(name: 'rest_time_seconds') this.restTimeSeconds = 90,
      @JsonKey(name: 'is_personal_record') this.isPersonalRecord = false,
      @JsonKey(name: 'is_weight_pr') this.isWeightPR = false,
      @JsonKey(name: 'is_volume_pr') this.isVolumePR = false,
      @JsonKey(name: 'is_1rm_pr') this.is1RmPR = false,
      @JsonKey(name: 'is_time_pr') this.isTimePR = false,
      @JsonKey(name: 'is_distance_pr') this.isDistancePR = false,
      @JsonKey(name: 'is_steps_pr') this.isStepsPR = false,
      @JsonKey(name: 'is_reps_pr') this.isRepsPR = false,
      @JsonKey(name: 'timer_mode') this.timerMode = TimerMode.STOPWATCH});

  factory _$ExerciseSetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseSetImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'weight')
  final double weight;
  @override
  @JsonKey(name: 'reps')
  final int reps;
  @override
  @JsonKey(name: 'time_seconds')
  final int durationTimeSeconds;
  @override
  @JsonKey(name: 'distance_km')
  final double distanceInKm;
  @override
  @JsonKey(name: 'steps')
  final int steps;
  @override
  @JsonKey(name: 'rpe')
  final int? rpe;
  @override
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @override
  @JsonKey(name: 'type')
  final SetType type;
  @override
  @JsonKey(name: 'rest_time_seconds')
  final int restTimeSeconds;
  @override
  @JsonKey(name: 'is_personal_record')
  final bool isPersonalRecord;
  @override
  @JsonKey(name: 'is_weight_pr')
  final bool isWeightPR;
  @override
  @JsonKey(name: 'is_volume_pr')
  final bool isVolumePR;
  @override
  @JsonKey(name: 'is_1rm_pr')
  final bool is1RmPR;
  @override
  @JsonKey(name: 'is_time_pr')
  final bool isTimePR;
  @override
  @JsonKey(name: 'is_distance_pr')
  final bool isDistancePR;
  @override
  @JsonKey(name: 'is_steps_pr')
  final bool isStepsPR;
  @override
  @JsonKey(name: 'is_reps_pr')
  final bool isRepsPR;
  @override
  @JsonKey(name: 'timer_mode')
  final TimerMode timerMode;

  @override
  String toString() {
    return 'ExerciseSet(id: $id, weight: $weight, reps: $reps, durationTimeSeconds: $durationTimeSeconds, distanceInKm: $distanceInKm, steps: $steps, rpe: $rpe, isCompleted: $isCompleted, type: $type, restTimeSeconds: $restTimeSeconds, isPersonalRecord: $isPersonalRecord, isWeightPR: $isWeightPR, isVolumePR: $isVolumePR, is1RmPR: $is1RmPR, isTimePR: $isTimePR, isDistancePR: $isDistancePR, isStepsPR: $isStepsPR, isRepsPR: $isRepsPR, timerMode: $timerMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseSetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.durationTimeSeconds, durationTimeSeconds) ||
                other.durationTimeSeconds == durationTimeSeconds) &&
            (identical(other.distanceInKm, distanceInKm) ||
                other.distanceInKm == distanceInKm) &&
            (identical(other.steps, steps) || other.steps == steps) &&
            (identical(other.rpe, rpe) || other.rpe == rpe) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.restTimeSeconds, restTimeSeconds) ||
                other.restTimeSeconds == restTimeSeconds) &&
            (identical(other.isPersonalRecord, isPersonalRecord) ||
                other.isPersonalRecord == isPersonalRecord) &&
            (identical(other.isWeightPR, isWeightPR) ||
                other.isWeightPR == isWeightPR) &&
            (identical(other.isVolumePR, isVolumePR) ||
                other.isVolumePR == isVolumePR) &&
            (identical(other.is1RmPR, is1RmPR) || other.is1RmPR == is1RmPR) &&
            (identical(other.isTimePR, isTimePR) ||
                other.isTimePR == isTimePR) &&
            (identical(other.isDistancePR, isDistancePR) ||
                other.isDistancePR == isDistancePR) &&
            (identical(other.isStepsPR, isStepsPR) ||
                other.isStepsPR == isStepsPR) &&
            (identical(other.isRepsPR, isRepsPR) ||
                other.isRepsPR == isRepsPR) &&
            (identical(other.timerMode, timerMode) ||
                other.timerMode == timerMode));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        weight,
        reps,
        durationTimeSeconds,
        distanceInKm,
        steps,
        rpe,
        isCompleted,
        type,
        restTimeSeconds,
        isPersonalRecord,
        isWeightPR,
        isVolumePR,
        is1RmPR,
        isTimePR,
        isDistancePR,
        isStepsPR,
        isRepsPR,
        timerMode
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseSetImplCopyWith<_$ExerciseSetImpl> get copyWith =>
      __$$ExerciseSetImplCopyWithImpl<_$ExerciseSetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseSetImplToJson(
      this,
    );
  }
}

abstract class _ExerciseSet implements ExerciseSet {
  const factory _ExerciseSet(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'weight') final double weight,
          @JsonKey(name: 'reps') final int reps,
          @JsonKey(name: 'time_seconds') final int durationTimeSeconds,
          @JsonKey(name: 'distance_km') final double distanceInKm,
          @JsonKey(name: 'steps') final int steps,
          @JsonKey(name: 'rpe') final int? rpe,
          @JsonKey(name: 'is_completed') final bool isCompleted,
          @JsonKey(name: 'type') final SetType type,
          @JsonKey(name: 'rest_time_seconds') final int restTimeSeconds,
          @JsonKey(name: 'is_personal_record') final bool isPersonalRecord,
          @JsonKey(name: 'is_weight_pr') final bool isWeightPR,
          @JsonKey(name: 'is_volume_pr') final bool isVolumePR,
          @JsonKey(name: 'is_1rm_pr') final bool is1RmPR,
          @JsonKey(name: 'is_time_pr') final bool isTimePR,
          @JsonKey(name: 'is_distance_pr') final bool isDistancePR,
          @JsonKey(name: 'is_steps_pr') final bool isStepsPR,
          @JsonKey(name: 'is_reps_pr') final bool isRepsPR,
          @JsonKey(name: 'timer_mode') final TimerMode timerMode}) =
      _$ExerciseSetImpl;

  factory _ExerciseSet.fromJson(Map<String, dynamic> json) =
      _$ExerciseSetImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'weight')
  double get weight;
  @override
  @JsonKey(name: 'reps')
  int get reps;
  @override
  @JsonKey(name: 'time_seconds')
  int get durationTimeSeconds;
  @override
  @JsonKey(name: 'distance_km')
  double get distanceInKm;
  @override
  @JsonKey(name: 'steps')
  int get steps;
  @override
  @JsonKey(name: 'rpe')
  int? get rpe;
  @override
  @JsonKey(name: 'is_completed')
  bool get isCompleted;
  @override
  @JsonKey(name: 'type')
  SetType get type;
  @override
  @JsonKey(name: 'rest_time_seconds')
  int get restTimeSeconds;
  @override
  @JsonKey(name: 'is_personal_record')
  bool get isPersonalRecord;
  @override
  @JsonKey(name: 'is_weight_pr')
  bool get isWeightPR;
  @override
  @JsonKey(name: 'is_volume_pr')
  bool get isVolumePR;
  @override
  @JsonKey(name: 'is_1rm_pr')
  bool get is1RmPR;
  @override
  @JsonKey(name: 'is_time_pr')
  bool get isTimePR;
  @override
  @JsonKey(name: 'is_distance_pr')
  bool get isDistancePR;
  @override
  @JsonKey(name: 'is_steps_pr')
  bool get isStepsPR;
  @override
  @JsonKey(name: 'is_reps_pr')
  bool get isRepsPR;
  @override
  @JsonKey(name: 'timer_mode')
  TimerMode get timerMode;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseSetImplCopyWith<_$ExerciseSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutExercise _$WorkoutExerciseFromJson(Map<String, dynamic> json) {
  return _WorkoutExercise.fromJson(json);
}

/// @nodoc
mixin _$WorkoutExercise {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'superset_id')
  String? get supersetId => throw _privateConstructorUsedError;
  @JsonKey(name: 'exercise')
  Exercise get exercise => throw _privateConstructorUsedError;
  @JsonKey(name: 'rest_time_seconds')
  int get restTimeSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'note')
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'sets')
  List<ExerciseSet> get sets => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<ExerciseSet> get previousSets => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutExerciseCopyWith<WorkoutExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutExerciseCopyWith<$Res> {
  factory $WorkoutExerciseCopyWith(
          WorkoutExercise value, $Res Function(WorkoutExercise) then) =
      _$WorkoutExerciseCopyWithImpl<$Res, WorkoutExercise>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'superset_id') String? supersetId,
      @JsonKey(name: 'exercise') Exercise exercise,
      @JsonKey(name: 'rest_time_seconds') int restTimeSeconds,
      @JsonKey(name: 'note') String? note,
      @JsonKey(name: 'sets') List<ExerciseSet> sets,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<ExerciseSet> previousSets});
}

/// @nodoc
class _$WorkoutExerciseCopyWithImpl<$Res, $Val extends WorkoutExercise>
    implements $WorkoutExerciseCopyWith<$Res> {
  _$WorkoutExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? supersetId = freezed,
    Object? exercise = null,
    Object? restTimeSeconds = null,
    Object? note = freezed,
    Object? sets = null,
    Object? previousSets = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      supersetId: freezed == supersetId
          ? _value.supersetId
          : supersetId // ignore: cast_nullable_to_non_nullable
              as String?,
      exercise: null == exercise
          ? _value.exercise
          : exercise // ignore: cast_nullable_to_non_nullable
              as Exercise,
      restTimeSeconds: null == restTimeSeconds
          ? _value.restTimeSeconds
          : restTimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<ExerciseSet>,
      previousSets: null == previousSets
          ? _value.previousSets
          : previousSets // ignore: cast_nullable_to_non_nullable
              as List<ExerciseSet>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutExerciseImplCopyWith<$Res>
    implements $WorkoutExerciseCopyWith<$Res> {
  factory _$$WorkoutExerciseImplCopyWith(_$WorkoutExerciseImpl value,
          $Res Function(_$WorkoutExerciseImpl) then) =
      __$$WorkoutExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'superset_id') String? supersetId,
      @JsonKey(name: 'exercise') Exercise exercise,
      @JsonKey(name: 'rest_time_seconds') int restTimeSeconds,
      @JsonKey(name: 'note') String? note,
      @JsonKey(name: 'sets') List<ExerciseSet> sets,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<ExerciseSet> previousSets});
}

/// @nodoc
class __$$WorkoutExerciseImplCopyWithImpl<$Res>
    extends _$WorkoutExerciseCopyWithImpl<$Res, _$WorkoutExerciseImpl>
    implements _$$WorkoutExerciseImplCopyWith<$Res> {
  __$$WorkoutExerciseImplCopyWithImpl(
      _$WorkoutExerciseImpl _value, $Res Function(_$WorkoutExerciseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? supersetId = freezed,
    Object? exercise = null,
    Object? restTimeSeconds = null,
    Object? note = freezed,
    Object? sets = null,
    Object? previousSets = null,
  }) {
    return _then(_$WorkoutExerciseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      supersetId: freezed == supersetId
          ? _value.supersetId
          : supersetId // ignore: cast_nullable_to_non_nullable
              as String?,
      exercise: null == exercise
          ? _value.exercise
          : exercise // ignore: cast_nullable_to_non_nullable
              as Exercise,
      restTimeSeconds: null == restTimeSeconds
          ? _value.restTimeSeconds
          : restTimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      sets: null == sets
          ? _value._sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<ExerciseSet>,
      previousSets: null == previousSets
          ? _value._previousSets
          : previousSets // ignore: cast_nullable_to_non_nullable
              as List<ExerciseSet>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutExerciseImpl extends _WorkoutExercise {
  const _$WorkoutExerciseImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'superset_id') this.supersetId,
      @JsonKey(name: 'exercise') required this.exercise,
      @JsonKey(name: 'rest_time_seconds') this.restTimeSeconds = 90,
      @JsonKey(name: 'note') this.note,
      @JsonKey(name: 'sets') final List<ExerciseSet> sets = const [],
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<ExerciseSet> previousSets = const []})
      : _sets = sets,
        _previousSets = previousSets,
        super._();

  factory _$WorkoutExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutExerciseImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'superset_id')
  final String? supersetId;
  @override
  @JsonKey(name: 'exercise')
  final Exercise exercise;
  @override
  @JsonKey(name: 'rest_time_seconds')
  final int restTimeSeconds;
  @override
  @JsonKey(name: 'note')
  final String? note;
  final List<ExerciseSet> _sets;
  @override
  @JsonKey(name: 'sets')
  List<ExerciseSet> get sets {
    if (_sets is EqualUnmodifiableListView) return _sets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sets);
  }

  final List<ExerciseSet> _previousSets;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<ExerciseSet> get previousSets {
    if (_previousSets is EqualUnmodifiableListView) return _previousSets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_previousSets);
  }

  @override
  String toString() {
    return 'WorkoutExercise(id: $id, supersetId: $supersetId, exercise: $exercise, restTimeSeconds: $restTimeSeconds, note: $note, sets: $sets, previousSets: $previousSets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutExerciseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.supersetId, supersetId) ||
                other.supersetId == supersetId) &&
            (identical(other.exercise, exercise) ||
                other.exercise == exercise) &&
            (identical(other.restTimeSeconds, restTimeSeconds) ||
                other.restTimeSeconds == restTimeSeconds) &&
            (identical(other.note, note) || other.note == note) &&
            const DeepCollectionEquality().equals(other._sets, _sets) &&
            const DeepCollectionEquality()
                .equals(other._previousSets, _previousSets));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      supersetId,
      exercise,
      restTimeSeconds,
      note,
      const DeepCollectionEquality().hash(_sets),
      const DeepCollectionEquality().hash(_previousSets));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutExerciseImplCopyWith<_$WorkoutExerciseImpl> get copyWith =>
      __$$WorkoutExerciseImplCopyWithImpl<_$WorkoutExerciseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutExerciseImplToJson(
      this,
    );
  }
}

abstract class _WorkoutExercise extends WorkoutExercise {
  const factory _WorkoutExercise(
      {@JsonKey(name: 'id') required final String id,
      @JsonKey(name: 'superset_id') final String? supersetId,
      @JsonKey(name: 'exercise') required final Exercise exercise,
      @JsonKey(name: 'rest_time_seconds') final int restTimeSeconds,
      @JsonKey(name: 'note') final String? note,
      @JsonKey(name: 'sets') final List<ExerciseSet> sets,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<ExerciseSet> previousSets}) = _$WorkoutExerciseImpl;
  const _WorkoutExercise._() : super._();

  factory _WorkoutExercise.fromJson(Map<String, dynamic> json) =
      _$WorkoutExerciseImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'superset_id')
  String? get supersetId;
  @override
  @JsonKey(name: 'exercise')
  Exercise get exercise;
  @override
  @JsonKey(name: 'rest_time_seconds')
  int get restTimeSeconds;
  @override
  @JsonKey(name: 'note')
  String? get note;
  @override
  @JsonKey(name: 'sets')
  List<ExerciseSet> get sets;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<ExerciseSet> get previousSets;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutExerciseImplCopyWith<_$WorkoutExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutSessionPayload _$WorkoutSessionPayloadFromJson(
    Map<String, dynamic> json) {
  return _WorkoutSessionPayload.fromJson(json);
}

/// @nodoc
mixin _$WorkoutSessionPayload {
  @JsonKey(name: 'schema_version')
  String get schemaVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'exercises')
  List<WorkoutExercise> get exercises => throw _privateConstructorUsedError;
  @JsonKey(name: 'muscle_distribution')
  Map<MajorMuscleGroup, double> get muscleDistribution =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'notes')
  String? get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutSessionPayloadCopyWith<WorkoutSessionPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutSessionPayloadCopyWith<$Res> {
  factory $WorkoutSessionPayloadCopyWith(WorkoutSessionPayload value,
          $Res Function(WorkoutSessionPayload) then) =
      _$WorkoutSessionPayloadCopyWithImpl<$Res, WorkoutSessionPayload>;
  @useResult
  $Res call(
      {@JsonKey(name: 'schema_version') String schemaVersion,
      @JsonKey(name: 'exercises') List<WorkoutExercise> exercises,
      @JsonKey(name: 'muscle_distribution')
      Map<MajorMuscleGroup, double> muscleDistribution,
      @JsonKey(name: 'notes') String? notes});
}

/// @nodoc
class _$WorkoutSessionPayloadCopyWithImpl<$Res,
        $Val extends WorkoutSessionPayload>
    implements $WorkoutSessionPayloadCopyWith<$Res> {
  _$WorkoutSessionPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemaVersion = null,
    Object? exercises = null,
    Object? muscleDistribution = null,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<WorkoutExercise>,
      muscleDistribution: null == muscleDistribution
          ? _value.muscleDistribution
          : muscleDistribution // ignore: cast_nullable_to_non_nullable
              as Map<MajorMuscleGroup, double>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutSessionPayloadImplCopyWith<$Res>
    implements $WorkoutSessionPayloadCopyWith<$Res> {
  factory _$$WorkoutSessionPayloadImplCopyWith(
          _$WorkoutSessionPayloadImpl value,
          $Res Function(_$WorkoutSessionPayloadImpl) then) =
      __$$WorkoutSessionPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'schema_version') String schemaVersion,
      @JsonKey(name: 'exercises') List<WorkoutExercise> exercises,
      @JsonKey(name: 'muscle_distribution')
      Map<MajorMuscleGroup, double> muscleDistribution,
      @JsonKey(name: 'notes') String? notes});
}

/// @nodoc
class __$$WorkoutSessionPayloadImplCopyWithImpl<$Res>
    extends _$WorkoutSessionPayloadCopyWithImpl<$Res,
        _$WorkoutSessionPayloadImpl>
    implements _$$WorkoutSessionPayloadImplCopyWith<$Res> {
  __$$WorkoutSessionPayloadImplCopyWithImpl(_$WorkoutSessionPayloadImpl _value,
      $Res Function(_$WorkoutSessionPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemaVersion = null,
    Object? exercises = null,
    Object? muscleDistribution = null,
    Object? notes = freezed,
  }) {
    return _then(_$WorkoutSessionPayloadImpl(
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<WorkoutExercise>,
      muscleDistribution: null == muscleDistribution
          ? _value._muscleDistribution
          : muscleDistribution // ignore: cast_nullable_to_non_nullable
              as Map<MajorMuscleGroup, double>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutSessionPayloadImpl implements _WorkoutSessionPayload {
  const _$WorkoutSessionPayloadImpl(
      {@JsonKey(name: 'schema_version') this.schemaVersion = '1.0',
      @JsonKey(name: 'exercises')
      final List<WorkoutExercise> exercises = const [],
      @JsonKey(name: 'muscle_distribution')
      final Map<MajorMuscleGroup, double> muscleDistribution = const {},
      @JsonKey(name: 'notes') this.notes})
      : _exercises = exercises,
        _muscleDistribution = muscleDistribution;

  factory _$WorkoutSessionPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutSessionPayloadImplFromJson(json);

  @override
  @JsonKey(name: 'schema_version')
  final String schemaVersion;
  final List<WorkoutExercise> _exercises;
  @override
  @JsonKey(name: 'exercises')
  List<WorkoutExercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  final Map<MajorMuscleGroup, double> _muscleDistribution;
  @override
  @JsonKey(name: 'muscle_distribution')
  Map<MajorMuscleGroup, double> get muscleDistribution {
    if (_muscleDistribution is EqualUnmodifiableMapView)
      return _muscleDistribution;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_muscleDistribution);
  }

  @override
  @JsonKey(name: 'notes')
  final String? notes;

  @override
  String toString() {
    return 'WorkoutSessionPayload(schemaVersion: $schemaVersion, exercises: $exercises, muscleDistribution: $muscleDistribution, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutSessionPayloadImpl &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises) &&
            const DeepCollectionEquality()
                .equals(other._muscleDistribution, _muscleDistribution) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      schemaVersion,
      const DeepCollectionEquality().hash(_exercises),
      const DeepCollectionEquality().hash(_muscleDistribution),
      notes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutSessionPayloadImplCopyWith<_$WorkoutSessionPayloadImpl>
      get copyWith => __$$WorkoutSessionPayloadImplCopyWithImpl<
          _$WorkoutSessionPayloadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutSessionPayloadImplToJson(
      this,
    );
  }
}

abstract class _WorkoutSessionPayload implements WorkoutSessionPayload {
  const factory _WorkoutSessionPayload(
          {@JsonKey(name: 'schema_version') final String schemaVersion,
          @JsonKey(name: 'exercises') final List<WorkoutExercise> exercises,
          @JsonKey(name: 'muscle_distribution')
          final Map<MajorMuscleGroup, double> muscleDistribution,
          @JsonKey(name: 'notes') final String? notes}) =
      _$WorkoutSessionPayloadImpl;

  factory _WorkoutSessionPayload.fromJson(Map<String, dynamic> json) =
      _$WorkoutSessionPayloadImpl.fromJson;

  @override
  @JsonKey(name: 'schema_version')
  String get schemaVersion;
  @override
  @JsonKey(name: 'exercises')
  List<WorkoutExercise> get exercises;
  @override
  @JsonKey(name: 'muscle_distribution')
  Map<MajorMuscleGroup, double> get muscleDistribution;
  @override
  @JsonKey(name: 'notes')
  String? get notes;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutSessionPayloadImplCopyWith<_$WorkoutSessionPayloadImpl>
      get copyWith => throw _privateConstructorUsedError;
}

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) {
  return _WorkoutSession.fromJson(json);
}

/// @nodoc
mixin _$WorkoutSession {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'routine_id')
  String? get routineId => throw _privateConstructorUsedError;
  @JsonKey(name: 'program_name')
  String? get programName => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  int get startTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_time')
  int? get endTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_seconds')
  int get totalDurationSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_calories')
  int get totalCaloriesBurned => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_volume')
  double get totalVolume => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_sets')
  int get totalSets => throw _privateConstructorUsedError;
  @JsonKey(name: 'rpe')
  int? get rpe => throw _privateConstructorUsedError;
  @JsonKey(name: 'xp_earned')
  int get xpEarned => throw _privateConstructorUsedError;
  @JsonKey(name: 'pr_count')
  int get prCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'sync_status')
  SyncStatus get syncStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  int get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_deleted')
  bool get isDeleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'payload')
  WorkoutSessionPayload get sessionPayload =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutSessionCopyWith<WorkoutSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutSessionCopyWith<$Res> {
  factory $WorkoutSessionCopyWith(
          WorkoutSession value, $Res Function(WorkoutSession) then) =
      _$WorkoutSessionCopyWithImpl<$Res, WorkoutSession>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'routine_id') String? routineId,
      @JsonKey(name: 'program_name') String? programName,
      @JsonKey(name: 'name') String name,
      @JsonKey(name: 'start_time') int startTime,
      @JsonKey(name: 'end_time') int? endTime,
      @JsonKey(name: 'duration_seconds') int totalDurationSeconds,
      @JsonKey(name: 'total_calories') int totalCaloriesBurned,
      @JsonKey(name: 'total_volume') double totalVolume,
      @JsonKey(name: 'total_sets') int totalSets,
      @JsonKey(name: 'rpe') int? rpe,
      @JsonKey(name: 'xp_earned') int xpEarned,
      @JsonKey(name: 'pr_count') int prCount,
      @JsonKey(name: 'sync_status') SyncStatus syncStatus,
      @JsonKey(name: 'updated_at') int updatedAt,
      @JsonKey(name: 'is_deleted') bool isDeleted,
      @JsonKey(name: 'payload') WorkoutSessionPayload sessionPayload});

  $WorkoutSessionPayloadCopyWith<$Res> get sessionPayload;
}

/// @nodoc
class _$WorkoutSessionCopyWithImpl<$Res, $Val extends WorkoutSession>
    implements $WorkoutSessionCopyWith<$Res> {
  _$WorkoutSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routineId = freezed,
    Object? programName = freezed,
    Object? name = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? totalDurationSeconds = null,
    Object? totalCaloriesBurned = null,
    Object? totalVolume = null,
    Object? totalSets = null,
    Object? rpe = freezed,
    Object? xpEarned = null,
    Object? prCount = null,
    Object? syncStatus = null,
    Object? updatedAt = null,
    Object? isDeleted = null,
    Object? sessionPayload = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routineId: freezed == routineId
          ? _value.routineId
          : routineId // ignore: cast_nullable_to_non_nullable
              as String?,
      programName: freezed == programName
          ? _value.programName
          : programName // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as int,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as int?,
      totalDurationSeconds: null == totalDurationSeconds
          ? _value.totalDurationSeconds
          : totalDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      totalCaloriesBurned: null == totalCaloriesBurned
          ? _value.totalCaloriesBurned
          : totalCaloriesBurned // ignore: cast_nullable_to_non_nullable
              as int,
      totalVolume: null == totalVolume
          ? _value.totalVolume
          : totalVolume // ignore: cast_nullable_to_non_nullable
              as double,
      totalSets: null == totalSets
          ? _value.totalSets
          : totalSets // ignore: cast_nullable_to_non_nullable
              as int,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int?,
      xpEarned: null == xpEarned
          ? _value.xpEarned
          : xpEarned // ignore: cast_nullable_to_non_nullable
              as int,
      prCount: null == prCount
          ? _value.prCount
          : prCount // ignore: cast_nullable_to_non_nullable
              as int,
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      sessionPayload: null == sessionPayload
          ? _value.sessionPayload
          : sessionPayload // ignore: cast_nullable_to_non_nullable
              as WorkoutSessionPayload,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $WorkoutSessionPayloadCopyWith<$Res> get sessionPayload {
    return $WorkoutSessionPayloadCopyWith<$Res>(_value.sessionPayload, (value) {
      return _then(_value.copyWith(sessionPayload: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WorkoutSessionImplCopyWith<$Res>
    implements $WorkoutSessionCopyWith<$Res> {
  factory _$$WorkoutSessionImplCopyWith(_$WorkoutSessionImpl value,
          $Res Function(_$WorkoutSessionImpl) then) =
      __$$WorkoutSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'routine_id') String? routineId,
      @JsonKey(name: 'program_name') String? programName,
      @JsonKey(name: 'name') String name,
      @JsonKey(name: 'start_time') int startTime,
      @JsonKey(name: 'end_time') int? endTime,
      @JsonKey(name: 'duration_seconds') int totalDurationSeconds,
      @JsonKey(name: 'total_calories') int totalCaloriesBurned,
      @JsonKey(name: 'total_volume') double totalVolume,
      @JsonKey(name: 'total_sets') int totalSets,
      @JsonKey(name: 'rpe') int? rpe,
      @JsonKey(name: 'xp_earned') int xpEarned,
      @JsonKey(name: 'pr_count') int prCount,
      @JsonKey(name: 'sync_status') SyncStatus syncStatus,
      @JsonKey(name: 'updated_at') int updatedAt,
      @JsonKey(name: 'is_deleted') bool isDeleted,
      @JsonKey(name: 'payload') WorkoutSessionPayload sessionPayload});

  @override
  $WorkoutSessionPayloadCopyWith<$Res> get sessionPayload;
}

/// @nodoc
class __$$WorkoutSessionImplCopyWithImpl<$Res>
    extends _$WorkoutSessionCopyWithImpl<$Res, _$WorkoutSessionImpl>
    implements _$$WorkoutSessionImplCopyWith<$Res> {
  __$$WorkoutSessionImplCopyWithImpl(
      _$WorkoutSessionImpl _value, $Res Function(_$WorkoutSessionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routineId = freezed,
    Object? programName = freezed,
    Object? name = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? totalDurationSeconds = null,
    Object? totalCaloriesBurned = null,
    Object? totalVolume = null,
    Object? totalSets = null,
    Object? rpe = freezed,
    Object? xpEarned = null,
    Object? prCount = null,
    Object? syncStatus = null,
    Object? updatedAt = null,
    Object? isDeleted = null,
    Object? sessionPayload = null,
  }) {
    return _then(_$WorkoutSessionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routineId: freezed == routineId
          ? _value.routineId
          : routineId // ignore: cast_nullable_to_non_nullable
              as String?,
      programName: freezed == programName
          ? _value.programName
          : programName // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as int,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as int?,
      totalDurationSeconds: null == totalDurationSeconds
          ? _value.totalDurationSeconds
          : totalDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      totalCaloriesBurned: null == totalCaloriesBurned
          ? _value.totalCaloriesBurned
          : totalCaloriesBurned // ignore: cast_nullable_to_non_nullable
              as int,
      totalVolume: null == totalVolume
          ? _value.totalVolume
          : totalVolume // ignore: cast_nullable_to_non_nullable
              as double,
      totalSets: null == totalSets
          ? _value.totalSets
          : totalSets // ignore: cast_nullable_to_non_nullable
              as int,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int?,
      xpEarned: null == xpEarned
          ? _value.xpEarned
          : xpEarned // ignore: cast_nullable_to_non_nullable
              as int,
      prCount: null == prCount
          ? _value.prCount
          : prCount // ignore: cast_nullable_to_non_nullable
              as int,
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      sessionPayload: null == sessionPayload
          ? _value.sessionPayload
          : sessionPayload // ignore: cast_nullable_to_non_nullable
              as WorkoutSessionPayload,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutSessionImpl extends _WorkoutSession {
  const _$WorkoutSessionImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'routine_id') this.routineId,
      @JsonKey(name: 'program_name') this.programName,
      @JsonKey(name: 'name') required this.name,
      @JsonKey(name: 'start_time') required this.startTime,
      @JsonKey(name: 'end_time') this.endTime,
      @JsonKey(name: 'duration_seconds') this.totalDurationSeconds = 0,
      @JsonKey(name: 'total_calories') this.totalCaloriesBurned = 0,
      @JsonKey(name: 'total_volume') this.totalVolume = 0.0,
      @JsonKey(name: 'total_sets') this.totalSets = 0,
      @JsonKey(name: 'rpe') this.rpe,
      @JsonKey(name: 'xp_earned') this.xpEarned = 0,
      @JsonKey(name: 'pr_count') this.prCount = 0,
      @JsonKey(name: 'sync_status') this.syncStatus = SyncStatus.PENDING,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'is_deleted') this.isDeleted = false,
      @JsonKey(name: 'payload') required this.sessionPayload})
      : super._();

  factory _$WorkoutSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutSessionImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'routine_id')
  final String? routineId;
  @override
  @JsonKey(name: 'program_name')
  final String? programName;
  @override
  @JsonKey(name: 'name')
  final String name;
  @override
  @JsonKey(name: 'start_time')
  final int startTime;
  @override
  @JsonKey(name: 'end_time')
  final int? endTime;
  @override
  @JsonKey(name: 'duration_seconds')
  final int totalDurationSeconds;
  @override
  @JsonKey(name: 'total_calories')
  final int totalCaloriesBurned;
  @override
  @JsonKey(name: 'total_volume')
  final double totalVolume;
  @override
  @JsonKey(name: 'total_sets')
  final int totalSets;
  @override
  @JsonKey(name: 'rpe')
  final int? rpe;
  @override
  @JsonKey(name: 'xp_earned')
  final int xpEarned;
  @override
  @JsonKey(name: 'pr_count')
  final int prCount;
  @override
  @JsonKey(name: 'sync_status')
  final SyncStatus syncStatus;
  @override
  @JsonKey(name: 'updated_at')
  final int updatedAt;
  @override
  @JsonKey(name: 'is_deleted')
  final bool isDeleted;
  @override
  @JsonKey(name: 'payload')
  final WorkoutSessionPayload sessionPayload;

  @override
  String toString() {
    return 'WorkoutSession(id: $id, routineId: $routineId, programName: $programName, name: $name, startTime: $startTime, endTime: $endTime, totalDurationSeconds: $totalDurationSeconds, totalCaloriesBurned: $totalCaloriesBurned, totalVolume: $totalVolume, totalSets: $totalSets, rpe: $rpe, xpEarned: $xpEarned, prCount: $prCount, syncStatus: $syncStatus, updatedAt: $updatedAt, isDeleted: $isDeleted, sessionPayload: $sessionPayload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.routineId, routineId) ||
                other.routineId == routineId) &&
            (identical(other.programName, programName) ||
                other.programName == programName) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.totalDurationSeconds, totalDurationSeconds) ||
                other.totalDurationSeconds == totalDurationSeconds) &&
            (identical(other.totalCaloriesBurned, totalCaloriesBurned) ||
                other.totalCaloriesBurned == totalCaloriesBurned) &&
            (identical(other.totalVolume, totalVolume) ||
                other.totalVolume == totalVolume) &&
            (identical(other.totalSets, totalSets) ||
                other.totalSets == totalSets) &&
            (identical(other.rpe, rpe) || other.rpe == rpe) &&
            (identical(other.xpEarned, xpEarned) ||
                other.xpEarned == xpEarned) &&
            (identical(other.prCount, prCount) || other.prCount == prCount) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.sessionPayload, sessionPayload) ||
                other.sessionPayload == sessionPayload));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      routineId,
      programName,
      name,
      startTime,
      endTime,
      totalDurationSeconds,
      totalCaloriesBurned,
      totalVolume,
      totalSets,
      rpe,
      xpEarned,
      prCount,
      syncStatus,
      updatedAt,
      isDeleted,
      sessionPayload);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      __$$WorkoutSessionImplCopyWithImpl<_$WorkoutSessionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutSessionImplToJson(
      this,
    );
  }
}

abstract class _WorkoutSession extends WorkoutSession {
  const factory _WorkoutSession(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'routine_id') final String? routineId,
          @JsonKey(name: 'program_name') final String? programName,
          @JsonKey(name: 'name') required final String name,
          @JsonKey(name: 'start_time') required final int startTime,
          @JsonKey(name: 'end_time') final int? endTime,
          @JsonKey(name: 'duration_seconds') final int totalDurationSeconds,
          @JsonKey(name: 'total_calories') final int totalCaloriesBurned,
          @JsonKey(name: 'total_volume') final double totalVolume,
          @JsonKey(name: 'total_sets') final int totalSets,
          @JsonKey(name: 'rpe') final int? rpe,
          @JsonKey(name: 'xp_earned') final int xpEarned,
          @JsonKey(name: 'pr_count') final int prCount,
          @JsonKey(name: 'sync_status') final SyncStatus syncStatus,
          @JsonKey(name: 'updated_at') required final int updatedAt,
          @JsonKey(name: 'is_deleted') final bool isDeleted,
          @JsonKey(name: 'payload')
          required final WorkoutSessionPayload sessionPayload}) =
      _$WorkoutSessionImpl;
  const _WorkoutSession._() : super._();

  factory _WorkoutSession.fromJson(Map<String, dynamic> json) =
      _$WorkoutSessionImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'routine_id')
  String? get routineId;
  @override
  @JsonKey(name: 'program_name')
  String? get programName;
  @override
  @JsonKey(name: 'name')
  String get name;
  @override
  @JsonKey(name: 'start_time')
  int get startTime;
  @override
  @JsonKey(name: 'end_time')
  int? get endTime;
  @override
  @JsonKey(name: 'duration_seconds')
  int get totalDurationSeconds;
  @override
  @JsonKey(name: 'total_calories')
  int get totalCaloriesBurned;
  @override
  @JsonKey(name: 'total_volume')
  double get totalVolume;
  @override
  @JsonKey(name: 'total_sets')
  int get totalSets;
  @override
  @JsonKey(name: 'rpe')
  int? get rpe;
  @override
  @JsonKey(name: 'xp_earned')
  int get xpEarned;
  @override
  @JsonKey(name: 'pr_count')
  int get prCount;
  @override
  @JsonKey(name: 'sync_status')
  SyncStatus get syncStatus;
  @override
  @JsonKey(name: 'updated_at')
  int get updatedAt;
  @override
  @JsonKey(name: 'is_deleted')
  bool get isDeleted;
  @override
  @JsonKey(name: 'payload')
  WorkoutSessionPayload get sessionPayload;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutProgram _$WorkoutProgramFromJson(Map<String, dynamic> json) {
  return _WorkoutProgram.fromJson(json);
}

/// @nodoc
mixin _$WorkoutProgram {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'description')
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'environment')
  WorkoutEnvironment get environment => throw _privateConstructorUsedError;
  @JsonKey(name: 'difficulty')
  String get difficulty => throw _privateConstructorUsedError;
  @JsonKey(name: 'goal')
  WorkoutGoal get goal => throw _privateConstructorUsedError;
  @JsonKey(name: 'routines')
  List<WorkoutSession> get routines => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutProgramCopyWith<WorkoutProgram> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutProgramCopyWith<$Res> {
  factory $WorkoutProgramCopyWith(
          WorkoutProgram value, $Res Function(WorkoutProgram) then) =
      _$WorkoutProgramCopyWithImpl<$Res, WorkoutProgram>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'name') String name,
      @JsonKey(name: 'description') String description,
      @JsonKey(name: 'environment') WorkoutEnvironment environment,
      @JsonKey(name: 'difficulty') String difficulty,
      @JsonKey(name: 'goal') WorkoutGoal goal,
      @JsonKey(name: 'routines') List<WorkoutSession> routines});
}

/// @nodoc
class _$WorkoutProgramCopyWithImpl<$Res, $Val extends WorkoutProgram>
    implements $WorkoutProgramCopyWith<$Res> {
  _$WorkoutProgramCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? environment = null,
    Object? difficulty = null,
    Object? goal = null,
    Object? routines = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      environment: null == environment
          ? _value.environment
          : environment // ignore: cast_nullable_to_non_nullable
              as WorkoutEnvironment,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as WorkoutGoal,
      routines: null == routines
          ? _value.routines
          : routines // ignore: cast_nullable_to_non_nullable
              as List<WorkoutSession>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutProgramImplCopyWith<$Res>
    implements $WorkoutProgramCopyWith<$Res> {
  factory _$$WorkoutProgramImplCopyWith(_$WorkoutProgramImpl value,
          $Res Function(_$WorkoutProgramImpl) then) =
      __$$WorkoutProgramImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'name') String name,
      @JsonKey(name: 'description') String description,
      @JsonKey(name: 'environment') WorkoutEnvironment environment,
      @JsonKey(name: 'difficulty') String difficulty,
      @JsonKey(name: 'goal') WorkoutGoal goal,
      @JsonKey(name: 'routines') List<WorkoutSession> routines});
}

/// @nodoc
class __$$WorkoutProgramImplCopyWithImpl<$Res>
    extends _$WorkoutProgramCopyWithImpl<$Res, _$WorkoutProgramImpl>
    implements _$$WorkoutProgramImplCopyWith<$Res> {
  __$$WorkoutProgramImplCopyWithImpl(
      _$WorkoutProgramImpl _value, $Res Function(_$WorkoutProgramImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? environment = null,
    Object? difficulty = null,
    Object? goal = null,
    Object? routines = null,
  }) {
    return _then(_$WorkoutProgramImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      environment: null == environment
          ? _value.environment
          : environment // ignore: cast_nullable_to_non_nullable
              as WorkoutEnvironment,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as WorkoutGoal,
      routines: null == routines
          ? _value._routines
          : routines // ignore: cast_nullable_to_non_nullable
              as List<WorkoutSession>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutProgramImpl implements _WorkoutProgram {
  const _$WorkoutProgramImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'name') required this.name,
      @JsonKey(name: 'description') required this.description,
      @JsonKey(name: 'environment') required this.environment,
      @JsonKey(name: 'difficulty') required this.difficulty,
      @JsonKey(name: 'goal') this.goal = WorkoutGoal.STRENGTH,
      @JsonKey(name: 'routines') required final List<WorkoutSession> routines})
      : _routines = routines;

  factory _$WorkoutProgramImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutProgramImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'name')
  final String name;
  @override
  @JsonKey(name: 'description')
  final String description;
  @override
  @JsonKey(name: 'environment')
  final WorkoutEnvironment environment;
  @override
  @JsonKey(name: 'difficulty')
  final String difficulty;
  @override
  @JsonKey(name: 'goal')
  final WorkoutGoal goal;
  final List<WorkoutSession> _routines;
  @override
  @JsonKey(name: 'routines')
  List<WorkoutSession> get routines {
    if (_routines is EqualUnmodifiableListView) return _routines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_routines);
  }

  @override
  String toString() {
    return 'WorkoutProgram(id: $id, name: $name, description: $description, environment: $environment, difficulty: $difficulty, goal: $goal, routines: $routines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutProgramImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.environment, environment) ||
                other.environment == environment) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            const DeepCollectionEquality().equals(other._routines, _routines));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      environment,
      difficulty,
      goal,
      const DeepCollectionEquality().hash(_routines));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutProgramImplCopyWith<_$WorkoutProgramImpl> get copyWith =>
      __$$WorkoutProgramImplCopyWithImpl<_$WorkoutProgramImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutProgramImplToJson(
      this,
    );
  }
}

abstract class _WorkoutProgram implements WorkoutProgram {
  const factory _WorkoutProgram(
      {@JsonKey(name: 'id') required final String id,
      @JsonKey(name: 'name') required final String name,
      @JsonKey(name: 'description') required final String description,
      @JsonKey(name: 'environment')
      required final WorkoutEnvironment environment,
      @JsonKey(name: 'difficulty') required final String difficulty,
      @JsonKey(name: 'goal') final WorkoutGoal goal,
      @JsonKey(name: 'routines')
      required final List<WorkoutSession> routines}) = _$WorkoutProgramImpl;

  factory _WorkoutProgram.fromJson(Map<String, dynamic> json) =
      _$WorkoutProgramImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'name')
  String get name;
  @override
  @JsonKey(name: 'description')
  String get description;
  @override
  @JsonKey(name: 'environment')
  WorkoutEnvironment get environment;
  @override
  @JsonKey(name: 'difficulty')
  String get difficulty;
  @override
  @JsonKey(name: 'goal')
  WorkoutGoal get goal;
  @override
  @JsonKey(name: 'routines')
  List<WorkoutSession> get routines;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutProgramImplCopyWith<_$WorkoutProgramImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScheduledWorkout _$ScheduledWorkoutFromJson(Map<String, dynamic> json) {
  return _ScheduledWorkout.fromJson(json);
}

/// @nodoc
mixin _$ScheduledWorkout {
  String get id => throw _privateConstructorUsedError;
  String get routineId => throw _privateConstructorUsedError;
  String get routineName => throw _privateConstructorUsedError;
  int get targetDateMillis => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'color_hex')
  String? get colorHex => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_group_id')
  String? get recurrenceGroupId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ScheduledWorkoutCopyWith<ScheduledWorkout> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduledWorkoutCopyWith<$Res> {
  factory $ScheduledWorkoutCopyWith(
          ScheduledWorkout value, $Res Function(ScheduledWorkout) then) =
      _$ScheduledWorkoutCopyWithImpl<$Res, ScheduledWorkout>;
  @useResult
  $Res call(
      {String id,
      String routineId,
      String routineName,
      int targetDateMillis,
      bool isCompleted,
      @JsonKey(name: 'color_hex') String? colorHex,
      @JsonKey(name: 'recurrence_group_id') String? recurrenceGroupId});
}

/// @nodoc
class _$ScheduledWorkoutCopyWithImpl<$Res, $Val extends ScheduledWorkout>
    implements $ScheduledWorkoutCopyWith<$Res> {
  _$ScheduledWorkoutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routineId = null,
    Object? routineName = null,
    Object? targetDateMillis = null,
    Object? isCompleted = null,
    Object? colorHex = freezed,
    Object? recurrenceGroupId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routineId: null == routineId
          ? _value.routineId
          : routineId // ignore: cast_nullable_to_non_nullable
              as String,
      routineName: null == routineName
          ? _value.routineName
          : routineName // ignore: cast_nullable_to_non_nullable
              as String,
      targetDateMillis: null == targetDateMillis
          ? _value.targetDateMillis
          : targetDateMillis // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      colorHex: freezed == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceGroupId: freezed == recurrenceGroupId
          ? _value.recurrenceGroupId
          : recurrenceGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScheduledWorkoutImplCopyWith<$Res>
    implements $ScheduledWorkoutCopyWith<$Res> {
  factory _$$ScheduledWorkoutImplCopyWith(_$ScheduledWorkoutImpl value,
          $Res Function(_$ScheduledWorkoutImpl) then) =
      __$$ScheduledWorkoutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String routineId,
      String routineName,
      int targetDateMillis,
      bool isCompleted,
      @JsonKey(name: 'color_hex') String? colorHex,
      @JsonKey(name: 'recurrence_group_id') String? recurrenceGroupId});
}

/// @nodoc
class __$$ScheduledWorkoutImplCopyWithImpl<$Res>
    extends _$ScheduledWorkoutCopyWithImpl<$Res, _$ScheduledWorkoutImpl>
    implements _$$ScheduledWorkoutImplCopyWith<$Res> {
  __$$ScheduledWorkoutImplCopyWithImpl(_$ScheduledWorkoutImpl _value,
      $Res Function(_$ScheduledWorkoutImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? routineId = null,
    Object? routineName = null,
    Object? targetDateMillis = null,
    Object? isCompleted = null,
    Object? colorHex = freezed,
    Object? recurrenceGroupId = freezed,
  }) {
    return _then(_$ScheduledWorkoutImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      routineId: null == routineId
          ? _value.routineId
          : routineId // ignore: cast_nullable_to_non_nullable
              as String,
      routineName: null == routineName
          ? _value.routineName
          : routineName // ignore: cast_nullable_to_non_nullable
              as String,
      targetDateMillis: null == targetDateMillis
          ? _value.targetDateMillis
          : targetDateMillis // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      colorHex: freezed == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceGroupId: freezed == recurrenceGroupId
          ? _value.recurrenceGroupId
          : recurrenceGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScheduledWorkoutImpl implements _ScheduledWorkout {
  const _$ScheduledWorkoutImpl(
      {required this.id,
      required this.routineId,
      required this.routineName,
      required this.targetDateMillis,
      this.isCompleted = false,
      @JsonKey(name: 'color_hex') this.colorHex,
      @JsonKey(name: 'recurrence_group_id') this.recurrenceGroupId});

  factory _$ScheduledWorkoutImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScheduledWorkoutImplFromJson(json);

  @override
  final String id;
  @override
  final String routineId;
  @override
  final String routineName;
  @override
  final int targetDateMillis;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  @JsonKey(name: 'color_hex')
  final String? colorHex;
  @override
  @JsonKey(name: 'recurrence_group_id')
  final String? recurrenceGroupId;

  @override
  String toString() {
    return 'ScheduledWorkout(id: $id, routineId: $routineId, routineName: $routineName, targetDateMillis: $targetDateMillis, isCompleted: $isCompleted, colorHex: $colorHex, recurrenceGroupId: $recurrenceGroupId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduledWorkoutImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.routineId, routineId) ||
                other.routineId == routineId) &&
            (identical(other.routineName, routineName) ||
                other.routineName == routineName) &&
            (identical(other.targetDateMillis, targetDateMillis) ||
                other.targetDateMillis == targetDateMillis) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.recurrenceGroupId, recurrenceGroupId) ||
                other.recurrenceGroupId == recurrenceGroupId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, routineId, routineName,
      targetDateMillis, isCompleted, colorHex, recurrenceGroupId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduledWorkoutImplCopyWith<_$ScheduledWorkoutImpl> get copyWith =>
      __$$ScheduledWorkoutImplCopyWithImpl<_$ScheduledWorkoutImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScheduledWorkoutImplToJson(
      this,
    );
  }
}

abstract class _ScheduledWorkout implements ScheduledWorkout {
  const factory _ScheduledWorkout(
      {required final String id,
      required final String routineId,
      required final String routineName,
      required final int targetDateMillis,
      final bool isCompleted,
      @JsonKey(name: 'color_hex') final String? colorHex,
      @JsonKey(name: 'recurrence_group_id')
      final String? recurrenceGroupId}) = _$ScheduledWorkoutImpl;

  factory _ScheduledWorkout.fromJson(Map<String, dynamic> json) =
      _$ScheduledWorkoutImpl.fromJson;

  @override
  String get id;
  @override
  String get routineId;
  @override
  String get routineName;
  @override
  int get targetDateMillis;
  @override
  bool get isCompleted;
  @override
  @JsonKey(name: 'color_hex')
  String? get colorHex;
  @override
  @JsonKey(name: 'recurrence_group_id')
  String? get recurrenceGroupId;
  @override
  @JsonKey(ignore: true)
  _$$ScheduledWorkoutImplCopyWith<_$ScheduledWorkoutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
