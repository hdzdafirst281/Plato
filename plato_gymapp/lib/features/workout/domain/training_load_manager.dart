import 'dart:math';
import '../data/models/workout_models.dart';
import '../../../../core/database/enums.dart';

class SafetyCheckResult {
  final bool isSafe;
  final double? dangerWeightThreshold;
  final double historicalMaxWeight;
  final double historicalMaxE1RM;

  SafetyCheckResult({
    required this.isSafe, 
    this.dangerWeightThreshold,
    required this.historicalMaxWeight,
    required this.historicalMaxE1RM,
  });

  factory SafetyCheckResult.safe({double maxWeight = 0.0, double maxE1RM = 0.0}) {
    return SafetyCheckResult(
      isSafe: true, 
      historicalMaxWeight: maxWeight, 
      historicalMaxE1RM: maxE1RM
    );
  }
}

class LoadAnalysis {
  final double acuteLoad;
  final double chronicLoad;
  final double ratio;
  final LoadZone zone;
  final String adviceKey;
  LoadAnalysis(this.acuteLoad, this.chronicLoad, this.ratio, this.zone, this.adviceKey);
}

class TrainingLoadManager {
  
  /// Thuật toán Absolute 1RM Clamp (Giữ nguyên dùng cho an toàn tạ vật lý)
  static SafetyCheckResult calculateProactiveSafetyThreshold({
    required String exerciseId,
    required List<WorkoutSession> workoutHistory,
  }) {
    final thirtyDaysAgoMillis = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;

    double maxPastWeight = 0.0;
    double maxPastE1RM = 0.0;
    bool hasData = false;

    for (var session in workoutHistory) {
      if (session.startTime < thirtyDaysAgoMillis) continue;
      for (var ex in session.exercises) {
        if (ex.exercise.id == exerciseId) {
          for (var set in ex.sets) {
            if (set.isCompleted && set.weight > 0 && set.reps > 0) {
              hasData = true;
              if (set.weight > maxPastWeight) maxPastWeight = set.weight;
              
              final e1rm = set.weight * (1.0 + set.reps / 30.0);
              if (e1rm > maxPastE1RM) maxPastE1RM = e1rm;
            }
          }
        }
      }
    }

    if (!hasData || maxPastE1RM == 0) {
      return SafetyCheckResult.safe();
    }

    final allowedJump = max(10.0, min(maxPastE1RM * 0.15, 15.0));
    final dangerE1RM = maxPastE1RM + allowedJump;
    final dangerWeight = dangerE1RM / (1.0 + 1.0 / 30.0);
    final roundedDangerWeight = (dangerWeight * 10).roundToDouble() / 10.0;

    return SafetyCheckResult(
      isSafe: false, 
      dangerWeightThreshold: roundedDangerWeight,
      historicalMaxWeight: maxPastWeight,
      historicalMaxE1RM: maxPastE1RM,
    );
  }

  // =====================================================================
  // ĐÃ REFACTOR: TÍNH TẢI TRỌNG THEO CÔNG THỨC FOSTER'S sRPE
  // =====================================================================
  static LoadAnalysis analyzeWeeklyLoad(List<WorkoutSession> workoutHistory, {int? evaluationDateMillis}) {
    final now = evaluationDateMillis ?? DateTime.now().millisecondsSinceEpoch;
    
    const sevenDays = 7 * 24 * 60 * 60 * 1000;
    const twentyEightDays = 28 * 24 * 60 * 60 * 1000;

    // Lõi tính toán Foster's sRPE cho 1 buổi tập
    double calculateSessionSRPE(WorkoutSession session) {
      // Fail-safe: Nếu user không nhập RPE, lấy mốc trung bình khá là 7
      final double rpeValue = (session.rpe != null && session.rpe! > 0) ? session.rpe!.toDouble() : 7.0;
      
      // Fail-safe: Nếu quên bấm giờ, lấy mốc trung bình là 60 phút
      final double durationMinutes = session.totalDurationSeconds > 0 
          ? (session.totalDurationSeconds / 60.0) 
          : 60.0;
          
      return rpeValue * durationMinutes;
    }

    // Tải trọng Cấp tính (7 ngày qua)
    final acuteLoad = workoutHistory
        .where((s) => s.startTime >= now - sevenDays && s.startTime <= now)
        .fold(0.0, (sum, s) => sum + calculateSessionSRPE(s));

    // Lịch sử 28 ngày
    final past28Workouts = workoutHistory
        .where((s) => s.startTime >= now - twentyEightDays && s.startTime <= now)
        .toList();
        
    final totalLoad28 = past28Workouts.fold(0.0, (sum, s) => sum + calculateSessionSRPE(s));

    // Tải trọng Mãn tính (Trung bình 4 tuần)
    double chronicLoad = 1.0;
    if (past28Workouts.isNotEmpty) {
      final firstSessionMillis = past28Workouts.map((s) => s.startTime).reduce(min);
      final activeWeeks = ((now - firstSessionMillis) / sevenDays).clamp(1.0, 4.0);
      chronicLoad = max(1.0, totalLoad28 / activeWeeks);
    }

    // Tỷ lệ ACWR
    final ratio = acuteLoad / chronicLoad;

    // Đánh giá Vùng tải trọng (Không đổi mốc vì ACWR là mô hình tương đối)
    LoadZone zone;
    String adviceKey;
    if (ratio < 0.8) {
      zone = LoadZone.UNDERTRAINING;
      adviceKey = 'MSG_LOAD_UNDER';
    } else if (ratio <= 1.3) {
      zone = LoadZone.OPTIMAL;
      adviceKey = 'MSG_LOAD_OPTIMAL';
    } else if (ratio <= 1.5) {
      zone = LoadZone.OVERREACHING;
      adviceKey = 'MSG_LOAD_OVERREACHING';
    } else {
      zone = LoadZone.OVERTRAINING;
      adviceKey = 'MSG_LOAD_OVERTRAINING';
    }

    return LoadAnalysis(acuteLoad, chronicLoad, ratio, zone, adviceKey);
  }
}       