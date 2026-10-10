import 'dart:math';

import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/major_muscle_recovery_projection.dart';
import 'package:plato_gymapp/features/workout/domain/muscle_exposure_calculator.dart';
import 'package:plato_gymapp/features/workout/domain/recovery_scale.dart';
import 'package:plato_gymapp/features/workout/domain/streak_calculator.dart';

enum RecoveryForecastState { allReady, partialReady, restToday, readyLater }

enum RoutineRecoveryState {
  ready,
  readyAdjusted,
  nearlyReady,
  low,
  unavailable,
}

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
  final int weightedPercentage;
  final int lowerTailPercentage;
  final Map<MajorMuscleGroup, double> muscleDistribution;
  final double redShare;
  final double redSeverity;
  final DateTime? readyAt;
  final DateTime? nextStateAt;

  const RoutineRecoveryAssessment({
    required this.routine,
    required this.state,
    required this.targetMuscles,
    required this.readyMuscles,
    required this.recoveringMuscles,
    required this.lowMuscles,
    required this.weightedPercentage,
    required this.lowerTailPercentage,
    this.muscleDistribution = const {},
    this.redShare = 0,
    this.redSeverity = 0,
    this.readyAt,
    this.nextStateAt,
  });

  bool get isActionable => state != RoutineRecoveryState.unavailable;
  bool get isReady =>
      state == RoutineRecoveryState.ready ||
      state == RoutineRecoveryState.readyAdjusted;
  bool get needsAdjustment => state == RoutineRecoveryState.readyAdjusted;
}

class _RoutineRecoveryMetrics {
  final RoutineRecoveryState state;
  final List<MajorMuscleGroup> readyMuscles;
  final List<MajorMuscleGroup> recoveringMuscles;
  final List<MajorMuscleGroup> lowMuscles;
  final int weightedPercentage;
  final int lowerTailPercentage;
  final double redShare;
  final double yellowShare;
  final double redSeverity;
  final double waitSeverity;

  const _RoutineRecoveryMetrics({
    required this.state,
    required this.readyMuscles,
    required this.recoveringMuscles,
    required this.lowMuscles,
    required this.weightedPercentage,
    required this.lowerTailPercentage,
    required this.redShare,
    required this.yellowShare,
    required this.redSeverity,
    required this.waitSeverity,
  });
}

class _RoutineRisk {
  final double redShare;
  final double yellowShare;
  final double redSeverity;
  final double waitSeverity;
  final bool hasDominantCriticalMuscle;

  const _RoutineRisk({
    required this.redShare,
    required this.yellowShare,
    required this.redSeverity,
    required this.waitSeverity,
    required this.hasDominantCriticalMuscle,
  });
}

class RecoveryRoutinePlan {
  final RecoveryRoutinePlanState state;
  final List<RoutineRecoveryAssessment> recommended;
  final List<RoutineRecoveryAssessment> cautions;
  final List<MajorMuscleGroup> uncoveredReadyMuscles;
  final int distinctRoutineCount;
  final DateTime? nextStateAt;

  const RecoveryRoutinePlan({
    required this.state,
    required this.recommended,
    required this.cautions,
    this.uncoveredReadyMuscles = const [],
    this.distinctRoutineCount = 0,
    this.nextStateAt,
  });

  /// Keeps the limited UI focused on what needs the user's attention first:
  /// unsuitable routines, routines that need more time, then ready routines.
  List<RoutineRecoveryAssessment> get prioritizedSuggestions => [
    ...cautions,
    ...recommended,
  ];

  /// Selection keeps warnings from being dropped, while presentation puts the
  /// most immediately useful action first.
  List<RoutineRecoveryAssessment> get displaySuggestions => [
    ...recommended,
    ...cautions.where((item) => item.state == RoutineRecoveryState.nearlyReady),
    ...cautions.where((item) => item.state == RoutineRecoveryState.low),
    ...cautions.where((item) => item.state == RoutineRecoveryState.unavailable),
  ];
}

/// Shared recovery projection for notification planning and in-app guidance.
/// Workout history is replayed once per detailed muscle. Future snapshots are
/// then derived analytically without replaying history for every day/routine.
class RecoveryForecastService {
  static const readyThreshold = RecoveryScale.readyThreshold;
  static const restThreshold = RecoveryScale.redThreshold;
  static const majorMuscles = MuscleExposureCalculator.majorMuscles;
  static const routineRiskLimitShare = 40.0;
  static const adjustmentBudgetShare = 20.0;
  static const maximumRedSeverity = 30.0;
  static const maximumWaitSeverity = 20.0;
  static const dominantMuscleShare = 30.0;
  static const criticalRecoveryPercentage = 20;
  static const lowerTailPercentile = 20.0;
  static const meaningfulCoverageShare = 10.0;
  static const _comparisonEpsilon = .0001;

  final DateTime baseTime;
  final List<WorkoutSession> history;
  final String historyRevision;
  final MajorMuscleRecoveryProjection _recovery;

  factory RecoveryForecastService(List<WorkoutSession> source, {DateTime? at}) {
    final baseTime = at ?? DateTime.now();
    final history = source.where(StreakCalculator.qualifies).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return RecoveryForecastService._(
      baseTime,
      history,
      revisionOf(history, historyIsSorted: true),
      MajorMuscleRecoveryProjection(
        history,
        at: baseTime,
        historyIsSorted: true,
      ),
    );
  }

  const RecoveryForecastService._(
    this.baseTime,
    this.history,
    this.historyRevision,
    this._recovery,
  );

  bool get hasHistory => history.isNotEmpty;

  RecoveryForecastSnapshot snapshotAt(DateTime at) {
    final forecasts = <MajorMuscleGroup, MajorMuscleForecast>{};
    for (final major in majorMuscles) {
      forecasts[major] = MajorMuscleForecast(
        muscle: major,
        percentage: _recovery.percentageAt(major, at),
        readyAt:
            _recovery.thresholdAt(major, readyThreshold, from: at) ??
            at.add(const Duration(days: 36500)),
        lastTrainedAt: _recovery.lastTrainedAt(major),
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

  /// Returns the next moment where a major muscle can cross the 40% or 80%
  /// boundary used by routine recommendations. Callers can schedule one
  /// refresh at this time instead of polling while the screen is open.
  DateTime? nextTransitionAfter(DateTime at) {
    return _recovery.nextTransitionAfter(at);
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
    final weights = MuscleExposureCalculator.majorWeights(routine.exercises);
    if (weights.isEmpty) {
      return RoutineRecoveryAssessment(
        routine: routine,
        state: RoutineRecoveryState.unavailable,
        targetMuscles: const [],
        readyMuscles: const [],
        recoveringMuscles: const [],
        lowMuscles: const [],
        weightedPercentage: 0,
        lowerTailPercentage: 0,
      );
    }

    final targets = weights.keys.toList(growable: false);
    var totalWeight = 0.0;
    for (final weight in weights.values) {
      totalWeight += weight;
    }

    final distribution = {
      for (final entry in weights.entries)
        entry.key: entry.value / totalWeight * 100,
    };
    final metrics = _routineMetrics(distribution, {
      for (final muscle in targets)
        muscle: snapshot.muscles[muscle]!.percentage,
    });
    final nextStateAt = _routineTransitionAt(
      distribution,
      snapshot,
      metrics.state,
    );
    final readyAt = metrics.state == RoutineRecoveryState.nearlyReady
        ? nextStateAt
        : null;
    return RoutineRecoveryAssessment(
      routine: routine,
      state: metrics.state,
      targetMuscles: targets,
      readyMuscles: metrics.readyMuscles,
      recoveringMuscles: metrics.recoveringMuscles,
      lowMuscles: metrics.lowMuscles,
      weightedPercentage: metrics.weightedPercentage,
      lowerTailPercentage: metrics.lowerTailPercentage,
      muscleDistribution: Map.unmodifiable(distribution),
      redShare: metrics.redShare,
      redSeverity: metrics.redSeverity,
      readyAt: readyAt,
      nextStateAt: nextStateAt,
    );
  }

  _RoutineRecoveryMetrics _routineMetrics(
    Map<MajorMuscleGroup, double> distribution,
    Map<MajorMuscleGroup, int> recoveryByMuscle,
  ) {
    final risk = _routineRisk(distribution, recoveryByMuscle);
    final ready = <MajorMuscleGroup>[];
    final recovering = <MajorMuscleGroup>[];
    final low = <MajorMuscleGroup>[];
    var weightedTotal = 0.0;
    for (final entry in distribution.entries) {
      final muscle = entry.key;
      final share = entry.value;
      final percentage = recoveryByMuscle[muscle] ?? 100;
      weightedTotal += percentage * share;
      if (percentage >= readyThreshold) {
        ready.add(muscle);
      } else if (percentage >= restThreshold) {
        recovering.add(muscle);
      } else {
        low.add(muscle);
      }
    }
    return _RoutineRecoveryMetrics(
      state: classifyRoutineRisk(
        redShare: risk.redShare,
        yellowShare: risk.yellowShare,
        redSeverity: risk.redSeverity,
        waitSeverity: risk.waitSeverity,
        hasDominantCriticalMuscle: risk.hasDominantCriticalMuscle,
      ),
      readyMuscles: List.unmodifiable(ready),
      recoveringMuscles: List.unmodifiable(recovering),
      lowMuscles: List.unmodifiable(low),
      weightedPercentage: (weightedTotal / 100).round().clamp(0, 100),
      lowerTailPercentage: _weightedPercentile(
        distribution,
        recoveryByMuscle,
        lowerTailPercentile,
      ),
      redShare: risk.redShare,
      yellowShare: risk.yellowShare,
      redSeverity: risk.redSeverity,
      waitSeverity: risk.waitSeverity,
    );
  }

  static _RoutineRisk _routineRisk(
    Map<MajorMuscleGroup, double> distribution,
    Map<MajorMuscleGroup, int> recoveryByMuscle,
  ) {
    var redShare = 0.0;
    var yellowShare = 0.0;
    var redSeverity = 0.0;
    var waitSeverity = 0.0;
    var hasDominantCriticalMuscle = false;
    for (final entry in distribution.entries) {
      final share = entry.value;
      final percentage = recoveryByMuscle[entry.key] ?? 100;
      if (percentage >= readyThreshold) continue;
      waitSeverity +=
          share *
          (readyThreshold - percentage) /
          (readyThreshold - restThreshold);
      if (percentage >= restThreshold) {
        yellowShare += share;
        continue;
      }
      redShare += share;
      redSeverity += share * (restThreshold - percentage) / restThreshold;
      if (_greaterThanOrEqual(share, dominantMuscleShare) &&
          percentage < criticalRecoveryPercentage) {
        hasDominantCriticalMuscle = true;
      }
    }
    return _RoutineRisk(
      redShare: redShare,
      yellowShare: yellowShare,
      redSeverity: redSeverity,
      waitSeverity: waitSeverity,
      hasDominantCriticalMuscle: hasDominantCriticalMuscle,
    );
  }

  DateTime? _routineTransitionAt(
    Map<MajorMuscleGroup, double> distribution,
    RecoveryForecastSnapshot snapshot,
    RoutineRecoveryState currentState,
  ) {
    if (currentState == RoutineRecoveryState.ready ||
        currentState == RoutineRecoveryState.readyAdjusted ||
        currentState == RoutineRecoveryState.unavailable) {
      return null;
    }
    var high = snapshot.at;
    for (final muscle in distribution.keys) {
      final candidate = snapshot.muscles[muscle]!.readyAt;
      if (candidate.isAfter(high)) high = candidate;
    }
    final limit = snapshot.at.add(const Duration(days: 90));
    if (high.isAfter(limit)) high = limit;
    bool hasImprovedAt(DateTime at) {
      final risk = _routineRisk(distribution, {
        for (final muscle in distribution.keys)
          muscle: _recovery.percentageAt(muscle, at),
      });
      final state = classifyRoutineRisk(
        redShare: risk.redShare,
        yellowShare: risk.yellowShare,
        redSeverity: risk.redSeverity,
        waitSeverity: risk.waitSeverity,
        hasDominantCriticalMuscle: risk.hasDominantCriticalMuscle,
      );
      return _routineStatePriority(state) < _routineStatePriority(currentState);
    }

    if (!hasImprovedAt(high)) return null;
    var lowMillis = snapshot.at.millisecondsSinceEpoch;
    var highMillis = high.millisecondsSinceEpoch;
    while (highMillis - lowMillis > Duration.millisecondsPerMinute) {
      final middle = lowMillis + ((highMillis - lowMillis) ~/ 2);
      if (hasImprovedAt(DateTime.fromMillisecondsSinceEpoch(middle))) {
        highMillis = middle;
      } else {
        lowMillis = middle;
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(highMillis);
  }

  static int _weightedPercentile(
    Map<MajorMuscleGroup, double> distribution,
    Map<MajorMuscleGroup, int> recoveryByMuscle,
    double percentile,
  ) {
    final ordered = distribution.entries.toList()
      ..sort((a, b) {
        final recoveryOrder = (recoveryByMuscle[a.key] ?? 100).compareTo(
          recoveryByMuscle[b.key] ?? 100,
        );
        if (recoveryOrder != 0) return recoveryOrder;
        return a.key.index.compareTo(b.key.index);
      });
    var accumulatedShare = 0.0;
    for (final entry in ordered) {
      accumulatedShare += entry.value;
      if (_greaterThanOrEqual(accumulatedShare, percentile)) {
        return recoveryByMuscle[entry.key] ?? 100;
      }
    }
    return ordered.isEmpty ? 0 : recoveryByMuscle[ordered.last.key] ?? 100;
  }

  List<RoutineRecoveryAssessment> rankRoutines(
    Iterable<WorkoutSession> routines, {
    DateTime? at,
    int? limit,
  }) {
    final targetTime = at ?? baseTime;
    final snapshot = snapshotAt(targetTime);
    final recentTrainingLoad = MuscleExposureCalculator.recentMajorLoad(
      history,
      targetTime,
    );
    final recentStart = targetTime
        .subtract(MuscleExposureCalculator.trainingBalanceWindow)
        .millisecondsSinceEpoch;
    final hasReliableBalance =
        history.where((session) => session.startTime >= recentStart).length >=
            3 &&
        recentTrainingLoad.values.fold(0.0, (sum, value) => sum + value) >= 6;
    final assessments = routines
        .map((routine) => _assessRoutine(routine, snapshot))
        .where((assessment) => assessment.isActionable)
        .toList();
    final deficitScores = {
      for (final assessment in assessments)
        assessment: hasReliableBalance
            ? _trainingDeficitScore(assessment, recentTrainingLoad)
            : 0.0,
    };
    assessments.sort((a, b) {
      final stateOrder = _routineStatePriority(
        a.state,
      ).compareTo(_routineStatePriority(b.state));
      if (stateOrder != 0) return stateOrder;
      if (a.state == RoutineRecoveryState.nearlyReady &&
          b.state == RoutineRecoveryState.nearlyReady) {
        final readyOrder = (a.readyAt?.millisecondsSinceEpoch ?? 1 << 62)
            .compareTo(b.readyAt?.millisecondsSinceEpoch ?? 1 << 62);
        if (readyOrder != 0) return readyOrder;
      }
      final aDeficit = deficitScores[a]!;
      final bDeficit = deficitScores[b]!;
      final priorityOrder = _routinePriorityScore(
        b,
        bDeficit,
      ).compareTo(_routinePriorityScore(a, aDeficit));
      if (priorityOrder != 0) return priorityOrder;
      final lowerTailOrder = b.lowerTailPercentage.compareTo(
        a.lowerTailPercentage,
      );
      if (lowerTailOrder != 0) return lowerTailOrder;
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
    final ranked = _deduplicateAssessments(rankRoutines(routines, at: at));
    if (ranked.isEmpty) {
      return const RecoveryRoutinePlan(
        state: RecoveryRoutinePlanState.empty,
        recommended: [],
        cautions: [],
      );
    }
    final nextStateAt = ranked
        .map((item) => item.nextStateAt)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (earliest, value) =>
              earliest == null || value.isBefore(earliest) ? value : earliest,
        );
    final ready = ranked.where((item) => item.isReady).toList(growable: false);
    final nearlyReady = ranked
        .where((item) => item.state == RoutineRecoveryState.nearlyReady)
        .toList(growable: false);
    final low =
        ranked
            .where((item) => item.state == RoutineRecoveryState.low)
            .toList(growable: true)
          ..sort((a, b) {
            final danger = _dangerScore(b).compareTo(_dangerScore(a));
            if (danger != 0) return danger;
            return a.routine.id.compareTo(b.routine.id);
          });
    final safelyCoveredMuscles = ready
        .expand(
          (assessment) => assessment.muscleDistribution.entries
              .where((entry) => entry.value >= meaningfulCoverageShare)
              .map((entry) => entry.key),
        )
        .toSet();
    final uncoveredReadyMuscles = snapshot.ready
        .where((muscle) => !safelyCoveredMuscles.contains(muscle))
        .toList(growable: false);
    if (low.isEmpty && nearlyReady.isEmpty) {
      return RecoveryRoutinePlan(
        state: RecoveryRoutinePlanState.allReady,
        recommended: ready.take(maxSuggestions).toList(growable: false),
        cautions: const [],
        uncoveredReadyMuscles: uncoveredReadyMuscles,
        distinctRoutineCount: ranked.length,
        nextStateAt: nextStateAt,
      );
    }
    final selected = <RoutineRecoveryAssessment>[];

    if (ready.isNotEmpty) {
      selected.add(ready.first);
      if (low.isNotEmpty) {
        selected.add(low.first);
      } else if (nearlyReady.isNotEmpty) {
        selected.add(nearlyReady.first);
      } else if (ready.length > 1) {
        selected.add(ready[1]);
      }
    } else if (nearlyReady.isNotEmpty) {
      selected.add(nearlyReady.first);
      if (low.isNotEmpty) {
        selected.add(low.first);
      } else if (nearlyReady.length > 1) {
        selected.add(nearlyReady[1]);
      }
    } else {
      selected.addAll(low.take(maxSuggestions));
    }
    if (selected.length > maxSuggestions) {
      selected.removeRange(maxSuggestions, selected.length);
    }
    return RecoveryRoutinePlan(
      state: ready.isEmpty
          ? RecoveryRoutinePlanState.noneReady
          : RecoveryRoutinePlanState.mixed,
      recommended: selected
          .where((item) => item.isReady)
          .toList(growable: false),
      cautions: selected.where((item) => !item.isReady).toList(growable: false),
      uncoveredReadyMuscles: uncoveredReadyMuscles,
      distinctRoutineCount: ranked.length,
      nextStateAt: nextStateAt,
    );
  }

  /// Returns an alternative only when it is materially safer than [current].
  /// A better recovery state always qualifies. Within the same state, require
  /// at least a ten-point gain in the exposure-aware lower tail or weighted
  /// recovery score so a tiny secondary muscle cannot dominate the decision.
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
    if (!currentAssessment.isActionable || currentAssessment.isReady) {
      return null;
    }
    for (final candidate in _deduplicateAssessments(
      rankRoutines(routines, at: at),
    )) {
      if (candidate.routine.id == current.id) continue;
      if (_sameSplit(currentAssessment, candidate)) continue;
      final stateGain =
          _routineStatePriority(currentAssessment.state) -
          _routineStatePriority(candidate.state);
      if (stateGain > 0) return candidate;
      if (stateGain < 0) continue;
      if (currentAssessment.state == RoutineRecoveryState.nearlyReady &&
          candidate.readyAt != null &&
          currentAssessment.readyAt != null &&
          candidate.readyAt!.isBefore(
            currentAssessment.readyAt!.subtract(const Duration(hours: 2)),
          )) {
        return candidate;
      }
      if (currentAssessment.state == RoutineRecoveryState.low &&
          _dangerScore(currentAssessment) - _dangerScore(candidate) >= 10) {
        return candidate;
      }
      final lowerTailGain =
          candidate.lowerTailPercentage - currentAssessment.lowerTailPercentage;
      final weightedGain =
          candidate.weightedPercentage - currentAssessment.weightedPercentage;
      if (lowerTailGain >= minimumImprovement ||
          (lowerTailGain >= 0 && weightedGain >= minimumImprovement)) {
        return candidate;
      }
    }
    return null;
  }

  static List<RoutineRecoveryAssessment> _deduplicateAssessments(
    List<RoutineRecoveryAssessment> ranked,
  ) {
    final result = <RoutineRecoveryAssessment>[];
    for (final candidate in ranked) {
      if (result.any((kept) => _sameSplit(kept, candidate))) continue;
      result.add(candidate);
    }
    return result;
  }

  static bool _sameSplit(
    RoutineRecoveryAssessment a,
    RoutineRecoveryAssessment b,
  ) {
    if (a.muscleDistribution.isEmpty || b.muscleDistribution.isEmpty) {
      return false;
    }
    Set<MajorMuscleGroup> dominant(Map<MajorMuscleGroup, double> distribution) {
      final highest = distribution.values.fold(0.0, max);
      return distribution.entries
          .where((entry) => highest - entry.value <= 5 && entry.value > 0)
          .map((entry) => entry.key)
          .toSet();
    }

    final aDominant = dominant(a.muscleDistribution);
    final bDominant = dominant(b.muscleDistribution);
    if (aDominant.length != bDominant.length ||
        !aDominant.containsAll(bDominant)) {
      return false;
    }
    final absoluteDifference = majorMuscles.fold(
      0.0,
      (sum, muscle) =>
          sum +
          ((a.muscleDistribution[muscle] ?? 0) -
                  (b.muscleDistribution[muscle] ?? 0))
              .abs(),
    );
    return absoluteDifference <= 20;
  }

  static double _dangerScore(RoutineRecoveryAssessment assessment) {
    return assessment.redSeverity * .7 + assessment.redShare * .3;
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
  static double _trainingDeficitScore(
    RoutineRecoveryAssessment assessment,
    Map<MajorMuscleGroup, double> recentLoad,
  ) {
    final routineWeights = assessment.muscleDistribution;
    if (routineWeights.isEmpty) return 0;
    final positive = recentLoad.values.where((value) => value > 0).toList()
      ..sort();
    if (positive.isEmpty) return 0;
    final median = positive.length.isOdd
        ? positive[positive.length ~/ 2]
        : (positive[positive.length ~/ 2 - 1] +
                  positive[positive.length ~/ 2]) /
              2;
    if (median <= 0) return 0;
    var weightedDeficit = 0.0;
    var totalWeight = 0.0;
    for (final entry in routineWeights.entries) {
      final need = ((median - (recentLoad[entry.key] ?? 0)) / median).clamp(
        0.0,
        1.0,
      );
      weightedDeficit += need * entry.value;
      totalWeight += entry.value;
    }
    return totalWeight == 0 ? 0 : weightedDeficit / totalWeight;
  }

  /// Safety state is compared before this score. The weighted 20th percentile
  /// represents the least-recovered meaningful portion of a routine without
  /// letting a tiny secondary muscle dominate. Training balance can compensate
  /// for at most ten points and never overrides the safety state.
  static double _routinePriorityScore(
    RoutineRecoveryAssessment assessment,
    double trainingDeficit,
  ) =>
      assessment.weightedPercentage * .8 +
      assessment.lowerTailPercentage * .2 +
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

  static RoutineRecoveryState classifyRoutineRisk({
    required double redShare,
    required double yellowShare,
    required double redSeverity,
    required double waitSeverity,
    bool hasDominantCriticalMuscle = false,
  }) {
    if (_greaterThanOrEqual(redShare, routineRiskLimitShare) ||
        _greaterThanOrEqual(redSeverity, maximumRedSeverity) ||
        hasDominantCriticalMuscle) {
      return RoutineRecoveryState.low;
    }
    final unreadyShare = redShare + yellowShare;
    if (_greaterThan(redShare, adjustmentBudgetShare) ||
        _greaterThanOrEqual(unreadyShare, routineRiskLimitShare) ||
        (_greaterThan(unreadyShare, adjustmentBudgetShare) &&
            _greaterThanOrEqual(waitSeverity, maximumWaitSeverity))) {
      return RoutineRecoveryState.nearlyReady;
    }
    if (_greaterThan(redShare, 0)) {
      return RoutineRecoveryState.readyAdjusted;
    }
    return RoutineRecoveryState.ready;
  }

  static bool _greaterThan(double value, double threshold) =>
      value - threshold > _comparisonEpsilon;

  static bool _greaterThanOrEqual(double value, double threshold) =>
      value > threshold - _comparisonEpsilon;

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

  static int _routineStatePriority(RoutineRecoveryState state) =>
      switch (state) {
        RoutineRecoveryState.ready => 0,
        RoutineRecoveryState.readyAdjusted => 1,
        RoutineRecoveryState.nearlyReady => 2,
        RoutineRecoveryState.low => 3,
        RoutineRecoveryState.unavailable => 4,
      };
}
