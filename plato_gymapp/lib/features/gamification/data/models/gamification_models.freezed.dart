// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gamification_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Quest _$QuestFromJson(Map<String, dynamic> json) {
  return _Quest.fromJson(json);
}

/// @nodoc
mixin _$Quest {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get target => throw _privateConstructorUsedError;
  int get current => throw _privateConstructorUsedError;
  int get xpReward => throw _privateConstructorUsedError;
  String get iconKey => throw _privateConstructorUsedError;
  QuestType get type => throw _privateConstructorUsedError;
  bool get claimedReward => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuestCopyWith<Quest> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestCopyWith<$Res> {
  factory $QuestCopyWith(Quest value, $Res Function(Quest) then) =
      _$QuestCopyWithImpl<$Res, Quest>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      int target,
      int current,
      int xpReward,
      String iconKey,
      QuestType type,
      bool claimedReward});
}

/// @nodoc
class _$QuestCopyWithImpl<$Res, $Val extends Quest>
    implements $QuestCopyWith<$Res> {
  _$QuestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? target = null,
    Object? current = null,
    Object? xpReward = null,
    Object? iconKey = null,
    Object? type = null,
    Object? claimedReward = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as int,
      current: null == current
          ? _value.current
          : current // ignore: cast_nullable_to_non_nullable
              as int,
      xpReward: null == xpReward
          ? _value.xpReward
          : xpReward // ignore: cast_nullable_to_non_nullable
              as int,
      iconKey: null == iconKey
          ? _value.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as QuestType,
      claimedReward: null == claimedReward
          ? _value.claimedReward
          : claimedReward // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestImplCopyWith<$Res> implements $QuestCopyWith<$Res> {
  factory _$$QuestImplCopyWith(
          _$QuestImpl value, $Res Function(_$QuestImpl) then) =
      __$$QuestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      int target,
      int current,
      int xpReward,
      String iconKey,
      QuestType type,
      bool claimedReward});
}

/// @nodoc
class __$$QuestImplCopyWithImpl<$Res>
    extends _$QuestCopyWithImpl<$Res, _$QuestImpl>
    implements _$$QuestImplCopyWith<$Res> {
  __$$QuestImplCopyWithImpl(
      _$QuestImpl _value, $Res Function(_$QuestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? target = null,
    Object? current = null,
    Object? xpReward = null,
    Object? iconKey = null,
    Object? type = null,
    Object? claimedReward = null,
  }) {
    return _then(_$QuestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as int,
      current: null == current
          ? _value.current
          : current // ignore: cast_nullable_to_non_nullable
              as int,
      xpReward: null == xpReward
          ? _value.xpReward
          : xpReward // ignore: cast_nullable_to_non_nullable
              as int,
      iconKey: null == iconKey
          ? _value.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as QuestType,
      claimedReward: null == claimedReward
          ? _value.claimedReward
          : claimedReward // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestImpl implements _Quest {
  const _$QuestImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.target,
      required this.current,
      required this.xpReward,
      required this.iconKey,
      required this.type,
      required this.claimedReward});

  factory _$QuestImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final int target;
  @override
  final int current;
  @override
  final int xpReward;
  @override
  final String iconKey;
  @override
  final QuestType type;
  @override
  final bool claimedReward;

  @override
  String toString() {
    return 'Quest(id: $id, title: $title, description: $description, target: $target, current: $current, xpReward: $xpReward, iconKey: $iconKey, type: $type, claimedReward: $claimedReward)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.xpReward, xpReward) ||
                other.xpReward == xpReward) &&
            (identical(other.iconKey, iconKey) || other.iconKey == iconKey) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.claimedReward, claimedReward) ||
                other.claimedReward == claimedReward));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, description, target,
      current, xpReward, iconKey, type, claimedReward);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestImplCopyWith<_$QuestImpl> get copyWith =>
      __$$QuestImplCopyWithImpl<_$QuestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestImplToJson(
      this,
    );
  }
}

abstract class _Quest implements Quest {
  const factory _Quest(
      {required final String id,
      required final String title,
      required final String description,
      required final int target,
      required final int current,
      required final int xpReward,
      required final String iconKey,
      required final QuestType type,
      required final bool claimedReward}) = _$QuestImpl;

  factory _Quest.fromJson(Map<String, dynamic> json) = _$QuestImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  int get target;
  @override
  int get current;
  @override
  int get xpReward;
  @override
  String get iconKey;
  @override
  QuestType get type;
  @override
  bool get claimedReward;
  @override
  @JsonKey(ignore: true)
  _$$QuestImplCopyWith<_$QuestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserGamificationStats _$UserGamificationStatsFromJson(
    Map<String, dynamic> json) {
  return _UserGamificationStats.fromJson(json);
}

/// @nodoc
mixin _$UserGamificationStats {
  int get level => throw _privateConstructorUsedError;
  int get currentXp => throw _privateConstructorUsedError;
  int get nextLevelXp => throw _privateConstructorUsedError;
  List<Quest> get weeklyQuests => throw _privateConstructorUsedError;
  bool get isChestClaimed => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserGamificationStatsCopyWith<UserGamificationStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserGamificationStatsCopyWith<$Res> {
  factory $UserGamificationStatsCopyWith(UserGamificationStats value,
          $Res Function(UserGamificationStats) then) =
      _$UserGamificationStatsCopyWithImpl<$Res, UserGamificationStats>;
  @useResult
  $Res call(
      {int level,
      int currentXp,
      int nextLevelXp,
      List<Quest> weeklyQuests,
      bool isChestClaimed});
}

/// @nodoc
class _$UserGamificationStatsCopyWithImpl<$Res,
        $Val extends UserGamificationStats>
    implements $UserGamificationStatsCopyWith<$Res> {
  _$UserGamificationStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? currentXp = null,
    Object? nextLevelXp = null,
    Object? weeklyQuests = null,
    Object? isChestClaimed = null,
  }) {
    return _then(_value.copyWith(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      currentXp: null == currentXp
          ? _value.currentXp
          : currentXp // ignore: cast_nullable_to_non_nullable
              as int,
      nextLevelXp: null == nextLevelXp
          ? _value.nextLevelXp
          : nextLevelXp // ignore: cast_nullable_to_non_nullable
              as int,
      weeklyQuests: null == weeklyQuests
          ? _value.weeklyQuests
          : weeklyQuests // ignore: cast_nullable_to_non_nullable
              as List<Quest>,
      isChestClaimed: null == isChestClaimed
          ? _value.isChestClaimed
          : isChestClaimed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserGamificationStatsImplCopyWith<$Res>
    implements $UserGamificationStatsCopyWith<$Res> {
  factory _$$UserGamificationStatsImplCopyWith(
          _$UserGamificationStatsImpl value,
          $Res Function(_$UserGamificationStatsImpl) then) =
      __$$UserGamificationStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int level,
      int currentXp,
      int nextLevelXp,
      List<Quest> weeklyQuests,
      bool isChestClaimed});
}

/// @nodoc
class __$$UserGamificationStatsImplCopyWithImpl<$Res>
    extends _$UserGamificationStatsCopyWithImpl<$Res,
        _$UserGamificationStatsImpl>
    implements _$$UserGamificationStatsImplCopyWith<$Res> {
  __$$UserGamificationStatsImplCopyWithImpl(_$UserGamificationStatsImpl _value,
      $Res Function(_$UserGamificationStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? currentXp = null,
    Object? nextLevelXp = null,
    Object? weeklyQuests = null,
    Object? isChestClaimed = null,
  }) {
    return _then(_$UserGamificationStatsImpl(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      currentXp: null == currentXp
          ? _value.currentXp
          : currentXp // ignore: cast_nullable_to_non_nullable
              as int,
      nextLevelXp: null == nextLevelXp
          ? _value.nextLevelXp
          : nextLevelXp // ignore: cast_nullable_to_non_nullable
              as int,
      weeklyQuests: null == weeklyQuests
          ? _value._weeklyQuests
          : weeklyQuests // ignore: cast_nullable_to_non_nullable
              as List<Quest>,
      isChestClaimed: null == isChestClaimed
          ? _value.isChestClaimed
          : isChestClaimed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserGamificationStatsImpl implements _UserGamificationStats {
  const _$UserGamificationStatsImpl(
      {this.level = 1,
      this.currentXp = 0,
      this.nextLevelXp = 1000,
      final List<Quest> weeklyQuests = const [],
      this.isChestClaimed = false})
      : _weeklyQuests = weeklyQuests;

  factory _$UserGamificationStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserGamificationStatsImplFromJson(json);

  @override
  @JsonKey()
  final int level;
  @override
  @JsonKey()
  final int currentXp;
  @override
  @JsonKey()
  final int nextLevelXp;
  final List<Quest> _weeklyQuests;
  @override
  @JsonKey()
  List<Quest> get weeklyQuests {
    if (_weeklyQuests is EqualUnmodifiableListView) return _weeklyQuests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_weeklyQuests);
  }

  @override
  @JsonKey()
  final bool isChestClaimed;

  @override
  String toString() {
    return 'UserGamificationStats(level: $level, currentXp: $currentXp, nextLevelXp: $nextLevelXp, weeklyQuests: $weeklyQuests, isChestClaimed: $isChestClaimed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserGamificationStatsImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.currentXp, currentXp) ||
                other.currentXp == currentXp) &&
            (identical(other.nextLevelXp, nextLevelXp) ||
                other.nextLevelXp == nextLevelXp) &&
            const DeepCollectionEquality()
                .equals(other._weeklyQuests, _weeklyQuests) &&
            (identical(other.isChestClaimed, isChestClaimed) ||
                other.isChestClaimed == isChestClaimed));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, level, currentXp, nextLevelXp,
      const DeepCollectionEquality().hash(_weeklyQuests), isChestClaimed);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserGamificationStatsImplCopyWith<_$UserGamificationStatsImpl>
      get copyWith => __$$UserGamificationStatsImplCopyWithImpl<
          _$UserGamificationStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserGamificationStatsImplToJson(
      this,
    );
  }
}

abstract class _UserGamificationStats implements UserGamificationStats {
  const factory _UserGamificationStats(
      {final int level,
      final int currentXp,
      final int nextLevelXp,
      final List<Quest> weeklyQuests,
      final bool isChestClaimed}) = _$UserGamificationStatsImpl;

  factory _UserGamificationStats.fromJson(Map<String, dynamic> json) =
      _$UserGamificationStatsImpl.fromJson;

  @override
  int get level;
  @override
  int get currentXp;
  @override
  int get nextLevelXp;
  @override
  List<Quest> get weeklyQuests;
  @override
  bool get isChestClaimed;
  @override
  @JsonKey(ignore: true)
  _$$UserGamificationStatsImplCopyWith<_$UserGamificationStatsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) {
  return _LeaderboardEntry.fromJson(json);
}

/// @nodoc
mixin _$LeaderboardEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get xp => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_rank_id')
  int get currentRankId => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isUser => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LeaderboardEntryCopyWith<LeaderboardEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaderboardEntryCopyWith<$Res> {
  factory $LeaderboardEntryCopyWith(
          LeaderboardEntry value, $Res Function(LeaderboardEntry) then) =
      _$LeaderboardEntryCopyWithImpl<$Res, LeaderboardEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      int xp,
      @JsonKey(name: 'current_rank_id') int currentRankId,
      @JsonKey(includeFromJson: false, includeToJson: false) bool isUser});
}

/// @nodoc
class _$LeaderboardEntryCopyWithImpl<$Res, $Val extends LeaderboardEntry>
    implements $LeaderboardEntryCopyWith<$Res> {
  _$LeaderboardEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? xp = null,
    Object? currentRankId = null,
    Object? isUser = null,
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
      xp: null == xp
          ? _value.xp
          : xp // ignore: cast_nullable_to_non_nullable
              as int,
      currentRankId: null == currentRankId
          ? _value.currentRankId
          : currentRankId // ignore: cast_nullable_to_non_nullable
              as int,
      isUser: null == isUser
          ? _value.isUser
          : isUser // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LeaderboardEntryImplCopyWith<$Res>
    implements $LeaderboardEntryCopyWith<$Res> {
  factory _$$LeaderboardEntryImplCopyWith(_$LeaderboardEntryImpl value,
          $Res Function(_$LeaderboardEntryImpl) then) =
      __$$LeaderboardEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int xp,
      @JsonKey(name: 'current_rank_id') int currentRankId,
      @JsonKey(includeFromJson: false, includeToJson: false) bool isUser});
}

/// @nodoc
class __$$LeaderboardEntryImplCopyWithImpl<$Res>
    extends _$LeaderboardEntryCopyWithImpl<$Res, _$LeaderboardEntryImpl>
    implements _$$LeaderboardEntryImplCopyWith<$Res> {
  __$$LeaderboardEntryImplCopyWithImpl(_$LeaderboardEntryImpl _value,
      $Res Function(_$LeaderboardEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? xp = null,
    Object? currentRankId = null,
    Object? isUser = null,
  }) {
    return _then(_$LeaderboardEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      xp: null == xp
          ? _value.xp
          : xp // ignore: cast_nullable_to_non_nullable
              as int,
      currentRankId: null == currentRankId
          ? _value.currentRankId
          : currentRankId // ignore: cast_nullable_to_non_nullable
              as int,
      isUser: null == isUser
          ? _value.isUser
          : isUser // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LeaderboardEntryImpl implements _LeaderboardEntry {
  const _$LeaderboardEntryImpl(
      {required this.id,
      required this.name,
      required this.xp,
      @JsonKey(name: 'current_rank_id') this.currentRankId = 1,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.isUser = false});

  factory _$LeaderboardEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$LeaderboardEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int xp;
  @override
  @JsonKey(name: 'current_rank_id')
  final int currentRankId;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isUser;

  @override
  String toString() {
    return 'LeaderboardEntry(id: $id, name: $name, xp: $xp, currentRankId: $currentRankId, isUser: $isUser)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaderboardEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.xp, xp) || other.xp == xp) &&
            (identical(other.currentRankId, currentRankId) ||
                other.currentRankId == currentRankId) &&
            (identical(other.isUser, isUser) || other.isUser == isUser));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, xp, currentRankId, isUser);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaderboardEntryImplCopyWith<_$LeaderboardEntryImpl> get copyWith =>
      __$$LeaderboardEntryImplCopyWithImpl<_$LeaderboardEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LeaderboardEntryImplToJson(
      this,
    );
  }
}

abstract class _LeaderboardEntry implements LeaderboardEntry {
  const factory _LeaderboardEntry(
      {required final String id,
      required final String name,
      required final int xp,
      @JsonKey(name: 'current_rank_id') final int currentRankId,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final bool isUser}) = _$LeaderboardEntryImpl;

  factory _LeaderboardEntry.fromJson(Map<String, dynamic> json) =
      _$LeaderboardEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get xp;
  @override
  @JsonKey(name: 'current_rank_id')
  int get currentRankId;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isUser;
  @override
  @JsonKey(ignore: true)
  _$$LeaderboardEntryImplCopyWith<_$LeaderboardEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RankScreenState {
  int get currentRankId => throw _privateConstructorUsedError;
  int get totalRp => throw _privateConstructorUsedError;
  int get cycleStartTimeMillis => throw _privateConstructorUsedError;
  List<RankTimelineItem> get history => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RankScreenStateCopyWith<RankScreenState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RankScreenStateCopyWith<$Res> {
  factory $RankScreenStateCopyWith(
          RankScreenState value, $Res Function(RankScreenState) then) =
      _$RankScreenStateCopyWithImpl<$Res, RankScreenState>;
  @useResult
  $Res call(
      {int currentRankId,
      int totalRp,
      int cycleStartTimeMillis,
      List<RankTimelineItem> history});
}

/// @nodoc
class _$RankScreenStateCopyWithImpl<$Res, $Val extends RankScreenState>
    implements $RankScreenStateCopyWith<$Res> {
  _$RankScreenStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentRankId = null,
    Object? totalRp = null,
    Object? cycleStartTimeMillis = null,
    Object? history = null,
  }) {
    return _then(_value.copyWith(
      currentRankId: null == currentRankId
          ? _value.currentRankId
          : currentRankId // ignore: cast_nullable_to_non_nullable
              as int,
      totalRp: null == totalRp
          ? _value.totalRp
          : totalRp // ignore: cast_nullable_to_non_nullable
              as int,
      cycleStartTimeMillis: null == cycleStartTimeMillis
          ? _value.cycleStartTimeMillis
          : cycleStartTimeMillis // ignore: cast_nullable_to_non_nullable
              as int,
      history: null == history
          ? _value.history
          : history // ignore: cast_nullable_to_non_nullable
              as List<RankTimelineItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RankScreenStateImplCopyWith<$Res>
    implements $RankScreenStateCopyWith<$Res> {
  factory _$$RankScreenStateImplCopyWith(_$RankScreenStateImpl value,
          $Res Function(_$RankScreenStateImpl) then) =
      __$$RankScreenStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int currentRankId,
      int totalRp,
      int cycleStartTimeMillis,
      List<RankTimelineItem> history});
}

/// @nodoc
class __$$RankScreenStateImplCopyWithImpl<$Res>
    extends _$RankScreenStateCopyWithImpl<$Res, _$RankScreenStateImpl>
    implements _$$RankScreenStateImplCopyWith<$Res> {
  __$$RankScreenStateImplCopyWithImpl(
      _$RankScreenStateImpl _value, $Res Function(_$RankScreenStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentRankId = null,
    Object? totalRp = null,
    Object? cycleStartTimeMillis = null,
    Object? history = null,
  }) {
    return _then(_$RankScreenStateImpl(
      currentRankId: null == currentRankId
          ? _value.currentRankId
          : currentRankId // ignore: cast_nullable_to_non_nullable
              as int,
      totalRp: null == totalRp
          ? _value.totalRp
          : totalRp // ignore: cast_nullable_to_non_nullable
              as int,
      cycleStartTimeMillis: null == cycleStartTimeMillis
          ? _value.cycleStartTimeMillis
          : cycleStartTimeMillis // ignore: cast_nullable_to_non_nullable
              as int,
      history: null == history
          ? _value._history
          : history // ignore: cast_nullable_to_non_nullable
              as List<RankTimelineItem>,
    ));
  }
}

/// @nodoc

class _$RankScreenStateImpl implements _RankScreenState {
  const _$RankScreenStateImpl(
      {required this.currentRankId,
      required this.totalRp,
      required this.cycleStartTimeMillis,
      required final List<RankTimelineItem> history})
      : _history = history;

  @override
  final int currentRankId;
  @override
  final int totalRp;
  @override
  final int cycleStartTimeMillis;
  final List<RankTimelineItem> _history;
  @override
  List<RankTimelineItem> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @override
  String toString() {
    return 'RankScreenState(currentRankId: $currentRankId, totalRp: $totalRp, cycleStartTimeMillis: $cycleStartTimeMillis, history: $history)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RankScreenStateImpl &&
            (identical(other.currentRankId, currentRankId) ||
                other.currentRankId == currentRankId) &&
            (identical(other.totalRp, totalRp) || other.totalRp == totalRp) &&
            (identical(other.cycleStartTimeMillis, cycleStartTimeMillis) ||
                other.cycleStartTimeMillis == cycleStartTimeMillis) &&
            const DeepCollectionEquality().equals(other._history, _history));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentRankId, totalRp,
      cycleStartTimeMillis, const DeepCollectionEquality().hash(_history));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RankScreenStateImplCopyWith<_$RankScreenStateImpl> get copyWith =>
      __$$RankScreenStateImplCopyWithImpl<_$RankScreenStateImpl>(
          this, _$identity);
}

abstract class _RankScreenState implements RankScreenState {
  const factory _RankScreenState(
      {required final int currentRankId,
      required final int totalRp,
      required final int cycleStartTimeMillis,
      required final List<RankTimelineItem> history}) = _$RankScreenStateImpl;

  @override
  int get currentRankId;
  @override
  int get totalRp;
  @override
  int get cycleStartTimeMillis;
  @override
  List<RankTimelineItem> get history;
  @override
  @JsonKey(ignore: true)
  _$$RankScreenStateImplCopyWith<_$RankScreenStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
