// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuthState {
  UserProfile? get userProfile => throw _privateConstructorUsedError;
  bool get showWeeklyWeightReminder => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get authMessage => throw _privateConstructorUsedError;
  AuthSyncResult? get syncResult => throw _privateConstructorUsedError;
  AuthFlowType? get currentFlow => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AuthStateCopyWith<AuthState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthStateCopyWith<$Res> {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) then) =
      _$AuthStateCopyWithImpl<$Res, AuthState>;
  @useResult
  $Res call(
      {UserProfile? userProfile,
      bool showWeeklyWeightReminder,
      bool isLoading,
      String? authMessage,
      AuthSyncResult? syncResult,
      AuthFlowType? currentFlow});

  $UserProfileCopyWith<$Res>? get userProfile;
}

/// @nodoc
class _$AuthStateCopyWithImpl<$Res, $Val extends AuthState>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userProfile = freezed,
    Object? showWeeklyWeightReminder = null,
    Object? isLoading = null,
    Object? authMessage = freezed,
    Object? syncResult = freezed,
    Object? currentFlow = freezed,
  }) {
    return _then(_value.copyWith(
      userProfile: freezed == userProfile
          ? _value.userProfile
          : userProfile // ignore: cast_nullable_to_non_nullable
              as UserProfile?,
      showWeeklyWeightReminder: null == showWeeklyWeightReminder
          ? _value.showWeeklyWeightReminder
          : showWeeklyWeightReminder // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      authMessage: freezed == authMessage
          ? _value.authMessage
          : authMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      syncResult: freezed == syncResult
          ? _value.syncResult
          : syncResult // ignore: cast_nullable_to_non_nullable
              as AuthSyncResult?,
      currentFlow: freezed == currentFlow
          ? _value.currentFlow
          : currentFlow // ignore: cast_nullable_to_non_nullable
              as AuthFlowType?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<$Res>? get userProfile {
    if (_value.userProfile == null) {
      return null;
    }

    return $UserProfileCopyWith<$Res>(_value.userProfile!, (value) {
      return _then(_value.copyWith(userProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthStateImplCopyWith<$Res>
    implements $AuthStateCopyWith<$Res> {
  factory _$$AuthStateImplCopyWith(
          _$AuthStateImpl value, $Res Function(_$AuthStateImpl) then) =
      __$$AuthStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {UserProfile? userProfile,
      bool showWeeklyWeightReminder,
      bool isLoading,
      String? authMessage,
      AuthSyncResult? syncResult,
      AuthFlowType? currentFlow});

  @override
  $UserProfileCopyWith<$Res>? get userProfile;
}

/// @nodoc
class __$$AuthStateImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$AuthStateImpl>
    implements _$$AuthStateImplCopyWith<$Res> {
  __$$AuthStateImplCopyWithImpl(
      _$AuthStateImpl _value, $Res Function(_$AuthStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userProfile = freezed,
    Object? showWeeklyWeightReminder = null,
    Object? isLoading = null,
    Object? authMessage = freezed,
    Object? syncResult = freezed,
    Object? currentFlow = freezed,
  }) {
    return _then(_$AuthStateImpl(
      userProfile: freezed == userProfile
          ? _value.userProfile
          : userProfile // ignore: cast_nullable_to_non_nullable
              as UserProfile?,
      showWeeklyWeightReminder: null == showWeeklyWeightReminder
          ? _value.showWeeklyWeightReminder
          : showWeeklyWeightReminder // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      authMessage: freezed == authMessage
          ? _value.authMessage
          : authMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      syncResult: freezed == syncResult
          ? _value.syncResult
          : syncResult // ignore: cast_nullable_to_non_nullable
              as AuthSyncResult?,
      currentFlow: freezed == currentFlow
          ? _value.currentFlow
          : currentFlow // ignore: cast_nullable_to_non_nullable
              as AuthFlowType?,
    ));
  }
}

/// @nodoc

class _$AuthStateImpl implements _AuthState {
  const _$AuthStateImpl(
      {this.userProfile,
      this.showWeeklyWeightReminder = false,
      this.isLoading = false,
      this.authMessage,
      this.syncResult,
      this.currentFlow});

  @override
  final UserProfile? userProfile;
  @override
  @JsonKey()
  final bool showWeeklyWeightReminder;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? authMessage;
  @override
  final AuthSyncResult? syncResult;
  @override
  final AuthFlowType? currentFlow;

  @override
  String toString() {
    return 'AuthState(userProfile: $userProfile, showWeeklyWeightReminder: $showWeeklyWeightReminder, isLoading: $isLoading, authMessage: $authMessage, syncResult: $syncResult, currentFlow: $currentFlow)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthStateImpl &&
            (identical(other.userProfile, userProfile) ||
                other.userProfile == userProfile) &&
            (identical(
                    other.showWeeklyWeightReminder, showWeeklyWeightReminder) ||
                other.showWeeklyWeightReminder == showWeeklyWeightReminder) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.authMessage, authMessage) ||
                other.authMessage == authMessage) &&
            (identical(other.syncResult, syncResult) ||
                other.syncResult == syncResult) &&
            (identical(other.currentFlow, currentFlow) ||
                other.currentFlow == currentFlow));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      userProfile,
      showWeeklyWeightReminder,
      isLoading,
      authMessage,
      syncResult,
      currentFlow);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      __$$AuthStateImplCopyWithImpl<_$AuthStateImpl>(this, _$identity);
}

abstract class _AuthState implements AuthState {
  const factory _AuthState(
      {final UserProfile? userProfile,
      final bool showWeeklyWeightReminder,
      final bool isLoading,
      final String? authMessage,
      final AuthSyncResult? syncResult,
      final AuthFlowType? currentFlow}) = _$AuthStateImpl;

  @override
  UserProfile? get userProfile;
  @override
  bool get showWeeklyWeightReminder;
  @override
  bool get isLoading;
  @override
  String? get authMessage;
  @override
  AuthSyncResult? get syncResult;
  @override
  AuthFlowType? get currentFlow;
  @override
  @JsonKey(ignore: true)
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
