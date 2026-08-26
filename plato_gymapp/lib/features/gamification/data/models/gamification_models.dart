import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:plato_gymapp/core/database/enums.dart';

import '../../../auth/data/models/user_models.dart'; 

part 'gamification_models.freezed.dart';
part 'gamification_models.g.dart';

@freezed
class Quest with _$Quest {
  const factory Quest({
    required String id,
    required String title,
    required String description,
    required int target,
    required int current,
    required int xpReward,
    required String iconKey,
    required QuestType type,
    required bool claimedReward,
  }) = _Quest;

  factory Quest.fromJson(Map<String, dynamic> json) => _$QuestFromJson(json);
}

extension QuestStatus on Quest {
  bool get isCompleted => current >= target;
}

@freezed
class UserGamificationStats with _$UserGamificationStats {
  const factory UserGamificationStats({
    @Default(1) int level,
    @Default(0) int currentXp,
    @Default(1000) int nextLevelXp,
    @Default([]) List<Quest> weeklyQuests,
    @Default(false) bool isChestClaimed,
  }) = _UserGamificationStats;

  factory UserGamificationStats.fromJson(Map<String, dynamic> json) => _$UserGamificationStatsFromJson(json);
}

@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String id,
    required String name,
    required int xp,
    @JsonKey(name: 'current_rank_id') @Default(1) int currentRankId,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(false) bool isUser,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => _$LeaderboardEntryFromJson(json);
}

@freezed
class RankScreenState with _$RankScreenState {
  const factory RankScreenState({
    required int currentRankId,
    required int totalRp,
    required int cycleStartTimeMillis, 
    required List<RankTimelineItem> history, // ĐÃ THÊM: Phục vụ UI render History
  }) = _RankScreenState;
}