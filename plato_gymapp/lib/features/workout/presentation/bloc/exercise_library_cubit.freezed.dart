// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_library_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ExerciseLibraryState {
  List<Exercise> get exercises => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ExerciseLibraryStateCopyWith<ExerciseLibraryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseLibraryStateCopyWith<$Res> {
  factory $ExerciseLibraryStateCopyWith(ExerciseLibraryState value,
          $Res Function(ExerciseLibraryState) then) =
      _$ExerciseLibraryStateCopyWithImpl<$Res, ExerciseLibraryState>;
  @useResult
  $Res call({List<Exercise> exercises, bool isLoading});
}

/// @nodoc
class _$ExerciseLibraryStateCopyWithImpl<$Res,
        $Val extends ExerciseLibraryState>
    implements $ExerciseLibraryStateCopyWith<$Res> {
  _$ExerciseLibraryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exercises = null,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<Exercise>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseLibraryStateImplCopyWith<$Res>
    implements $ExerciseLibraryStateCopyWith<$Res> {
  factory _$$ExerciseLibraryStateImplCopyWith(_$ExerciseLibraryStateImpl value,
          $Res Function(_$ExerciseLibraryStateImpl) then) =
      __$$ExerciseLibraryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Exercise> exercises, bool isLoading});
}

/// @nodoc
class __$$ExerciseLibraryStateImplCopyWithImpl<$Res>
    extends _$ExerciseLibraryStateCopyWithImpl<$Res, _$ExerciseLibraryStateImpl>
    implements _$$ExerciseLibraryStateImplCopyWith<$Res> {
  __$$ExerciseLibraryStateImplCopyWithImpl(_$ExerciseLibraryStateImpl _value,
      $Res Function(_$ExerciseLibraryStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exercises = null,
    Object? isLoading = null,
  }) {
    return _then(_$ExerciseLibraryStateImpl(
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<Exercise>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ExerciseLibraryStateImpl implements _ExerciseLibraryState {
  const _$ExerciseLibraryStateImpl(
      {final List<Exercise> exercises = const [], this.isLoading = false})
      : _exercises = exercises;

  final List<Exercise> _exercises;
  @override
  @JsonKey()
  List<Exercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'ExerciseLibraryState(exercises: $exercises, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseLibraryStateImpl &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_exercises), isLoading);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseLibraryStateImplCopyWith<_$ExerciseLibraryStateImpl>
      get copyWith =>
          __$$ExerciseLibraryStateImplCopyWithImpl<_$ExerciseLibraryStateImpl>(
              this, _$identity);
}

abstract class _ExerciseLibraryState implements ExerciseLibraryState {
  const factory _ExerciseLibraryState(
      {final List<Exercise> exercises,
      final bool isLoading}) = _$ExerciseLibraryStateImpl;

  @override
  List<Exercise> get exercises;
  @override
  bool get isLoading;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseLibraryStateImplCopyWith<_$ExerciseLibraryStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
