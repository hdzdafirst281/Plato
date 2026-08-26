import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/database/enums.dart';
import '../../../nutrition/data/models/nutrition_models.dart'; 

part 'user_models.freezed.dart';
part 'user_models.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') @Default('Gym Warrior') String displayName,
    @JsonKey(name: 'avatar_base64') String? avatarBase64, 
    
    @JsonKey(name: 'gender') @Default(Gender.MALE) Gender gender,
    @JsonKey(name: 'age') @Default(25) int userAge,
    @JsonKey(name: 'height_cm') @Default(175.0) double heightInCm,
    @JsonKey(name: 'weight_kg') @Default(75.0) double weightInKg,
    @JsonKey(name: 'body_fat') double? bodyFatPercentage,
    
    // Thuộc tính tùy chọn
    @JsonKey(name: 'workout_goal') @Default(WorkoutGoal.STRENGTH) WorkoutGoal workoutGoal,
    @JsonKey(name: 'nutrition_goal') @Default(NutritionGoal.MAINTAIN_WEIGHT) NutritionGoal nutritionGoal,
    @JsonKey(name: 'activity_level') @Default(ActivityLevel.MODERATE) ActivityLevel activityLevel,
    @JsonKey(name: 'days_available') @Default('3-5') String trainingDaysPerWeek,
    @JsonKey(name: 'injuries') @Default([]) List<String> reportedInjuries,
    @JsonKey(name: 'dietary_restrictions') @Default([]) List<String> dietaryRestrictions,
    @JsonKey(name: 'environment') @Default(WorkoutEnvironment.GYM) WorkoutEnvironment environment,
    
    // Mục tiêu & Macro
    @JsonKey(name: 'tdee') @Default(2000) int calculatedTdee,
    @JsonKey(name: 'target_macros') required Macros targetMacros, 
    
    // BỔ SUNG CỜ CUSTOM MACRO ĐỂ TRÁNH XUNG ĐỘT LOGIC
    @JsonKey(name: 'is_custom_macros') @Default(false) bool isCustomMacros,
    
    @JsonKey(name: 'weekly_goal_rate') double? weeklyGoalRate, 
    
    // Gamification
    @JsonKey(name: 'xp') @Default(0) int experiencePoints,
    @JsonKey(name: 'current_rp') @Default(0) int currentRp,
    @JsonKey(name: 'last_rp_season_id') @Default(1) int lastRpSeasonId,
    @JsonKey(name: 'rank_history') @Default([]) List<RankTimelineItem> rankAdvancementHistory,
    @JsonKey(name: 'current_rank_id') @Default(1) int activeRankId,
    
    @JsonKey(name: 'body_metrics') required BodyMetrics detailedBodyMetrics,
    
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(0) int socialFollowersCount,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(0) int socialFollowingCount,
    
    @JsonKey(name: 'experience_level') String? experienceLevel,
    @JsonKey(name: 'diet_plan') String? dietPlan,
    
    @JsonKey(name: 'target_weight_kg') double? targetGoalWeightKg,
    @JsonKey(name: 'start_weight_kg') double? startingWeightKg,
    @JsonKey(name: 'start_date_millis') int? goalStartTimestampMillis,
    @JsonKey(name: 'last_weight_update_millis') int? lastWeightUpdateTimestampMillis,
    @JsonKey(name: 'disable_weekly_weight_reminder') @Default(false) bool disableWeeklyWeightReminder,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}

@freezed
class BodyMeasurement with _$BodyMeasurement {
  const factory BodyMeasurement({
    @JsonKey(name: 'date') required int recordTimestampMillis,
    @JsonKey(name: 'weight') required double recordedWeightKg,
  }) = _BodyMeasurement;

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) => _$BodyMeasurementFromJson(json);
}

@freezed
class RankTimelineItem with _$RankTimelineItem {
  const factory RankTimelineItem({
    @JsonKey(name: 'rank_id') required int rankId,
    @JsonKey(name: 'timestamp') required int achievedAtMillis,
    @JsonKey(name: 'reason') required String unlockReasonDescription,
  }) = _RankTimelineItem;

  factory RankTimelineItem.fromJson(Map<String, dynamic> json) => _$RankTimelineItemFromJson(json);
}

@freezed
class BodyMetrics with _$BodyMetrics {
  const factory BodyMetrics({
    @JsonKey(name: 'neck') @Default(0.0) double neckCm,
    @JsonKey(name: 'shoulders') @Default(0.0) double shouldersCm,
    @JsonKey(name: 'chest') @Default(0.0) double chestCm,
    @JsonKey(name: 'biceps_left') @Default(0.0) double bicepsLeftCm,
    @JsonKey(name: 'biceps_right') @Default(0.0) double bicepsRightCm,
    @JsonKey(name: 'forearm_left') @Default(0.0) double forearmLeftCm,
    @JsonKey(name: 'forearm_right') @Default(0.0) double forearmRightCm,
    @JsonKey(name: 'waist') @Default(0.0) double waistCm,
    @JsonKey(name: 'hips') @Default(0.0) double hipsCm,
    @JsonKey(name: 'thigh_left') @Default(0.0) double thighLeftCm,
    @JsonKey(name: 'thigh_right') @Default(0.0) double thighRightCm,
    @JsonKey(name: 'calf_left') @Default(0.0) double calfLeftCm,
    @JsonKey(name: 'calf_right') @Default(0.0) double calfRightCm,
  }) = _BodyMetrics;

  factory BodyMetrics.fromJson(Map<String, dynamic> json) => _$BodyMetricsFromJson(json);
}