import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';

class NutritionSafetyHelper {
  /// Checks if a food contains any allergens that the user is allergic to.
  /// Returns a list of matching allergen keys. If empty, the food is safe.
  static List<String> getViolatedAllergens(FoodResult food, UserProfile userProfile) {
    if (food.allergenTags == null || food.allergenTags!.isEmpty) return [];
    if (userProfile.dietaryRestrictions.isEmpty) return [];

    return food.allergenTags!
        .where((tag) => userProfile.dietaryRestrictions.contains("nutrition.$tag"))
        .map((tag) => "nutrition.$tag")
        .toList();
  }

  /// Checks if a food is safe for the user to eat.
  static bool isFoodSafe(FoodResult food, UserProfile userProfile) {
    return getViolatedAllergens(food, userProfile).isEmpty;
  }

  /// Checks if a food matches the user's dietary preferences (e.g. Keto, Vegan).
  static List<String> getMatchedDiets(FoodResult food, UserProfile userProfile) {
    if (food.dietTags == null || food.dietTags!.isEmpty) return [];
    if (userProfile.dietaryRestrictions.isEmpty) return [];

    return food.dietTags!
        .where((tag) => userProfile.dietaryRestrictions.contains("nutrition.$tag"))
        .map((tag) => "nutrition.$tag")
        .toList();
  }
}
