// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_session_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ActiveSessionState {
  WorkoutSession? get activeWorkout => throw _privateConstructorUsedError;
  int get workoutTimerSeconds => throw _privateConstructorUsedError;
  int get restTimerSeconds => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isMiniplayerMinimized => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ActiveSessionStateCopyWith<ActiveSessionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActiveSessionStateCopyWith<$Res> {
  factory $ActiveSessionStateCopyWith(
          ActiveSessionState value, $Res Function(ActiveSessionState) then) =
      _$ActiveSessionStateCopyWithImpl<$Res, ActiveSessionState>;
  @useResult
  $Res call(
      {WorkoutSession? activeWorkout,
      int workoutTimerSeconds,
      int restTimerSeconds,
      bool isLoading,
      bool isMiniplayerMinimized});

  $WorkoutSessionCopyWith<$Res>? get activeWorkout;
}

/// @nodoc
class _$ActiveSessionStateCopyWithImpl<$Res, $Val extends ActiveSessionState>
    implements $ActiveSessionStateCopyWith<$Res> {
  _$ActiveSessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeWorkout = freezed,
    Object? workoutTimerSeconds = null,
    Object? restTimerSeconds = null,
    Object? isLoading = null,
    Object? isMiniplayerMinimized = null,
  }) {
    return _then(_value.copyWith(
      activeWorkout: freezed == activeWorkout
          ? _value.activeWorkout
          : activeWorkout // ignore: cast_nullable_to_non_nullable
              as WorkoutSession?,
      workoutTimerSeconds: null == workoutTimerSeconds
          ? _value.workoutTimerSeconds
          : workoutTimerSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      restTimerSeconds: null == restTimerSeconds
          ? _value.restTimerSeconds
          : restTimerSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isMiniplayerMinimized: null == isMiniplayerMinimized
          ? _value.isMiniplayerMinimized
          : isMiniplayerMinimized // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $WorkoutSessionCopyWith<$Res>? get activeWorkout {
    if (_value.activeWorkout == null) {
      return null;
    }

    return $WorkoutSessionCopyWith<$Res>(_value.activeWorkout!, (value) {
      return _then(_value.copyWith(activeWorkout: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ActiveSessionStateImplCopyWith<$Res>
    implements $ActiveSessionStateCopyWith<$Res> {
  factory _$$ActiveSessionStateImplCopyWith(_$ActiveSessionStateImpl value,
          $Res Function(_$ActiveSessionStateImpl) then) =
      __$$ActiveSessionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {WorkoutSession? activeWorkout,
      int workoutTimerSeconds,
      int restTimerSeconds,
      bool isLoading,
      bool isMiniplayerMinimized});

  @override
  $WorkoutSessionCopyWith<$Res>? get activeWorkout;
}

/// @nodoc
class __$$ActiveSessionStateImplCopyWithImpl<$Res>
    extends _$ActiveSessionStateCopyWithImpl<$Res, _$ActiveSessionStateImpl>
    implements _$$ActiveSessionStateImplCopyWith<$Res> {
  __$$ActiveSessionStateImplCopyWithImpl(_$ActiveSessionStateImpl _value,
      $Res Function(_$ActiveSessionStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeWorkout = freezed,
    Object? workoutTimerSeconds = null,
    Object? restTimerSeconds = null,
    Object? isLoading = null,
    Object? isMiniplayerMinimized = null,
  }) {
    return _then(_$ActiveSessionStateImpl(
      activeWorkout: freezed == activeWorkout
          ? _value.activeWorkout
          : activeWorkout // ignore: cast_nullable_to_non_nullable
              as WorkoutSession?,
      workoutTimerSeconds: null == workoutTimerSeconds
          ? _value.workoutTimerSeconds
          : workoutTimerSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      restTimerSeconds: null == restTimerSeconds
          ? _value.restTimerSeconds
          : restTimerSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isMiniplayerMinimized: null == isMiniplayerMinimized
          ? _value.isMiniplayerMinimized
          : isMiniplayerMinimized // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ActiveSessionStateImpl implements _ActiveSessionState {
  const _$ActiveSessionStateImpl(
      {this.activeWorkout,
      this.workoutTimerSeconds = 0,
      this.restTimerSeconds = 0,
      this.isLoading = false,
      this.isMiniplayerMinimized = false});

  @override
  final WorkoutSession? activeWorkout;
  @override
  @JsonKey()
  final int workoutTimerSeconds;
  @override
  @JsonKey()
  final int restTimerSeconds;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isMiniplayerMinimized;

  @override
  String toString() {
    return 'ActiveSessionState(activeWorkout: $activeWorkout, workoutTimerSeconds: $workoutTimerSeconds, restTimerSeconds: $restTimerSeconds, isLoading: $isLoading, isMiniplayerMinimized: $isMiniplayerMinimized)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActiveSessionStateImpl &&
            (identical(other.activeWorkout, activeWorkout) ||
                other.activeWorkout == activeWorkout) &&
            (identical(other.workoutTimerSeconds, workoutTimerSeconds) ||
                other.workoutTimerSeconds == workoutTimerSeconds) &&
            (identical(other.restTimerSeconds, restTimerSeconds) ||
                other.restTimerSeconds == restTimerSeconds) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isMiniplayerMinimized, isMiniplayerMinimized) ||
                other.isMiniplayerMinimized == isMiniplayerMinimized));
  }

  @override
  int get hashCode => Object.hash(runtimeType, activeWorkout,
      workoutTimerSeconds, restTimerSeconds, isLoading, isMiniplayerMinimized);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ActiveSessionStateImplCopyWith<_$ActiveSessionStateImpl> get copyWith =>
      __$$ActiveSessionStateImplCopyWithImpl<_$ActiveSessionStateImpl>(
          this, _$identity);
}

abstract class _ActiveSessionState implements ActiveSessionState {
  const factory _ActiveSessionState(
      {final WorkoutSession? activeWorkout,
      final int workoutTimerSeconds,
      final int restTimerSeconds,
      final bool isLoading,
      final bool isMiniplayerMinimized}) = _$ActiveSessionStateImpl;

  @override
  WorkoutSession? get activeWorkout;
  @override
  int get workoutTimerSeconds;
  @override
  int get restTimerSeconds;
  @override
  bool get isLoading;
  @override
  bool get isMiniplayerMinimized;
  @override
  @JsonKey(ignore: true)
  _$$ActiveSessionStateImplCopyWith<_$ActiveSessionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
