class IngredientDef {
  final String id;
  final String nameKey;
  final List<String> allergenTags;
  final List<String> dietTags;

  const IngredientDef({
    required this.id,
    required this.nameKey,
    this.allergenTags = const [],
    this.dietTags = const [],
  });
}

class NutritionConstants {
  static const List<IngredientDef> knownIngredients = [
    // Gia vị & Đồ uống
    IngredientDef(id: 'ing_salt', nameKey: 'nutrition.ing_salt'),
    IngredientDef(id: 'ing_sugar', nameKey: 'nutrition.ing_sugar'),
    IngredientDef(id: 'ing_pepper', nameKey: 'nutrition.ing_pepper'),
    IngredientDef(id: 'ing_garlic', nameKey: 'nutrition.ing_garlic'),
    IngredientDef(id: 'ing_onion', nameKey: 'nutrition.ing_onion'),
    IngredientDef(id: 'ing_coffee', nameKey: 'nutrition.ing_coffee', dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_tea', nameKey: 'nutrition.ing_tea', dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_lemon', nameKey: 'nutrition.ing_lemon', dietTags: ['diet_vegan', 'diet_keto']),

    // Cơm, Tinh bột
    IngredientDef(id: 'ing_white_rice', nameKey: 'nutrition.ing_white_rice', dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_brown_rice', nameKey: 'nutrition.ing_brown_rice', dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_bread', nameKey: 'nutrition.ing_bread', allergenTags: ['allergy_gluten'], dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_potato', nameKey: 'nutrition.ing_potato', dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_sweet_potato', nameKey: 'nutrition.ing_sweet_potato', dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_noodle', nameKey: 'nutrition.ing_noodle', allergenTags: ['allergy_gluten'], dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_oatmeal', nameKey: 'nutrition.ing_oatmeal', dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_rice_paper', nameKey: 'nutrition.ing_rice_paper', dietTags: ['diet_vegan']),

    // Thịt, Trứng
    IngredientDef(id: 'ing_chicken_breast', nameKey: 'nutrition.ing_chicken_breast', dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_chicken_thigh', nameKey: 'nutrition.ing_chicken_thigh', dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_beef', nameKey: 'nutrition.ing_beef', allergenTags: ['diet_no_red_meat'], dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_pork', nameKey: 'nutrition.ing_pork', allergenTags: ['diet_no_red_meat'], dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_pork_chop', nameKey: 'nutrition.ing_pork_chop', allergenTags: ['diet_no_red_meat'], dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_egg', nameKey: 'nutrition.ing_egg', allergenTags: ['allergy_egg'], dietTags: ['diet_keto']),

    // Hải sản
    IngredientDef(id: 'ing_shrimp', nameKey: 'nutrition.ing_shrimp', allergenTags: ['allergy_seafood'], dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_crab', nameKey: 'nutrition.ing_crab', allergenTags: ['allergy_seafood'], dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_squid', nameKey: 'nutrition.ing_squid', allergenTags: ['allergy_seafood'], dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_fish_salmon', nameKey: 'nutrition.ing_fish_salmon', allergenTags: ['allergy_seafood'], dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_fish_tilapia', nameKey: 'nutrition.ing_fish_tilapia', allergenTags: ['allergy_seafood'], dietTags: ['diet_keto']),

    // Sữa, Đậu, Hạt, Chất béo
    IngredientDef(id: 'ing_milk', nameKey: 'nutrition.ing_milk', allergenTags: ['allergy_lactose']),
    IngredientDef(id: 'ing_cheese', nameKey: 'nutrition.ing_cheese', allergenTags: ['allergy_lactose'], dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_yogurt', nameKey: 'nutrition.ing_yogurt', allergenTags: ['allergy_lactose']),
    IngredientDef(id: 'ing_butter', nameKey: 'nutrition.ing_butter', allergenTags: ['allergy_lactose'], dietTags: ['diet_keto']),
    IngredientDef(id: 'ing_peanut', nameKey: 'nutrition.ing_peanut', allergenTags: ['allergy_peanut'], dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_peanut_butter', nameKey: 'nutrition.ing_peanut_butter', allergenTags: ['allergy_peanut'], dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_almond', nameKey: 'nutrition.ing_almond', allergenTags: ['allergy_tree_nuts'], dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_walnut', nameKey: 'nutrition.ing_walnut', allergenTags: ['allergy_tree_nuts'], dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_soybean', nameKey: 'nutrition.ing_soybean', allergenTags: ['allergy_soy'], dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_tofu', nameKey: 'nutrition.ing_tofu', allergenTags: ['allergy_soy'], dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_almond_milk', nameKey: 'nutrition.ing_almond_milk', allergenTags: ['allergy_tree_nuts'], dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_olive_oil', nameKey: 'nutrition.ing_olive_oil', dietTags: ['diet_vegan', 'diet_keto']),

    // Rau củ quả
    IngredientDef(id: 'ing_tomato', nameKey: 'nutrition.ing_tomato', dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_cucumber', nameKey: 'nutrition.ing_cucumber', dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_lettuce', nameKey: 'nutrition.ing_lettuce', dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_broccoli', nameKey: 'nutrition.ing_broccoli', dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_carrot', nameKey: 'nutrition.ing_carrot', dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_mushroom', nameKey: 'nutrition.ing_mushroom', dietTags: ['diet_vegan', 'diet_keto']),
    IngredientDef(id: 'ing_apple', nameKey: 'nutrition.ing_apple', dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_banana', nameKey: 'nutrition.ing_banana', dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_orange', nameKey: 'nutrition.ing_orange', dietTags: ['diet_vegan']),
    IngredientDef(id: 'ing_avocado', nameKey: 'nutrition.ing_avocado', dietTags: ['diet_vegan', 'diet_keto']),
  ];
}
