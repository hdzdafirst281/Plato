import 'dart:math';

import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';

/// Shared muscle-load rules used by Muscle Split, recovery guidance, the
/// training-balance tie breaker, and history charts.
class MuscleExposureCalculator {
  static const displayBaselinePercent = 1.0;
  static const primaryCoefficient = 1.0;
  static const secondaryCoefficient = 1.0 / 3.0;
  static const sessionHeatmapLow = 0.2;
  static const sessionHeatmapMedium = 0.4;
  static const sessionHeatmapHigh = 0.7;

  static const majorMuscles = <MajorMuscleGroup>[
    MajorMuscleGroup.CHEST,
    MajorMuscleGroup.BACK,
    MajorMuscleGroup.LEGS,
    MajorMuscleGroup.SHOULDERS,
    MajorMuscleGroup.ARMS,
    MajorMuscleGroup.CORE,
  ];

  static const trainingBalanceHalfLife = Duration(days: 14);
  static const trainingBalanceWindow = Duration(days: 28);

  static bool isWorkingSet(ExerciseSet set) =>
      set.type == SetType.NORMAL ||
      set.type == SetType.SUPERSET ||
      set.type == SetType.DROPSET ||
      set.type == SetType.FAILURE;

  static int validSetCount(
    WorkoutExercise exercise, {
    required bool onlyCompletedSets,
  }) => exercise.sets
      .where(
        (set) => isWorkingSet(set) && (!onlyCompletedSets || set.isCompleted),
      )
      .length;

  static Map<MuscleGroup, double> detailedCoefficients(
    WorkoutExercise exercise,
  ) {
    final result = <MuscleGroup, double>{};
    final primary = exercise.exercise.primaryMuscle;
    if (primary != null) result[primary] = primaryCoefficient;

    final secondaries =
        (exercise.exercise.secondaryMuscles ?? const <MuscleGroup>[])
            .where((muscle) => muscle != primary)
            .toSet();
    for (final secondary in secondaries) {
      result[secondary] = secondaryCoefficient;
    }
    return result;
  }

  /// Primary work is worth three parts and each distinct secondary major
  /// group one part. A secondary tag never double-counts the primary major or
  /// another detailed muscle that belongs to the same major group.
  static Map<MajorMuscleGroup, double> majorWeights(
    Iterable<WorkoutExercise> exercises, {
    bool onlyCompletedSets = false,
  }) {
    final result = <MajorMuscleGroup, double>{};
    for (final workoutExercise in exercises) {
      final setCount = validSetCount(
        workoutExercise,
        onlyCompletedSets: onlyCompletedSets,
      );
      if (setCount == 0) continue;
      final primary = workoutExercise.exercise.primaryMuscle?.major;
      if (primary != null && majorMuscles.contains(primary)) {
        result[primary] = (result[primary] ?? 0) + 3.0 * setCount;
      }
      final secondaryMajors =
          (workoutExercise.exercise.secondaryMuscles ?? const <MuscleGroup>[])
              .map((muscle) => muscle.major)
              .where(
                (major) => majorMuscles.contains(major) && major != primary,
              )
              .toSet();
      for (final secondary in secondaryMajors) {
        result[secondary] = (result[secondary] ?? 0) + setCount;
      }
    }
    return result;
  }

  static Map<MajorMuscleGroup, double> distribution(
    Iterable<WorkoutExercise> exercises, {
    bool onlyCompletedSets = false,
  }) {
    final weights = majorWeights(
      exercises,
      onlyCompletedSets: onlyCompletedSets,
    );
    final total = weights.values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) return <MajorMuscleGroup, double>{};
    final distributablePercent =
        100 - displayBaselinePercent * majorMuscles.length;
    return {
      for (final muscle in majorMuscles)
        muscle:
            displayBaselinePercent +
            (weights[muscle] ?? 0) / total * distributablePercent,
    };
  }

  /// Relative muscle exposure inside one completed session.
  ///
  /// The most-trained detailed muscle is the reference for the session, so
  /// short and long workouts use the same visual meaning: high, medium, low,
  /// or absent. Only completed working sets contribute.
  static Map<MuscleGroup, double> sessionHeatmapIntensities(
    Iterable<WorkoutExercise> exercises,
  ) {
    final scores = <MuscleGroup, double>{};
    for (final exercise in exercises) {
      final setCount = validSetCount(exercise, onlyCompletedSets: true);
      if (setCount == 0) continue;

      for (final entry in detailedCoefficients(exercise).entries) {
        if (!majorMuscles.contains(entry.key.major)) continue;
        scores[entry.key] = (scores[entry.key] ?? 0) + setCount * entry.value;
      }
    }
    if (scores.isEmpty) return <MuscleGroup, double>{};

    final maxScore = scores.values.reduce(max);
    return {
      for (final entry in scores.entries)
        entry.key: switch (entry.value / maxScore) {
          < 1 / 3 => sessionHeatmapLow,
          < 2 / 3 => sessionHeatmapMedium,
          _ => sessionHeatmapHigh,
        },
    };
  }

  /// Exponentially decayed completed-set exposure for recommendation balance.
  /// The fixed 28-day cutoff bounds work, while the 14-day half-life prevents
  /// a workout from disappearing abruptly at the edge of the window.
  static Map<MajorMuscleGroup, double> recentMajorLoad(
    Iterable<WorkoutSession> history,
    DateTime at,
  ) {
    final result = {for (final muscle in majorMuscles) muscle: 0.0};
    final start = at.subtract(trainingBalanceWindow).millisecondsSinceEpoch;
    final end = at.millisecondsSinceEpoch;
    for (final session in history) {
      if (session.startTime < start || session.startTime > end) continue;
      final ageDays = max(
        0.0,
        (end - session.startTime) / Duration.millisecondsPerDay,
      );
      final decay = pow(
        .5,
        ageDays / trainingBalanceHalfLife.inDays,
      ).toDouble();
      final weights = majorWeights(session.exercises, onlyCompletedSets: true);
      for (final entry in weights.entries) {
        // majorWeights uses 3:1 for presentation. Divide by three here so a
        // primary hard set remains one training-balance unit.
        result[entry.key] = result[entry.key]! + entry.value / 3 * decay;
      }
    }
    return result;
  }

  /// Recent exposure for weighting detailed-muscle recovery inside one major
  /// group. This keeps a lightly involved secondary muscle from dominating the
  /// six-group recovery result.
  static Map<MuscleGroup, double> recentDetailedLoad(
    Iterable<WorkoutSession> history,
    DateTime at,
  ) {
    final result = <MuscleGroup, double>{};
    final start = at.subtract(trainingBalanceWindow).millisecondsSinceEpoch;
    final end = at.millisecondsSinceEpoch;
    for (final session in history) {
      if (session.startTime < start || session.startTime > end) continue;
      final ageDays = max(
        0.0,
        (end - session.startTime) / Duration.millisecondsPerDay,
      );
      final decay = pow(
        .5,
        ageDays / trainingBalanceHalfLife.inDays,
      ).toDouble();
      for (final workoutExercise in session.exercises) {
        final setCount = validSetCount(
          workoutExercise,
          onlyCompletedSets: true,
        );
        if (setCount == 0) continue;
        final primary = workoutExercise.exercise.primaryMuscle;
        if (primary != null && majorMuscles.contains(primary.major)) {
          result[primary] =
              (result[primary] ?? 0) + setCount * primaryCoefficient * decay;
        }
        final secondaries =
            (workoutExercise.exercise.secondaryMuscles ?? const <MuscleGroup>[])
                .where(
                  (muscle) =>
                      majorMuscles.contains(muscle.major) && muscle != primary,
                )
                .toSet();
        for (final secondary in secondaries) {
          result[secondary] =
              (result[secondary] ?? 0) +
              setCount * secondaryCoefficient * decay;
        }
      }
    }
    return result;
  }
}
