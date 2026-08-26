import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart';

part 'nutrition_models.freezed.dart';
part 'nutrition_models.g.dart';

// ==========================================
// MACROS MODEL
// ==========================================
@freezed
class Macros with _$Macros {
  const factory Macros({
    @JsonKey(name: 'cal') @Default(2000) int calories,
    @JsonKey(name: 'p') @Default(150) int protein,
    @JsonKey(name: 'c') @Default(200) int carbs,
    @JsonKey(name: 'f') @Default(60) int fat,
  }) = _Macros;

  factory Macros.fromJson(Map<String, dynamic> json) => _$MacrosFromJson(json);
}

// ==========================================
// DAILY NUTRITION MODEL
// ==========================================
@freezed
class DailyNutrition with _$DailyNutrition {
  const DailyNutrition._(); 

  const factory DailyNutrition({
    @Default("") String formattedDateString,
    @Default([]) List<FoodResult> breakfastMealsList,
    @Default([]) List<FoodResult> lunchMealsList,
    @Default([]) List<FoodResult> dinnerMealsList,
    @Default([]) List<FoodResult> snackMealsList,
    @Default(0.0) double waterConsumedLiters,
  }) = _DailyNutrition;

  factory DailyNutrition.fromJson(Map<String, dynamic> json) => _$DailyNutritionFromJson(json);

  List<FoodResult> get allMeals => [
        ...breakfastMealsList,
        ...lunchMealsList,
        ...dinnerMealsList,
        ...snackMealsList
      ];

  int get dailyTotalCalories => allMeals.fold(0, (sum, item) => sum + item.calculatedTotalCalories);
  int get dailyTotalProtein => allMeals.fold(0, (sum, item) => sum + item.calculatedTotalProtein);
  int get dailyTotalCarbs => allMeals.fold(0, (sum, item) => sum + item.calculatedTotalCarbs);
  int get dailyTotalFat => allMeals.fold(0, (sum, item) => sum + item.calculatedTotalFat);

  List<FoodResult> getMealsForType(MealType targetMealType) {
    switch (targetMealType) {
      case MealType.BREAKFAST: return breakfastMealsList;
      case MealType.LUNCH: return lunchMealsList;
      case MealType.DINNER: return dinnerMealsList;
      case MealType.SNACK: return snackMealsList;
    }
  }
}