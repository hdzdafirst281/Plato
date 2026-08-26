// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_set.dart';

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
      @JsonKey(name: 'is_reps_pr') bool isRepsPR});
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
      @JsonKey(name: 'is_reps_pr') bool isRepsPR});
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseSetImpl implements _ExerciseSet {
  const _$ExerciseSetImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'weight') this.weight = 0.0,
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
      @JsonKey(name: 'is_reps_pr') this.isRepsPR = false});

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
  String toString() {
    return 'ExerciseSet(id: $id, weight: $weight, reps: $reps, durationTimeSeconds: $durationTimeSeconds, distanceInKm: $distanceInKm, steps: $steps, rpe: $rpe, isCompleted: $isCompleted, type: $type, restTimeSeconds: $restTimeSeconds, isPersonalRecord: $isPersonalRecord, isWeightPR: $isWeightPR, isVolumePR: $isVolumePR, is1RmPR: $is1RmPR, isTimePR: $isTimePR, isDistancePR: $isDistancePR, isStepsPR: $isStepsPR, isRepsPR: $isRepsPR)';
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
                other.isRepsPR == isRepsPR));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
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
      isRepsPR);

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
      @JsonKey(name: 'is_reps_pr') final bool isRepsPR}) = _$ExerciseSetImpl;

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
  @JsonKey(ignore: true)
  _$$ExerciseSetImplCopyWith<_$ExerciseSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
