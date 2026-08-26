// ignore_for_file: experimental_member_use
import 'dart:convert';
import 'package:floor/floor.dart';
import 'enums.dart';

// --- ENUM CONVERTERS ---
class MuscleGroupConverter extends TypeConverter<MuscleGroup?, String?> {
  @override
  MuscleGroup? decode(String? databaseValue) {
    if (databaseValue == null) return null;
    return MuscleGroup.values.firstWhere((e) => e.name == databaseValue);
  }
  @override
  String? encode(MuscleGroup? value) => value?.name;
}

class ExerciseTypeConverter extends TypeConverter<ExerciseType, String> {
  @override
  ExerciseType decode(String databaseValue) {
    if (databaseValue.isEmpty) return ExerciseType.WEIGHT_REPS;

    String cleanVal = databaseValue.replaceAll('ExerciseType.', '').trim().toUpperCase();

    int? asInt = int.tryParse(cleanVal);
    if (asInt != null && asInt >= 0 && asInt < ExerciseType.values.length) {
      return ExerciseType.values[asInt];
    }

    for (var type in ExerciseType.values) {
      if (type.name.toUpperCase() == cleanVal) {
        return type;
      }
    }

    return ExerciseType.WEIGHT_REPS;
  }

  @override
  String encode(ExerciseType value) => value.name;
}

class FoodUnitConverter extends TypeConverter<FoodUnit, String> {
  @override
  FoodUnit decode(String databaseValue) {
    return FoodUnit.values.firstWhere((e) => e.name == databaseValue);
  }
  @override
  String encode(FoodUnit value) => value.name;
}

class MealTypeConverter extends TypeConverter<MealType?, String?> {
  @override
  MealType? decode(String? databaseValue) {
    if (databaseValue == null) return null;
    return MealType.values.firstWhere((e) => e.name == databaseValue);
  }
  @override
  String? encode(MealType? value) => value?.name;
}

class WorkoutEnvironmentConverter extends TypeConverter<WorkoutEnvironment, String> {
  @override
  WorkoutEnvironment decode(String databaseValue) {
    return WorkoutEnvironment.values.firstWhere((e) => e.name == databaseValue);
  }
  @override
  String encode(WorkoutEnvironment value) => value.name;
}

class WorkoutGoalConverter extends TypeConverter<WorkoutGoal, String> {
  @override
  WorkoutGoal decode(String databaseValue) {
    return WorkoutGoal.values.firstWhere((e) => e.name == databaseValue, orElse: () => WorkoutGoal.STRENGTH);
  }
  @override
  String encode(WorkoutGoal value) => value.name;
}

// --- LIST CONVERTERS ---
class MuscleGroupListConverter extends TypeConverter<List<MuscleGroup>?, String?> {
  @override
  List<MuscleGroup>? decode(String? databaseValue) {
    if (databaseValue == null || databaseValue.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(databaseValue);
      return jsonList.map((e) => MuscleGroup.values.firstWhere((m) => m.name == e)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  String? encode(List<MuscleGroup>? value) {
    if (value == null) return '[]';
    return jsonEncode(value.map((e) => e.name).toList());
  }
}

class EquipmentConverter extends TypeConverter<Equipment?, String?> {
  @override
  Equipment? decode(String? databaseValue) {
    if (databaseValue == null || databaseValue.isEmpty) return null;
    return Equipment.values.firstWhere(
      (e) => e.name == databaseValue,
      orElse: () => Equipment.OTHER,
    );
  }

  @override
  String? encode(Equipment? value) => value?.name;
}
