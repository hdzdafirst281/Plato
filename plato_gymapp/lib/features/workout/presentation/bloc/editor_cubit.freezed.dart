// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EditorState {
  WorkoutSession? get routineToEdit => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $EditorStateCopyWith<EditorState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorStateCopyWith<$Res> {
  factory $EditorStateCopyWith(
          EditorState value, $Res Function(EditorState) then) =
      _$EditorStateCopyWithImpl<$Res, EditorState>;
  @useResult
  $Res call({WorkoutSession? routineToEdit, bool isLoading});

  $WorkoutSessionCopyWith<$Res>? get routineToEdit;
}

/// @nodoc
class _$EditorStateCopyWithImpl<$Res, $Val extends EditorState>
    implements $EditorStateCopyWith<$Res> {
  _$EditorStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routineToEdit = freezed,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      routineToEdit: freezed == routineToEdit
          ? _value.routineToEdit
          : routineToEdit // ignore: cast_nullable_to_non_nullable
              as WorkoutSession?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $WorkoutSessionCopyWith<$Res>? get routineToEdit {
    if (_value.routineToEdit == null) {
      return null;
    }

    return $WorkoutSessionCopyWith<$Res>(_value.routineToEdit!, (value) {
      return _then(_value.copyWith(routineToEdit: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EditorStateImplCopyWith<$Res>
    implements $EditorStateCopyWith<$Res> {
  factory _$$EditorStateImplCopyWith(
          _$EditorStateImpl value, $Res Function(_$EditorStateImpl) then) =
      __$$EditorStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({WorkoutSession? routineToEdit, bool isLoading});

  @override
  $WorkoutSessionCopyWith<$Res>? get routineToEdit;
}

/// @nodoc
class __$$EditorStateImplCopyWithImpl<$Res>
    extends _$EditorStateCopyWithImpl<$Res, _$EditorStateImpl>
    implements _$$EditorStateImplCopyWith<$Res> {
  __$$EditorStateImplCopyWithImpl(
      _$EditorStateImpl _value, $Res Function(_$EditorStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routineToEdit = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$EditorStateImpl(
      routineToEdit: freezed == routineToEdit
          ? _value.routineToEdit
          : routineToEdit // ignore: cast_nullable_to_non_nullable
              as WorkoutSession?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$EditorStateImpl implements _EditorState {
  const _$EditorStateImpl({this.routineToEdit, this.isLoading = false});

  @override
  final WorkoutSession? routineToEdit;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'EditorState(routineToEdit: $routineToEdit, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorStateImpl &&
            (identical(other.routineToEdit, routineToEdit) ||
                other.routineToEdit == routineToEdit) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType, routineToEdit, isLoading);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorStateImplCopyWith<_$EditorStateImpl> get copyWith =>
      __$$EditorStateImplCopyWithImpl<_$EditorStateImpl>(this, _$identity);
}

abstract class _EditorState implements EditorState {
  const factory _EditorState(
      {final WorkoutSession? routineToEdit,
      final bool isLoading}) = _$EditorStateImpl;

  @override
  WorkoutSession? get routineToEdit;
  @override
  bool get isLoading;
  @override
  @JsonKey(ignore: true)
  _$$EditorStateImplCopyWith<_$EditorStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
