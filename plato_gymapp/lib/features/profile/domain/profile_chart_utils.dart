import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../workout/data/models/workout_models.dart';
import '../../workout/domain/workout_extensions.dart'; 
import '../../../../core/database/enums.dart';
import '../../workout/domain/training_load_manager.dart'; 

// ==========================================
// DATA CLASSES
// ==========================================

class StatPoint {
  final int timestamp;
  final String label;
  final double volume;
  final double durationHours;
  final int reps;
  StatPoint(this.timestamp, this.label, this.volume, this.durationHours, this.reps);
}

// ==========================================
// THUẬT TOÁN BIỂU ĐỒ & THỐNG KÊ
// ==========================================
class ProfileChartUtils {

  // ==========================================
  // ELITE VOLUME THRESHOLDS (GAMIFICATION HARDCORE SCALING)
  // ==========================================
  
  /// Lấy mốc Rank S (1.0) cho Hexagon Screen (Macro Groups)
  /// Được thiết lập dựa trên Elite MRV để đảm bảo Rank S là một thử thách thực sự.
  static double getHexagonMaxVolume(String majorMuscleName) {
    switch (majorMuscleName) {
      case "Legs": 
        return 160.0; 
      case "Back": 
        return 140.0;
      case "Chest":
      case "Shoulders":
      case "Arms":
        return 120.0;
      case "Abs":
        return 90.0;
      default:
        return 100.0;
    }
  }

  /// Lấy mốc Extreme (1.0) cho Heatmap Screen (Micro Muscles)
  /// Dựa trên MAV (Maximum Adaptive Volume) của 1 nhóm cơ sinh học cụ thể.
  static double getHeatmapOptimalVolume(MuscleGroup group) {
    switch (group) {
      case MuscleGroup.QUADS:
      case MuscleGroup.LATS:
      case MuscleGroup.UPPER_CHEST:
      case MuscleGroup.MIDDLE_CHEST:
      case MuscleGroup.LOWER_CHEST:
      case MuscleGroup.GLUTES:
        return 80.0; 
      default:
        return 60.0;
    }
  }

  static List<LoadAnalysis> calculateLoadHistory(List<WorkoutSession> workouts, int maxWeeks) {
    if (workouts.isEmpty) return [];

    final sortedWorkouts = List<WorkoutSession>.from(workouts)..sort((a, b) => a.startTime.compareTo(b.startTime));
    final firstWorkoutDate = DateTime.fromMillisecondsSinceEpoch(sortedWorkouts.first.startTime);
    final now = DateTime.now();

    final daysSinceFirst = now.difference(firstWorkoutDate).inDays;
    int activeWeeks = math.max(1, (daysSinceFirst / 7).floor() + 1); 
    int weeksToShow = math.min(activeWeeks, maxWeeks);
    
    final result = <LoadAnalysis>[];
    for (int i = weeksToShow - 1; i >= 0; i--) {
      final targetDateMillis = now.subtract(Duration(days: i * 7)).millisecondsSinceEpoch;
      final historicalWorkouts = sortedWorkouts.where((w) => w.startTime <= targetDateMillis).toList();
      
      final analysis = TrainingLoadManager.analyzeWeeklyLoad(historicalWorkouts, evaluationDateMillis: targetDateMillis);
      result.add(analysis);
    }
    return result;
  }

  static Map<MuscleGroup, double> calculateWeeklyCoverage(List<WorkoutSession> workouts) {
    final scores = <MuscleGroup, double>{};
    for (var muscle in MuscleGroup.values) {
      scores[muscle] = 0.0; 
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);
    final recentWorkouts = workouts.where((w) => w.startTime >= sevenDaysAgo).toList();
    
    for (var w in recentWorkouts) {
      for (var we in w.exercises) {
        if (we.exercise.primaryMuscle != null) scores[we.exercise.primaryMuscle!] = 1.0;
        if (we.exercise.secondaryMuscles != null) {
          for (var secondary in we.exercise.secondaryMuscles!) {
            scores[secondary] = 1.0;
          }
        }
      }
    }
    return scores;
  }

  static Map<MuscleGroup, double> calculateDetailedMuscleScores(List<WorkoutSession> workouts) {
    final scores = <MuscleGroup, double>{};
    for (var w in workouts) {
      for (var we in w.exercises) {
        // LỌC HARD SETS DỰA TRÊN SetType VÀ isCompleted
        final hardSetsCompleted = we.sets.where((s) => 
            s.isCompleted && 
            (s.type == SetType.NORMAL || s.type == SetType.DROPSET || s.type == SetType.FAILURE)
        ).length.toDouble();

        if (hardSetsCompleted > 0) {
          final primary = we.exercise.primaryMuscle;
          if (primary != null && primary != MuscleGroup.FULL_BODY && primary != MuscleGroup.CARDIO) {
            scores[primary] = (scores[primary] ?? 0.0) + hardSetsCompleted; // Tỷ lệ 1.0 cho cơ chính
          }
          for (var secondary in we.exercise.secondaryMuscles ?? []) {
            if (secondary != MuscleGroup.FULL_BODY && secondary != MuscleGroup.CARDIO) {
              scores[secondary] = (scores[secondary] ?? 0.0) + (hardSetsCompleted / 3.0); // Tỷ lệ 1/3 cho cơ phụ
            }
          }
        }
      }
    }
    return scores;
  }

  static Map<String, double> calculateRawMuscleScores(List<WorkoutSession> workouts) {
    final scores = {"Chest": 0.0, "Back": 0.0, "Abs": 0.0, "Legs": 0.0, "Shoulders": 0.0, "Arms": 0.0};
    if (workouts.isEmpty) return scores;

    void addScore(MajorMuscleGroup? mg, double weight, double setsCompleted) {
      switch (mg) {
        case MajorMuscleGroup.CHEST: scores["Chest"] = scores["Chest"]! + (setsCompleted * weight); break;
        case MajorMuscleGroup.BACK: scores["Back"] = scores["Back"]! + (setsCompleted * weight); break;
        case MajorMuscleGroup.CORE: scores["Abs"] = scores["Abs"]! + (setsCompleted * weight); break;
        case MajorMuscleGroup.LEGS: scores["Legs"] = scores["Legs"]! + (setsCompleted * weight); break;
        case MajorMuscleGroup.SHOULDERS: scores["Shoulders"] = scores["Shoulders"]! + (setsCompleted * weight); break;
        case MajorMuscleGroup.ARMS: scores["Arms"] = scores["Arms"]! + (setsCompleted * weight); break;
        default: break;
      }
    }

    for (var w in workouts) {
      for (var we in w.exercises) {
        // LỌC HARD SETS DỰA TRÊN SetType VÀ isCompleted
        final hardSetsCompleted = we.sets.where((s) => 
            s.isCompleted && 
            (s.type == SetType.NORMAL || s.type == SetType.DROPSET || s.type == SetType.FAILURE)
        ).length.toDouble();
        
        if (hardSetsCompleted > 0) {
          addScore(we.exercise.primaryMuscle?.major, 1.0, hardSetsCompleted); // Tỷ lệ 1.0 cho cơ chính
          for (var secondary in we.exercise.secondaryMuscles ?? []) {
            addScore(secondary.major, 1.0 / 3.0, hardSetsCompleted); // Tỷ lệ 1/3 cho cơ phụ
          }
        }
      }
    }
    return scores;
  }

  static List<StatPoint> aggregateStatsByTimeRange(List<WorkoutSession> workouts, ChartTimeRange range, String langCode) {
    if (workouts.isEmpty) return [];

    final now = DateTime.now();
    DateTime limitDate;
    bool isWeekly = range == ChartTimeRange.THREE_MONTHS;

    if (range == ChartTimeRange.THREE_MONTHS) {
      limitDate = now.subtract(const Duration(days: 90));
    } else if (range == ChartTimeRange.YEAR) limitDate = now.subtract(const Duration(days: 365));
    else limitDate = DateTime.fromMillisecondsSinceEpoch(0);

    final validWorkouts = workouts.where((w) {
      final d = DateTime.fromMillisecondsSinceEpoch(w.startTime);
      return d.isAfter(limitDate) || d.isAtSameMomentAs(limitDate);
    }).toList();

    if (validWorkouts.isEmpty) return [];

    validWorkouts.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    final firstDate = DateTime.fromMillisecondsSinceEpoch(validWorkouts.first.startTime);
    final lastDate = DateTime.fromMillisecondsSinceEpoch(validWorkouts.last.startTime);
    
    final buckets = <DateTime, List<WorkoutSession>>{};

    DateTime current = isWeekly
        ? DateTime(firstDate.year, firstDate.month, firstDate.day).subtract(Duration(days: firstDate.weekday - 1))
        : DateTime(firstDate.year, firstDate.month, 1);
        
    DateTime endAligned = isWeekly
        ? DateTime(lastDate.year, lastDate.month, lastDate.day).subtract(Duration(days: lastDate.weekday - 1))
        : DateTime(lastDate.year, lastDate.month, 1);

    while (current.isBefore(endAligned) || current.isAtSameMomentAs(endAligned)) {
      buckets[current] = [];
      if (isWeekly) {
        current = current.add(const Duration(days: 7));
      } else {
        current = DateTime(current.year, current.month + 1, 1);
      }
    }

    for (var w in validWorkouts) {
      final d = DateTime.fromMillisecondsSinceEpoch(w.startTime);
      DateTime bucketKey = isWeekly
          ? DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1))
          : DateTime(d.year, d.month, 1);
          
      if (buckets.containsKey(bucketKey)) {
        buckets[bucketKey]!.add(w);
      }
    }

    final dateFormat = isWeekly ? DateFormat('dd/MM') : DateFormat('MM/yyyy');
    var result = buckets.entries.map((e) {
      final date = e.key;
      final slice = e.value;
      return StatPoint(
        date.millisecondsSinceEpoch,
        dateFormat.format(date), 
        slice.fold(0.0, (sum, w) => sum + w.totalVolume),
        slice.fold(0.0, (sum, w) => sum + w.totalDurationSeconds) / 3600.0,
        slice.fold(0, (sum, w) => sum + w.exercises.fold(0, (sumE, ex) => sumE + ex.getMetricValue(ExerciseMetric.SESSION_REPS).toInt())),
      );
    }).toList();

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (result.length > 12) {
      result = result.sublist(result.length - 12);
    }

    return result;
  }
}

class HeatmapStats {
  final int totalWorkouts;
  final int maxDaysStreak;
  final int maxWeeksStreak;
  const HeatmapStats(this.totalWorkouts, this.maxDaysStreak, this.maxWeeksStreak);
}

// Thêm hàm này vào bên trong class ProfileChartUtils
HeatmapStats calculateHeatmapStats(List<WorkoutSession> workouts, {int? targetYear}) {
  if (workouts.isEmpty) return const HeatmapStats(0, 0, 0);

  Iterable<WorkoutSession> filtered = workouts;
  if (targetYear != null) {
    filtered = workouts.where((w) {
      return DateTime.fromMillisecondsSinceEpoch(w.startTime).toLocal().year == targetYear;
    });
  }

  if (filtered.isEmpty) return const HeatmapStats(0, 0, 0);

  int totalWorkouts = filtered.length;
  
  // Ép về UTC để loại bỏ hoàn toàn các sai số do múi giờ và Daylight Saving Time
  List<DateTime> activeDates = filtered.map((w) {
    final d = DateTime.fromMillisecondsSinceEpoch(w.startTime).toLocal();
    return DateTime.utc(d.year, d.month, d.day);
  }).toSet().toList();
  
  activeDates.sort();

  int maxDays = 0, currentDays = 0;
  DateTime? lastDate;
  Set<DateTime> weekStarts = {};

  for (var date in activeDates) {
    if (lastDate == null) {
      currentDays = 1;
    } else {
      final diff = date.difference(lastDate).inDays;
      if (diff == 1) {
        currentDays++;
      } else if (diff > 1) {
        currentDays = 1;
      }
    }
    if (currentDays > maxDays) maxDays = currentDays;
    lastDate = date;

    // Xác định ngày thứ 2 đầu tuần của workout đó
    weekStarts.add(date.subtract(Duration(days: date.weekday - 1)));
  }

  int maxWeeks = 0, currentWeeks = 0;
  DateTime? lastWeek;
  final sortedWeeks = weekStarts.toList()..sort();

  for (var w in sortedWeeks) {
    if (lastWeek == null) {
      currentWeeks = 1;
    } else {
      final diff = w.difference(lastWeek).inDays;
      if (diff == 7) {
        currentWeeks++;
      } else if (diff > 7) {
        currentWeeks = 1;
      }
    }
    if (currentWeeks > maxWeeks) maxWeeks = currentWeeks;
    lastWeek = w;
  }

  return HeatmapStats(totalWorkouts, maxDays, maxWeeks);
}