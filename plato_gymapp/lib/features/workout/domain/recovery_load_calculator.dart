import 'dart:math';

import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';

import 'muscle_exposure_calculator.dart';

/// Shared volume, objective-intensity and effort rules for Recovery and load
/// analytics. Raw units intentionally stay exercise-specific and only become
/// comparable after division by that exercise's personal capacity.
class RecoveryLoadCalculator {
  static const defaultRecoveryRpe = 8.0;
  static const minObjectiveIntensity = 0.75;
  static const maxObjectiveIntensity = 1.25;
  static const maxAdjustedRelativeLoad = 1.75;

  static List<ExerciseSet> completedWorkingSets(WorkoutExercise exercise) =>
      exercise.sets
          .where(
            (set) =>
                set.isCompleted && MuscleExposureCalculator.isWorkingSet(set),
          )
          .toList(growable: false);

  static double setVolume(
    ExerciseSet set,
    ExerciseType type, {
    double? userBodyWeight,
  }) {
    switch (type) {
      case ExerciseType.WEIGHT_REPS:
        final effectiveWeight = set.weight > 0
            ? set.weight
            : (userBodyWeight ?? 1.0);
        return max(0.0, effectiveWeight) * max(0, set.reps);
      case ExerciseType.REPS_ONLY:
        return max(0, set.reps).toDouble();
      case ExerciseType.TIME_ONLY:
        return max(0, set.durationTimeSeconds).toDouble();
      case ExerciseType.CARDIO_DISTANCE:
        return max(0.0, set.distanceInKm);
      case ExerciseType.CARDIO_STEPS:
        return max(0, set.steps).toDouble();
    }
  }

  static double exerciseVolume(
    WorkoutExercise exercise, {
    double? userBodyWeight,
  }) => completedWorkingSets(exercise).fold(
    0.0,
    (sum, set) =>
        sum +
        setVolume(set, exercise.exercise.type, userBodyWeight: userBodyWeight),
  );

  /// Returns km/h for distance cardio and steps/minute for step cardio.
  /// Other exercise types do not currently expose an independent objective
  /// intensity metric, so they return null rather than inventing one.
  static double? objectiveMetric(WorkoutExercise exercise) {
    final sets = completedWorkingSets(exercise);
    if (sets.isEmpty) return null;

    switch (exercise.exercise.type) {
      case ExerciseType.CARDIO_DISTANCE:
        final distance = sets.fold(0.0, (sum, set) => sum + set.distanceInKm);
        final seconds = sets.fold(
          0,
          (sum, set) => sum + set.durationTimeSeconds,
        );
        if (distance <= 0 || seconds <= 0) return null;
        final speedKmh = distance / (seconds / 3600.0);
        return speedKmh.isFinite && speedKmh > 0 ? speedKmh : null;
      case ExerciseType.CARDIO_STEPS:
        final steps = sets.fold(0, (sum, set) => sum + set.steps);
        final seconds = sets.fold(
          0,
          (sum, set) => sum + set.durationTimeSeconds,
        );
        if (steps <= 0 || seconds <= 0) return null;
        final cadence = steps / (seconds / 60.0);
        return cadence.isFinite && cadence > 0 ? cadence : null;
      case ExerciseType.WEIGHT_REPS:
      case ExerciseType.REPS_ONLY:
      case ExerciseType.TIME_ONLY:
        return null;
    }
  }

  static double objectiveIntensity({
    required double? currentMetric,
    required double? baselineMetric,
  }) {
    if (currentMetric == null ||
        baselineMetric == null ||
        currentMetric <= 0 ||
        baselineMetric <= 0) {
      return 1.0;
    }
    return (currentMetric / baselineMetric).clamp(
      minObjectiveIntensity,
      maxObjectiveIntensity,
    );
  }

  static double updateEma(double? previous, double current) {
    if (!current.isFinite || current <= 0) return previous ?? 0.0;
    if (previous == null || previous <= 0) return current;
    return previous * 0.75 + current * 0.25;
  }

  static double resolvedSetRpe(ExerciseSet set, int? sessionRpe) {
    final setRpe = set.rpe;
    if (setRpe != null && setRpe >= 1 && setRpe <= 10) {
      return setRpe.toDouble();
    }
    if (sessionRpe != null && sessionRpe >= 1 && sessionRpe <= 10) {
      return sessionRpe.toDouble();
    }
    return defaultRecoveryRpe;
  }

  static double exerciseRpe(
    WorkoutExercise exercise, {
    required int? sessionRpe,
    double? userBodyWeight,
  }) {
    final sets = completedWorkingSets(exercise);
    if (sets.isEmpty) {
      return sessionRpe?.toDouble() ?? defaultRecoveryRpe;
    }

    var weightedRpe = 0.0;
    var totalWeight = 0.0;
    for (final set in sets) {
      final volume = setVolume(
        set,
        exercise.exercise.type,
        userBodyWeight: userBodyWeight,
      );
      final weight = volume > 0 ? volume : 1.0;
      weightedRpe += resolvedSetRpe(set, sessionRpe) * weight;
      totalWeight += weight;
    }
    return totalWeight > 0
        ? (weightedRpe / totalWeight).clamp(1.0, 10.0)
        : defaultRecoveryRpe;
  }

  static double? averageEnteredSetRpe(WorkoutSession session) {
    final ratings = <int>[];
    for (final exercise in session.exercises) {
      for (final set in completedWorkingSets(exercise)) {
        final rpe = set.rpe;
        if (rpe != null && rpe >= 1 && rpe <= 10) ratings.add(rpe);
      }
    }
    if (ratings.isEmpty) return null;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  static double? effectiveSessionRpe(WorkoutSession session) {
    final sessionRpe = session.rpe;
    if (sessionRpe != null && sessionRpe >= 1 && sessionRpe <= 10) {
      return sessionRpe.toDouble();
    }
    return averageEnteredSetRpe(session);
  }
}
