// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuestImpl _$$QuestImplFromJson(Map<String, dynamic> json) => _$QuestImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      target: (json['target'] as num).toInt(),
      current: (json['current'] as num).toInt(),
      xpReward: (json['xpReward'] as num).toInt(),
      iconKey: json['iconKey'] as String,
      type: $enumDecode(_$QuestTypeEnumMap, json['type']),
      claimedReward: json['claimedReward'] as bool,
    );

Map<String, dynamic> _$$QuestImplToJson(_$QuestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'target': instance.target,
      'current': instance.current,
      'xpReward': instance.xpReward,
      'iconKey': instance.iconKey,
      'type': _$QuestTypeEnumMap[instance.type]!,
      'claimedReward': instance.claimedReward,
    };

const _$QuestTypeEnumMap = {
  QuestType.WORKOUT_COUNT: 'WORKOUT_COUNT',
  QuestType.TOTAL_VOLUME: 'TOTAL_VOLUME',
  QuestType.PR_COUNT: 'PR_COUNT',
  QuestType.TOTAL_TIME: 'TOTAL_TIME',
  QuestType.TOTAL_SETS: 'TOTAL_SETS',
  QuestType.TOTAL_EXERCISES: 'TOTAL_EXERCISES',
};

_$UserGamificationStatsImpl _$$UserGamificationStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$UserGamificationStatsImpl(
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentXp: (json['currentXp'] as num?)?.toInt() ?? 0,
      nextLevelXp: (json['nextLevelXp'] as num?)?.toInt() ?? 1000,
      weeklyQuests: (json['weeklyQuests'] as List<dynamic>?)
              ?.map((e) => Quest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isChestClaimed: json['isChestClaimed'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserGamificationStatsImplToJson(
        _$UserGamificationStatsImpl instance) =>
    <String, dynamic>{
      'level': instance.level,
      'currentXp': instance.currentXp,
      'nextLevelXp': instance.nextLevelXp,
      'weeklyQuests': instance.weeklyQuests,
      'isChestClaimed': instance.isChestClaimed,
    };

_$LeaderboardEntryImpl _$$LeaderboardEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$LeaderboardEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      xp: (json['xp'] as num).toInt(),
      currentRankId: (json['current_rank_id'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$LeaderboardEntryImplToJson(
        _$LeaderboardEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'xp': instance.xp,
      'current_rank_id': instance.currentRankId,
    };
