// ignore_for_file: constant_identifier_names

// lib/core/database/enums.dart

enum MajorMuscleGroup { CHEST, BACK, LEGS, SHOULDERS, ARMS, CORE, FULL_BODY, CARDIO }

enum MuscleGroup {
  UPPER_CHEST(MajorMuscleGroup.CHEST),
  MIDDLE_CHEST(MajorMuscleGroup.CHEST),
  LOWER_CHEST(MajorMuscleGroup.CHEST),

  LATS(MajorMuscleGroup.BACK),
  UPPER_BACK(MajorMuscleGroup.BACK),
  LOWER_BACK(MajorMuscleGroup.BACK),
  TRAPS(MajorMuscleGroup.BACK),
  NECK(MajorMuscleGroup.BACK),

  FRONT_DELTS(MajorMuscleGroup.SHOULDERS),
  SIDE_DELTS(MajorMuscleGroup.SHOULDERS),
  REAR_DELTS(MajorMuscleGroup.SHOULDERS),

  BICEPS(MajorMuscleGroup.ARMS),
  TRICEPS(MajorMuscleGroup.ARMS),
  FOREARMS(MajorMuscleGroup.ARMS),

  QUADS(MajorMuscleGroup.LEGS),
  HAMSTRINGS(MajorMuscleGroup.LEGS),
  GLUTES(MajorMuscleGroup.LEGS),
  CALVES(MajorMuscleGroup.LEGS),
  ADDUCTORS(MajorMuscleGroup.LEGS),
  ABDUCTORS(MajorMuscleGroup.LEGS),

  ABS(MajorMuscleGroup.CORE),
  OBLIQUES(MajorMuscleGroup.CORE),

  FULL_BODY(MajorMuscleGroup.FULL_BODY),
  CARDIO(MajorMuscleGroup.CARDIO);

  // 1. Khai báo thuộc tính major
  final MajorMuscleGroup major;

  // 2. Khai báo constructor
  const MuscleGroup(this.major);
}

enum TimerMode { STOPWATCH, COUNTDOWN }

enum QuestType { WORKOUT_COUNT, TOTAL_VOLUME, PR_COUNT, TOTAL_TIME, TOTAL_SETS, TOTAL_EXERCISES}

enum ExerciseType { WEIGHT_REPS, REPS_ONLY, TIME_ONLY, CARDIO_DISTANCE, CARDIO_STEPS }

enum FoodUnit { GRAM, SERVING, ML, OZ, QUANTITY }

enum MealType { BREAKFAST, LUNCH, DINNER, SNACK }

enum WorkoutEnvironment { GYM, HOME_BODYWEIGHT, HOME_DUMBBELL }

enum WorkoutGoal { BULK, CUT, STRENGTH }

enum NutritionGoal { GAIN_WEIGHT, LOSE_WEIGHT, MAINTAIN_WEIGHT }

enum SyncStatus { PENDING, SYNCED }

enum PostAuthSyncResult { NEW_USER_PUSHED, OLD_USER_RESTORED, DATA_MERGED, ERROR }

enum Gender { MALE, FEMALE }

enum ActivityLevel { SEDENTARY, LIGHT, MODERATE, ACTIVE }

enum SetType { NORMAL, WARMUP, SUPERSET, DROPSET, FAILURE }

enum ChartTimeRange {
  WEEK, MONTH, THREE_MONTHS, YEAR, ALL_TIME;

  int get days {
    switch (this) {
      case ChartTimeRange.WEEK: return 7;
      case ChartTimeRange.MONTH: return 30;
      case ChartTimeRange.THREE_MONTHS: return 90;
      case ChartTimeRange.YEAR: return 365;
      case ChartTimeRange.ALL_TIME: return 9999;
    }
  }
}

enum ExerciseMetric { 
  BEST_WEIGHT, 
  ONE_RM, 
  BEST_SET_VOL, 
  SESSION_VOL, 
  BEST_TIME, 
  BEST_STEPS, 
  LONGEST_DISTANCE, 
  BEST_REPS, 
  SESSION_REPS,
  SESSION_TIME, 
  PACE          
}

enum RecoveryState { FRESH, RECOVERING, EXHAUSTED }

enum LoadZone { UNDERTRAINING, OPTIMAL, OVERREACHING, OVERTRAINING }

enum WarningLevel { SAFE, CAUTION, DANGER }

enum RankTier { BEGINNER, INTERMEDIATE, ADVANCED, ELITE }

enum HeatmapMode { INTENSITY, FREQUENCY }

enum BarChartMetric { VOLUME, DURATION, REPS }

enum CalendarViewMode { MONTH, YEAR, MULTI_YEAR }

enum StatsScreenType { DASHBOARD, HEXAGON_DETAIL, HEATMAP_DETAIL, HISTORY_DETAIL, LOAD_DETAIL }

enum Equipment {
  BODYWEIGHT,
  BARBELL,
  DUMBBELL,
  MACHINE,
  CABLE,
  KETTLEBELL,
  BAND,
  ROPE,
  OTHER;

  // Extension helper để lấy key dịch thuật (tương tự như getLocalizedName() của bạn)
  String getLocalizedName() {
    return 'equipment_${name.toLowerCase()}'; // VD: 'equipment_dumbbell' sẽ được dịch bằng .tr()
  }
}