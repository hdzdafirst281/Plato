import 'dart:math';
import '../data/models/workout_models.dart';
import '../../../../core/database/enums.dart';
import 'muscle_exposure_calculator.dart';
import 'recovery_load_calculator.dart';
import 'recovery_scale.dart';

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
  static MuscleRecoveryStatus getRecoveryStatus(
    MuscleGroup targetMuscle,
    List<WorkoutSession> history, {
    DateTime? at,
    bool historyIsSorted = false,
    double? userBodyWeight,
  }) {
    if (history.isEmpty) {
      return MuscleRecoveryStatus(
        targetMuscle,
        0,
        999,
        100,
        RecoveryState.FRESH,
        0,
        0,
      );
    }

    // Sắp xếp tăng dần theo thời gian (Từ quá khứ -> Hiện tại)
    final sortedHistory = historyIsSorted
        ? history
        : (List<WorkoutSession>.from(history)
            ..sort((a, b) => a.startTime.compareTo(b.startTime)));

    // Bộ nhớ tạm cho EMA (Exponential Moving Average)
    Map<String, double> exerciseCapacities = {};
    Map<String, double> exerciseIntensityBaselines = {};
    double targetMuscleCapacity = 0.0;

    double cumulativeFatigue = 0.0;
    int lastTrainedTime = 0;
    double previousLambda = 0.0;

    for (var session in sortedHistory) {
      // ---------------------------------------------------------
      // GIAI ĐOẠN 1 & 2: TÍNH TOÁN LOAD BÀI TẬP & NHÓM CƠ (MSL)
      // ---------------------------------------------------------
      final sessionMuscleLoads = <MuscleGroup, double>{};
      final sessionMuscleRpeLoads = <MuscleGroup, double>{};

      for (var we in session.exercises) {
        final loadEx = RecoveryLoadCalculator.exerciseVolume(
          we,
          userBodyWeight: userBodyWeight,
        );
        if (loadEx <= 0) continue;

        final exId = we.exercise.id;

        // B1: Lấy hoặc khởi tạo Capacity của bài tập
        final capEx = exerciseCapacities[exId] ?? loadEx;

        // B2: Tính Relative Load (RL) & Clamp Max 1.5
        final relativeVolume = capEx > 0 ? min(loadEx / capEx, 1.5) : 1.0;

        // Ưu tiên intensity khách quan khi bài có đủ dữ liệu.
        final objectiveMetric = RecoveryLoadCalculator.objectiveMetric(we);
        final objectiveIntensity = RecoveryLoadCalculator.objectiveIntensity(
          currentMetric: objectiveMetric,
          baselineMetric: exerciseIntensityBaselines[exId],
        );
        final adjustedRelativeLoad = min(
          relativeVolume * objectiveIntensity,
          RecoveryLoadCalculator.maxAdjustedRelativeLoad,
        );

        final exerciseRpe = RecoveryLoadCalculator.exerciseRpe(
          we,
          sessionRpe: session.rpe,
          userBodyWeight: userBodyWeight,
        );

        // Chỉ cập nhật baseline sau khi đã tính tải hiện tại.
        exerciseCapacities[exId] =
            RecoveryLoadCalculator.updateEma(capEx, loadEx);
        if (objectiveMetric != null) {
          exerciseIntensityBaselines[exId] = RecoveryLoadCalculator.updateEma(
            exerciseIntensityBaselines[exId],
            objectiveMetric,
          );
        }

        for (final entry
            in MuscleExposureCalculator.detailedCoefficients(we).entries) {
          final contribution = adjustedRelativeLoad * entry.value;
          sessionMuscleLoads[entry.key] =
              (sessionMuscleLoads[entry.key] ?? 0.0) + contribution;
          sessionMuscleRpeLoads[entry.key] =
              (sessionMuscleRpeLoads[entry.key] ?? 0.0) +
              contribution * exerciseRpe;
        }
      }

      // Lấy Tổng Điểm Tải Trọng (MSL) của nhóm cơ mục tiêu
      double mslTarget = sessionMuscleLoads[targetMuscle] ?? 0.0;

      // Nếu nhóm cơ mục tiêu không hoạt động trong buổi này -> Bỏ qua tính fatigue
      if (mslTarget <= 0.0) continue;

      // ---------------------------------------------------------
      // GIAI ĐOẠN 3: PHÂN BỔ RPE & TÍNH MỆT MỎI (F_new)
      // ---------------------------------------------------------

      // Effort của nhóm cơ chỉ đến từ các bài tác động lên chính nhóm cơ đó.
      final effectiveRpe = (
        (sessionMuscleRpeLoads[targetMuscle] ??
                mslTarget * RecoveryLoadCalculator.defaultRecoveryRpe) /
            mslTarget
      ).clamp(1.0, 10.0);

      // Suy giảm mệt mỏi cũ từ buổi trước (Decay)
      final sessionEndTime = _sessionEndTime(session);
      if (lastTrainedTime > 0 && previousLambda > 0.0) {
        final hoursBetween = max(
          0.0,
          (sessionEndTime - lastTrainedTime) / 3600000.0,
        );
        cumulativeFatigue =
            cumulativeFatigue * exp(-previousLambda * hoursBetween);
      }

      // Khởi tạo Capacity Nhóm Cơ (MC) nếu là buổi đầu tiên
      if (targetMuscleCapacity == 0.0) {
        targetMuscleCapacity = mslTarget;
      }

      // Sinh mệt mỏi mới (F_new) dựa trên MSL và MC
      double fNew = 0.0;
      if (targetMuscleCapacity > 0) {
        fNew =
            (mslTarget / targetMuscleCapacity) * (effectiveRpe / 10.0) * 100.0;
      }
      cumulativeFatigue += fNew;

      // Giới hạn chống Overreaching vô hạn (Max 150)
      cumulativeFatigue = min(150.0, cumulativeFatigue);

      // Cập nhật Capacity Nhóm cơ (MC) bằng EMA
      targetMuscleCapacity = (targetMuscleCapacity * 0.75) + (mslTarget * 0.25);

      // Tính Lambda phục hồi cho chặng tiếp theo
      lastTrainedTime = sessionEndTime;
      final lambdaRange = _getLambdaRange(targetMuscle);
      previousLambda =
          lambdaRange.$1 +
          ((10.0 - effectiveRpe) / 9.0) * (lambdaRange.$2 - lambdaRange.$1);
    }

    // Nếu sau khi loop mà targetMuscle chưa từng được tập
    if (lastTrainedTime == 0) {
      return MuscleRecoveryStatus(
        targetMuscle,
        0,
        999,
        100,
        RecoveryState.FRESH,
        0,
        0,
      );
    }

    // ---------------------------------------------------------
    // GIAI ĐOẠN 4: HIỂN THỊ UI & TRẠNG THÁI HIỆN TẠI
    // ---------------------------------------------------------
    final now = (at ?? DateTime.now()).millisecondsSinceEpoch;
    final exactHoursPassed = max(0.0, (now - lastTrainedTime) / 3600000.0);

    // Tính mệt mỏi hiện hành (Current Fatigue)
    final currentFatigue =
        cumulativeFatigue * exp(-previousLambda * exactHoursPassed);

    // Recovery Percentage
    final trueRecovery = 100.0 - currentFatigue;
    final recoveryPercentage = RecoveryScale.displayPercentageFromRaw(
      trueRecovery,
    );
    RecoveryState state = RecoveryState.EXHAUSTED;
    if (recoveryPercentage >= RecoveryScale.readyThreshold) {
      state = RecoveryState.FRESH;
    } else if (recoveryPercentage >= RecoveryScale.redThreshold) {
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

  static int _sessionEndTime(WorkoutSession session) {
    final endTime = session.endTime;
    if (endTime != null && endTime >= session.startTime) return endTime;
    if (session.totalDurationSeconds > 0) {
      return session.startTime + session.totalDurationSeconds * 1000;
    }
    return session.startTime;
  }

  /// Dải hằng số phục hồi theo độ lớn nhóm cơ
  static (double, double) _getLambdaRange(MuscleGroup muscle) {
    switch (muscle) {
      case MuscleGroup.LATS:
      case MuscleGroup.LOWER_BACK:
      case MuscleGroup.UPPER_BACK:
      case MuscleGroup.TRAPS:
      case MuscleGroup.QUADS:
      case MuscleGroup.HAMSTRINGS:
      case MuscleGroup.GLUTES:
      case MuscleGroup.ADDUCTORS:
      case MuscleGroup.ABDUCTORS:
      case MuscleGroup.FULL_BODY:
        return (0.031, 0.041);
      case MuscleGroup.UPPER_CHEST:
      case MuscleGroup.MIDDLE_CHEST:
      case MuscleGroup.LOWER_CHEST:
      case MuscleGroup.ABS:
      case MuscleGroup.OBLIQUES:
        return (0.050, 0.062);
      default:
        return (0.050, 0.062);
    }
  }
}
