import 'dart:math';

import '../../auth/data/models/user_models.dart';
import '../../workout/data/models/workout_models.dart';
import '../../../../core/database/enums.dart';

class RankLevel {
  final int id;
  final String nameKey;
  final int maintainPoints;
  final int promotePoints;
  final RankTier tier;
  final String iconKey;
  final int colorHex;
  const RankLevel(this.id, this.nameKey, this.maintainPoints, this.promotePoints, this.tier, this.iconKey, this.colorHex);
}

class RankConfig {
  static const int rollingWindowDays = 45;
  static const int dailyRpCap = 40;
  static const List<RankLevel> hierarchy = [
    // Bronze: Giảm nhẹ để Beginner có động lực gắn bó từ những ngày đầu
    RankLevel(1, "rank.name_bronze_1", 0, 80, RankTier.BEGINNER, "rank_bronze_1", 0xFFCD7F32), // Cũ: 100
    RankLevel(2, "rank.name_bronze_2", 50, 150, RankTier.BEGINNER, "rank_bronze_2", 0xFFCD7F32), // Cũ: 60 - 200
    
    // Silver: Giảm 15% - Vừa đủ thách thức cho người duy trì thói quen 3 buổi/tuần
    RankLevel(3, "rank.name_silver_1", 120, 280, RankTier.INTERMEDIATE, "rank_silver_1", 0xFFC0C0C0), // Cũ: 150 - 350
    RankLevel(4, "rank.name_silver_2", 220, 420, RankTier.INTERMEDIATE, "rank_silver_2", 0xFFC0C0C0), // Cũ: 280 - 500
    
    // Gold: Giảm 15-20% - Cho người tập nghiêm túc 4-5 buổi/tuần
    RankLevel(5, "rank.name_gold_1", 350, 580, RankTier.ADVANCED, "rank_gold_1", 0xFFFFD700), // Cũ: 420 - 700
    RankLevel(6, "rank.name_gold_2", 500, 750, RankTier.ADVANCED, "rank_gold_2", 0xFFFFD700), // Cũ: 600 - 900
    RankLevel(7, "rank.name_gold_3", 650, 950, RankTier.ADVANCED, "rank_gold_3", 0xFFFFD700), // Cũ: 800 - 1150
    
    // Diamond: Đỉnh cao - Vẫn cần cố gắng nhưng không còn phi lý (Cần ~19 RP/ngày trong 45 ngày)
    RankLevel(8, "rank.name_diamond_1", 850, 99999, RankTier.ELITE, "rank_diamond_1", 0xFFE040FB), // Cũ: 1000
  ];

  static RankLevel getRankById(int id) => hierarchy.firstWhere((r) => r.id == id, orElse: () => hierarchy.first);
  static RankLevel? getNextRank(int currentId) => hierarchy.where((r) => r.id == currentId + 1).firstOrNull;
}

class SeasonResult {
  final int currentRankId;
  final int cycleStartTimeMillis;
  final int cycleEndTimeMillis;
  final int currentCycleRankPoints;
  final List<RankTimelineItem> generatedHistory;
  SeasonResult(this.currentRankId, this.cycleStartTimeMillis, this.cycleEndTimeMillis, this.currentCycleRankPoints, this.generatedHistory);
}

class RankCalculator {
  static const int cycleDurationMillis = RankConfig.rollingWindowDays * 24 * 60 * 60 * 1000;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Calculates total RP for an iterable of sessions, capping completed sets at [RankConfig.dailyRpCap] per calendar day.
  static int calculateCappedRp(Iterable<WorkoutSession> sessions) {
    final Map<int, int> setsPerDay = {};
    for (final session in sessions) {
      final completedSets = session.exercises
          .expand((e) => e.sets)
          .where((set) => set.isCompleted)
          .length;
      if (completedSets == 0) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(session.startTime);
      final dayKey = date.year * 10000 + date.month * 100 + date.day;
      setsPerDay[dayKey] = (setsPerDay[dayKey] ?? 0) + completedSets;
    }

    int totalRp = 0;
    for (final sets in setsPerDay.values) {
      totalRp += min(sets, RankConfig.dailyRpCap);
    }
    return totalRp;
  }

  /// Calculates RP earned by a single session, taking into account any prior sessions on the same calendar day.
  static int calculateSessionRp(
    WorkoutSession session, [
    Iterable<WorkoutSession>? allSessions,
  ]) {
    final sessionSets = session.exercises
        .expand((e) => e.sets)
        .where((set) => set.isCompleted)
        .length;
    if (sessionSets == 0) return 0;
    if (allSessions == null || allSessions.isEmpty) {
      return min(sessionSets, RankConfig.dailyRpCap);
    }

    final sessionDate = DateTime.fromMillisecondsSinceEpoch(session.startTime);
    final priorSets = allSessions
        .where((s) =>
            s.id != session.id &&
            !s.isDeleted &&
            s.startTime <= session.startTime &&
            isSameDay(DateTime.fromMillisecondsSinceEpoch(s.startTime), sessionDate))
        .expand((s) => s.exercises)
        .expand((e) => e.sets)
        .where((set) => set.isCompleted)
        .length;

    final remaining = max(0, RankConfig.dailyRpCap - priorSets);
    return min(sessionSets, remaining);
  }

  /// Checks whether the daily RP cap has been reached for a specific day.
  static bool isRpCapReached(DateTime day, Iterable<WorkoutSession> allSessions) {
    final totalSets = allSessions
        .where((s) =>
            !s.isDeleted &&
            isSameDay(DateTime.fromMillisecondsSinceEpoch(s.startTime), day))
        .expand((s) => s.exercises)
        .expand((e) => e.sets)
        .where((set) => set.isCompleted)
        .length;
    return totalSets >= RankConfig.dailyRpCap;
  }

  // 🚀 ĐƯỢC THÊM MỚI: Hàm dùng chung để lấy Cycle Start nhằm đồng bộ 100% giữa Profile và Rank
  static int getPersonalCycleStartMillis(List<WorkoutSession> sessions, int lastRpSeasonId) {
    int anchorTime = DateTime.now().millisecondsSinceEpoch;
    final activeSessions = sessions.where((s) => !s.isDeleted).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
      
    if (activeSessions.isNotEmpty) {
      anchorTime = activeSessions.first.startTime;
    }
    
    final int daysOffset = ((lastRpSeasonId > 0 ? lastRpSeasonId : 1) - 1) * RankConfig.rollingWindowDays;
    return anchorTime + (daysOffset * 24 * 60 * 60 * 1000);
  }

  // 🚀 FIX 1: Bắt buộc truyền trueTimeMillis vào hàm
  static SeasonResult calculateTrueRankAndSeasons(
    List<WorkoutSession> sessions, 
    UserProfile profile,
    int trueTimeMillis, 
  ) {
    final activeSessions = sessions.where((s) => !s.isDeleted).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    int currentRankId = 1; 
    List<RankTimelineItem> history = [];

    // 🚀 FIX TẠI ĐÂY: Mỏ neo tính từ buổi tập ĐẦU TIÊN (Khớp với quy tắc của ProfileScreen)
    int anchorTime = DateTime.now().millisecondsSinceEpoch;
    if (activeSessions.isNotEmpty) {
      anchorTime = activeSessions.first.startTime; 
    }
    
    if (activeSessions.isEmpty) {
      return SeasonResult(currentRankId, anchorTime, anchorTime + cycleDurationMillis, 0, history);
    }

    int cycleStart = anchorTime; 
    int cycleEnd = cycleStart + cycleDurationMillis;
    
    final maxRankId = RankConfig.hierarchy.map((r) => r.id).reduce(max);

    // 🚀 FIX 3: Dùng trueTimeMillis thay vì DateTime.now()
    while (cycleEnd <= trueTimeMillis) {
      final sessionsInCycle = activeSessions
          .where((s) => s.startTime >= cycleStart && s.startTime < cycleEnd);
      final pointsInCycle = calculateCappedRp(sessionsInCycle);

      final currentRankInfo = RankConfig.getRankById(currentRankId);
      final eventTime = cycleEnd + 1000;

      if (pointsInCycle >= currentRankInfo.promotePoints && currentRankId < maxRankId) {
        currentRankId++;
        history.add(RankTimelineItem(rankId: currentRankId, achievedAtMillis: eventTime, unlockReasonDescription: "REASON_PROMOTED"));
      } else if (pointsInCycle < currentRankInfo.maintainPoints && currentRankId > 1) {
        currentRankId--;
        history.add(RankTimelineItem(rankId: currentRankId, achievedAtMillis: eventTime, unlockReasonDescription: "REASON_DEMOTED"));
      } else {
        history.add(RankTimelineItem(rankId: currentRankId, achievedAtMillis: eventTime, unlockReasonDescription: "REASON_MAINTAINED"));
      }

      cycleStart = cycleEnd;
      cycleEnd += cycleDurationMillis;
    }

    final currentSessions = activeSessions
        .where((s) => s.startTime >= cycleStart);
    final activePoints = calculateCappedRp(currentSessions);

    return SeasonResult(currentRankId, cycleStart, cycleEnd, activePoints, history);
  }
}