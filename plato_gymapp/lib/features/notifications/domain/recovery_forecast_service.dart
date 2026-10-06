import 'dart:math';

import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/muscle_recovery_calculator.dart';
import 'package:plato_gymapp/features/workout/domain/streak_calculator.dart';

enum RecoveryForecastState { allReady, partialReady, restToday, readyLater }

enum RoutineRecoveryState { ready, nearlyReady, low, unavailable }

enum RecoveryRoutinePlanState { empty, restToday, allReady, mixed, noneReady }

class MajorMuscleForecast {
  final MajorMuscleGroup muscle;
  final int percentage;
  final DateTime readyAt;
  final int lastTrainedAt;

  const MajorMuscleForecast({
    required this.muscle,
    required this.percentage,
    required this.readyAt,
    required this.lastTrainedAt,
  });
}

class RecoveryForecastSnapshot {
  final DateTime at;
  final String historyRevision;
  final Map<MajorMuscleGroup, MajorMuscleForecast> muscles;
  final RecoveryForecastState state;

  const RecoveryForecastSnapshot({
    required this.at,
    required this.historyRevision,
    required this.muscles,
    required this.state,
  });

  List<MajorMuscleGroup> get ready => muscles.entries
      .where(
        (entry) =>
            entry.value.percentage >= RecoveryForecastService.readyThreshold,
      )
      .map((entry) => entry.key)
      .toList(growable: false);

  List<MajorMuscleGroup> get nearlyReady => muscles.entries
      .where(
        (entry) =>
            entry.value.percentage >= RecoveryForecastService.restThreshold &&
            entry.value.percentage < RecoveryForecastService.readyThreshold,
      )
      .map((entry) => entry.key)
      .toList(growable: false);

  List<MajorMuscleGroup> get low => muscles.entries
      .where(
        (entry) =>
            entry.value.percentage < RecoveryForecastService.restThreshold,
      )
      .map((entry) => entry.key)
      .toList(growable: false);
}

class RoutineRecoveryAssessment {
  final WorkoutSession routine;
  final RoutineRecoveryState state;
  final List<MajorMuscleGroup> targetMuscles;
  final List<MajorMuscleGroup> readyMuscles;
  final List<MajorMuscleGroup> recoveringMuscles;
  final List<MajorMuscleGroup> lowMuscles;
  final int minimumPercentage;
  final int weightedPercentage;

  const RoutineRecoveryAssessment({
    required this.routine,
    required this.state,
    required this.targetMuscles,
    required this.readyMuscles,
    required this.recoveringMuscles,
    required this.lowMuscles,
    required this.minimumPercentage,
    required this.weightedPercentage,
  });

  bool get isActionable => state != RoutineRecoveryState.unavailable;
}

class RecoveryRoutinePlan {
  final RecoveryRoutinePlanState state;
  final List<RoutineRecoveryAssessment> recommended;
  final List<RoutineRecoveryAssessment> cautions;

  const RecoveryRoutinePlan({
    required this.state,
    required this.recommended,
    required this.cautions,
  });
}

/// Shared recovery projection for notification planning and in-app guidance.
/// Workout history is replayed once per detailed muscle. Future snapshots are
/// then derived analytically without replaying history for every day/routine.
class RecoveryForecastService {
  static const readyThreshold = 80;
  static const restThreshold = 50;
  static const trainingBalanceWindow = Duration(days: 30);
  static const majorMuscles = <MajorMuscleGroup>[
    MajorMuscleGroup.CHEST,
    MajorMuscleGroup.BACK,
    MajorMuscleGroup.LEGS,
    MajorMuscleGroup.SHOULDERS,
    MajorMuscleGroup.ARMS,
    MajorMuscleGroup.CORE,
  ];

  final DateTime baseTime;
  final List<WorkoutSession> history;
  final String historyRevision;
  final Map<MuscleGroup, MuscleRecoveryStatus> _base;

  factory RecoveryForecastService(List<WorkoutSession> source, {DateTime? at}) {
    final baseTime = at ?? DateTime.now();
    final history = source.where(StreakCalculator.qualifies).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return RecoveryForecastService._(
      baseTime,
      history,
      revisionOf(history, historyIsSorted: true),
      {
        for (final muscle in MuscleGroup.values)
          muscle: MuscleRecoveryCalculator.getRecoveryStatus(
            muscle,
            history,
            at: baseTime,
            historyIsSorted: true,
          ),
      },
    );
  }

  const RecoveryForecastService._(
    this.baseTime,
    this.history,
    this.historyRevision,
    this._base,
  );

  bool get hasHistory => history.isNotEmpty;

  RecoveryForecastSnapshot snapshotAt(DateTime at) {
    final forecasts = <MajorMuscleGroup, MajorMuscleForecast>{};
    for (final major in majorMuscles) {
      final details = MuscleGroup.values
          .where((muscle) => muscle.major == major)
          .map((muscle) => _base[muscle]!)
          .toList(growable: false);
      forecasts[major] = MajorMuscleForecast(
        muscle: major,
        percentage: details
            .map((status) => _percentageAt(status, at))
            .reduce(min),
        readyAt: details
            .map(_readyAt)
            .reduce((latest, value) => value.isAfter(latest) ? value : latest),
        lastTrainedAt: details
            .map((status) => status.lastTrainedDate)
            .reduce(max),
      );
    }
    return RecoveryForecastSnapshot(
      at: at,
      historyRevision: historyRevision,
      muscles: Map.unmodifiable(forecasts),
      state: classify({
        for (final entry in forecasts.entries)
          entry.key: entry.value.percentage,
      }),
    );
  }

  /// Returns the next moment where a major muscle can cross the 50% or 80%
  /// boundary used by routine recommendations. Callers can schedule one
  /// refresh at this time instead of polling while the screen is open.
  DateTime? nextTransitionAfter(DateTime at) {
    DateTime? next;
    for (final major in majorMuscles) {
      final details = MuscleGroup.values
          .where((muscle) => muscle.major == major)
          .map((muscle) => _base[muscle]!)
          .toList(growable: false);
      for (final threshold in [restThreshold, readyThreshold]) {
        final crossings = details
            .map((status) => _thresholdAt(status, threshold))
            .toList(growable: false);
        if (crossings.any((value) => value == null)) continue;
        final groupCrossing = crossings.cast<DateTime>().reduce(
          (latest, value) => value.isAfter(latest) ? value : latest,
        );
        if (!groupCrossing.isAfter(at)) continue;
        if (next == null || groupCrossing.isBefore(next)) {
          next = groupCrossing;
        }
      }
    }
    return next;
  }

  RoutineRecoveryAssessment assessRoutine(
    WorkoutSession routine, {
    DateTime? at,
  }) {
    final snapshot = snapshotAt(at ?? baseTime);
    return _assessRoutine(routine, snapshot);
  }

  RoutineRecoveryAssessment _assessRoutine(
    WorkoutSession routine,
    RecoveryForecastSnapshot snapshot,
  ) {
    final weights = _routineWeights(routine);
    if (weights.isEmpty) {
      return RoutineRecoveryAssessment(
        routine: routine,
        state: RoutineRecoveryState.unavailable,
        targetMuscles: const [],
        readyMuscles: const [],
        recoveringMuscles: const [],
        lowMuscles: const [],
        minimumPercentage: 0,
        weightedPercentage: 0,
      );
    }

    final targets = weights.keys.toList(growable: false);
    final ready = <MajorMuscleGroup>[];
    final recovering = <MajorMuscleGroup>[];
    final low = <MajorMuscleGroup>[];
    var minimum = 100;
    var weightedTotal = 0.0;
    var totalWeight = 0.0;
    for (final muscle in targets) {
      final percentage = snapshot.muscles[muscle]!.percentage;
      minimum = min(minimum, percentage);
      weightedTotal += percentage * weights[muscle]!;
      totalWeight += weights[muscle]!;
      if (percentage >= readyThreshold) {
        ready.add(muscle);
      } else if (percentage >= restThreshold) {
        recovering.add(muscle);
      } else {
        low.add(muscle);
      }
    }

    final state = low.isNotEmpty
        ? RoutineRecoveryState.low
        : recovering.isNotEmpty
        ? RoutineRecoveryState.nearlyReady
        : RoutineRecoveryState.ready;
    return RoutineRecoveryAssessment(
      routine: routine,
      state: state,
      targetMuscles: targets,
      readyMuscles: ready,
      recoveringMuscles: recovering,
      lowMuscles: low,
      minimumPercentage: minimum,
      weightedPercentage: totalWeight == 0
          ? minimum
          : (weightedTotal / totalWeight).round().clamp(0, 100),
    );
  }

  List<RoutineRecoveryAssessment> rankRoutines(
    Iterable<WorkoutSession> routines, {
    DateTime? at,
    int? limit,
  }) {
    final targetTime = at ?? baseTime;
    final snapshot = snapshotAt(targetTime);
    final recentTrainingLoad = _recentMajorMuscleLoad(targetTime);
    final assessments = routines
        .map((routine) => _assessRoutine(routine, snapshot))
        .where((assessment) => assessment.isActionable)
        .toList();
    final deficitScores = {
      for (final assessment in assessments)
        assessment: _trainingDeficitScore(assessment, recentTrainingLoad),
    };
    assessments.sort((a, b) {
      final stateOrder = _routineStatePriority(
        a.state,
      ).compareTo(_routineStatePriority(b.state));
      if (stateOrder != 0) return stateOrder;
      final aDeficit = deficitScores[a]!;
      final bDeficit = deficitScores[b]!;
      final priorityOrder = _routinePriorityScore(
        b,
        bDeficit,
      ).compareTo(_routinePriorityScore(a, aDeficit));
      if (priorityOrder != 0) return priorityOrder;
      final minimumOrder = b.minimumPercentage.compareTo(a.minimumPercentage);
      if (minimumOrder != 0) return minimumOrder;
      final weightedOrder = b.weightedPercentage.compareTo(
        a.weightedPercentage,
      );
      if (weightedOrder != 0) return weightedOrder;
      final balanceOrder = bDeficit.compareTo(aDeficit);
      if (balanceOrder != 0) return balanceOrder;
      final lastTrainedOrder = _lastTargetWorkout(
        a,
        snapshot,
      ).compareTo(_lastTargetWorkout(b, snapshot));
      if (lastTrainedOrder != 0) return lastTrainedOrder;
      final coverageOrder = b.targetMuscles.length.compareTo(
        a.targetMuscles.length,
      );
      if (coverageOrder != 0) return coverageOrder;
      return a.routine.id.compareTo(b.routine.id);
    });
    if (limit != null && assessments.length > limit) {
      return assessments.take(limit).toList(growable: false);
    }
    return assessments;
  }

  RecoveryRoutinePlan planRoutines(
    Iterable<WorkoutSession> routines, {
    DateTime? at,
    int maxSuggestions = 2,
  }) {
    final snapshot = snapshotAt(at ?? baseTime);
    if (snapshot.state == RecoveryForecastState.restToday) {
      return const RecoveryRoutinePlan(
        state: RecoveryRoutinePlanState.restToday,
        recommended: [],
        cautions: [],
      );
    }
    final ranked = rankRoutines(routines, at: at);
    if (ranked.isEmpty) {
      return const RecoveryRoutinePlan(
        state: RecoveryRoutinePlanState.empty,
        recommended: [],
        cautions: [],
      );
    }
    final ready = ranked
        .where((item) => item.state == RoutineRecoveryState.ready)
        .toList(growable: false);
    final notReady = ranked
        .where((item) => item.state != RoutineRecoveryState.ready)
        .toList(growable: false);
    if (notReady.isEmpty) {
      return RecoveryRoutinePlan(
        state: RecoveryRoutinePlanState.allReady,
        recommended: ready.take(maxSuggestions).toList(growable: false),
        cautions: const [],
      );
    }
    if (ready.length >= maxSuggestions) {
      return RecoveryRoutinePlan(
        state: RecoveryRoutinePlanState.mixed,
        recommended: ready.take(maxSuggestions).toList(growable: false),
        cautions: const [],
      );
    }
    if (ready.isNotEmpty) {
      final highestRisk = [...notReady]
        ..sort((a, b) {
          final minimum = a.minimumPercentage.compareTo(b.minimumPercentage);
          if (minimum != 0) return minimum;
          final weighted = a.weightedPercentage.compareTo(b.weightedPercentage);
          if (weighted != 0) return weighted;
          return a.routine.id.compareTo(b.routine.id);
        });
      return RecoveryRoutinePlan(
        state: RecoveryRoutinePlanState.mixed,
        recommended: [ready.first],
        cautions: [highestRisk.first],
      );
    }
    return RecoveryRoutinePlan(
      state: RecoveryRoutinePlanState.noneReady,
      recommended: const [],
      // rankRoutines puts nearly-ready and the safest low-recovery options
      // first, which is the most useful ordering when every routine needs care.
      cautions: notReady.take(maxSuggestions).toList(growable: false),
    );
  }

  /// Returns an alternative only when it is materially safer than [current].
  /// A better recovery state always qualifies. Within the same state, require
  /// at least a ten-point gain in the weakest or weighted recovery score so a
  /// visually similar routine is not presented as a meaningful replacement.
  RoutineRecoveryAssessment? bestAlternativeFor(
    WorkoutSession current,
    Iterable<WorkoutSession> routines, {
    DateTime? at,
    int minimumImprovement = 10,
  }) {
    if (snapshotAt(at ?? baseTime).state == RecoveryForecastState.restToday) {
      return null;
    }
    final currentAssessment = assessRoutine(current, at: at);
    if (!currentAssessment.isActionable ||
        currentAssessment.state == RoutineRecoveryState.ready) {
      return null;
    }
    for (final candidate in rankRoutines(routines, at: at)) {
      if (candidate.routine.id == current.id) continue;
      final stateGain =
          _routineStatePriority(currentAssessment.state) -
          _routineStatePriority(candidate.state);
      if (stateGain > 0) return candidate;
      if (stateGain < 0) continue;
      final minimumGain =
          candidate.minimumPercentage - currentAssessment.minimumPercentage;
      final weightedGain =
          candidate.weightedPercentage - currentAssessment.weightedPercentage;
      if (minimumGain >= minimumImprovement ||
          (minimumGain >= 0 && weightedGain >= minimumImprovement)) {
        return candidate;
      }
    }
    return null;
  }

  static int _lastTargetWorkout(
    RoutineRecoveryAssessment assessment,
    RecoveryForecastSnapshot snapshot,
  ) => assessment.targetMuscles
      .map((muscle) => snapshot.muscles[muscle]?.lastTrainedAt ?? 0)
      .fold(0, max);

  /// Mirrors the heatmap intensity model for the last 30 days: completed hard
  /// sets count as 1 for the primary muscle and 1/3 for secondary muscles.
  /// The map is calculated once per ranking pass, so adding more routines does
  /// not replay workout history for every candidate.
  Map<MajorMuscleGroup, double> _recentMajorMuscleLoad(DateTime at) {
    final load = {for (final muscle in majorMuscles) muscle: 0.0};
    final end = at.millisecondsSinceEpoch;
    final start = at.subtract(trainingBalanceWindow).millisecondsSinceEpoch;
    for (final session in history.reversed) {
      if (session.startTime > end) continue;
      if (session.startTime < start) break;
      for (final workoutExercise in session.exercises) {
        final hardSets = workoutExercise.sets
            .where(
              (set) =>
                  set.isCompleted &&
                  (set.type == SetType.NORMAL ||
                      set.type == SetType.DROPSET ||
                      set.type == SetType.FAILURE),
            )
            .length
            .toDouble();
        if (hardSets == 0) continue;
        final primary = workoutExercise.exercise.primaryMuscle?.major;
        if (primary != null && majorMuscles.contains(primary)) {
          load[primary] = load[primary]! + hardSets;
        }
        for (final secondary
            in workoutExercise.exercise.secondaryMuscles ??
                const <MuscleGroup>[]) {
          if (!majorMuscles.contains(secondary.major)) continue;
          load[secondary.major] = load[secondary.major]! + hardSets / 3;
        }
      }
    }
    return load;
  }

  static double _trainingDeficitScore(
    RoutineRecoveryAssessment assessment,
    Map<MajorMuscleGroup, double> recentLoad,
  ) {
    final routineWeights = _routineWeights(assessment.routine);
    if (routineWeights.isEmpty) return 0;
    final highestLoad = recentLoad.values.fold(0.0, max);
    if (highestLoad <= 0) return 0;
    var weightedDeficit = 0.0;
    var totalWeight = 0.0;
    for (final entry in routineWeights.entries) {
      final normalizedLoad = (recentLoad[entry.key] ?? 0) / highestLoad;
      weightedDeficit += (1 - normalizedLoad.clamp(0.0, 1.0)) * entry.value;
      totalWeight += entry.value;
    }
    return totalWeight == 0 ? 0 : weightedDeficit / totalWeight;
  }

  /// Safety state is compared before this score. Within the same state,
  /// recovery remains dominant while training balance can compensate for at
  /// most ten recovery points. This avoids overreacting to small 98/99%
  /// differences caused by muscle-specific recovery rates.
  static double _routinePriorityScore(
    RoutineRecoveryAssessment assessment,
    double trainingDeficit,
  ) =>
      assessment.minimumPercentage * .65 +
      assessment.weightedPercentage * .35 +
      trainingDeficit * 10;

  static RecoveryForecastState classify(
    Map<MajorMuscleGroup, int> recoveryByMajor,
  ) {
    final values = majorMuscles.map((major) => recoveryByMajor[major] ?? 0);
    final readyCount = values.where((value) => value >= readyThreshold).length;
    if (readyCount == majorMuscles.length)
      return RecoveryForecastState.allReady;
    if (readyCount > 0) return RecoveryForecastState.partialReady;
    if (values.every((value) => value < restThreshold)) {
      return RecoveryForecastState.restToday;
    }
    return RecoveryForecastState.readyLater;
  }

  static String revisionOf(
    List<WorkoutSession> history, {
    bool historyIsSorted = false,
  }) {
    var hash = 0x811c9dc5;
    final qualifying = history.where(StreakCalculator.qualifies).toList();
    if (!historyIsSorted) {
      qualifying.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    for (final session in qualifying) {
      final value = '${session.id}:${session.startTime}:${session.updatedAt};';
      for (final code in value.codeUnits) {
        hash ^= code;
        hash = (hash * 0x01000193) & 0x7fffffff;
      }
    }
    return '${qualifying.length}:$hash';
  }

  static Map<MajorMuscleGroup, double> _routineWeights(WorkoutSession routine) {
    final weights = <MajorMuscleGroup, double>{};
    for (final workoutExercise in routine.exercises) {
      final setWeight = max(1, workoutExercise.sets.length).toDouble();
      final primary = workoutExercise.exercise.primaryMuscle?.major;
      if (primary != null && majorMuscles.contains(primary)) {
        weights[primary] = (weights[primary] ?? 0) + 3 * setWeight;
      }
      for (final secondary
          in workoutExercise.exercise.secondaryMuscles ??
              const <MuscleGroup>[]) {
        if (!majorMuscles.contains(secondary.major)) continue;
        weights[secondary.major] = (weights[secondary.major] ?? 0) + setWeight;
      }
    }
    return weights;
  }

  static int _routineStatePriority(RoutineRecoveryState state) =>
      switch (state) {
        RoutineRecoveryState.ready => 0,
        RoutineRecoveryState.nearlyReady => 1,
        RoutineRecoveryState.low => 2,
        RoutineRecoveryState.unavailable => 3,
      };

  static int _percentageAt(MuscleRecoveryStatus status, DateTime at) {
    if (status.lastTrainedDate == 0) return 100;
    final hours = max(
      0.0,
      (at.millisecondsSinceEpoch - status.lastTrainedDate) /
          Duration.millisecondsPerHour,
    );
    final fatigue = status.initialFatigue * exp(-status.recoveryRate * hours);
    return (100 - fatigue).toInt().clamp(0, 100);
  }

  static DateTime _readyAt(MuscleRecoveryStatus status) {
    return _thresholdAt(status, readyThreshold) ??
        DateTime.fromMillisecondsSinceEpoch(
          status.lastTrainedDate,
        ).add(const Duration(days: 36500));
  }

  static DateTime? _thresholdAt(MuscleRecoveryStatus status, int threshold) {
    final targetFatigue = 100 - threshold;
    if (status.lastTrainedDate == 0 || status.initialFatigue <= targetFatigue) {
      return DateTime.fromMillisecondsSinceEpoch(status.lastTrainedDate);
    }
    if (status.recoveryRate <= 0) {
      return null;
    }
    final hours =
        log(status.initialFatigue / targetFatigue) / status.recoveryRate;
    return DateTime.fromMillisecondsSinceEpoch(
      status.lastTrainedDate + (hours * Duration.millisecondsPerHour).ceil(),
    );
  }
}
