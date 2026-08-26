// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stats_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$StatsState {
  List<WorkoutSession> get workouts => throw _privateConstructorUsedError;
  int get weeklyStreak => throw _privateConstructorUsedError;
  int get restDays => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $StatsStateCopyWith<StatsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatsStateCopyWith<$Res> {
  factory $StatsStateCopyWith(
          StatsState value, $Res Function(StatsState) then) =
      _$StatsStateCopyWithImpl<$Res, StatsState>;
  @useResult
  $Res call(
      {List<WorkoutSession> workouts,
      int weeklyStreak,
      int restDays,
      bool isLoading});
}

/// @nodoc
class _$StatsStateCopyWithImpl<$Res, $Val extends StatsState>
    implements $StatsStateCopyWith<$Res> {
  _$StatsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workouts = null,
    Object? weeklyStreak = null,
    Object? restDays = null,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      workouts: null == workouts
          ? _value.workouts
          : workouts // ignore: cast_nullable_to_non_nullable
              as List<WorkoutSession>,
      weeklyStreak: null == weeklyStreak
          ? _value.weeklyStreak
          : weeklyStreak // ignore: cast_nullable_to_non_nullable
              as int,
      restDays: null == restDays
          ? _value.restDays
          : restDays // ignore: cast_nullable_to_non_nullable
              as int,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StatsStateImplCopyWith<$Res>
    implements $StatsStateCopyWith<$Res> {
  factory _$$StatsStateImplCopyWith(
          _$StatsStateImpl value, $Res Function(_$StatsStateImpl) then) =
      __$$StatsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<WorkoutSession> workouts,
      int weeklyStreak,
      int restDays,
      bool isLoading});
}

/// @nodoc
class __$$StatsStateImplCopyWithImpl<$Res>
    extends _$StatsStateCopyWithImpl<$Res, _$StatsStateImpl>
    implements _$$StatsStateImplCopyWith<$Res> {
  __$$StatsStateImplCopyWithImpl(
      _$StatsStateImpl _value, $Res Function(_$StatsStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workouts = null,
    Object? weeklyStreak = null,
    Object? restDays = null,
    Object? isLoading = null,
  }) {
    return _then(_$StatsStateImpl(
      workouts: null == workouts
          ? _value._workouts
          : workouts // ignore: cast_nullable_to_non_nullable
              as List<WorkoutSession>,
      weeklyStreak: null == weeklyStreak
          ? _value.weeklyStreak
          : weeklyStreak // ignore: cast_nullable_to_non_nullable
              as int,
      restDays: null == restDays
          ? _value.restDays
          : restDays // ignore: cast_nullable_to_non_nullable
              as int,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$StatsStateImpl with DiagnosticableTreeMixin implements _StatsState {
  const _$StatsStateImpl(
      {final List<WorkoutSession> workouts = const [],
      this.weeklyStreak = 0,
      this.restDays = 0,
      this.isLoading = true})
      : _workouts = workouts;

  final List<WorkoutSession> _workouts;
  @override
  @JsonKey()
  List<WorkoutSession> get workouts {
    if (_workouts is EqualUnmodifiableListView) return _workouts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_workouts);
  }

  @override
  @JsonKey()
  final int weeklyStreak;
  @override
  @JsonKey()
  final int restDays;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'StatsState(workouts: $workouts, weeklyStreak: $weeklyStreak, restDays: $restDays, isLoading: $isLoading)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'StatsState'))
      ..add(DiagnosticsProperty('workouts', workouts))
      ..add(DiagnosticsProperty('weeklyStreak', weeklyStreak))
      ..add(DiagnosticsProperty('restDays', restDays))
      ..add(DiagnosticsProperty('isLoading', isLoading));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatsStateImpl &&
            const DeepCollectionEquality().equals(other._workouts, _workouts) &&
            (identical(other.weeklyStreak, weeklyStreak) ||
                other.weeklyStreak == weeklyStreak) &&
            (identical(other.restDays, restDays) ||
                other.restDays == restDays) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_workouts),
      weeklyStreak,
      restDays,
      isLoading);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StatsStateImplCopyWith<_$StatsStateImpl> get copyWith =>
      __$$StatsStateImplCopyWithImpl<_$StatsStateImpl>(this, _$identity);
}

abstract class _StatsState implements StatsState {
  const factory _StatsState(
      {final List<WorkoutSession> workouts,
      final int weeklyStreak,
      final int restDays,
      final bool isLoading}) = _$StatsStateImpl;

  @override
  List<WorkoutSession> get workouts;
  @override
  int get weeklyStreak;
  @override
  int get restDays;
  @override
  bool get isLoading;
  @override
  @JsonKey(ignore: true)
  _$$StatsStateImplCopyWith<_$StatsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
