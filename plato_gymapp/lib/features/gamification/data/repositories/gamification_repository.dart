import 'package:injectable/injectable.dart';
import 'package:plato_gymapp/core/utils/time_manager.dart';
import 'package:plato_gymapp/features/workout/domain/workout_extensions.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/gamification_models.dart';
import '../../../auth/data/models/user_models.dart';
import '../../../workout/data/models/workout_models.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/entities.dart';    
import '../../domain/rank_calculator.dart';

@lazySingleton
class GamificationRepository {
  final AppDatabase _db; // 🚀 Chuyển sang dùng SQLite làm Source of Truth

  UserGamificationStats _currentStats = const UserGamificationStats();
  UserGamificationStats get userStats => _currentStats;

  Set<String> _claimedQuestIds = {};
  bool _isChestClaimed = false;
  String _currentWeekKey = "";

  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  GamificationRepository(this._db, this._supabase, this._prefs);

  String _getWeekKey(int timestampInMillis) {
    // 🚀 BẮT BUỘC dùng isUtc: true
    final date = DateTime.fromMillisecondsSinceEpoch(timestampInMillis, isUtc: true);
    final startOfYear = DateTime.utc(date.year, 1, 1);
    final firstMonday = startOfYear.weekday;
    final daysInFirstWeek = 8 - firstMonday;
    final diff = date.difference(startOfYear).inDays;
    
    int weekNumber = 1;
    if (diff >= daysInFirstWeek) {
      weekNumber = 2 + ((diff - daysInFirstWeek) / 7).floor();
    }
    return "${date.year}-W$weekNumber";
  }

  // 🚀 ĐỌC SỔ CÁI TỪ SQLITE ĐỂ BIẾT TRẠNG THÁI HIỆN TẠI
  Future<void> _loadClaimedStateAsync() async {
    final trueTimeMillis = await TimeManager.getTrueTimeMillis(); 
    final currentWeekKey = _getWeekKey(trueTimeMillis);
    _currentWeekKey = currentWeekKey;

    final claimsList = await _db.rewardClaimDao.getClaimsByPeriod(currentWeekKey);

    // Tính toán trạng thái cuối cùng của từng Quest/Chest bằng cách duyệt lịch sử
    Map<String, bool> claimStatusMap = {};
    for (var claim in claimsList) {
      if (claim.actionType == 'CLAIMED') {
        claimStatusMap[claim.sourceRef] = true;
      } else if (claim.actionType == 'REVOKED') {
        claimStatusMap[claim.sourceRef] = false;
      }
    }

    _claimedQuestIds = claimStatusMap.entries
        .where((e) => e.value && e.key.startsWith('q'))
        .map((e) => e.key)
        .toSet();

    _isChestClaimed = claimStatusMap['weekly_chest'] == true;
  }

  int calculateTotalLifetimeXp(List<WorkoutSession> historyList) {
    return historyList.where((w) => !w.isDeleted).fold(0, (sum, w) => sum + w.xpEarned);
  }

  // 🚀 REFRESH STATE ASYNC
  Future<void> refreshStateFromDb() async {
    await _loadClaimedStateAsync();
    
    final updatedQuests = _currentStats.weeklyQuests.map((q) {
      return q.copyWith(claimedReward: _claimedQuestIds.contains(q.id));
    }).toList();

    _currentStats = _currentStats.copyWith(
      weeklyQuests: updatedQuests,
      isChestClaimed: _isChestClaimed,
    );
  }

  // 🚀 TÍNH TOÁN & THU HỒI TỰ ĐỘNG NẾU RỚT ĐIỀU KIỆN
  Future<int> calculateWeeklyStats({
    required List<WorkoutSession> workoutsList,
    required UserProfile userProfileData,
  }) async {
    await _loadClaimedStateAsync();

    final completedWorkoutsInWeek = workoutsList.where((w) => 
        !w.isDeleted && _getWeekKey(w.startTime) == _currentWeekKey
    ).toList();
    
    // Khởi tạo các Quest (Giữ nguyên logic tính toán của bạn)
    final q1Id = "q1_$_currentWeekKey";
    final q1 = Quest(id: q1Id, title: "gamification.title_quest_1", description: "gamification.desc_quest_1", target: 3, current: completedWorkoutsInWeek.length, xpReward: 300, iconKey: "workout_count", type: QuestType.WORKOUT_COUNT, claimedReward: _claimedQuestIds.contains(q1Id));

    final totalVolume = completedWorkoutsInWeek.fold(0.0, (sum, w) => sum + w.totalVolume).toInt();
    final q2Id = "q2_$_currentWeekKey";
    final q2 = Quest(id: q2Id, title: "gamification.title_quest_2", description: "gamification.desc_quest_2", target: 10000, current: totalVolume, xpReward: 400, iconKey: "total_volume", type: QuestType.TOTAL_VOLUME, claimedReward: _claimedQuestIds.contains(q2Id));

    int totalPrCount = 0;
    for (var w in completedWorkoutsInWeek) {
      totalPrCount += w.calculateTotalPRs(workoutsList);
    }
    
    final q3Id = "q3_$_currentWeekKey";
    final q3 = Quest(id: q3Id, title: "gamification.title_quest_3", description: "gamification.desc_quest_3", target: 1, current: totalPrCount, xpReward: 200, iconKey: "pr_count", type: QuestType.PR_COUNT, claimedReward: _claimedQuestIds.contains(q3Id));

    final totalDurationMinutes = completedWorkoutsInWeek.fold(0, (sum, w) => sum + w.totalDurationSeconds) ~/ 60;
    final q4Id = "q4_$_currentWeekKey";
    final q4 = Quest(id: q4Id, title: "gamification.title_quest_4", description: "gamification.desc_quest_4", target: 120, current: totalDurationMinutes, xpReward: 300, iconKey: "duration", type: QuestType.TOTAL_TIME, claimedReward: _claimedQuestIds.contains(q4Id));

    final totalSets = completedWorkoutsInWeek.fold(0, (sum, w) => sum + w.totalSets);
    final q5Id = "q5_$_currentWeekKey";
    final q5 = Quest(id: q5Id, title: "gamification.title_quest_5", description: "gamification.desc_quest_5", target: 50, current: totalSets, xpReward: 250, iconKey: "sets", type: QuestType.TOTAL_SETS, claimedReward: _claimedQuestIds.contains(q5Id));

    final totalExercises = completedWorkoutsInWeek.fold(0, (sum, w) => sum + w.exercises.length);
    final q6Id = "q6_$_currentWeekKey";
    final q6 = Quest(id: q6Id, title: "gamification.title_quest_6", description: "gamification.desc_quest_6", target: 15, current: totalExercises, xpReward: 200, iconKey: "exercises", type: QuestType.TOTAL_EXERCISES, claimedReward: _claimedQuestIds.contains(q6Id));

    List<Quest> compiledWeeklyQuests = [q1, q2, q3, q4, q5, q6]; 

    int xpToRollback = 0;

    // 🚀 LOGIC THU HỒI QUEST (REVOKE)
    for (int i = 0; i < compiledWeeklyQuests.length; i++) {
      final q = compiledWeeklyQuests[i];
      if (q.claimedReward && !q.isCompleted) {
        
        final trueTimeMillis = await TimeManager.getTrueTimeMillis();
        // Ghi nhận lệnh Thu Hồi vào SQLite
        final revokeRecord = RewardClaimEntity(
          id: const Uuid().v4(),
          sourceType: 'QUEST',
          sourceRef: q.id,
          periodKey: _currentWeekKey,
          actionType: 'REVOKED',
          xpAmount: -q.xpReward, // Âm XP để server tính tổng lại cho đúng
          createdAt: trueTimeMillis,
          syncStatus: 'PENDING',
        );
        await _db.rewardClaimDao.insertClaim(revokeRecord);

        _claimedQuestIds.remove(q.id);
        compiledWeeklyQuests[i] = q.copyWith(claimedReward: false);
        xpToRollback += q.xpReward; 
      }
    }

    // 🚀 LOGIC THU HỒI CHEST (REVOKE)
    final completedCount = compiledWeeklyQuests.where((q) => q.isCompleted).length;
    if (_isChestClaimed && completedCount < 5) {
      final trueTimeMillis = await TimeManager.getTrueTimeMillis();
      final revokeChestRecord = RewardClaimEntity(
        id: const Uuid().v4(),
        sourceType: 'CHEST',
        sourceRef: 'weekly_chest',
        periodKey: _currentWeekKey,
        actionType: 'REVOKED',
        xpAmount: -1500,
        createdAt: trueTimeMillis,
        syncStatus: 'PENDING',
      );
      await _db.rewardClaimDao.insertClaim(revokeChestRecord);

      _isChestClaimed = false;
      xpToRollback += 1500;
    }

    int finalXp = userProfileData.experiencePoints - xpToRollback;
    final currentLevelInfo = calculateLevelInfo(finalXp > 0 ? finalXp : 0);
    
    _currentStats = UserGamificationStats(
      level: currentLevelInfo.$1,
      currentXp: currentLevelInfo.$2,
      nextLevelXp: calculateNextLevelRequirement(currentLevelInfo.$1),
      weeklyQuests: compiledWeeklyQuests,
      isChestClaimed: _isChestClaimed,
    );

    return xpToRollback;
  }

  // 🚀 HÀM MỚI: Quét lại Sổ cái của một tuần bất kỳ (Audit) để chống Hack Time
  Future<void> auditSpecificWeek(int targetTimeMillis, List<WorkoutSession> workoutsList) async {
    final targetWeekKey = _getWeekKey(targetTimeMillis);
    
    // 1. Lấy lịch sử nhận thưởng của riêng tuần bị ảnh hưởng
    final claimsList = await _db.rewardClaimDao.getClaimsByPeriod(targetWeekKey);
    Map<String, bool> claimStatusMap = {};
    for (var claim in claimsList) {
      if (claim.actionType == 'CLAIMED') {
        claimStatusMap[claim.sourceRef] = true;
      } else if (claim.actionType == 'REVOKED') claimStatusMap[claim.sourceRef] = false;
    }

    // 2. Lấy các buổi tập hợp lệ còn sót lại của tuần đó
    final completedWorkoutsInWeek = workoutsList.where((w) => 
        !w.isDeleted && _getWeekKey(w.startTime) == targetWeekKey
    ).toList();

    // 3. Tính toán lại thành tích
    int totalVolume = completedWorkoutsInWeek.fold(0.0, (sum, w) => sum + w.totalVolume).toInt();
    int totalPrCount = completedWorkoutsInWeek.fold(0, (sum, w) => sum + w.calculateTotalPRs(workoutsList));
    int totalDurationMinutes = completedWorkoutsInWeek.fold(0, (sum, w) => sum + w.totalDurationSeconds) ~/ 60;
    int totalSets = completedWorkoutsInWeek.fold(0, (sum, w) => sum + w.totalSets);
    int totalExercises = completedWorkoutsInWeek.fold(0, (sum, w) => sum + w.exercises.length);

    final conditions = {
      'q1_$targetWeekKey': completedWorkoutsInWeek.length >= 3,
      'q2_$targetWeekKey': totalVolume >= 10000,
      'q3_$targetWeekKey': totalPrCount >= 1,
      'q4_$targetWeekKey': totalDurationMinutes >= 120,
      'q5_$targetWeekKey': totalSets >= 50,
      'q6_$targetWeekKey': totalExercises >= 15,
    };

    final xpRewards = { 'q1': 300, 'q2': 400, 'q3': 200, 'q4': 300, 'q5': 250, 'q6': 200 };
    int validQuestsCount = 0;
    final trueTimeMillis = await TimeManager.getTrueTimeMillis();

    // 4. Sinh lệnh REVOKED vào SQLite nếu phát hiện gian lận
    for (var entry in conditions.entries) {
      final questId = entry.key;
      final isConditionMet = entry.value;
      final isClaimed = claimStatusMap[questId] == true;

      if (isConditionMet) {
        validQuestsCount++;
      } else if (isClaimed && !isConditionMet) {
        final prefix = questId.split('_')[0];
        await _db.rewardClaimDao.insertClaim(RewardClaimEntity(
          id: const Uuid().v4(), sourceType: 'QUEST', sourceRef: questId,
          periodKey: targetWeekKey, actionType: 'REVOKED', xpAmount: -xpRewards[prefix]!,
          createdAt: trueTimeMillis, syncStatus: 'PENDING',
        ));
        claimStatusMap[questId] = false; 
      }
    }

    // 5. Xử lý Rương Tuần (Chest)
    final isChestClaimed = claimStatusMap['weekly_chest'] == true;
    if (isChestClaimed && validQuestsCount < 5) {
      await _db.rewardClaimDao.insertClaim(RewardClaimEntity(
        id: const Uuid().v4(), sourceType: 'CHEST', sourceRef: 'weekly_chest',
        periodKey: targetWeekKey, actionType: 'REVOKED', xpAmount: -1500,
        createdAt: trueTimeMillis, syncStatus: 'PENDING',
      ));
    }
  }

  // 🚀 NHẬN THƯỞNG QUEST (CLAIM)
  Future<int> claimQuestReward(String questId) async {
    final questIndex = _currentStats.weeklyQuests.indexWhere((q) => q.id == questId);
    if (questIndex != -1) {
      final quest = _currentStats.weeklyQuests[questIndex];
      if (quest.isCompleted && !quest.claimedReward) {
        
        final trueTimeMillis = await TimeManager.getTrueTimeMillis();
        // Ghi nhận vào SQLite thay vì SharedPreferences
        final claimRecord = RewardClaimEntity(
          id: const Uuid().v4(),
          sourceType: 'QUEST',
          sourceRef: quest.id,
          periodKey: _currentWeekKey,
          actionType: 'CLAIMED',
          xpAmount: quest.xpReward,
          createdAt: trueTimeMillis,
          syncStatus: 'PENDING',
        );
        await _db.rewardClaimDao.insertClaim(claimRecord);
        
        _claimedQuestIds.add(questId);
        
        final updatedQuests = List<Quest>.from(_currentStats.weeklyQuests);
        updatedQuests[questIndex] = quest.copyWith(claimedReward: true);
        _currentStats = _currentStats.copyWith(weeklyQuests: updatedQuests);

        // 🚀 FIX: Xóa/Comment dòng này để chống kẹt Database
        // SyncManager.scheduleBackgroundSync();

        return quest.xpReward;
      }
    }
    return 0;
  }

  // 🚀 NHẬN THƯỞNG CHEST (CLAIM)
  Future<int> claimChestReward() async {
    final completedCount = _currentStats.weeklyQuests.where((q) => q.isCompleted).length;
    if (completedCount >= 5 && !_isChestClaimed) {
      
      final trueTimeMillis = await TimeManager.getTrueTimeMillis();
      final claimRecord = RewardClaimEntity(
        id: const Uuid().v4(),
        sourceType: 'CHEST',
        sourceRef: 'weekly_chest',
        periodKey: _currentWeekKey,
        actionType: 'CLAIMED',
        xpAmount: 1500,
        createdAt: trueTimeMillis,
        syncStatus: 'PENDING',
      );
      await _db.rewardClaimDao.insertClaim(claimRecord);

      _isChestClaimed = true;
      _currentStats = _currentStats.copyWith(isChestClaimed: true);

      // 🚀 FIX: Xóa/Comment dòng này để chống kẹt Database
      // SyncManager.scheduleBackgroundSync();

      return 1500; 
    }
    return 0;
  }

  void updateStatsAfterXpGain(UserProfile updatedProfile) {
    final currentLevelInfo = calculateLevelInfo(updatedProfile.experiencePoints);
    _currentStats = _currentStats.copyWith(
      level: currentLevelInfo.$1,
      currentXp: currentLevelInfo.$2,
      nextLevelXp: calculateNextLevelRequirement(currentLevelInfo.$1),
    );
  }

  int calculateXpForSession(WorkoutSession session) {
    const int baseXP = 50; 
    const int prBonusXP = 20; 
    return baseXP + (session.prCount * prBonusXP);
  }

  (int, int) calculateLevelInfo(int totalLifetimeXp) {
    int level = 1;
    int remainingXp = totalLifetimeXp;
    while (true) {
      int requiredXp = calculateNextLevelRequirement(level);
      if (remainingXp >= requiredXp) {
        remainingXp -= requiredXp;
        level++;
      } else {
        break;
      }
    }
    return (level, remainingXp);
  }

  int calculateNextLevelRequirement(int level) => 1000 + ((level - 1) * 50);

  Future<void> evaluateAndLogRankChange({
    required List<WorkoutSession> workoutsHistoryList,
    required UserProfile userProfileData,
    required Function(List<RankTimelineItem>, int, int) onRankChangedAction,
  }) async {
    // 1. Lấy thời gian chuẩn từ Server (đã chống đổi ngày giờ)
    final trueTimeMillis = await TimeManager.getTrueTimeMillis();
    
    // 2. Truyền trueTimeMillis vào RankCalculator
    final seasonResult = RankCalculator.calculateTrueRankAndSeasons(
      workoutsHistoryList, 
      userProfileData, 
      trueTimeMillis, // Thêm param này để đồng bộ cấu trúc mới
    );
    
    // 3. Thực thi callback
    await onRankChangedAction(
      seasonResult.generatedHistory, 
      seasonResult.currentRankId, 
      seasonResult.currentCycleRankPoints
    );
  }

  // =======================================
  // LEADERBOARD (SUPABASE + CACHE)
  // =======================================
  Future<List<LeaderboardEntry>> getLeaderboard({bool forceRefresh = false}) async {
    const cacheKey = 'leaderboard_data';
    const timeKey = 'leaderboard_last_sync';
    const cacheDurationMillis = 30 * 60 * 1000; // 30 minutes

    final lastSyncStr = _prefs.getString(timeKey);
    final cacheStr = _prefs.getString(cacheKey);

    final trueTimeMillis = await TimeManager.getTrueTimeMillis();

    // Kiểm tra Cache
    if (!forceRefresh && lastSyncStr != null && cacheStr != null) {
      final lastSync = int.tryParse(lastSyncStr) ?? 0;
      if (trueTimeMillis - lastSync < cacheDurationMillis) {
        try {
          final List<dynamic> jsonList = jsonDecode(cacheStr);
          final leaderboard = jsonList.map((e) => LeaderboardEntry.fromJson(e)).toList();
          return leaderboard;
        } catch (e) {
          debugPrint("Lỗi parse cache leaderboard: $e");
          // Bỏ qua lỗi parse để lấy lại từ mạng
        }
      }
    }

    // Nếu không có cache hợp lệ, fetch từ Supabase
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, xp, current_rank_id')
          .order('xp', ascending: false)
          .limit(50);
          
      debugPrint("🎯 [DEBUG LEADERBOARD] Supabase trả về ${(response as List).length} users.");
      
      final List<LeaderboardEntry> leaderboard = [];
      for (final e in (response as List<dynamic>)) {
        try {
          leaderboard.add(LeaderboardEntry.fromJson(e as Map<String, dynamic>));
        } catch (parseError) {
          debugPrint("Lỗi parse 1 user trong leaderboard: $parseError - data: $e");
        }
      }

      debugPrint("🎯 [DEBUG LEADERBOARD] Đã parse thành công ${leaderboard.length} users.");

      // Lưu Cache mới
      final jsonToCache = jsonEncode(leaderboard.map((e) => e.toJson()).toList());
      await _prefs.setString(cacheKey, jsonToCache);
      await _prefs.setString(timeKey, trueTimeMillis.toString());

      return leaderboard;
    } catch (e) {
      debugPrint("LỖI NGHIÊM TRỌNG TỪ SUPABASE (Leaderboard): $e");
      
      // Nếu rớt mạng nhưng có cache cũ, trả về cache cũ tạm thời
      if (cacheStr != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(cacheStr);
          return jsonList.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
      return []; // Nếu không có cả mạng lẫn cache
    }
  }
}