import 'dart:math';
import '../data/models/workout_models.dart';
import '../../../../core/database/enums.dart';

class MuscleRecoveryStatus {
  final MuscleGroup muscle;
  final int lastTrainedDate;
  final int hoursSinceLastTrain;
  final int recoveryPercentage;
  final RecoveryState state;
  final double initialFatigue;
  final double recoveryRate;

  MuscleRecoveryStatus(
    this.muscle,
    this.lastTrainedDate,
    this.hoursSinceLastTrain,
    this.recoveryPercentage,
    this.state,
    this.initialFatigue,
    this.recoveryRate,
  );
}

class MuscleRecoveryCalculator {
  static MuscleRecoveryStatus getRecoveryStatus(MuscleGroup targetMuscle, List<WorkoutSession> history) {
    if (history.isEmpty) {
      return MuscleRecoveryStatus(targetMuscle, 0, 999, 100, RecoveryState.FRESH, 0, 0);
    }

    // Sắp xếp tăng dần theo thời gian (Từ quá khứ -> Hiện tại)
    final sortedHistory = List<WorkoutSession>.from(history)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Bộ nhớ tạm cho EMA (Exponential Moving Average)
    Map<String, double> exerciseCapacities = {};
    double targetMuscleCapacity = 0.0;

    double cumulativeFatigue = 0.0;
    int lastTrainedTime = 0;
    double previousLambda = 0.0;

    for (var session in sortedHistory) {
      // ---------------------------------------------------------
      // GIAI ĐOẠN 1 & 2: TÍNH TOÁN LOAD BÀI TẬP & NHÓM CƠ (MSL)
      // ---------------------------------------------------------
      Map<MuscleGroup, double> sessionMuscleLoads = {};

      for (var we in session.exercises) {
        // Sử dụng hàm tính Load nội bộ, không dùng workout_extensions
        double loadEx = _calculateStandardizedLoad(we);
        if (loadEx <= 0) continue;

        String exId = we.exercise.id;

        // B1: Lấy hoặc khởi tạo Capacity của bài tập
        double capEx = exerciseCapacities[exId] ?? loadEx;

        // B2: Tính Relative Load (RL) & Clamp Max 1.5
        double rlEx = capEx > 0 ? min(loadEx / capEx, 1.5) : 1.0;

        // B3: Cập nhật Capacity bài tập bằng EMA
        exerciseCapacities[exId] = (capEx * 0.75) + (loadEx * 0.25);

        // Phân bổ RL vào Nhóm Cơ Chính (Primary = 100%) - FIX LỖI TYPE
        MuscleGroup? primary = we.exercise.primaryMuscle;
        if (primary != null) {
          sessionMuscleLoads[primary] = (sessionMuscleLoads[primary] ?? 0.0) + (rlEx * 1.0);
        }

        // Phân bổ RL vào Nhóm Cơ Phụ (Secondary = 33.3%)
        if (we.exercise.secondaryMuscles != null) {
          for (var sec in we.exercise.secondaryMuscles!) {
            // Check null an toàn cho các phần tử trong list enum
            sessionMuscleLoads[sec] = (sessionMuscleLoads[sec] ?? 0.0) + (rlEx * (1.0 / 3.0));
                    }
        }
      }

      // Lấy Tổng Điểm Tải Trọng (MSL) của nhóm cơ mục tiêu
      double mslTarget = sessionMuscleLoads[targetMuscle] ?? 0.0;

      // Nếu nhóm cơ mục tiêu không hoạt động trong buổi này -> Bỏ qua tính fatigue
      if (mslTarget <= 0.0) continue;

      // ---------------------------------------------------------
      // GIAI ĐOẠN 3: PHÂN BỔ RPE & TÍNH MỆT MỎI (F_new)
      // ---------------------------------------------------------
      
      // Tìm nhóm cơ bị cày ải nặng nhất (Max MSL) để làm chuẩn RPE
      double mslMax = sessionMuscleLoads.values.reduce(max);
      double impactFactor = mslTarget / mslMax;

      double sessionRpe = session.rpe?.toDouble() ?? 8.0;
      double effectiveRpe = max(1.0, sessionRpe * impactFactor);

      // Suy giảm mệt mỏi cũ từ buổi trước (Decay)
      if (lastTrainedTime > 0 && previousLambda > 0.0) {
        final hoursBetween = (session.startTime - lastTrainedTime) / 3600000.0;
        cumulativeFatigue = cumulativeFatigue * exp(-previousLambda * hoursBetween);
      }

      // Khởi tạo Capacity Nhóm Cơ (MC) nếu là buổi đầu tiên
      if (targetMuscleCapacity == 0.0) {
        targetMuscleCapacity = mslTarget;
      }

      // Sinh mệt mỏi mới (F_new) dựa trên MSL và MC
      double fNew = 0.0;
      if (targetMuscleCapacity > 0) {
        fNew = (mslTarget / targetMuscleCapacity) * (effectiveRpe / 10.0) * 100.0;
      }
      cumulativeFatigue += fNew;

      // Giới hạn chống Overreaching vô hạn (Max 150)
      cumulativeFatigue = min(150.0, cumulativeFatigue);

      // Cập nhật Capacity Nhóm cơ (MC) bằng EMA
      targetMuscleCapacity = (targetMuscleCapacity * 0.75) + (mslTarget * 0.25);

      // Tính Lambda phục hồi cho chặng tiếp theo
      lastTrainedTime = session.startTime;
      final lambdaRange = _getLambdaRange(targetMuscle);
      previousLambda = lambdaRange.$1 + ((10.0 - effectiveRpe) / 9.0) * (lambdaRange.$2 - lambdaRange.$1);
    }

    // Nếu sau khi loop mà targetMuscle chưa từng được tập
    if (lastTrainedTime == 0) {
      return MuscleRecoveryStatus(targetMuscle, 0, 999, 100, RecoveryState.FRESH, 0, 0);
    }

    // ---------------------------------------------------------
    // GIAI ĐOẠN 4: HIỂN THỊ UI & TRẠNG THÁI HIỆN TẠI
    // ---------------------------------------------------------
    final now = DateTime.now().millisecondsSinceEpoch;
    final exactHoursPassed = max(0.0, (now - lastTrainedTime) / 3600000.0);

    // Tính mệt mỏi hiện hành (Current Fatigue)
    final currentFatigue = cumulativeFatigue * exp(-previousLambda * exactHoursPassed);

    // Recovery Percentage
    final trueRecovery = 100.0 - currentFatigue;
    final recoveryPercentage = trueRecovery.toInt().clamp(0, 100);

    RecoveryState state = RecoveryState.EXHAUSTED;
    if (recoveryPercentage >= 80) {
      state = RecoveryState.FRESH;
    } else if (recoveryPercentage >= 40) {
      state = RecoveryState.RECOVERING;
    }

    return MuscleRecoveryStatus(
      targetMuscle,
      lastTrainedTime,
      exactHoursPassed.toInt(),
      recoveryPercentage,
      state,
      cumulativeFatigue,
      previousLambda,
    );
  }

  // =========================================================
  // HELPER MENTHODS (KHÔNG SỬ DỤNG EXTENSION BÊN NGOÀI)
  // =========================================================

  /// Tính toán Tải Trọng Bài Tập (Load_ex)
  /// Xử lý an toàn bodyweight fallback và đa loại hình tập
  static double _calculateStandardizedLoad(WorkoutExercise we, {double userBodyWeight = 65.0}) {
    final completedSets = we.sets.where((s) => s.isCompleted).toList();
    if (completedSets.isEmpty) return 0.0;

    // Giả định `Exercise` entity có biến type. Nếu property name khác, bạn update lại ở đây.
    switch (we.exercise.type) {
      case ExerciseType.WEIGHT_REPS:
        return completedSets.fold(0.0, (sum, set) {
          double effectiveWeight = set.weight > 0 ? set.weight : userBodyWeight;
          return sum + (effectiveWeight * set.reps);
        });
      case ExerciseType.REPS_ONLY:
        return completedSets.fold(0.0, (sum, set) => sum + set.reps.toDouble());
      case ExerciseType.TIME_ONLY:
        return completedSets.fold(0.0, (sum, set) => sum + set.durationTimeSeconds.toDouble());
      case ExerciseType.CARDIO_DISTANCE:
        return completedSets.fold(0.0, (sum, set) => sum + set.distanceInKm);
      case ExerciseType.CARDIO_STEPS:
        return completedSets.fold(0.0, (sum, set) => sum + set.steps.toDouble());
      
    }
  }

  /// Dải hằng số phục hồi theo độ lớn nhóm cơ
  static (double, double) _getLambdaRange(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.LATS: case MuscleGroup.LOWER_BACK: case MuscleGroup.UPPER_BACK:
      case MuscleGroup.TRAPS: case MuscleGroup.QUADS: case MuscleGroup.HAMSTRINGS:
      case MuscleGroup.GLUTES: case MuscleGroup.ADDUCTORS: case MuscleGroup.ABDUCTORS:
      case MuscleGroup.FULL_BODY:
        return (0.031, 0.041);
      case MuscleGroup.UPPER_CHEST: case MuscleGroup.MIDDLE_CHEST: case MuscleGroup.LOWER_CHEST:
      case MuscleGroup.ABS: case MuscleGroup.OBLIQUES:
        return (0.050, 0.062);
      default:
        return (0.050, 0.062);
    }
  }
}