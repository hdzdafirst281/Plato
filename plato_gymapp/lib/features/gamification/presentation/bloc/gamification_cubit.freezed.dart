// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gamification_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$GamificationState {
  UserGamificationStats get stats => throw _privateConstructorUsedError;
  List<LeaderboardEntry>? get leaderboard => throw _privateConstructorUsedError;
  bool get isLeaderboardLoading => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GamificationStateCopyWith<GamificationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GamificationStateCopyWith<$Res> {
  factory $GamificationStateCopyWith(
          GamificationState value, $Res Function(GamificationState) then) =
      _$GamificationStateCopyWithImpl<$Res, GamificationState>;
  @useResult
  $Res call(
      {UserGamificationStats stats,
      List<LeaderboardEntry>? leaderboard,
      bool isLeaderboardLoading});

  $UserGamificationStatsCopyWith<$Res> get stats;
}

/// @nodoc
class _$GamificationStateCopyWithImpl<$Res, $Val extends GamificationState>
    implements $GamificationStateCopyWith<$Res> {
  _$GamificationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stats = null,
    Object? leaderboard = freezed,
    Object? isLeaderboardLoading = null,
  }) {
    return _then(_value.copyWith(
      stats: null == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as UserGamificationStats,
      leaderboard: freezed == leaderboard
          ? _value.leaderboard
          : leaderboard // ignore: cast_nullable_to_non_nullable
              as List<LeaderboardEntry>?,
      isLeaderboardLoading: null == isLeaderboardLoading
          ? _value.isLeaderboardLoading
          : isLeaderboardLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserGamificationStatsCopyWith<$Res> get stats {
    return $UserGamificationStatsCopyWith<$Res>(_value.stats, (value) {
      return _then(_value.copyWith(stats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GamificationStateImplCopyWith<$Res>
    implements $GamificationStateCopyWith<$Res> {
  factory _$$GamificationStateImplCopyWith(_$GamificationStateImpl value,
          $Res Function(_$GamificationStateImpl) then) =
      __$$GamificationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {UserGamificationStats stats,
      List<LeaderboardEntry>? leaderboard,
      bool isLeaderboardLoading});

  @override
  $UserGamificationStatsCopyWith<$Res> get stats;
}

/// @nodoc
class __$$GamificationStateImplCopyWithImpl<$Res>
    extends _$GamificationStateCopyWithImpl<$Res, _$GamificationStateImpl>
    implements _$$GamificationStateImplCopyWith<$Res> {
  __$$GamificationStateImplCopyWithImpl(_$GamificationStateImpl _value,
      $Res Function(_$GamificationStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stats = null,
    Object? leaderboard = freezed,
    Object? isLeaderboardLoading = null,
  }) {
    return _then(_$GamificationStateImpl(
      stats: null == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as UserGamificationStats,
      leaderboard: freezed == leaderboard
          ? _value._leaderboard
          : leaderboard // ignore: cast_nullable_to_non_nullable
              as List<LeaderboardEntry>?,
      isLeaderboardLoading: null == isLeaderboardLoading
          ? _value.isLeaderboardLoading
          : isLeaderboardLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$GamificationStateImpl
    with DiagnosticableTreeMixin
    implements _GamificationState {
  const _$GamificationStateImpl(
      {required this.stats,
      final List<LeaderboardEntry>? leaderboard = null,
      this.isLeaderboardLoading = false})
      : _leaderboard = leaderboard;

  @override
  final UserGamificationStats stats;
  final List<LeaderboardEntry>? _leaderboard;
  @override
  @JsonKey()
  List<LeaderboardEntry>? get leaderboard {
    final value = _leaderboard;
    if (value == null) return null;
    if (_leaderboard is EqualUnmodifiableListView) return _leaderboard;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final bool isLeaderboardLoading;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'GamificationState(stats: $stats, leaderboard: $leaderboard, isLeaderboardLoading: $isLeaderboardLoading)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'GamificationState'))
      ..add(DiagnosticsProperty('stats', stats))
      ..add(DiagnosticsProperty('leaderboard', leaderboard))
      ..add(DiagnosticsProperty('isLeaderboardLoading', isLeaderboardLoading));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GamificationStateImpl &&
            (identical(other.stats, stats) || other.stats == stats) &&
            const DeepCollectionEquality()
                .equals(other._leaderboard, _leaderboard) &&
            (identical(other.isLeaderboardLoading, isLeaderboardLoading) ||
                other.isLeaderboardLoading == isLeaderboardLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType, stats,
      const DeepCollectionEquality().hash(_leaderboard), isLeaderboardLoading);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GamificationStateImplCopyWith<_$GamificationStateImpl> get copyWith =>
      __$$GamificationStateImplCopyWithImpl<_$GamificationStateImpl>(
          this, _$identity);
}

abstract class _GamificationState implements GamificationState {
  const factory _GamificationState(
      {required final UserGamificationStats stats,
      final List<LeaderboardEntry>? leaderboard,
      final bool isLeaderboardLoading}) = _$GamificationStateImpl;

  @override
  UserGamificationStats get stats;
  @override
  List<LeaderboardEntry>? get leaderboard;
  @override
  bool get isLeaderboardLoading;
  @override
  @JsonKey(ignore: true)
  _$$GamificationStateImplCopyWith<_$GamificationStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
