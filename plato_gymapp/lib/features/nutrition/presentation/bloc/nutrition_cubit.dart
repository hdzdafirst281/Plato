import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../data/models/nutrition_models.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart';
import '../../../../core/database/daos.dart';

part 'nutrition_cubit.freezed.dart';

@freezed
class NutritionState with _$NutritionState {
  const factory NutritionState({
    @Default(DailyNutrition()) DailyNutrition nutritionToday,
    @Default([]) List<FoodResult> recentFoods,
    @Default([]) List<FoodResult> foodDatabase,
    @Default([]) List<DailyNutrition> nutritionHistory,
  }) = _NutritionState;
}

@injectable
class NutritionCubit extends Cubit<NutritionState> {
  final NutritionRepository _nutritionRepo;
  final FoodDao _foodDao;
  static const _uuid = Uuid();

  String _activeDateId = '';

  NutritionCubit(this._nutritionRepo, this._foodDao)
    : super(const NutritionState()) {
    _initData();
  }

  String get _todayDateId => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _initData() async {
    try {
      _activeDateId = _todayDateId;

      final localFoods = await _foodDao.getAllFoods();
      final todayNutrition = await _nutritionRepo.getDailyNutrition(
        _todayDateId,
      );

      emit(
        state.copyWith(
          foodDatabase: localFoods,
          nutritionToday: todayNutrition,
        ),
      );
    } catch (e) {
      debugPrint("❌ Lỗi khởi tạo Nutrition: $e");
    }
  }

  Future<void> resetNutritionState() async {
    _activeDateId = _todayDateId;
    emit(const NutritionState());

    try {
      final localFoods = await _foodDao.getAllFoods();
      final todayNutrition = await _nutritionRepo.getDailyNutrition(
        _activeDateId,
      );
      emit(
        NutritionState(
          foodDatabase: localFoods,
          nutritionToday: todayNutrition,
        ),
      );
    } catch (e) {
      debugPrint("❌ Lỗi đặt lại trạng thái Nutrition: $e");
    }
  }

  Future<void> loadNutritionHistory() async {
    try {
      final history = await _nutritionRepo.getAllNutritionHistory();
      emit(state.copyWith(nutritionHistory: history));
    } catch (e) {
      debugPrint("❌ Lỗi tải lịch sử dinh dưỡng: $e");
    }
  }

  Future<void> _saveTodayNutrition(DailyNutrition dailyData) async {
    await _nutritionRepo.saveDailyNutrition(_activeDateId, dailyData);
  }

  void addFoodToLog(FoodResult foodItem, MealType targetMeal) {
    final configuredFood = FoodResult(
      id: _uuid.v4(),
      foodName: foodItem.foodName,
      baseCalories: foodItem.baseCalories,
      baseProtein: foodItem.baseProtein,
      baseCarbs: foodItem.baseCarbs,
      baseFat: foodItem.baseFat,
      measurementUnit: foodItem.measurementUnit,
      consumedAmount: foodItem.consumedAmount,
      assignedMealType: targetMeal,
    );

    final updatedDaily = _updateMealsList(
      state.nutritionToday,
      targetMeal,
      (list) => [...list, configuredFood],
    );

    final updatedRecents = [foodItem, ...state.recentFoods]
        .fold<Map<String, FoodResult>>(
          {},
          (map, food) => map..putIfAbsent(food.foodName, () => food),
        )
        .values
        .take(10)
        .toList();

    emit(
      state.copyWith(nutritionToday: updatedDaily, recentFoods: updatedRecents),
    );
    _saveTodayNutrition(updatedDaily);
  }

  void removeFoodFromLog(String foodId, MealType targetMeal) {
    final updatedDaily = _updateMealsList(
      state.nutritionToday,
      targetMeal,
      (list) => list.where((f) => f.id != foodId).toList(),
    );
    emit(state.copyWith(nutritionToday: updatedDaily));
    _saveTodayNutrition(updatedDaily);
  }

  void updateFoodWeight(String foodId, MealType targetMeal, double newAmount) {
    final updatedDaily = _updateMealsList(state.nutritionToday, targetMeal, (
      list,
    ) {
      return list
          .map(
            (f) => f.id == foodId
                ? FoodResult(
                    id: f.id,
                    foodName: f.foodName,
                    baseCalories: f.baseCalories,
                    baseProtein: f.baseProtein,
                    baseCarbs: f.baseCarbs,
                    baseFat: f.baseFat,
                    measurementUnit: f.measurementUnit,
                    consumedAmount: newAmount,
                    assignedMealType: f.assignedMealType,
                  )
                : f,
          )
          .toList();
    });
    emit(state.copyWith(nutritionToday: updatedDaily));
    _saveTodayNutrition(updatedDaily);
  }

  // [HÀM MỚI]: Cập nhật toàn diện một món ăn trong Log (Bao gồm Macros/Tên và Số lượng)
  void updateFoodEntry(
    String logEntryId,
    MealType targetMeal,
    FoodResult updatedFood,
  ) {
    final updatedDaily = _updateMealsList(state.nutritionToday, targetMeal, (
      list,
    ) {
      // Map đúng theo UUID của Log Entry
      return list.map((f) => f.id == logEntryId ? updatedFood : f).toList();
    });
    emit(state.copyWith(nutritionToday: updatedDaily));
    _saveTodayNutrition(updatedDaily);
  }

  void quickAddCalories(int caloriesAmount, MealType targetMeal) {
    addFoodToLog(
      FoodResult(
        id: "",
        foodName: "Thêm nhanh Calo",
        baseCalories: caloriesAmount,
        baseProtein: 0,
        baseCarbs: 0,
        baseFat: 0,
      ),
      targetMeal,
    );
  }

  void addWater(double liters) {
    final currentWater = state.nutritionToday.waterConsumedLiters;
    final newWater = (currentWater + liters) >= 0
        ? (currentWater + liters)
        : 0.0;
    final updatedDaily = state.nutritionToday.copyWith(
      waterConsumedLiters: newWater,
    );
    emit(state.copyWith(nutritionToday: updatedDaily));
    _saveTodayNutrition(updatedDaily);
  }

  DailyNutrition _updateMealsList(
    DailyNutrition daily,
    MealType mealType,
    List<FoodResult> Function(List<FoodResult>) updater,
  ) {
    switch (mealType) {
      case MealType.BREAKFAST:
        return daily.copyWith(
          breakfastMealsList: updater(daily.breakfastMealsList),
        );
      case MealType.LUNCH:
        return daily.copyWith(lunchMealsList: updater(daily.lunchMealsList));
      case MealType.DINNER:
        return daily.copyWith(dinnerMealsList: updater(daily.dinnerMealsList));
      case MealType.SNACK:
        return daily.copyWith(snackMealsList: updater(daily.snackMealsList));
    }
  }

  Future<void> saveCustomFoodBlueprint(FoodResult customFood) async {
    try {
      await _nutritionRepo.saveCustomFoodBlueprint(customFood);
      final localFoods = await _foodDao.getAllFoods();

      // ĐÃ FIX: Cập nhật món ăn này vào danh sách recentFoods nếu user sửa
      final updatedRecents = [customFood, ...state.recentFoods]
          .fold<Map<String, FoodResult>>(
            {},
            (map, food) => map..putIfAbsent(food.id, () => food),
          )
          .values
          .take(10)
          .toList();

      emit(
        state.copyWith(foodDatabase: localFoods, recentFoods: updatedRecents),
      );
    } catch (e) {
      debugPrint("❌ Lỗi lưu món ăn custom: $e");
    }
  }

  Future<void> deleteCustomFoodBlueprint(String foodId) async {
    try {
      await _nutritionRepo.deleteCustomFoodBlueprint(foodId);
      final localFoods = await _foodDao.getAllFoods();

      // ĐÃ FIX: Đồng thời dọn dẹp món ăn này khỏi lịch sử "Gần đây"
      final updatedRecents = state.recentFoods
          .where((f) => f.id != foodId)
          .toList();

      emit(
        state.copyWith(foodDatabase: localFoods, recentFoods: updatedRecents),
      );
    } catch (e) {
      debugPrint("❌ Lỗi xóa món ăn custom: $e");
    }
  }

  Future<bool> copyMealFromYesterday(MealType targetMeal) async {
    final yesterdayDateId = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));
    try {
      final yesterdayData = await _nutritionRepo.getDailyNutrition(
        yesterdayDateId,
      );

      List<FoodResult> pastFoods = [];
      switch (targetMeal) {
        case MealType.BREAKFAST:
          pastFoods = yesterdayData.breakfastMealsList;
          break;
        case MealType.LUNCH:
          pastFoods = yesterdayData.lunchMealsList;
          break;
        case MealType.DINNER:
          pastFoods = yesterdayData.dinnerMealsList;
          break;
        case MealType.SNACK:
          pastFoods = yesterdayData.snackMealsList;
          break;
      }

      if (pastFoods.isEmpty) return false;

      final newFoods = pastFoods
          .map(
            (f) => FoodResult(
              id: _uuid.v4(),
              foodName: f.foodName,
              baseCalories: f.baseCalories,
              baseProtein: f.baseProtein,
              baseCarbs: f.baseCarbs,
              baseFat: f.baseFat,
              measurementUnit: f.measurementUnit,
              consumedAmount: f.consumedAmount,
              assignedMealType: targetMeal,
            ),
          )
          .toList();

      final updatedDaily = _updateMealsList(
        state.nutritionToday,
        targetMeal,
        (list) => [...list, ...newFoods],
      );

      emit(state.copyWith(nutritionToday: updatedDaily));
      await _saveTodayNutrition(updatedDaily);
      return true;
    } catch (e) {
      debugPrint("❌ Lỗi copy dữ liệu bữa ăn hôm qua: $e");
      return false;
    }
  }
}
