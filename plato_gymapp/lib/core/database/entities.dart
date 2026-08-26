import 'package:floor/floor.dart';
import 'enums.dart';

// ======================= BẢNG EXERCISES =======================
@Entity(tableName: 'exercises')
class Exercise {
  @primaryKey
  @ColumnInfo(name: 'id')
  final String id;

  @ColumnInfo(name: 'idx')
  final int? sortIndex;

  @ColumnInfo(name: 'name')
  final String name;

  @ColumnInfo(name: 'primary_muscle')
  final MuscleGroup? primaryMuscle;

  @ColumnInfo(name: 'secondary_muscles')
  final List<MuscleGroup>? secondaryMuscles;

  @ColumnInfo(name: 'instructions')
  final String? instructions;

  @ColumnInfo(name: 'type')
  final ExerciseType type;

  @ColumnInfo(name: 'equipment')
  final Equipment? equipment;

  @ColumnInfo(name: 'url_instructions')
  final String? instructionVideoUrl;

  @ColumnInfo(name: 'created_at')
  final String? createdAt;

  @ColumnInfo(name: 'updated_at')
  final String? updatedAt;

  @ColumnInfo(name: 'is_deleted')
  final bool isDeleted; 

  @ColumnInfo(name: 'is_custom')
  final bool isCustom;

  @ColumnInfo(name: 'local_image_path')
  final String? localImagePath; // (Optional: Giữ lại để tương thích ngược nếu cần)

  @ColumnInfo(name: 'user_note')
  final String? userNote;

  // 🚀 THÊM TRƯỜNG IMAGE
  @ColumnInfo(name: 'image')
  final String? image;

  Exercise({
    required this.id,
    this.sortIndex,
    required this.name,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.instructions,
    required this.type,
    this.equipment,
    this.instructionVideoUrl,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
    this.isCustom = false, 
    this.localImagePath,
    this.userNote,
    this.image, // 🚀 KHAI BÁO VÀO CONSTRUCTOR
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // 1. Xử lý an toàn ExerciseType
    ExerciseType parsedType = ExerciseType.WEIGHT_REPS;
    if (json['type'] != null) {
      String cleanVal = json['type'].toString().replaceAll('ExerciseType.', '').trim().toUpperCase();
      int? asInt = int.tryParse(cleanVal);
      
      if (asInt != null && asInt >= 0 && asInt < ExerciseType.values.length) {
        parsedType = ExerciseType.values[asInt]; 
      } else {
        for (var t in ExerciseType.values) {
          if (t.name.toUpperCase() == cleanVal) {
            parsedType = t; 
            break;
          }
        }
      }
    }

    // 2. Xử lý an toàn Primary Muscle
    MuscleGroup? parsedPrimaryMuscle;
    if (json['primary_muscle'] != null) {
      String cleanVal = json['primary_muscle'].toString().replaceAll('MuscleGroup.', '').trim().toUpperCase();
      for (var m in MuscleGroup.values) {
        if (m.name.toUpperCase() == cleanVal) {
          parsedPrimaryMuscle = m;
          break;
        }
      }
    }

    // 3. Xử lý an toàn Secondary Muscles
    List<MuscleGroup> parsedSecondary = [];
    if (json['secondary_muscles'] != null && json['secondary_muscles'] is List) {
      for (var item in json['secondary_muscles']) {
        String cleanVal = item.toString().replaceAll('MuscleGroup.', '').trim().toUpperCase();
        for (var m in MuscleGroup.values) {
          if (m.name.toUpperCase() == cleanVal) {
            parsedSecondary.add(m);
            break;
          }
        }
      }
    }

    // 4. Xử lý an toàn Equipment
    Equipment? parsedEquipment;
    if (json['equipment'] != null) {
      String cleanVal = json['equipment'].toString().replaceAll('Equipment.', '').trim().toUpperCase();
      for (var e in Equipment.values) {
        if (e.name.toUpperCase() == cleanVal) {
          parsedEquipment = e;
          break;
        }
      }
    }

    return Exercise(
      id: json['id'].toString(),
      sortIndex: json['idx'] as int?,
      name: json['name']?.toString() ?? 'Unknown Exercise',
      primaryMuscle: parsedPrimaryMuscle,
      secondaryMuscles: parsedSecondary,
      instructions: json['instructions'] as String?,
      type: parsedType,
      equipment: parsedEquipment,
      instructionVideoUrl: json['url_instructions'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1 || json['is_deleted'] == 'true',
      isCustom: json['is_custom'] == true || json['is_custom'] == 1 || json['is_custom'] == 'true',
      localImagePath: json['local_image_path'] as String?,
      userNote: json['user_note'] as String?,
      image: json['image'] as String?, // 🚀 PARSE TỪ JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idx': sortIndex,
      'name': name,
      'primary_muscle': primaryMuscle?.name,
      'equipment': equipment?.name,
      'secondary_muscles': secondaryMuscles?.map((e) => e.name).toList() ?? [],
      'instructions': instructions,
      'type': type.name,
      'url_instructions': instructionVideoUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted,
      'is_custom': isCustom,
      'local_image_path': localImagePath,
      'user_note': userNote,
      'image': image, // 🚀 ĐẨY VÀO JSON
    };
  }
}

// ======================= BẢNG ROUTINES LOCAL =======================
@Entity(tableName: 'routines_local')
class RoutineEntity {
  @primaryKey
  final String id;
  final String name;
  final String? programName;
  final String payloadJson; 
  final String syncStatus;
  final int updatedAt;
  final bool isDeleted;

  RoutineEntity({
    required this.id,
    required this.name,
    this.programName,
    required this.payloadJson,
    required this.syncStatus,
    required this.updatedAt,
    required this.isDeleted,
  });
}

// ======================= BẢNG WORKOUT HISTORY =======================
@Entity(tableName: 'workout_history_local')
class WorkoutSessionEntity {
  @primaryKey
  final String id;
  final String? routineId;
  final String? programName;
  final String name;
  final int startTime; 
  final int? endTime;
  final int durationSeconds;
  final int totalCaloriesBurned;
  final double totalVolume;
  final int totalSets;
  final int? rpe;
  final int xpEarned;
  final int prCount;
  final String payloadJson; 
  final String syncStatus;
  final int updatedAt;
  final bool isDeleted;

  WorkoutSessionEntity({
    required this.id,
    this.routineId,
    this.programName,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.totalCaloriesBurned,
    required this.totalVolume,
    required this.totalSets,
    this.rpe,
    required this.xpEarned,
    required this.prCount,
    required this.payloadJson,
    required this.syncStatus,
    required this.updatedAt,
    required this.isDeleted,
  });
}

// ======================= BẢNG FOODS =======================
@Entity(tableName: 'foods')
class FoodResult {
  @primaryKey
  @ColumnInfo(name: 'id')
  final String id;

  @ColumnInfo(name: 'name')
  final String foodName;

  @ColumnInfo(name: 'cal')
  final int baseCalories;

  @ColumnInfo(name: 'p')
  final int baseProtein;

  @ColumnInfo(name: 'c')
  final int baseCarbs;

  @ColumnInfo(name: 'f')
  final int baseFat;

  @ColumnInfo(name: 'unit')
  final FoodUnit measurementUnit;

  @ColumnInfo(name: 'amount')
  final double consumedAmount;

  @ColumnInfo(name: 'mealType')
  final MealType? assignedMealType;

  @ColumnInfo(name: 'updated_at')
  final String? lastUpdatedAt;

  @ColumnInfo(name: 'is_deleted')
  final bool isMarkedForDeletion;

  FoodResult({
    required this.id,
    required this.foodName,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    this.measurementUnit = FoodUnit.SERVING,
    this.consumedAmount = 1.0,
    this.assignedMealType,
    this.lastUpdatedAt,
    this.isMarkedForDeletion = false,
  });

  int get calculatedTotalCalories => (baseCalories * consumedAmount).toInt();
  int get calculatedTotalProtein => (baseProtein * consumedAmount).toInt();
  int get calculatedTotalCarbs => (baseCarbs * consumedAmount).toInt();
  int get calculatedTotalFat => (baseFat * consumedAmount).toInt();

  factory FoodResult.fromJson(Map<String, dynamic> json) {
    return FoodResult(
      id: json['id'] as String,
      foodName: json['name'] as String,
      baseCalories: json['cal'] as int,
      baseProtein: json['p'] as int,
      baseCarbs: json['c'] as int,
      baseFat: json['f'] as int,
      measurementUnit: json['unit'] != null 
          ? FoodUnit.values.firstWhere((e) => e.name == json['unit'], orElse: () => FoodUnit.SERVING)
          : FoodUnit.SERVING,
      consumedAmount: (json['amount'] as num?)?.toDouble() ?? 1.0,
      assignedMealType: json['mealType'] != null 
          ? MealType.values.firstWhere((e) => e.name == json['mealType'])
          : null,
      lastUpdatedAt: json['updated_at'] as String?,
      isMarkedForDeletion: json['is_deleted'] == true || json['is_deleted'] == 1 || json['is_deleted'] == 'true',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': foodName, 'cal': baseCalories, 'p': baseProtein,
    'c': baseCarbs, 'f': baseFat, 'unit': measurementUnit.name,
    'amount': consumedAmount, 'mealType': assignedMealType?.name,
    'updated_at': lastUpdatedAt, 'is_deleted': isMarkedForDeletion,
  };
}

@Entity(tableName: 'nutrition_daily_local')
class NutritionDailyEntity {
  @primaryKey
  final String dateId; 

  final double waterConsumedLiters;
  
  final String breakfastJson;
  final String lunchJson;
  final String dinnerJson;
  final String snackJson;

  final String syncStatus;
  final int updatedAt;
  final bool isDeleted;

  NutritionDailyEntity({
    required this.dateId,
    required this.waterConsumedLiters,
    required this.breakfastJson,
    required this.lunchJson,
    required this.dinnerJson,
    required this.snackJson,
    required this.syncStatus,
    required this.updatedAt,
    required this.isDeleted,
  });
}

// ======================= BẢNG WORKOUT PROGRAMS =======================
@Entity(tableName: 'workout_programs_local')
class WorkoutProgramEntity {
  @primaryKey
  @ColumnInfo(name: 'id')
  final String id;

  @ColumnInfo(name: 'name')
  final String name;

  @ColumnInfo(name: 'description')
  final String description;

  @ColumnInfo(name: 'environment')
  final WorkoutEnvironment environment;

  @ColumnInfo(name: 'difficulty')
  final String difficulty;

  @ColumnInfo(name: 'goal')
  final WorkoutGoal goal;

  @ColumnInfo(name: 'routines')
  final String routinesJson; 

  @ColumnInfo(name: 'updatedAt')
  final int updatedAt; 

  WorkoutProgramEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.environment,
    required this.difficulty,
    required this.goal,
    required this.routinesJson,
    required this.updatedAt,
  });
}

// ======================= BẢNG SCHEDULED WORKOUTS =======================
@Entity(tableName: 'scheduled_workouts_local')
class ScheduledWorkoutEntity {
  @primaryKey
  final String id;
  final String routineId; 
  final String routineName; 
  final int targetDateMillis; 
  final bool isCompleted;
  
  final String? colorHex;
  final String? recurrenceGroupId;

  final String syncStatus;
  final int updatedAt;
  final bool isDeleted;

  ScheduledWorkoutEntity({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.targetDateMillis,
    required this.isCompleted,
    this.colorHex,
    this.recurrenceGroupId,
    required this.syncStatus,
    required this.updatedAt,
    required this.isDeleted,
  });
}

// ======================= BẢNG REWARD CLAIMS LEDGER =======================
@Entity(tableName: 'reward_claims_local')
class RewardClaimEntity {
  @primaryKey
  final String id; // Khóa chính (Nên dùng UUID v4)
  
  final String sourceType; // 'QUEST' hoặc 'CHEST'
  final String sourceRef;  // VD: 'q1_2026-W24' hoặc 'weekly_chest'
  final String periodKey;  // Tuần hiện tại, VD: '2026-W24'
  
  final String actionType; // 'CLAIMED' hoặc 'REVOKED'
  final int xpAmount;      // Số XP: > 0 nếu CLAIMED, < 0 nếu REVOKED
  
  final int createdAt;     // Timestamp lúc hành động xảy ra
  
  final String syncStatus; // 'PENDING' (chưa đẩy) hoặc 'SYNCED' (đã đẩy lên Supabase)

  RewardClaimEntity({
    required this.id,
    required this.sourceType,
    required this.sourceRef,
    required this.periodKey,
    required this.actionType,
    required this.xpAmount,
    required this.createdAt,
    required this.syncStatus,
  });
}