import 'dart:math';

import '../../../../core/database/enums.dart';
import '../data/models/nutrition_models.dart';

class NutritionCalculator {
  static double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    return weightKg / pow(heightM, 2);
  }

  static NutritionGoal? suggestGoalBasedOnBMI(double bmi) {
    if (bmi < 18.5) return NutritionGoal.GAIN_WEIGHT;
    if (bmi >= 25.0) return NutritionGoal.LOSE_WEIGHT;
    return null;
  }

  static bool validateWeightGoal(double currentWeight, double targetWeight, NutritionGoal goal) {
    final gap = targetWeight - currentWeight;
    switch (goal) {
      case NutritionGoal.LOSE_WEIGHT: return gap < 0;
      case NutritionGoal.GAIN_WEIGHT: return gap > 0;
      case NutritionGoal.MAINTAIN_WEIGHT: return true;
    }
  }

  static int calculateMinDays(double currentWeight, double targetWeight) {
    if (currentWeight <= 0) return 0;
    final gap = targetWeight - currentWeight;
    if (gap == 0.0) return 0;

    final minWeeks = (gap < 0) 
        ? gap.abs() / (currentWeight * 0.01)  // Giảm cân: max 1% / tuần
        : gap / (currentWeight * 0.005);      // Tăng cân: max 0.5% / tuần
        
    return max(1, (minWeeks * 7).round());
  }

  static double calculateBMR(double weightKg, double heightCm, int age, Gender gender, double? bodyFat) {
    if (bodyFat != null && bodyFat > 0.0) {
      final lbm = weightKg * (1 - (bodyFat / 100.0));
      return 370.0 + (21.6 * lbm);
    } else {
      final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
      return gender == Gender.MALE ? base + 5.0 : base - 161.0;
    }
  }

  static double calculateTDEE(double bmr, ActivityLevel activityLevel) {
    double multiplier = 1.2;
    switch (activityLevel) {
      case ActivityLevel.SEDENTARY: multiplier = 1.2; break;
      case ActivityLevel.LIGHT: multiplier = 1.375; break;
      case ActivityLevel.MODERATE: multiplier = 1.55; break;
      case ActivityLevel.ACTIVE: multiplier = 1.725; break;
    }
    return bmr * multiplier;
  }

  static int calculateTargetCalories(double bmr, double tdee, double currentWeight, double targetWeight, int days, NutritionGoal goal) {
    final gap = targetWeight - currentWeight;

    if (days <= 0 || gap == 0.0) {
      return tdee.round(); 
    }

    final ratePerWeek = gap.abs() / (days / 7.0);
    final dailyDiff = ratePerWeek * 1100.0;

    double targetCal;
    switch (goal) {
      case NutritionGoal.LOSE_WEIGHT:
        targetCal = max(bmr, tdee - dailyDiff);
        break;
      case NutritionGoal.GAIN_WEIGHT:
        targetCal = tdee + dailyDiff;
        break;
      case NutritionGoal.MAINTAIN_WEIGHT:
        targetCal = tdee;
        break;
    }
    return targetCal.round();
  }

  static Macros calculateMacros(double weightKg, int targetCalories, NutritionGoal goal) {
    double proteinMultiplier = 2.0;
    if (goal == NutritionGoal.LOSE_WEIGHT) proteinMultiplier = 2.4;
    if (goal == NutritionGoal.GAIN_WEIGHT) proteinMultiplier = 2.2;

    final proteinGrams = (weightKg * proteinMultiplier).round();
    final proteinCals = proteinGrams * 4;

    final fatCals = targetCalories * 0.25;
    final fatGrams = (fatCals / 9.0).round();
    final actualFatCals = fatGrams * 9;

    final remainingCals = targetCalories - proteinCals - actualFatCals;
    int carbsGrams = max(50, (remainingCals / 4.0).round()); 

    final finalCalories = (proteinGrams * 4) + (fatGrams * 9) + (carbsGrams * 4);

    return Macros(
      calories: finalCalories,
      protein: proteinGrams,
      fat: fatGrams,
      carbs: carbsGrams,
    );
  }

  static int calculateDaysFromCustomCalories(double tdee, int customCalories, double currentWeight, double targetWeight) {
    final gap = targetWeight - currentWeight; 
    if (gap == 0.0) return 0; 

    final dailyDeficit = customCalories - tdee; 

    if (gap < 0 && dailyDeficit > -50) return -1; 
    if (gap > 0 && dailyDeficit < 50) return -1; 

    final totalCaloriesNeeded = gap.abs() * 7700.0;
    final expectedDays = totalCaloriesNeeded / dailyDeficit.abs();

    return expectedDays.round();
  }
}