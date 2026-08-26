import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos.dart';
import '../../../../core/database/entities.dart';
import '../models/nutrition_models.dart';

@lazySingleton
class NutritionRepository {
  final AppDatabase _db;
  
  FoodDao get _foodDao => _db.foodDao;
  NutritionDao get _nutritionDao => _db.nutritionDao; 

  NutritionRepository(this._db);

  // --- THỰC PHẨM CƠ BẢN ---
  Future<List<FoodResult>> getAllFoodsLocal() async {
    return await _foodDao.getAllFoods();
  }

  // --- LƯU TRỮ VÀ LẤY DỮ LIỆU DINH DƯỠNG THEO NGÀY ---
  
  Future<DailyNutrition> getDailyNutrition(String dateId) async {
    final entity = await _nutritionDao.getDailyNutritionByDate(dateId);
    
    if (entity == null) {
      return DailyNutrition(formattedDateString: dateId);
    }
    
    return _mapEntityToModel(entity);
  }

  Future<void> saveDailyNutrition(String dateId, DailyNutrition daily) async {
    final entity = NutritionDailyEntity(
      dateId: dateId,
      waterConsumedLiters: daily.waterConsumedLiters,
      breakfastJson: jsonEncode(daily.breakfastMealsList.map((e) => e.toJson()).toList()),
      lunchJson: jsonEncode(daily.lunchMealsList.map((e) => e.toJson()).toList()),
      dinnerJson: jsonEncode(daily.dinnerMealsList.map((e) => e.toJson()).toList()),
      snackJson: jsonEncode(daily.snackMealsList.map((e) => e.toJson()).toList()),
      syncStatus: 'PENDING',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isDeleted: false,
    );
    
    await _nutritionDao.insertOrUpdateDailyNutrition(entity);
  }

  // ĐÃ THÊM: Kéo toàn bộ lịch sử ăn uống & convert qua model sử dụng cho UI
  Future<List<DailyNutrition>> getAllNutritionHistory() async {
    final listEntities = await _nutritionDao.getAllNutritionHistory();
    return listEntities.map((e) => _mapEntityToModel(e)).toList();
  }

  Future<void> saveCustomFoodBlueprint(FoodResult food) async {
  await _foodDao.insertOrReplaceFood(food);
  }

  Future<void> deleteCustomFoodBlueprint(String id) async {
    await _foodDao.deleteFoodById(id);
  }

  // Helper chuyển đổi Entity của SQL sang Model của UI
  DailyNutrition _mapEntityToModel(NutritionDailyEntity entity) {
    List<FoodResult> parseFoods(String jsonStr) {
      if (jsonStr.isEmpty) return [];
      try {
        final List decoded = jsonDecode(jsonStr);
        return decoded.map((e) => FoodResult.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint("🚨 Lỗi parse JSON thức ăn từ Database: $e");
        return [];
      }
    }

    return DailyNutrition(
      formattedDateString: entity.dateId,
      waterConsumedLiters: entity.waterConsumedLiters,
      breakfastMealsList: parseFoods(entity.breakfastJson),
      lunchMealsList: parseFoods(entity.lunchJson),
      dinnerMealsList: parseFoods(entity.dinnerJson),
      snackMealsList: parseFoods(entity.snackJson),
    );
  }
}