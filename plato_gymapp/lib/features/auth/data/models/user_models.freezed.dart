// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  @JsonKey(name: 'id')
  String? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  String get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_base64')
  String? get avatarBase64 => throw _privateConstructorUsedError;
  @JsonKey(name: 'gender')
  Gender get gender => throw _privateConstructorUsedError;
  @JsonKey(name: 'age')
  int get userAge => throw _privateConstructorUsedError;
  @JsonKey(name: 'height_cm')
  double get heightInCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'weight_kg')
  double get weightInKg => throw _privateConstructorUsedError;
  @JsonKey(name: 'body_fat')
  double? get bodyFatPercentage =>
      throw _privateConstructorUsedError; // Thuộc tính tùy chọn
  @JsonKey(name: 'workout_goal')
  WorkoutGoal get workoutGoal => throw _privateConstructorUsedError;
  @JsonKey(name: 'nutrition_goal')
  NutritionGoal get nutritionGoal => throw _privateConstructorUsedError;
  @JsonKey(name: 'activity_level')
  ActivityLevel get activityLevel => throw _privateConstructorUsedError;
  @JsonKey(name: 'days_available')
  String get trainingDaysPerWeek => throw _privateConstructorUsedError;
  @JsonKey(name: 'injuries')
  List<String> get reportedInjuries => throw _privateConstructorUsedError;
  @JsonKey(name: 'dietary_restrictions')
  List<String> get dietaryRestrictions => throw _privateConstructorUsedError;
  @JsonKey(name: 'environment')
  WorkoutEnvironment get environment =>
      throw _privateConstructorUsedError; // Mục tiêu & Macro
  @JsonKey(name: 'tdee')
  int get calculatedTdee => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_macros')
  Macros get targetMacros =>
      throw _privateConstructorUsedError; // BỔ SUNG CỜ CUSTOM MACRO ĐỂ TRÁNH XUNG ĐỘT LOGIC
  @JsonKey(name: 'is_custom_macros')
  bool get isCustomMacros => throw _privateConstructorUsedError;
  @JsonKey(name: 'weekly_goal_rate')
  double? get weeklyGoalRate =>
      throw _privateConstructorUsedError; // Gamification
  @JsonKey(name: 'xp')
  int get experiencePoints => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_rp')
  int get currentRp => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_rp_season_id')
  int get lastRpSeasonId => throw _privateConstructorUsedError;
  @JsonKey(name: 'rank_history')
  List<RankTimelineItem> get rankAdvancementHistory =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'current_rank_id')
  int get activeRankId => throw _privateConstructorUsedError;
  @JsonKey(name: 'body_metrics')
  BodyMetrics get detailedBodyMetrics => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get socialFollowersCount => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get socialFollowingCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'experience_level')
  String? get experienceLevel => throw _privateConstructorUsedError;
  @JsonKey(name: 'diet_plan')
  String? get dietPlan => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_weight_kg')
  double? get targetGoalWeightKg => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_weight_kg')
  double? get startingWeightKg => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_date_millis')
  int? get goalStartTimestampMillis => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_weight_update_millis')
  int? get lastWeightUpdateTimestampMillis =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'disable_weekly_weight_reminder')
  bool get disableWeeklyWeightReminder => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String? id,
      @JsonKey(name: 'name') String displayName,
      @JsonKey(name: 'avatar_base64') String? avatarBase64,
      @JsonKey(name: 'gender') Gender gender,
      @JsonKey(name: 'age') int userAge,
      @JsonKey(name: 'height_cm') double heightInCm,
      @JsonKey(name: 'weight_kg') double weightInKg,
      @JsonKey(name: 'body_fat') double? bodyFatPercentage,
      @JsonKey(name: 'workout_goal') WorkoutGoal workoutGoal,
      @JsonKey(name: 'nutrition_goal') NutritionGoal nutritionGoal,
      @JsonKey(name: 'activity_level') ActivityLevel activityLevel,
      @JsonKey(name: 'days_available') String trainingDaysPerWeek,
      @JsonKey(name: 'injuries') List<String> reportedInjuries,
      @JsonKey(name: 'dietary_restrictions') List<String> dietaryRestrictions,
      @JsonKey(name: 'environment') WorkoutEnvironment environment,
      @JsonKey(name: 'tdee') int calculatedTdee,
      @JsonKey(name: 'target_macros') Macros targetMacros,
      @JsonKey(name: 'is_custom_macros') bool isCustomMacros,
      @JsonKey(name: 'weekly_goal_rate') double? weeklyGoalRate,
      @JsonKey(name: 'xp') int experiencePoints,
      @JsonKey(name: 'current_rp') int currentRp,
      @JsonKey(name: 'last_rp_season_id') int lastRpSeasonId,
      @JsonKey(name: 'rank_history')
      List<RankTimelineItem> rankAdvancementHistory,
      @JsonKey(name: 'current_rank_id') int activeRankId,
      @JsonKey(name: 'body_metrics') BodyMetrics detailedBodyMetrics,
      @JsonKey(includeFromJson: false, includeToJson: false)
      int socialFollowersCount,
      @JsonKey(includeFromJson: false, includeToJson: false)
      int socialFollowingCount,
      @JsonKey(name: 'experience_level') String? experienceLevel,
      @JsonKey(name: 'diet_plan') String? dietPlan,
      @JsonKey(name: 'target_weight_kg') double? targetGoalWeightKg,
      @JsonKey(name: 'start_weight_kg') double? startingWeightKg,
      @JsonKey(name: 'start_date_millis') int? goalStartTimestampMillis,
      @JsonKey(name: 'last_weight_update_millis')
      int? lastWeightUpdateTimestampMillis,
      @JsonKey(name: 'disable_weekly_weight_reminder')
      bool disableWeeklyWeightReminder});

  $MacrosCopyWith<$Res> get targetMacros;
  $BodyMetricsCopyWith<$Res> get detailedBodyMetrics;
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? displayName = null,
    Object? avatarBase64 = freezed,
    Object? gender = null,
    Object? userAge = null,
    Object? heightInCm = null,
    Object? weightInKg = null,
    Object? bodyFatPercentage = freezed,
    Object? workoutGoal = null,
    Object? nutritionGoal = null,
    Object? activityLevel = null,
    Object? trainingDaysPerWeek = null,
    Object? reportedInjuries = null,
    Object? dietaryRestrictions = null,
    Object? environment = null,
    Object? calculatedTdee = null,
    Object? targetMacros = null,
    Object? isCustomMacros = null,
    Object? weeklyGoalRate = freezed,
    Object? experiencePoints = null,
    Object? currentRp = null,
    Object? lastRpSeasonId = null,
    Object? rankAdvancementHistory = null,
    Object? activeRankId = null,
    Object? detailedBodyMetrics = null,
    Object? socialFollowersCount = null,
    Object? socialFollowingCount = null,
    Object? experienceLevel = freezed,
    Object? dietPlan = freezed,
    Object? targetGoalWeightKg = freezed,
    Object? startingWeightKg = freezed,
    Object? goalStartTimestampMillis = freezed,
    Object? lastWeightUpdateTimestampMillis = freezed,
    Object? disableWeeklyWeightReminder = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarBase64: freezed == avatarBase64
          ? _value.avatarBase64
          : avatarBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
      userAge: null == userAge
          ? _value.userAge
          : userAge // ignore: cast_nullable_to_non_nullable
              as int,
      heightInCm: null == heightInCm
          ? _value.heightInCm
          : heightInCm // ignore: cast_nullable_to_non_nullable
              as double,
      weightInKg: null == weightInKg
          ? _value.weightInKg
          : weightInKg // ignore: cast_nullable_to_non_nullable
              as double,
      bodyFatPercentage: freezed == bodyFatPercentage
          ? _value.bodyFatPercentage
          : bodyFatPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      workoutGoal: null == workoutGoal
          ? _value.workoutGoal
          : workoutGoal // ignore: cast_nullable_to_non_nullable
              as WorkoutGoal,
      nutritionGoal: null == nutritionGoal
          ? _value.nutritionGoal
          : nutritionGoal // ignore: cast_nullable_to_non_nullable
              as NutritionGoal,
      activityLevel: null == activityLevel
          ? _value.activityLevel
          : activityLevel // ignore: cast_nullable_to_non_nullable
              as ActivityLevel,
      trainingDaysPerWeek: null == trainingDaysPerWeek
          ? _value.trainingDaysPerWeek
          : trainingDaysPerWeek // ignore: cast_nullable_to_non_nullable
              as String,
      reportedInjuries: null == reportedInjuries
          ? _value.reportedInjuries
          : reportedInjuries // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dietaryRestrictions: null == dietaryRestrictions
          ? _value.dietaryRestrictions
          : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      environment: null == environment
          ? _value.environment
          : environment // ignore: cast_nullable_to_non_nullable
              as WorkoutEnvironment,
      calculatedTdee: null == calculatedTdee
          ? _value.calculatedTdee
          : calculatedTdee // ignore: cast_nullable_to_non_nullable
              as int,
      targetMacros: null == targetMacros
          ? _value.targetMacros
          : targetMacros // ignore: cast_nullable_to_non_nullable
              as Macros,
      isCustomMacros: null == isCustomMacros
          ? _value.isCustomMacros
          : isCustomMacros // ignore: cast_nullable_to_non_nullable
              as bool,
      weeklyGoalRate: freezed == weeklyGoalRate
          ? _value.weeklyGoalRate
          : weeklyGoalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      experiencePoints: null == experiencePoints
          ? _value.experiencePoints
          : experiencePoints // ignore: cast_nullable_to_non_nullable
              as int,
      currentRp: null == currentRp
          ? _value.currentRp
          : currentRp // ignore: cast_nullable_to_non_nullable
              as int,
      lastRpSeasonId: null == lastRpSeasonId
          ? _value.lastRpSeasonId
          : lastRpSeasonId // ignore: cast_nullable_to_non_nullable
              as int,
      rankAdvancementHistory: null == rankAdvancementHistory
          ? _value.rankAdvancementHistory
          : rankAdvancementHistory // ignore: cast_nullable_to_non_nullable
              as List<RankTimelineItem>,
      activeRankId: null == activeRankId
          ? _value.activeRankId
          : activeRankId // ignore: cast_nullable_to_non_nullable
              as int,
      detailedBodyMetrics: null == detailedBodyMetrics
          ? _value.detailedBodyMetrics
          : detailedBodyMetrics // ignore: cast_nullable_to_non_nullable
              as BodyMetrics,
      socialFollowersCount: null == socialFollowersCount
          ? _value.socialFollowersCount
          : socialFollowersCount // ignore: cast_nullable_to_non_nullable
              as int,
      socialFollowingCount: null == socialFollowingCount
          ? _value.socialFollowingCount
          : socialFollowingCount // ignore: cast_nullable_to_non_nullable
              as int,
      experienceLevel: freezed == experienceLevel
          ? _value.experienceLevel
          : experienceLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      dietPlan: freezed == dietPlan
          ? _value.dietPlan
          : dietPlan // ignore: cast_nullable_to_non_nullable
              as String?,
      targetGoalWeightKg: freezed == targetGoalWeightKg
          ? _value.targetGoalWeightKg
          : targetGoalWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      startingWeightKg: freezed == startingWeightKg
          ? _value.startingWeightKg
          : startingWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      goalStartTimestampMillis: freezed == goalStartTimestampMillis
          ? _value.goalStartTimestampMillis
          : goalStartTimestampMillis // ignore: cast_nullable_to_non_nullable
              as int?,
      lastWeightUpdateTimestampMillis: freezed ==
              lastWeightUpdateTimestampMillis
          ? _value.lastWeightUpdateTimestampMillis
          : lastWeightUpdateTimestampMillis // ignore: cast_nullable_to_non_nullable
              as int?,
      disableWeeklyWeightReminder: null == disableWeeklyWeightReminder
          ? _value.disableWeeklyWeightReminder
          : disableWeeklyWeightReminder // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MacrosCopyWith<$Res> get targetMacros {
    return $MacrosCopyWith<$Res>(_value.targetMacros, (value) {
      return _then(_value.copyWith(targetMacros: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $BodyMetricsCopyWith<$Res> get detailedBodyMetrics {
    return $BodyMetricsCopyWith<$Res>(_value.detailedBodyMetrics, (value) {
      return _then(_value.copyWith(detailedBodyMetrics: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String? id,
      @JsonKey(name: 'name') String displayName,
      @JsonKey(name: 'avatar_base64') String? avatarBase64,
      @JsonKey(name: 'gender') Gender gender,
      @JsonKey(name: 'age') int userAge,
      @JsonKey(name: 'height_cm') double heightInCm,
      @JsonKey(name: 'weight_kg') double weightInKg,
      @JsonKey(name: 'body_fat') double? bodyFatPercentage,
      @JsonKey(name: 'workout_goal') WorkoutGoal workoutGoal,
      @JsonKey(name: 'nutrition_goal') NutritionGoal nutritionGoal,
      @JsonKey(name: 'activity_level') ActivityLevel activityLevel,
      @JsonKey(name: 'days_available') String trainingDaysPerWeek,
      @JsonKey(name: 'injuries') List<String> reportedInjuries,
      @JsonKey(name: 'dietary_restrictions') List<String> dietaryRestrictions,
      @JsonKey(name: 'environment') WorkoutEnvironment environment,
      @JsonKey(name: 'tdee') int calculatedTdee,
      @JsonKey(name: 'target_macros') Macros targetMacros,
      @JsonKey(name: 'is_custom_macros') bool isCustomMacros,
      @JsonKey(name: 'weekly_goal_rate') double? weeklyGoalRate,
      @JsonKey(name: 'xp') int experiencePoints,
      @JsonKey(name: 'current_rp') int currentRp,
      @JsonKey(name: 'last_rp_season_id') int lastRpSeasonId,
      @JsonKey(name: 'rank_history')
      List<RankTimelineItem> rankAdvancementHistory,
      @JsonKey(name: 'current_rank_id') int activeRankId,
      @JsonKey(name: 'body_metrics') BodyMetrics detailedBodyMetrics,
      @JsonKey(includeFromJson: false, includeToJson: false)
      int socialFollowersCount,
      @JsonKey(includeFromJson: false, includeToJson: false)
      int socialFollowingCount,
      @JsonKey(name: 'experience_level') String? experienceLevel,
      @JsonKey(name: 'diet_plan') String? dietPlan,
      @JsonKey(name: 'target_weight_kg') double? targetGoalWeightKg,
      @JsonKey(name: 'start_weight_kg') double? startingWeightKg,
      @JsonKey(name: 'start_date_millis') int? goalStartTimestampMillis,
      @JsonKey(name: 'last_weight_update_millis')
      int? lastWeightUpdateTimestampMillis,
      @JsonKey(name: 'disable_weekly_weight_reminder')
      bool disableWeeklyWeightReminder});

  @override
  $MacrosCopyWith<$Res> get targetMacros;
  @override
  $BodyMetricsCopyWith<$Res> get detailedBodyMetrics;
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? displayName = null,
    Object? avatarBase64 = freezed,
    Object? gender = null,
    Object? userAge = null,
    Object? heightInCm = null,
    Object? weightInKg = null,
    Object? bodyFatPercentage = freezed,
    Object? workoutGoal = null,
    Object? nutritionGoal = null,
    Object? activityLevel = null,
    Object? trainingDaysPerWeek = null,
    Object? reportedInjuries = null,
    Object? dietaryRestrictions = null,
    Object? environment = null,
    Object? calculatedTdee = null,
    Object? targetMacros = null,
    Object? isCustomMacros = null,
    Object? weeklyGoalRate = freezed,
    Object? experiencePoints = null,
    Object? currentRp = null,
    Object? lastRpSeasonId = null,
    Object? rankAdvancementHistory = null,
    Object? activeRankId = null,
    Object? detailedBodyMetrics = null,
    Object? socialFollowersCount = null,
    Object? socialFollowingCount = null,
    Object? experienceLevel = freezed,
    Object? dietPlan = freezed,
    Object? targetGoalWeightKg = freezed,
    Object? startingWeightKg = freezed,
    Object? goalStartTimestampMillis = freezed,
    Object? lastWeightUpdateTimestampMillis = freezed,
    Object? disableWeeklyWeightReminder = null,
  }) {
    return _then(_$UserProfileImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarBase64: freezed == avatarBase64
          ? _value.avatarBase64
          : avatarBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
      userAge: null == userAge
          ? _value.userAge
          : userAge // ignore: cast_nullable_to_non_nullable
              as int,
      heightInCm: null == heightInCm
          ? _value.heightInCm
          : heightInCm // ignore: cast_nullable_to_non_nullable
              as double,
      weightInKg: null == weightInKg
          ? _value.weightInKg
          : weightInKg // ignore: cast_nullable_to_non_nullable
              as double,
      bodyFatPercentage: freezed == bodyFatPercentage
          ? _value.bodyFatPercentage
          : bodyFatPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      workoutGoal: null == workoutGoal
          ? _value.workoutGoal
          : workoutGoal // ignore: cast_nullable_to_non_nullable
              as WorkoutGoal,
      nutritionGoal: null == nutritionGoal
          ? _value.nutritionGoal
          : nutritionGoal // ignore: cast_nullable_to_non_nullable
              as NutritionGoal,
      activityLevel: null == activityLevel
          ? _value.activityLevel
          : activityLevel // ignore: cast_nullable_to_non_nullable
              as ActivityLevel,
      trainingDaysPerWeek: null == trainingDaysPerWeek
          ? _value.trainingDaysPerWeek
          : trainingDaysPerWeek // ignore: cast_nullable_to_non_nullable
              as String,
      reportedInjuries: null == reportedInjuries
          ? _value._reportedInjuries
          : reportedInjuries // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dietaryRestrictions: null == dietaryRestrictions
          ? _value._dietaryRestrictions
          : dietaryRestrictions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      environment: null == environment
          ? _value.environment
          : environment // ignore: cast_nullable_to_non_nullable
              as WorkoutEnvironment,
      calculatedTdee: null == calculatedTdee
          ? _value.calculatedTdee
          : calculatedTdee // ignore: cast_nullable_to_non_nullable
              as int,
      targetMacros: null == targetMacros
          ? _value.targetMacros
          : targetMacros // ignore: cast_nullable_to_non_nullable
              as Macros,
      isCustomMacros: null == isCustomMacros
          ? _value.isCustomMacros
          : isCustomMacros // ignore: cast_nullable_to_non_nullable
              as bool,
      weeklyGoalRate: freezed == weeklyGoalRate
          ? _value.weeklyGoalRate
          : weeklyGoalRate // ignore: cast_nullable_to_non_nullable
              as double?,
      experiencePoints: null == experiencePoints
          ? _value.experiencePoints
          : experiencePoints // ignore: cast_nullable_to_non_nullable
              as int,
      currentRp: null == currentRp
          ? _value.currentRp
          : currentRp // ignore: cast_nullable_to_non_nullable
              as int,
      lastRpSeasonId: null == lastRpSeasonId
          ? _value.lastRpSeasonId
          : lastRpSeasonId // ignore: cast_nullable_to_non_nullable
              as int,
      rankAdvancementHistory: null == rankAdvancementHistory
          ? _value._rankAdvancementHistory
          : rankAdvancementHistory // ignore: cast_nullable_to_non_nullable
              as List<RankTimelineItem>,
      activeRankId: null == activeRankId
          ? _value.activeRankId
          : activeRankId // ignore: cast_nullable_to_non_nullable
              as int,
      detailedBodyMetrics: null == detailedBodyMetrics
          ? _value.detailedBodyMetrics
          : detailedBodyMetrics // ignore: cast_nullable_to_non_nullable
              as BodyMetrics,
      socialFollowersCount: null == socialFollowersCount
          ? _value.socialFollowersCount
          : socialFollowersCount // ignore: cast_nullable_to_non_nullable
              as int,
      socialFollowingCount: null == socialFollowingCount
          ? _value.socialFollowingCount
          : socialFollowingCount // ignore: cast_nullable_to_non_nullable
              as int,
      experienceLevel: freezed == experienceLevel
          ? _value.experienceLevel
          : experienceLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      dietPlan: freezed == dietPlan
          ? _value.dietPlan
          : dietPlan // ignore: cast_nullable_to_non_nullable
              as String?,
      targetGoalWeightKg: freezed == targetGoalWeightKg
          ? _value.targetGoalWeightKg
          : targetGoalWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      startingWeightKg: freezed == startingWeightKg
          ? _value.startingWeightKg
          : startingWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      goalStartTimestampMillis: freezed == goalStartTimestampMillis
          ? _value.goalStartTimestampMillis
          : goalStartTimestampMillis // ignore: cast_nullable_to_non_nullable
              as int?,
      lastWeightUpdateTimestampMillis: freezed ==
              lastWeightUpdateTimestampMillis
          ? _value.lastWeightUpdateTimestampMillis
          : lastWeightUpdateTimestampMillis // ignore: cast_nullable_to_non_nullable
              as int?,
      disableWeeklyWeightReminder: null == disableWeeklyWeightReminder
          ? _value.disableWeeklyWeightReminder
          : disableWeeklyWeightReminder // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {@JsonKey(name: 'id') this.id,
      @JsonKey(name: 'name') this.displayName = 'Gym Warrior',
      @JsonKey(name: 'avatar_base64') this.avatarBase64,
      @JsonKey(name: 'gender') this.gender = Gender.MALE,
      @JsonKey(name: 'age') this.userAge = 25,
      @JsonKey(name: 'height_cm') this.heightInCm = 175.0,
      @JsonKey(name: 'weight_kg') this.weightInKg = 75.0,
      @JsonKey(name: 'body_fat') this.bodyFatPercentage,
      @JsonKey(name: 'workout_goal') this.workoutGoal = WorkoutGoal.STRENGTH,
      @JsonKey(name: 'nutrition_goal')
      this.nutritionGoal = NutritionGoal.MAINTAIN_WEIGHT,
      @JsonKey(name: 'activity_level')
      this.activityLevel = ActivityLevel.MODERATE,
      @JsonKey(name: 'days_available') this.trainingDaysPerWeek = '3-5',
      @JsonKey(name: 'injuries') final List<String> reportedInjuries = const [],
      @JsonKey(name: 'dietary_restrictions')
      final List<String> dietaryRestrictions = const [],
      @JsonKey(name: 'environment') this.environment = WorkoutEnvironment.GYM,
      @JsonKey(name: 'tdee') this.calculatedTdee = 2000,
      @JsonKey(name: 'target_macros') required this.targetMacros,
      @JsonKey(name: 'is_custom_macros') this.isCustomMacros = false,
      @JsonKey(name: 'weekly_goal_rate') this.weeklyGoalRate,
      @JsonKey(name: 'xp') this.experiencePoints = 0,
      @JsonKey(name: 'current_rp') this.currentRp = 0,
      @JsonKey(name: 'last_rp_season_id') this.lastRpSeasonId = 1,
      @JsonKey(name: 'rank_history')
      final List<RankTimelineItem> rankAdvancementHistory = const [],
      @JsonKey(name: 'current_rank_id') this.activeRankId = 1,
      @JsonKey(name: 'body_metrics') required this.detailedBodyMetrics,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.socialFollowersCount = 0,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.socialFollowingCount = 0,
      @JsonKey(name: 'experience_level') this.experienceLevel,
      @JsonKey(name: 'diet_plan') this.dietPlan,
      @JsonKey(name: 'target_weight_kg') this.targetGoalWeightKg,
      @JsonKey(name: 'start_weight_kg') this.startingWeightKg,
      @JsonKey(name: 'start_date_millis') this.goalStartTimestampMillis,
      @JsonKey(name: 'last_weight_update_millis')
      this.lastWeightUpdateTimestampMillis,
      @JsonKey(name: 'disable_weekly_weight_reminder')
      this.disableWeeklyWeightReminder = false})
      : _reportedInjuries = reportedInjuries,
        _dietaryRestrictions = dietaryRestrictions,
        _rankAdvancementHistory = rankAdvancementHistory;

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String? id;
  @override
  @JsonKey(name: 'name')
  final String displayName;
  @override
  @JsonKey(name: 'avatar_base64')
  final String? avatarBase64;
  @override
  @JsonKey(name: 'gender')
  final Gender gender;
  @override
  @JsonKey(name: 'age')
  final int userAge;
  @override
  @JsonKey(name: 'height_cm')
  final double heightInCm;
  @override
  @JsonKey(name: 'weight_kg')
  final double weightInKg;
  @override
  @JsonKey(name: 'body_fat')
  final double? bodyFatPercentage;
// Thuộc tính tùy chọn
  @override
  @JsonKey(name: 'workout_goal')
  final WorkoutGoal workoutGoal;
  @override
  @JsonKey(name: 'nutrition_goal')
  final NutritionGoal nutritionGoal;
  @override
  @JsonKey(name: 'activity_level')
  final ActivityLevel activityLevel;
  @override
  @JsonKey(name: 'days_available')
  final String trainingDaysPerWeek;
  final List<String> _reportedInjuries;
  @override
  @JsonKey(name: 'injuries')
  List<String> get reportedInjuries {
    if (_reportedInjuries is EqualUnmodifiableListView)
      return _reportedInjuries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reportedInjuries);
  }

  final List<String> _dietaryRestrictions;
  @override
  @JsonKey(name: 'dietary_restrictions')
  List<String> get dietaryRestrictions {
    if (_dietaryRestrictions is EqualUnmodifiableListView)
      return _dietaryRestrictions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dietaryRestrictions);
  }

  @override
  @JsonKey(name: 'environment')
  final WorkoutEnvironment environment;
// Mục tiêu & Macro
  @override
  @JsonKey(name: 'tdee')
  final int calculatedTdee;
  @override
  @JsonKey(name: 'target_macros')
  final Macros targetMacros;
// BỔ SUNG CỜ CUSTOM MACRO ĐỂ TRÁNH XUNG ĐỘT LOGIC
  @override
  @JsonKey(name: 'is_custom_macros')
  final bool isCustomMacros;
  @override
  @JsonKey(name: 'weekly_goal_rate')
  final double? weeklyGoalRate;
// Gamification
  @override
  @JsonKey(name: 'xp')
  final int experiencePoints;
  @override
  @JsonKey(name: 'current_rp')
  final int currentRp;
  @override
  @JsonKey(name: 'last_rp_season_id')
  final int lastRpSeasonId;
  final List<RankTimelineItem> _rankAdvancementHistory;
  @override
  @JsonKey(name: 'rank_history')
  List<RankTimelineItem> get rankAdvancementHistory {
    if (_rankAdvancementHistory is EqualUnmodifiableListView)
      return _rankAdvancementHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rankAdvancementHistory);
  }

  @override
  @JsonKey(name: 'current_rank_id')
  final int activeRankId;
  @override
  @JsonKey(name: 'body_metrics')
  final BodyMetrics detailedBodyMetrics;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int socialFollowersCount;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int socialFollowingCount;
  @override
  @JsonKey(name: 'experience_level')
  final String? experienceLevel;
  @override
  @JsonKey(name: 'diet_plan')
  final String? dietPlan;
  @override
  @JsonKey(name: 'target_weight_kg')
  final double? targetGoalWeightKg;
  @override
  @JsonKey(name: 'start_weight_kg')
  final double? startingWeightKg;
  @override
  @JsonKey(name: 'start_date_millis')
  final int? goalStartTimestampMillis;
  @override
  @JsonKey(name: 'last_weight_update_millis')
  final int? lastWeightUpdateTimestampMillis;
  @override
  @JsonKey(name: 'disable_weekly_weight_reminder')
  final bool disableWeeklyWeightReminder;

  @override
  String toString() {
    return 'UserProfile(id: $id, displayName: $displayName, avatarBase64: $avatarBase64, gender: $gender, userAge: $userAge, heightInCm: $heightInCm, weightInKg: $weightInKg, bodyFatPercentage: $bodyFatPercentage, workoutGoal: $workoutGoal, nutritionGoal: $nutritionGoal, activityLevel: $activityLevel, trainingDaysPerWeek: $trainingDaysPerWeek, reportedInjuries: $reportedInjuries, dietaryRestrictions: $dietaryRestrictions, environment: $environment, calculatedTdee: $calculatedTdee, targetMacros: $targetMacros, isCustomMacros: $isCustomMacros, weeklyGoalRate: $weeklyGoalRate, experiencePoints: $experiencePoints, currentRp: $currentRp, lastRpSeasonId: $lastRpSeasonId, rankAdvancementHistory: $rankAdvancementHistory, activeRankId: $activeRankId, detailedBodyMetrics: $detailedBodyMetrics, socialFollowersCount: $socialFollowersCount, socialFollowingCount: $socialFollowingCount, experienceLevel: $experienceLevel, dietPlan: $dietPlan, targetGoalWeightKg: $targetGoalWeightKg, startingWeightKg: $startingWeightKg, goalStartTimestampMillis: $goalStartTimestampMillis, lastWeightUpdateTimestampMillis: $lastWeightUpdateTimestampMillis, disableWeeklyWeightReminder: $disableWeeklyWeightReminder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarBase64, avatarBase64) ||
                other.avatarBase64 == avatarBase64) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.userAge, userAge) || other.userAge == userAge) &&
            (identical(other.heightInCm, heightInCm) ||
                other.heightInCm == heightInCm) &&
            (identical(other.weightInKg, weightInKg) ||
                other.weightInKg == weightInKg) &&
            (identical(other.bodyFatPercentage, bodyFatPercentage) ||
                other.bodyFatPercentage == bodyFatPercentage) &&
            (identical(other.workoutGoal, workoutGoal) ||
                other.workoutGoal == workoutGoal) &&
            (identical(other.nutritionGoal, nutritionGoal) ||
                other.nutritionGoal == nutritionGoal) &&
            (identical(other.activityLevel, activityLevel) ||
                other.activityLevel == activityLevel) &&
            (identical(other.trainingDaysPerWeek, trainingDaysPerWeek) ||
                other.trainingDaysPerWeek == trainingDaysPerWeek) &&
            const DeepCollectionEquality()
                .equals(other._reportedInjuries, _reportedInjuries) &&
            const DeepCollectionEquality()
                .equals(other._dietaryRestrictions, _dietaryRestrictions) &&
            (identical(other.environment, environment) ||
                other.environment == environment) &&
            (identical(other.calculatedTdee, calculatedTdee) ||
                other.calculatedTdee == calculatedTdee) &&
            (identical(other.targetMacros, targetMacros) ||
                other.targetMacros == targetMacros) &&
            (identical(other.isCustomMacros, isCustomMacros) ||
                other.isCustomMacros == isCustomMacros) &&
            (identical(other.weeklyGoalRate, weeklyGoalRate) ||
                other.weeklyGoalRate == weeklyGoalRate) &&
            (identical(other.experiencePoints, experiencePoints) ||
                other.experiencePoints == experiencePoints) &&
            (identical(other.currentRp, currentRp) ||
                other.currentRp == currentRp) &&
            (identical(other.lastRpSeasonId, lastRpSeasonId) ||
                other.lastRpSeasonId == lastRpSeasonId) &&
            const DeepCollectionEquality().equals(
                other._rankAdvancementHistory, _rankAdvancementHistory) &&
            (identical(other.activeRankId, activeRankId) ||
                other.activeRankId == activeRankId) &&
            (identical(other.detailedBodyMetrics, detailedBodyMetrics) ||
                other.detailedBodyMetrics == detailedBodyMetrics) &&
            (identical(other.socialFollowersCount, socialFollowersCount) ||
                other.socialFollowersCount == socialFollowersCount) &&
            (identical(other.socialFollowingCount, socialFollowingCount) ||
                other.socialFollowingCount == socialFollowingCount) &&
            (identical(other.experienceLevel, experienceLevel) ||
                other.experienceLevel == experienceLevel) &&
            (identical(other.dietPlan, dietPlan) ||
                other.dietPlan == dietPlan) &&
            (identical(other.targetGoalWeightKg, targetGoalWeightKg) ||
                other.targetGoalWeightKg == targetGoalWeightKg) &&
            (identical(other.startingWeightKg, startingWeightKg) ||
                other.startingWeightKg == startingWeightKg) &&
            (identical(
                    other.goalStartTimestampMillis, goalStartTimestampMillis) ||
                other.goalStartTimestampMillis == goalStartTimestampMillis) &&
            (identical(other.lastWeightUpdateTimestampMillis,
                    lastWeightUpdateTimestampMillis) ||
                other.lastWeightUpdateTimestampMillis ==
                    lastWeightUpdateTimestampMillis) &&
            (identical(other.disableWeeklyWeightReminder,
                    disableWeeklyWeightReminder) ||
                other.disableWeeklyWeightReminder ==
                    disableWeeklyWeightReminder));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        displayName,
        avatarBase64,
        gender,
        userAge,
        heightInCm,
        weightInKg,
        bodyFatPercentage,
        workoutGoal,
        nutritionGoal,
        activityLevel,
        trainingDaysPerWeek,
        const DeepCollectionEquality().hash(_reportedInjuries),
        const DeepCollectionEquality().hash(_dietaryRestrictions),
        environment,
        calculatedTdee,
        targetMacros,
        isCustomMacros,
        weeklyGoalRate,
        experiencePoints,
        currentRp,
        lastRpSeasonId,
        const DeepCollectionEquality().hash(_rankAdvancementHistory),
        activeRankId,
        detailedBodyMetrics,
        socialFollowersCount,
        socialFollowingCount,
        experienceLevel,
        dietPlan,
        targetGoalWeightKg,
        startingWeightKg,
        goalStartTimestampMillis,
        lastWeightUpdateTimestampMillis,
        disableWeeklyWeightReminder
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
      {@JsonKey(name: 'id') final String? id,
      @JsonKey(name: 'name') final String displayName,
      @JsonKey(name: 'avatar_base64') final String? avatarBase64,
      @JsonKey(name: 'gender') final Gender gender,
      @JsonKey(name: 'age') final int userAge,
      @JsonKey(name: 'height_cm') final double heightInCm,
      @JsonKey(name: 'weight_kg') final double weightInKg,
      @JsonKey(name: 'body_fat') final double? bodyFatPercentage,
      @JsonKey(name: 'workout_goal') final WorkoutGoal workoutGoal,
      @JsonKey(name: 'nutrition_goal') final NutritionGoal nutritionGoal,
      @JsonKey(name: 'activity_level') final ActivityLevel activityLevel,
      @JsonKey(name: 'days_available') final String trainingDaysPerWeek,
      @JsonKey(name: 'injuries') final List<String> reportedInjuries,
      @JsonKey(name: 'dietary_restrictions')
      final List<String> dietaryRestrictions,
      @JsonKey(name: 'environment') final WorkoutEnvironment environment,
      @JsonKey(name: 'tdee') final int calculatedTdee,
      @JsonKey(name: 'target_macros') required final Macros targetMacros,
      @JsonKey(name: 'is_custom_macros') final bool isCustomMacros,
      @JsonKey(name: 'weekly_goal_rate') final double? weeklyGoalRate,
      @JsonKey(name: 'xp') final int experiencePoints,
      @JsonKey(name: 'current_rp') final int currentRp,
      @JsonKey(name: 'last_rp_season_id') final int lastRpSeasonId,
      @JsonKey(name: 'rank_history')
      final List<RankTimelineItem> rankAdvancementHistory,
      @JsonKey(name: 'current_rank_id') final int activeRankId,
      @JsonKey(name: 'body_metrics')
      required final BodyMetrics detailedBodyMetrics,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final int socialFollowersCount,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final int socialFollowingCount,
      @JsonKey(name: 'experience_level') final String? experienceLevel,
      @JsonKey(name: 'diet_plan') final String? dietPlan,
      @JsonKey(name: 'target_weight_kg') final double? targetGoalWeightKg,
      @JsonKey(name: 'start_weight_kg') final double? startingWeightKg,
      @JsonKey(name: 'start_date_millis') final int? goalStartTimestampMillis,
      @JsonKey(name: 'last_weight_update_millis')
      final int? lastWeightUpdateTimestampMillis,
      @JsonKey(name: 'disable_weekly_weight_reminder')
      final bool disableWeeklyWeightReminder}) = _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String? get id;
  @override
  @JsonKey(name: 'name')
  String get displayName;
  @override
  @JsonKey(name: 'avatar_base64')
  String? get avatarBase64;
  @override
  @JsonKey(name: 'gender')
  Gender get gender;
  @override
  @JsonKey(name: 'age')
  int get userAge;
  @override
  @JsonKey(name: 'height_cm')
  double get heightInCm;
  @override
  @JsonKey(name: 'weight_kg')
  double get weightInKg;
  @override
  @JsonKey(name: 'body_fat')
  double? get bodyFatPercentage;
  @override // Thuộc tính tùy chọn
  @JsonKey(name: 'workout_goal')
  WorkoutGoal get workoutGoal;
  @override
  @JsonKey(name: 'nutrition_goal')
  NutritionGoal get nutritionGoal;
  @override
  @JsonKey(name: 'activity_level')
  ActivityLevel get activityLevel;
  @override
  @JsonKey(name: 'days_available')
  String get trainingDaysPerWeek;
  @override
  @JsonKey(name: 'injuries')
  List<String> get reportedInjuries;
  @override
  @JsonKey(name: 'dietary_restrictions')
  List<String> get dietaryRestrictions;
  @override
  @JsonKey(name: 'environment')
  WorkoutEnvironment get environment;
  @override // Mục tiêu & Macro
  @JsonKey(name: 'tdee')
  int get calculatedTdee;
  @override
  @JsonKey(name: 'target_macros')
  Macros get targetMacros;
  @override // BỔ SUNG CỜ CUSTOM MACRO ĐỂ TRÁNH XUNG ĐỘT LOGIC
  @JsonKey(name: 'is_custom_macros')
  bool get isCustomMacros;
  @override
  @JsonKey(name: 'weekly_goal_rate')
  double? get weeklyGoalRate;
  @override // Gamification
  @JsonKey(name: 'xp')
  int get experiencePoints;
  @override
  @JsonKey(name: 'current_rp')
  int get currentRp;
  @override
  @JsonKey(name: 'last_rp_season_id')
  int get lastRpSeasonId;
  @override
  @JsonKey(name: 'rank_history')
  List<RankTimelineItem> get rankAdvancementHistory;
  @override
  @JsonKey(name: 'current_rank_id')
  int get activeRankId;
  @override
  @JsonKey(name: 'body_metrics')
  BodyMetrics get detailedBodyMetrics;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get socialFollowersCount;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  int get socialFollowingCount;
  @override
  @JsonKey(name: 'experience_level')
  String? get experienceLevel;
  @override
  @JsonKey(name: 'diet_plan')
  String? get dietPlan;
  @override
  @JsonKey(name: 'target_weight_kg')
  double? get targetGoalWeightKg;
  @override
  @JsonKey(name: 'start_weight_kg')
  double? get startingWeightKg;
  @override
  @JsonKey(name: 'start_date_millis')
  int? get goalStartTimestampMillis;
  @override
  @JsonKey(name: 'last_weight_update_millis')
  int? get lastWeightUpdateTimestampMillis;
  @override
  @JsonKey(name: 'disable_weekly_weight_reminder')
  bool get disableWeeklyWeightReminder;
  @override
  @JsonKey(ignore: true)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BodyMeasurement _$BodyMeasurementFromJson(Map<String, dynamic> json) {
  return _BodyMeasurement.fromJson(json);
}

/// @nodoc
mixin _$BodyMeasurement {
  @JsonKey(name: 'date')
  int get recordTimestampMillis => throw _privateConstructorUsedError;
  @JsonKey(name: 'weight')
  double get recordedWeightKg => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BodyMeasurementCopyWith<BodyMeasurement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BodyMeasurementCopyWith<$Res> {
  factory $BodyMeasurementCopyWith(
          BodyMeasurement value, $Res Function(BodyMeasurement) then) =
      _$BodyMeasurementCopyWithImpl<$Res, BodyMeasurement>;
  @useResult
  $Res call(
      {@JsonKey(name: 'date') int recordTimestampMillis,
      @JsonKey(name: 'weight') double recordedWeightKg});
}

/// @nodoc
class _$BodyMeasurementCopyWithImpl<$Res, $Val extends BodyMeasurement>
    implements $BodyMeasurementCopyWith<$Res> {
  _$BodyMeasurementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordTimestampMillis = null,
    Object? recordedWeightKg = null,
  }) {
    return _then(_value.copyWith(
      recordTimestampMillis: null == recordTimestampMillis
          ? _value.recordTimestampMillis
          : recordTimestampMillis // ignore: cast_nullable_to_non_nullable
              as int,
      recordedWeightKg: null == recordedWeightKg
          ? _value.recordedWeightKg
          : recordedWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BodyMeasurementImplCopyWith<$Res>
    implements $BodyMeasurementCopyWith<$Res> {
  factory _$$BodyMeasurementImplCopyWith(_$BodyMeasurementImpl value,
          $Res Function(_$BodyMeasurementImpl) then) =
      __$$BodyMeasurementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'date') int recordTimestampMillis,
      @JsonKey(name: 'weight') double recordedWeightKg});
}

/// @nodoc
class __$$BodyMeasurementImplCopyWithImpl<$Res>
    extends _$BodyMeasurementCopyWithImpl<$Res, _$BodyMeasurementImpl>
    implements _$$BodyMeasurementImplCopyWith<$Res> {
  __$$BodyMeasurementImplCopyWithImpl(
      _$BodyMeasurementImpl _value, $Res Function(_$BodyMeasurementImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordTimestampMillis = null,
    Object? recordedWeightKg = null,
  }) {
    return _then(_$BodyMeasurementImpl(
      recordTimestampMillis: null == recordTimestampMillis
          ? _value.recordTimestampMillis
          : recordTimestampMillis // ignore: cast_nullable_to_non_nullable
              as int,
      recordedWeightKg: null == recordedWeightKg
          ? _value.recordedWeightKg
          : recordedWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BodyMeasurementImpl implements _BodyMeasurement {
  const _$BodyMeasurementImpl(
      {@JsonKey(name: 'date') required this.recordTimestampMillis,
      @JsonKey(name: 'weight') required this.recordedWeightKg});

  factory _$BodyMeasurementImpl.fromJson(Map<String, dynamic> json) =>
      _$$BodyMeasurementImplFromJson(json);

  @override
  @JsonKey(name: 'date')
  final int recordTimestampMillis;
  @override
  @JsonKey(name: 'weight')
  final double recordedWeightKg;

  @override
  String toString() {
    return 'BodyMeasurement(recordTimestampMillis: $recordTimestampMillis, recordedWeightKg: $recordedWeightKg)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BodyMeasurementImpl &&
            (identical(other.recordTimestampMillis, recordTimestampMillis) ||
                other.recordTimestampMillis == recordTimestampMillis) &&
            (identical(other.recordedWeightKg, recordedWeightKg) ||
                other.recordedWeightKg == recordedWeightKg));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, recordTimestampMillis, recordedWeightKg);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BodyMeasurementImplCopyWith<_$BodyMeasurementImpl> get copyWith =>
      __$$BodyMeasurementImplCopyWithImpl<_$BodyMeasurementImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BodyMeasurementImplToJson(
      this,
    );
  }
}

abstract class _BodyMeasurement implements BodyMeasurement {
  const factory _BodyMeasurement(
          {@JsonKey(name: 'date') required final int recordTimestampMillis,
          @JsonKey(name: 'weight') required final double recordedWeightKg}) =
      _$BodyMeasurementImpl;

  factory _BodyMeasurement.fromJson(Map<String, dynamic> json) =
      _$BodyMeasurementImpl.fromJson;

  @override
  @JsonKey(name: 'date')
  int get recordTimestampMillis;
  @override
  @JsonKey(name: 'weight')
  double get recordedWeightKg;
  @override
  @JsonKey(ignore: true)
  _$$BodyMeasurementImplCopyWith<_$BodyMeasurementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RankTimelineItem _$RankTimelineItemFromJson(Map<String, dynamic> json) {
  return _RankTimelineItem.fromJson(json);
}

/// @nodoc
mixin _$RankTimelineItem {
  @JsonKey(name: 'rank_id')
  int get rankId => throw _privateConstructorUsedError;
  @JsonKey(name: 'timestamp')
  int get achievedAtMillis => throw _privateConstructorUsedError;
  @JsonKey(name: 'reason')
  String get unlockReasonDescription => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RankTimelineItemCopyWith<RankTimelineItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RankTimelineItemCopyWith<$Res> {
  factory $RankTimelineItemCopyWith(
          RankTimelineItem value, $Res Function(RankTimelineItem) then) =
      _$RankTimelineItemCopyWithImpl<$Res, RankTimelineItem>;
  @useResult
  $Res call(
      {@JsonKey(name: 'rank_id') int rankId,
      @JsonKey(name: 'timestamp') int achievedAtMillis,
      @JsonKey(name: 'reason') String unlockReasonDescription});
}

/// @nodoc
class _$RankTimelineItemCopyWithImpl<$Res, $Val extends RankTimelineItem>
    implements $RankTimelineItemCopyWith<$Res> {
  _$RankTimelineItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rankId = null,
    Object? achievedAtMillis = null,
    Object? unlockReasonDescription = null,
  }) {
    return _then(_value.copyWith(
      rankId: null == rankId
          ? _value.rankId
          : rankId // ignore: cast_nullable_to_non_nullable
              as int,
      achievedAtMillis: null == achievedAtMillis
          ? _value.achievedAtMillis
          : achievedAtMillis // ignore: cast_nullable_to_non_nullable
              as int,
      unlockReasonDescription: null == unlockReasonDescription
          ? _value.unlockReasonDescription
          : unlockReasonDescription // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RankTimelineItemImplCopyWith<$Res>
    implements $RankTimelineItemCopyWith<$Res> {
  factory _$$RankTimelineItemImplCopyWith(_$RankTimelineItemImpl value,
          $Res Function(_$RankTimelineItemImpl) then) =
      __$$RankTimelineItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'rank_id') int rankId,
      @JsonKey(name: 'timestamp') int achievedAtMillis,
      @JsonKey(name: 'reason') String unlockReasonDescription});
}

/// @nodoc
class __$$RankTimelineItemImplCopyWithImpl<$Res>
    extends _$RankTimelineItemCopyWithImpl<$Res, _$RankTimelineItemImpl>
    implements _$$RankTimelineItemImplCopyWith<$Res> {
  __$$RankTimelineItemImplCopyWithImpl(_$RankTimelineItemImpl _value,
      $Res Function(_$RankTimelineItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rankId = null,
    Object? achievedAtMillis = null,
    Object? unlockReasonDescription = null,
  }) {
    return _then(_$RankTimelineItemImpl(
      rankId: null == rankId
          ? _value.rankId
          : rankId // ignore: cast_nullable_to_non_nullable
              as int,
      achievedAtMillis: null == achievedAtMillis
          ? _value.achievedAtMillis
          : achievedAtMillis // ignore: cast_nullable_to_non_nullable
              as int,
      unlockReasonDescription: null == unlockReasonDescription
          ? _value.unlockReasonDescription
          : unlockReasonDescription // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RankTimelineItemImpl implements _RankTimelineItem {
  const _$RankTimelineItemImpl(
      {@JsonKey(name: 'rank_id') required this.rankId,
      @JsonKey(name: 'timestamp') required this.achievedAtMillis,
      @JsonKey(name: 'reason') required this.unlockReasonDescription});

  factory _$RankTimelineItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$RankTimelineItemImplFromJson(json);

  @override
  @JsonKey(name: 'rank_id')
  final int rankId;
  @override
  @JsonKey(name: 'timestamp')
  final int achievedAtMillis;
  @override
  @JsonKey(name: 'reason')
  final String unlockReasonDescription;

  @override
  String toString() {
    return 'RankTimelineItem(rankId: $rankId, achievedAtMillis: $achievedAtMillis, unlockReasonDescription: $unlockReasonDescription)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RankTimelineItemImpl &&
            (identical(other.rankId, rankId) || other.rankId == rankId) &&
            (identical(other.achievedAtMillis, achievedAtMillis) ||
                other.achievedAtMillis == achievedAtMillis) &&
            (identical(
                    other.unlockReasonDescription, unlockReasonDescription) ||
                other.unlockReasonDescription == unlockReasonDescription));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, rankId, achievedAtMillis, unlockReasonDescription);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RankTimelineItemImplCopyWith<_$RankTimelineItemImpl> get copyWith =>
      __$$RankTimelineItemImplCopyWithImpl<_$RankTimelineItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RankTimelineItemImplToJson(
      this,
    );
  }
}

abstract class _RankTimelineItem implements RankTimelineItem {
  const factory _RankTimelineItem(
      {@JsonKey(name: 'rank_id') required final int rankId,
      @JsonKey(name: 'timestamp') required final int achievedAtMillis,
      @JsonKey(name: 'reason')
      required final String unlockReasonDescription}) = _$RankTimelineItemImpl;

  factory _RankTimelineItem.fromJson(Map<String, dynamic> json) =
      _$RankTimelineItemImpl.fromJson;

  @override
  @JsonKey(name: 'rank_id')
  int get rankId;
  @override
  @JsonKey(name: 'timestamp')
  int get achievedAtMillis;
  @override
  @JsonKey(name: 'reason')
  String get unlockReasonDescription;
  @override
  @JsonKey(ignore: true)
  _$$RankTimelineItemImplCopyWith<_$RankTimelineItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BodyMetrics _$BodyMetricsFromJson(Map<String, dynamic> json) {
  return _BodyMetrics.fromJson(json);
}

/// @nodoc
mixin _$BodyMetrics {
  @JsonKey(name: 'neck')
  double get neckCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'shoulders')
  double get shouldersCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'chest')
  double get chestCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'biceps_left')
  double get bicepsLeftCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'biceps_right')
  double get bicepsRightCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'forearm_left')
  double get forearmLeftCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'forearm_right')
  double get forearmRightCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'waist')
  double get waistCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'hips')
  double get hipsCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'thigh_left')
  double get thighLeftCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'thigh_right')
  double get thighRightCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'calf_left')
  double get calfLeftCm => throw _privateConstructorUsedError;
  @JsonKey(name: 'calf_right')
  double get calfRightCm => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BodyMetricsCopyWith<BodyMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BodyMetricsCopyWith<$Res> {
  factory $BodyMetricsCopyWith(
          BodyMetrics value, $Res Function(BodyMetrics) then) =
      _$BodyMetricsCopyWithImpl<$Res, BodyMetrics>;
  @useResult
  $Res call(
      {@JsonKey(name: 'neck') double neckCm,
      @JsonKey(name: 'shoulders') double shouldersCm,
      @JsonKey(name: 'chest') double chestCm,
      @JsonKey(name: 'biceps_left') double bicepsLeftCm,
      @JsonKey(name: 'biceps_right') double bicepsRightCm,
      @JsonKey(name: 'forearm_left') double forearmLeftCm,
      @JsonKey(name: 'forearm_right') double forearmRightCm,
      @JsonKey(name: 'waist') double waistCm,
      @JsonKey(name: 'hips') double hipsCm,
      @JsonKey(name: 'thigh_left') double thighLeftCm,
      @JsonKey(name: 'thigh_right') double thighRightCm,
      @JsonKey(name: 'calf_left') double calfLeftCm,
      @JsonKey(name: 'calf_right') double calfRightCm});
}

/// @nodoc
class _$BodyMetricsCopyWithImpl<$Res, $Val extends BodyMetrics>
    implements $BodyMetricsCopyWith<$Res> {
  _$BodyMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? neckCm = null,
    Object? shouldersCm = null,
    Object? chestCm = null,
    Object? bicepsLeftCm = null,
    Object? bicepsRightCm = null,
    Object? forearmLeftCm = null,
    Object? forearmRightCm = null,
    Object? waistCm = null,
    Object? hipsCm = null,
    Object? thighLeftCm = null,
    Object? thighRightCm = null,
    Object? calfLeftCm = null,
    Object? calfRightCm = null,
  }) {
    return _then(_value.copyWith(
      neckCm: null == neckCm
          ? _value.neckCm
          : neckCm // ignore: cast_nullable_to_non_nullable
              as double,
      shouldersCm: null == shouldersCm
          ? _value.shouldersCm
          : shouldersCm // ignore: cast_nullable_to_non_nullable
              as double,
      chestCm: null == chestCm
          ? _value.chestCm
          : chestCm // ignore: cast_nullable_to_non_nullable
              as double,
      bicepsLeftCm: null == bicepsLeftCm
          ? _value.bicepsLeftCm
          : bicepsLeftCm // ignore: cast_nullable_to_non_nullable
              as double,
      bicepsRightCm: null == bicepsRightCm
          ? _value.bicepsRightCm
          : bicepsRightCm // ignore: cast_nullable_to_non_nullable
              as double,
      forearmLeftCm: null == forearmLeftCm
          ? _value.forearmLeftCm
          : forearmLeftCm // ignore: cast_nullable_to_non_nullable
              as double,
      forearmRightCm: null == forearmRightCm
          ? _value.forearmRightCm
          : forearmRightCm // ignore: cast_nullable_to_non_nullable
              as double,
      waistCm: null == waistCm
          ? _value.waistCm
          : waistCm // ignore: cast_nullable_to_non_nullable
              as double,
      hipsCm: null == hipsCm
          ? _value.hipsCm
          : hipsCm // ignore: cast_nullable_to_non_nullable
              as double,
      thighLeftCm: null == thighLeftCm
          ? _value.thighLeftCm
          : thighLeftCm // ignore: cast_nullable_to_non_nullable
              as double,
      thighRightCm: null == thighRightCm
          ? _value.thighRightCm
          : thighRightCm // ignore: cast_nullable_to_non_nullable
              as double,
      calfLeftCm: null == calfLeftCm
          ? _value.calfLeftCm
          : calfLeftCm // ignore: cast_nullable_to_non_nullable
              as double,
      calfRightCm: null == calfRightCm
          ? _value.calfRightCm
          : calfRightCm // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BodyMetricsImplCopyWith<$Res>
    implements $BodyMetricsCopyWith<$Res> {
  factory _$$BodyMetricsImplCopyWith(
          _$BodyMetricsImpl value, $Res Function(_$BodyMetricsImpl) then) =
      __$$BodyMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'neck') double neckCm,
      @JsonKey(name: 'shoulders') double shouldersCm,
      @JsonKey(name: 'chest') double chestCm,
      @JsonKey(name: 'biceps_left') double bicepsLeftCm,
      @JsonKey(name: 'biceps_right') double bicepsRightCm,
      @JsonKey(name: 'forearm_left') double forearmLeftCm,
      @JsonKey(name: 'forearm_right') double forearmRightCm,
      @JsonKey(name: 'waist') double waistCm,
      @JsonKey(name: 'hips') double hipsCm,
      @JsonKey(name: 'thigh_left') double thighLeftCm,
      @JsonKey(name: 'thigh_right') double thighRightCm,
      @JsonKey(name: 'calf_left') double calfLeftCm,
      @JsonKey(name: 'calf_right') double calfRightCm});
}

/// @nodoc
class __$$BodyMetricsImplCopyWithImpl<$Res>
    extends _$BodyMetricsCopyWithImpl<$Res, _$BodyMetricsImpl>
    implements _$$BodyMetricsImplCopyWith<$Res> {
  __$$BodyMetricsImplCopyWithImpl(
      _$BodyMetricsImpl _value, $Res Function(_$BodyMetricsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? neckCm = null,
    Object? shouldersCm = null,
    Object? chestCm = null,
    Object? bicepsLeftCm = null,
    Object? bicepsRightCm = null,
    Object? forearmLeftCm = null,
    Object? forearmRightCm = null,
    Object? waistCm = null,
    Object? hipsCm = null,
    Object? thighLeftCm = null,
    Object? thighRightCm = null,
    Object? calfLeftCm = null,
    Object? calfRightCm = null,
  }) {
    return _then(_$BodyMetricsImpl(
      neckCm: null == neckCm
          ? _value.neckCm
          : neckCm // ignore: cast_nullable_to_non_nullable
              as double,
      shouldersCm: null == shouldersCm
          ? _value.shouldersCm
          : shouldersCm // ignore: cast_nullable_to_non_nullable
              as double,
      chestCm: null == chestCm
          ? _value.chestCm
          : chestCm // ignore: cast_nullable_to_non_nullable
              as double,
      bicepsLeftCm: null == bicepsLeftCm
          ? _value.bicepsLeftCm
          : bicepsLeftCm // ignore: cast_nullable_to_non_nullable
              as double,
      bicepsRightCm: null == bicepsRightCm
          ? _value.bicepsRightCm
          : bicepsRightCm // ignore: cast_nullable_to_non_nullable
              as double,
      forearmLeftCm: null == forearmLeftCm
          ? _value.forearmLeftCm
          : forearmLeftCm // ignore: cast_nullable_to_non_nullable
              as double,
      forearmRightCm: null == forearmRightCm
          ? _value.forearmRightCm
          : forearmRightCm // ignore: cast_nullable_to_non_nullable
              as double,
      waistCm: null == waistCm
          ? _value.waistCm
          : waistCm // ignore: cast_nullable_to_non_nullable
              as double,
      hipsCm: null == hipsCm
          ? _value.hipsCm
          : hipsCm // ignore: cast_nullable_to_non_nullable
              as double,
      thighLeftCm: null == thighLeftCm
          ? _value.thighLeftCm
          : thighLeftCm // ignore: cast_nullable_to_non_nullable
              as double,
      thighRightCm: null == thighRightCm
          ? _value.thighRightCm
          : thighRightCm // ignore: cast_nullable_to_non_nullable
              as double,
      calfLeftCm: null == calfLeftCm
          ? _value.calfLeftCm
          : calfLeftCm // ignore: cast_nullable_to_non_nullable
              as double,
      calfRightCm: null == calfRightCm
          ? _value.calfRightCm
          : calfRightCm // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BodyMetricsImpl implements _BodyMetrics {
  const _$BodyMetricsImpl(
      {@JsonKey(name: 'neck') this.neckCm = 0.0,
      @JsonKey(name: 'shoulders') this.shouldersCm = 0.0,
      @JsonKey(name: 'chest') this.chestCm = 0.0,
      @JsonKey(name: 'biceps_left') this.bicepsLeftCm = 0.0,
      @JsonKey(name: 'biceps_right') this.bicepsRightCm = 0.0,
      @JsonKey(name: 'forearm_left') this.forearmLeftCm = 0.0,
      @JsonKey(name: 'forearm_right') this.forearmRightCm = 0.0,
      @JsonKey(name: 'waist') this.waistCm = 0.0,
      @JsonKey(name: 'hips') this.hipsCm = 0.0,
      @JsonKey(name: 'thigh_left') this.thighLeftCm = 0.0,
      @JsonKey(name: 'thigh_right') this.thighRightCm = 0.0,
      @JsonKey(name: 'calf_left') this.calfLeftCm = 0.0,
      @JsonKey(name: 'calf_right') this.calfRightCm = 0.0});

  factory _$BodyMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$BodyMetricsImplFromJson(json);

  @override
  @JsonKey(name: 'neck')
  final double neckCm;
  @override
  @JsonKey(name: 'shoulders')
  final double shouldersCm;
  @override
  @JsonKey(name: 'chest')
  final double chestCm;
  @override
  @JsonKey(name: 'biceps_left')
  final double bicepsLeftCm;
  @override
  @JsonKey(name: 'biceps_right')
  final double bicepsRightCm;
  @override
  @JsonKey(name: 'forearm_left')
  final double forearmLeftCm;
  @override
  @JsonKey(name: 'forearm_right')
  final double forearmRightCm;
  @override
  @JsonKey(name: 'waist')
  final double waistCm;
  @override
  @JsonKey(name: 'hips')
  final double hipsCm;
  @override
  @JsonKey(name: 'thigh_left')
  final double thighLeftCm;
  @override
  @JsonKey(name: 'thigh_right')
  final double thighRightCm;
  @override
  @JsonKey(name: 'calf_left')
  final double calfLeftCm;
  @override
  @JsonKey(name: 'calf_right')
  final double calfRightCm;

  @override
  String toString() {
    return 'BodyMetrics(neckCm: $neckCm, shouldersCm: $shouldersCm, chestCm: $chestCm, bicepsLeftCm: $bicepsLeftCm, bicepsRightCm: $bicepsRightCm, forearmLeftCm: $forearmLeftCm, forearmRightCm: $forearmRightCm, waistCm: $waistCm, hipsCm: $hipsCm, thighLeftCm: $thighLeftCm, thighRightCm: $thighRightCm, calfLeftCm: $calfLeftCm, calfRightCm: $calfRightCm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BodyMetricsImpl &&
            (identical(other.neckCm, neckCm) || other.neckCm == neckCm) &&
            (identical(other.shouldersCm, shouldersCm) ||
                other.shouldersCm == shouldersCm) &&
            (identical(other.chestCm, chestCm) || other.chestCm == chestCm) &&
            (identical(other.bicepsLeftCm, bicepsLeftCm) ||
                other.bicepsLeftCm == bicepsLeftCm) &&
            (identical(other.bicepsRightCm, bicepsRightCm) ||
                other.bicepsRightCm == bicepsRightCm) &&
            (identical(other.forearmLeftCm, forearmLeftCm) ||
                other.forearmLeftCm == forearmLeftCm) &&
            (identical(other.forearmRightCm, forearmRightCm) ||
                other.forearmRightCm == forearmRightCm) &&
            (identical(other.waistCm, waistCm) || other.waistCm == waistCm) &&
            (identical(other.hipsCm, hipsCm) || other.hipsCm == hipsCm) &&
            (identical(other.thighLeftCm, thighLeftCm) ||
                other.thighLeftCm == thighLeftCm) &&
            (identical(other.thighRightCm, thighRightCm) ||
                other.thighRightCm == thighRightCm) &&
            (identical(other.calfLeftCm, calfLeftCm) ||
                other.calfLeftCm == calfLeftCm) &&
            (identical(other.calfRightCm, calfRightCm) ||
                other.calfRightCm == calfRightCm));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      neckCm,
      shouldersCm,
      chestCm,
      bicepsLeftCm,
      bicepsRightCm,
      forearmLeftCm,
      forearmRightCm,
      waistCm,
      hipsCm,
      thighLeftCm,
      thighRightCm,
      calfLeftCm,
      calfRightCm);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BodyMetricsImplCopyWith<_$BodyMetricsImpl> get copyWith =>
      __$$BodyMetricsImplCopyWithImpl<_$BodyMetricsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BodyMetricsImplToJson(
      this,
    );
  }
}

abstract class _BodyMetrics implements BodyMetrics {
  const factory _BodyMetrics(
          {@JsonKey(name: 'neck') final double neckCm,
          @JsonKey(name: 'shoulders') final double shouldersCm,
          @JsonKey(name: 'chest') final double chestCm,
          @JsonKey(name: 'biceps_left') final double bicepsLeftCm,
          @JsonKey(name: 'biceps_right') final double bicepsRightCm,
          @JsonKey(name: 'forearm_left') final double forearmLeftCm,
          @JsonKey(name: 'forearm_right') final double forearmRightCm,
          @JsonKey(name: 'waist') final double waistCm,
          @JsonKey(name: 'hips') final double hipsCm,
          @JsonKey(name: 'thigh_left') final double thighLeftCm,
          @JsonKey(name: 'thigh_right') final double thighRightCm,
          @JsonKey(name: 'calf_left') final double calfLeftCm,
          @JsonKey(name: 'calf_right') final double calfRightCm}) =
      _$BodyMetricsImpl;

  factory _BodyMetrics.fromJson(Map<String, dynamic> json) =
      _$BodyMetricsImpl.fromJson;

  @override
  @JsonKey(name: 'neck')
  double get neckCm;
  @override
  @JsonKey(name: 'shoulders')
  double get shouldersCm;
  @override
  @JsonKey(name: 'chest')
  double get chestCm;
  @override
  @JsonKey(name: 'biceps_left')
  double get bicepsLeftCm;
  @override
  @JsonKey(name: 'biceps_right')
  double get bicepsRightCm;
  @override
  @JsonKey(name: 'forearm_left')
  double get forearmLeftCm;
  @override
  @JsonKey(name: 'forearm_right')
  double get forearmRightCm;
  @override
  @JsonKey(name: 'waist')
  double get waistCm;
  @override
  @JsonKey(name: 'hips')
  double get hipsCm;
  @override
  @JsonKey(name: 'thigh_left')
  double get thighLeftCm;
  @override
  @JsonKey(name: 'thigh_right')
  double get thighRightCm;
  @override
  @JsonKey(name: 'calf_left')
  double get calfLeftCm;
  @override
  @JsonKey(name: 'calf_right')
  double get calfRightCm;
  @override
  @JsonKey(ignore: true)
  _$$BodyMetricsImplCopyWith<_$BodyMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
