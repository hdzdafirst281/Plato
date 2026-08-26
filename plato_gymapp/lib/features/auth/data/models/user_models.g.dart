// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: json['id'] as String?,
      displayName: json['name'] as String? ?? 'Gym Warrior',
      avatarBase64: json['avatar_base64'] as String?,
      gender:
          $enumDecodeNullable(_$GenderEnumMap, json['gender']) ?? Gender.MALE,
      userAge: (json['age'] as num?)?.toInt() ?? 25,
      heightInCm: (json['height_cm'] as num?)?.toDouble() ?? 175.0,
      weightInKg: (json['weight_kg'] as num?)?.toDouble() ?? 75.0,
      bodyFatPercentage: (json['body_fat'] as num?)?.toDouble(),
      workoutGoal:
          $enumDecodeNullable(_$WorkoutGoalEnumMap, json['workout_goal']) ??
              WorkoutGoal.STRENGTH,
      nutritionGoal:
          $enumDecodeNullable(_$NutritionGoalEnumMap, json['nutrition_goal']) ??
              NutritionGoal.MAINTAIN_WEIGHT,
      activityLevel:
          $enumDecodeNullable(_$ActivityLevelEnumMap, json['activity_level']) ??
              ActivityLevel.MODERATE,
      trainingDaysPerWeek: json['days_available'] as String? ?? '3-5',
      reportedInjuries: (json['injuries'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      dietaryRestrictions: (json['dietary_restrictions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      environment: $enumDecodeNullable(
              _$WorkoutEnvironmentEnumMap, json['environment']) ??
          WorkoutEnvironment.GYM,
      calculatedTdee: (json['tdee'] as num?)?.toInt() ?? 2000,
      targetMacros:
          Macros.fromJson(json['target_macros'] as Map<String, dynamic>),
      isCustomMacros: json['is_custom_macros'] as bool? ?? false,
      weeklyGoalRate: (json['weekly_goal_rate'] as num?)?.toDouble(),
      experiencePoints: (json['xp'] as num?)?.toInt() ?? 0,
      currentRp: (json['current_rp'] as num?)?.toInt() ?? 0,
      lastRpSeasonId: (json['last_rp_season_id'] as num?)?.toInt() ?? 1,
      rankAdvancementHistory: (json['rank_history'] as List<dynamic>?)
              ?.map((e) => RankTimelineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeRankId: (json['current_rank_id'] as num?)?.toInt() ?? 1,
      detailedBodyMetrics:
          BodyMetrics.fromJson(json['body_metrics'] as Map<String, dynamic>),
      experienceLevel: json['experience_level'] as String?,
      dietPlan: json['diet_plan'] as String?,
      targetGoalWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
      startingWeightKg: (json['start_weight_kg'] as num?)?.toDouble(),
      goalStartTimestampMillis: (json['start_date_millis'] as num?)?.toInt(),
      lastWeightUpdateTimestampMillis:
          (json['last_weight_update_millis'] as num?)?.toInt(),
      disableWeeklyWeightReminder:
          json['disable_weekly_weight_reminder'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.displayName,
      'avatar_base64': instance.avatarBase64,
      'gender': _$GenderEnumMap[instance.gender]!,
      'age': instance.userAge,
      'height_cm': instance.heightInCm,
      'weight_kg': instance.weightInKg,
      'body_fat': instance.bodyFatPercentage,
      'workout_goal': _$WorkoutGoalEnumMap[instance.workoutGoal]!,
      'nutrition_goal': _$NutritionGoalEnumMap[instance.nutritionGoal]!,
      'activity_level': _$ActivityLevelEnumMap[instance.activityLevel]!,
      'days_available': instance.trainingDaysPerWeek,
      'injuries': instance.reportedInjuries,
      'dietary_restrictions': instance.dietaryRestrictions,
      'environment': _$WorkoutEnvironmentEnumMap[instance.environment]!,
      'tdee': instance.calculatedTdee,
      'target_macros': instance.targetMacros,
      'is_custom_macros': instance.isCustomMacros,
      'weekly_goal_rate': instance.weeklyGoalRate,
      'xp': instance.experiencePoints,
      'current_rp': instance.currentRp,
      'last_rp_season_id': instance.lastRpSeasonId,
      'rank_history': instance.rankAdvancementHistory,
      'current_rank_id': instance.activeRankId,
      'body_metrics': instance.detailedBodyMetrics,
      'experience_level': instance.experienceLevel,
      'diet_plan': instance.dietPlan,
      'target_weight_kg': instance.targetGoalWeightKg,
      'start_weight_kg': instance.startingWeightKg,
      'start_date_millis': instance.goalStartTimestampMillis,
      'last_weight_update_millis': instance.lastWeightUpdateTimestampMillis,
      'disable_weekly_weight_reminder': instance.disableWeeklyWeightReminder,
    };

const _$GenderEnumMap = {
  Gender.MALE: 'MALE',
  Gender.FEMALE: 'FEMALE',
};

const _$WorkoutGoalEnumMap = {
  WorkoutGoal.BULK: 'BULK',
  WorkoutGoal.CUT: 'CUT',
  WorkoutGoal.STRENGTH: 'STRENGTH',
};

const _$NutritionGoalEnumMap = {
  NutritionGoal.GAIN_WEIGHT: 'GAIN_WEIGHT',
  NutritionGoal.LOSE_WEIGHT: 'LOSE_WEIGHT',
  NutritionGoal.MAINTAIN_WEIGHT: 'MAINTAIN_WEIGHT',
};

const _$ActivityLevelEnumMap = {
  ActivityLevel.SEDENTARY: 'SEDENTARY',
  ActivityLevel.LIGHT: 'LIGHT',
  ActivityLevel.MODERATE: 'MODERATE',
  ActivityLevel.ACTIVE: 'ACTIVE',
};

const _$WorkoutEnvironmentEnumMap = {
  WorkoutEnvironment.GYM: 'GYM',
  WorkoutEnvironment.HOME_BODYWEIGHT: 'HOME_BODYWEIGHT',
  WorkoutEnvironment.HOME_DUMBBELL: 'HOME_DUMBBELL',
};

_$BodyMeasurementImpl _$$BodyMeasurementImplFromJson(
        Map<String, dynamic> json) =>
    _$BodyMeasurementImpl(
      recordTimestampMillis: (json['date'] as num).toInt(),
      recordedWeightKg: (json['weight'] as num).toDouble(),
    );

Map<String, dynamic> _$$BodyMeasurementImplToJson(
        _$BodyMeasurementImpl instance) =>
    <String, dynamic>{
      'date': instance.recordTimestampMillis,
      'weight': instance.recordedWeightKg,
    };

_$RankTimelineItemImpl _$$RankTimelineItemImplFromJson(
        Map<String, dynamic> json) =>
    _$RankTimelineItemImpl(
      rankId: (json['rank_id'] as num).toInt(),
      achievedAtMillis: (json['timestamp'] as num).toInt(),
      unlockReasonDescription: json['reason'] as String,
    );

Map<String, dynamic> _$$RankTimelineItemImplToJson(
        _$RankTimelineItemImpl instance) =>
    <String, dynamic>{
      'rank_id': instance.rankId,
      'timestamp': instance.achievedAtMillis,
      'reason': instance.unlockReasonDescription,
    };

_$BodyMetricsImpl _$$BodyMetricsImplFromJson(Map<String, dynamic> json) =>
    _$BodyMetricsImpl(
      neckCm: (json['neck'] as num?)?.toDouble() ?? 0.0,
      shouldersCm: (json['shoulders'] as num?)?.toDouble() ?? 0.0,
      chestCm: (json['chest'] as num?)?.toDouble() ?? 0.0,
      bicepsLeftCm: (json['biceps_left'] as num?)?.toDouble() ?? 0.0,
      bicepsRightCm: (json['biceps_right'] as num?)?.toDouble() ?? 0.0,
      forearmLeftCm: (json['forearm_left'] as num?)?.toDouble() ?? 0.0,
      forearmRightCm: (json['forearm_right'] as num?)?.toDouble() ?? 0.0,
      waistCm: (json['waist'] as num?)?.toDouble() ?? 0.0,
      hipsCm: (json['hips'] as num?)?.toDouble() ?? 0.0,
      thighLeftCm: (json['thigh_left'] as num?)?.toDouble() ?? 0.0,
      thighRightCm: (json['thigh_right'] as num?)?.toDouble() ?? 0.0,
      calfLeftCm: (json['calf_left'] as num?)?.toDouble() ?? 0.0,
      calfRightCm: (json['calf_right'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$BodyMetricsImplToJson(_$BodyMetricsImpl instance) =>
    <String, dynamic>{
      'neck': instance.neckCm,
      'shoulders': instance.shouldersCm,
      'chest': instance.chestCm,
      'biceps_left': instance.bicepsLeftCm,
      'biceps_right': instance.bicepsRightCm,
      'forearm_left': instance.forearmLeftCm,
      'forearm_right': instance.forearmRightCm,
      'waist': instance.waistCm,
      'hips': instance.hipsCm,
      'thigh_left': instance.thighLeftCm,
      'thigh_right': instance.thighRightCm,
      'calf_left': instance.calfLeftCm,
      'calf_right': instance.calfRightCm,
    };
