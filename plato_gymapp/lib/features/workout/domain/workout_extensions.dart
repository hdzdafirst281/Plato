import 'dart:math';
import '../data/models/workout_models.dart';
import '../../../../core/database/enums.dart';

extension WorkoutExerciseX on WorkoutExercise {
  // TÍNH TOÁN LOAD CHUẨN HÓA ($Load_{ex}$)
  // Sử dụng cho thuật toán Dimensionless Relative Load
  double calculateWorkload({double userBodyWeight = 65.0}) {
    final completedSets = sets.where((s) => s.isCompleted).toList();
    if (completedSets.isEmpty) return 0.0;

    switch (exercise.type) {
      case ExerciseType.WEIGHT_REPS:
        return completedSets.fold(0.0, (sum, set) {
          // Xử lý Bodyweight Fallback: Nếu tạ = 0 (Bodyweight) thì lấy cân nặng cơ thể
          double effectiveWeight = set.weight > 0 ? set.weight : userBodyWeight;
          return sum + (effectiveWeight * set.reps);
        });
        
      case ExerciseType.REPS_ONLY:
        // Với REPS_ONLY (vd: Pull-up), Capacity của họ chính là số Reps, không cần nhân kg
        return completedSets.fold(0.0, (sum, set) => sum + set.reps.toDouble());
        
      case ExerciseType.TIME_ONLY:
        return completedSets.fold(0.0, (sum, set) => sum + set.durationTimeSeconds.toDouble());
        
      case ExerciseType.CARDIO_DISTANCE:
        return completedSets.fold(0.0, (sum, set) => sum + set.distanceInKm);
        
      case ExerciseType.CARDIO_STEPS:
        return completedSets.fold(0.0, (sum, set) => sum + set.steps.toDouble());
        
      
    }
  }

  // Lấy giá trị Metric cụ thể dùng cho Biểu đồ
  double getMetricValue(ExerciseMetric metric) {
    final completedSets = sets.where((s) => s.isCompleted).toList();
    if (completedSets.isEmpty) return 0.0;

    switch (metric) {
      case ExerciseMetric.BEST_WEIGHT:
        return completedSets.map((s) => s.weight).reduce(max);
      case ExerciseMetric.ONE_RM:
        return completedSets.map((s) => s.weight * (1 + s.reps / 30.0)).reduce(max);
      case ExerciseMetric.BEST_SET_VOL:
        return completedSets.map((s) => s.weight * s.reps).reduce(max);
      case ExerciseMetric.SESSION_VOL:
        return completedSets.fold(0.0, (sum, s) => sum + (s.weight * s.reps));
      case ExerciseMetric.BEST_TIME:
        return completedSets.map((s) => s.durationTimeSeconds.toDouble()).reduce(max);
      case ExerciseMetric.BEST_STEPS:
        return completedSets.map((s) => s.steps.toDouble()).reduce(max);
      case ExerciseMetric.LONGEST_DISTANCE:
        return completedSets.map((s) => s.distanceInKm).reduce(max);
      case ExerciseMetric.BEST_REPS:
        return completedSets.map((s) => s.reps.toDouble()).reduce(max);
      case ExerciseMetric.SESSION_REPS:
        return completedSets.fold(0.0, (sum, s) => sum + s.reps.toDouble());
      // [THÊM MỚI] Tính tổng thời gian
      case ExerciseMetric.SESSION_TIME:
        return completedSets.fold(0.0, (sum, s) => sum + s.durationTimeSeconds.toDouble());
      // [THÊM MỚI] Tính Pace (Tốc độ km/h cao nhất trong các set)
      case ExerciseMetric.PACE:
        double maxPace = 0.0;
        for (var s in completedSets) {
          if (s.durationTimeSeconds > 0 && s.distanceInKm > 0) {
            double currentPace = s.distanceInKm / (s.durationTimeSeconds / 3600.0);
            if (currentPace > maxPace) maxPace = currentPace;
          }
        }
        return maxPace;
    }
  }

  // ==========================================
  // LOGIC TÍNH PR: ĐẢM BẢO DUY NHẤT 1 PR/BÀI TẬP (First set wins)
  // ==========================================
  List<ExerciseMetric> getAchievedPRsForSet(List<ExerciseSet> pastSets, String targetSetId) {
    final completedSets = sets.where((s) => s.isCompleted).toList();
    if (completedSets.isEmpty) return [];

    final targetSet = completedSets.firstWhere((s) => s.id == targetSetId, orElse: () => const ExerciseSet(id: "fake", weight: 0, reps: 0, durationTimeSeconds: 0, distanceInKm: 0, steps: 0, isCompleted: false));
    if (!targetSet.isCompleted) return [];

    if (pastSets.isEmpty) return [];

    List<ExerciseMetric> prs = [];

    switch (exercise.type) {
      case ExerciseType.WEIGHT_REPS:
        double maxPastWeight = pastSets.isEmpty ? 0.0 : pastSets.map((s) => s.weight).reduce(max);
        double maxTodayWeight = completedSets.map((s) => s.weight).reduce(max);
        if (maxTodayWeight > maxPastWeight && maxTodayWeight > 0) {
          final firstWinner = completedSets.firstWhere((s) => s.weight == maxTodayWeight);
          if (targetSet.id == firstWinner.id) prs.add(ExerciseMetric.BEST_WEIGHT);
        }

        double maxPast1RM = pastSets.isEmpty ? 0.0 : pastSets.map((s) => s.weight * (1 + s.reps / 30.0)).reduce(max);
        double maxToday1RM = completedSets.map((s) => s.weight * (1 + s.reps / 30.0)).reduce(max);
        if (maxToday1RM > maxPast1RM && maxToday1RM > 0) {
          final firstWinner = completedSets.firstWhere((s) => (s.weight * (1 + s.reps / 30.0)) == maxToday1RM);
          if (targetSet.id == firstWinner.id) prs.add(ExerciseMetric.ONE_RM);
        }

        double maxPastVol = pastSets.isEmpty ? 0.0 : pastSets.map((s) => s.weight * s.reps).reduce(max);
        double maxTodayVol = completedSets.map((s) => s.weight * s.reps).reduce(max);
        if (maxTodayVol > maxPastVol && maxTodayVol > 0) {
          final firstWinner = completedSets.firstWhere((s) => (s.weight * s.reps) == maxTodayVol);
          if (targetSet.id == firstWinner.id) prs.add(ExerciseMetric.BEST_SET_VOL);
        }
        break;
      
      case ExerciseType.REPS_ONLY:
        int maxPastReps = pastSets.isEmpty ? 0 : pastSets.map((s) => s.reps).reduce(max);
        int maxTodayReps = completedSets.map((s) => s.reps).reduce(max);
        if (maxTodayReps > maxPastReps && maxTodayReps > 0) {
          final firstWinner = completedSets.firstWhere((s) => s.reps == maxTodayReps);
          if (targetSet.id == firstWinner.id) prs.add(ExerciseMetric.BEST_REPS);
        }
        break;
      
      case ExerciseType.TIME_ONLY:
        int maxPastTime = pastSets.isEmpty ? 0 : pastSets.map((s) => s.durationTimeSeconds).reduce(max);
        int maxTodayTime = completedSets.map((s) => s.durationTimeSeconds).reduce(max);
        if (maxTodayTime > maxPastTime && maxTodayTime > 0) {
          final firstWinner = completedSets.firstWhere((s) => s.durationTimeSeconds == maxTodayTime);
          if (targetSet.id == firstWinner.id) prs.add(ExerciseMetric.BEST_TIME);
        }
        break;
      
      case ExerciseType.CARDIO_DISTANCE:
        double maxPastDist = pastSets.isEmpty ? 0.0 : pastSets.map((s) => s.distanceInKm).reduce(max);
        double maxTodayDist = completedSets.map((s) => s.distanceInKm).reduce(max);
        if (maxTodayDist > maxPastDist && maxTodayDist > 0) {
          final firstWinner = completedSets.firstWhere((s) => s.distanceInKm == maxTodayDist);
          if (targetSet.id == firstWinner.id) prs.add(ExerciseMetric.LONGEST_DISTANCE);
        }
        
        int maxPastTimeDist = pastSets.isEmpty ? 0 : pastSets.map((s) => s.durationTimeSeconds).reduce(max);
        int maxTodayTimeDist = completedSets.map((s) => s.durationTimeSeconds).reduce(max);
        if (maxTodayTimeDist > maxPastTimeDist && maxTodayTimeDist > 0) {
          final firstWinner = completedSets.firstWhere((s) => s.durationTimeSeconds == maxTodayTimeDist);
          if (targetSet.id == firstWinner.id) prs.add(ExerciseMetric.BEST_TIME);
        }

        // [THÊM MỚI] Check PR cho Pace (Tốc độ km/h)
        double maxPastPace = 0.0;
        for (var s in pastSets) {
          if (s.durationTimeSeconds > 0 && s.distanceInKm > 0) {
            double p = s.distanceInKm / (s.durationTimeSeconds / 3600.0);
            if (p > maxPastPace) maxPastPace = p;
          }
        }
        double maxTodayPace = 0.0;
        for (var s in completedSets) {
          if (s.durationTimeSeconds > 0 && s.distanceInKm > 0) {
            double p = s.distanceInKm / (s.durationTimeSeconds / 3600.0);
            if (p > maxTodayPace) maxTodayPace = p;
          }
        }
        if (maxTodayPace > maxPastPace && maxTodayPace > 0) {
          final firstWinner = completedSets.firstWhere((s) {
            if (s.durationTimeSeconds > 0 && s.distanceInKm > 0) {
              return (s.distanceInKm / (s.durationTimeSeconds / 3600.0)) == maxTodayPace;
            }
            return false;
          });
          if (targetSet.id == firstWinner.id) prs.add(ExerciseMetric.PACE);
        }
        break;
      
      case ExerciseType.CARDIO_STEPS:
        int maxPastSteps = pastSets.isEmpty ? 0 : pastSets.map((s) => s.steps).reduce(max);
        int maxTodaySteps = completedSets.map((s) => s.steps).reduce(max);
        if (maxTodaySteps > maxPastSteps && maxTodaySteps > 0) {
          final firstWinner = completedSets.firstWhere((s) => s.steps == maxTodaySteps);
          if (targetSet.id == firstWinner.id) prs.add(ExerciseMetric.BEST_STEPS);
        }
        
        int maxPastTimeSteps = pastSets.isEmpty ? 0 : pastSets.map((s) => s.durationTimeSeconds).reduce(max);
        int maxTodayTimeSteps = completedSets.map((s) => s.durationTimeSeconds).reduce(max);
        if (maxTodayTimeSteps > maxPastTimeSteps && maxTodayTimeSteps > 0) {
          final firstWinner = completedSets.firstWhere((s) => s.durationTimeSeconds == maxTodayTimeSteps);
          if (targetSet.id == firstWinner.id) prs.add(ExerciseMetric.BEST_TIME);
        }
        break;
    }
    return prs;
  }
}

extension WorkoutSessionPRX on WorkoutSession {
  /// Tính TỔNG SỐ LƯỢNG PR đạt được trong toàn bộ Buổi Tập (Session)
  int calculateTotalPRs(List<WorkoutSession> allHistory) {
    int totalPRs = 0;
    // Lọc ra các buổi tập xảy ra TRƯỚC thời điểm của session này
    final pastHistory = allHistory.where((s) => s.startTime < startTime).toList();

    for (var ex in exercises) {
      List<ExerciseSet> pastSetsForEx = [];
      for (var pastSession in pastHistory) {
        final pastEx = pastSession.exercises.where((e) => e.exercise.id == ex.exercise.id).firstOrNull;
        if (pastEx != null) pastSetsForEx.addAll(pastEx.sets.where((s) => s.isCompleted));
      }

      final Set<ExerciseMetric> achievedMetricsForThisExercise = {};
      for (var set in ex.sets) {
         if (!set.isCompleted) continue;
         final prs = ex.getAchievedPRsForSet(pastSetsForEx, set.id);
         achievedMetricsForThisExercise.addAll(prs); 
      }
      totalPRs += achievedMetricsForThisExercise.length;
    }
    return totalPRs;
  }
}

extension MuscleDistributionX on List<WorkoutExercise> {
  /// Tính toán phần trăm phân bổ nhóm cơ (Luôn trả về tổng = 100.0, min = 1.0%)
  /// - [onlyCompletedSets]: Đặt true nếu dùng cho Lịch sử (Workout Session), false nếu dùng cho Giáo án.
  Map<MajorMuscleGroup, double> calculateMuscleDistribution({bool onlyCompletedSets = false}) {
    final List<MajorMuscleGroup> physicalMuscles = [
      MajorMuscleGroup.CHEST, MajorMuscleGroup.BACK, MajorMuscleGroup.LEGS,
      MajorMuscleGroup.SHOULDERS, MajorMuscleGroup.ARMS, MajorMuscleGroup.CORE,
    ];

    final rawScoresMap = <MajorMuscleGroup, double>{};
    for (var m in physicalMuscles) {
      rawScoresMap[m] = 0.0;
    }

    // 1. Chấm điểm thô (Raw Scores)
    for (var exercise in this) {
      final validSets = onlyCompletedSets 
          ? exercise.sets.where((s) => s.isCompleted).toList() 
          : exercise.sets;
      
      final setCount = validSets.length;
      if (setCount == 0) continue;

      final primaryMajor = exercise.exercise.primaryMuscle?.major;
      if (primaryMajor != null && physicalMuscles.contains(primaryMajor)) {
        rawScoresMap[primaryMajor] = rawScoresMap[primaryMajor]! + (3.0 * setCount);
      }
      
      exercise.exercise.secondaryMuscles?.forEach((secondaryMuscle) {
        if (physicalMuscles.contains(secondaryMuscle.major)) {
          rawScoresMap[secondaryMuscle.major] = rawScoresMap[secondaryMuscle.major]! + (1.0 * setCount);
        }
      });
    }

    final totalScore = rawScoresMap.values.fold(0.0, (sum, val) => sum + val);
    final distributionMap = <MajorMuscleGroup, double>{};
    
    // 2. Chuẩn hóa tỷ lệ (Ép min 1%)
    if (totalScore > 0) {
      for (var m in physicalMuscles) {
        // [CRITIC FIX]: Cấp vốn 1.0 (1%) cho mọi nhóm cơ. 94.0% còn lại chia theo tỷ lệ điểm thô.
        // Đảm bảo: (6 * 1.0) + 94.0 = 100.0% tuyệt đối.
        distributionMap[m] = 1.0 + ((rawScoresMap[m]! / totalScore) * 94.0);
      }
    } else {
      // Xử lý Fallback khi không có data: Chia đều 100% cho 6 nhóm (16.66% mỗi nhóm)
      for (var m in physicalMuscles) {
        distributionMap[m] = 100.0 / 6.0; 
      }
    }
    
    return distributionMap;
  }
}
