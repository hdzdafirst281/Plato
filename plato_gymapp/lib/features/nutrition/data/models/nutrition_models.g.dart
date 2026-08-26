// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MacrosImpl _$$MacrosImplFromJson(Map<String, dynamic> json) => _$MacrosImpl(
      calories: (json['cal'] as num?)?.toInt() ?? 2000,
      protein: (json['p'] as num?)?.toInt() ?? 150,
      carbs: (json['c'] as num?)?.toInt() ?? 200,
      fat: (json['f'] as num?)?.toInt() ?? 60,
    );

Map<String, dynamic> _$$MacrosImplToJson(_$MacrosImpl instance) =>
    <String, dynamic>{
      'cal': instance.calories,
      'p': instance.protein,
      'c': instance.carbs,
      'f': instance.fat,
    };

_$DailyNutritionImpl _$$DailyNutritionImplFromJson(Map<String, dynamic> json) =>
    _$DailyNutritionImpl(
      formattedDateString: json['formattedDateString'] as String? ?? "",
      breakfastMealsList: (json['breakfastMealsList'] as List<dynamic>?)
              ?.map((e) => FoodResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lunchMealsList: (json['lunchMealsList'] as List<dynamic>?)
              ?.map((e) => FoodResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dinnerMealsList: (json['dinnerMealsList'] as List<dynamic>?)
              ?.map((e) => FoodResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      snackMealsList: (json['snackMealsList'] as List<dynamic>?)
              ?.map((e) => FoodResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      waterConsumedLiters:
          (json['waterConsumedLiters'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$DailyNutritionImplToJson(
        _$DailyNutritionImpl instance) =>
    <String, dynamic>{
      'formattedDateString': instance.formattedDateString,
      'breakfastMealsList': instance.breakfastMealsList,
      'lunchMealsList': instance.lunchMealsList,
      'dinnerMealsList': instance.dinnerMealsList,
      'snackMealsList': instance.snackMealsList,
      'waterConsumedLiters': instance.waterConsumedLiters,
    };
