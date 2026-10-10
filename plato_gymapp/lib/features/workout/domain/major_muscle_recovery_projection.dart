import 'dart:math';

import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/muscle_exposure_calculator.dart';
import 'package:plato_gymapp/features/workout/domain/muscle_recovery_calculator.dart';
import 'package:plato_gymapp/features/workout/domain/recovery_scale.dart';

class WeightedMuscleRecovery {
  final MuscleRecoveryStatus status;
  final double weight;

  const WeightedMuscleRecovery(this.status, this.weight);
}

class MajorMuscleRecoveryProjection {
  final DateTime baseTime;
  final Map<MajorMuscleGroup, List<WeightedMuscleRecovery>> components;
  final Map<(MajorMuscleGroup, int), DateTime?> _thresholdCache = {};

  MajorMuscleRecoveryProjection._(this.baseTime, this.components);

  factory MajorMuscleRecoveryProjection(
    List<WorkoutSession> source, {
    DateTime? at,
    bool historyIsSorted = false,
  }) {
    final baseTime = at ?? DateTime.now();
    final history = historyIsSorted
        ? source
        : (List<WorkoutSession>.from(source)
            ..sort((a, b) => a.startTime.compareTo(b.startTime)));
    final recentLoad = MuscleExposureCalculator.recentDetailedLoad(
      history,
      baseTime,
    );
    final statuses = {
      for (final muscle in MuscleGroup.values)
        muscle: MuscleRecoveryCalculator.getRecoveryStatus(
          muscle,
          history,
          at: baseTime,
          historyIsSorted: true,
        ),
    };
    final result = <MajorMuscleGroup, List<WeightedMuscleRecovery>>{};
    for (final major in MuscleExposureCalculator.majorMuscles) {
      final values = <WeightedMuscleRecovery>[];
      for (final muscle in MuscleGroup.values.where(
        (muscle) => muscle.major == major,
      )) {
        final status = statuses[muscle]!;
        var weight = recentLoad[muscle] ?? 0;
        // Preserve a tiny contribution for older fatigue that has not fully
        // decayed, without allowing an old secondary muscle to dominate.
        if (weight == 0 &&
            status.lastTrainedDate > 0 &&
            _displayPercentageAt(status, baseTime) < 100) {
          weight = .01;
        }
        if (weight > 0) values.add(WeightedMuscleRecovery(status, weight));
      }
      result[major] = List.unmodifiable(values);
    }
    return MajorMuscleRecoveryProjection._(baseTime, Map.unmodifiable(result));
  }

  int percentageAt(MajorMuscleGroup muscle, DateTime at) {
    final values = components[muscle] ?? const <WeightedMuscleRecovery>[];
    if (values.isEmpty) return 100;
    var total = 0.0;
    var weighted = 0.0;
    for (final component in values) {
      total += component.weight;
      weighted += _displayPercentageAt(component.status, at) * component.weight;
    }
    return total == 0
        ? 100
        : RecoveryScale.aggregateDisplayPercentage(weighted / total);
  }

  static int _displayPercentageAt(MuscleRecoveryStatus status, DateTime at) {
    if (status.lastTrainedDate == 0 || status.initialFatigue <= 0) return 100;
    final hours = max(
      0.0,
      (at.millisecondsSinceEpoch - status.lastTrainedDate) /
          Duration.millisecondsPerHour,
    );
    final fatigue = status.initialFatigue * exp(-status.recoveryRate * hours);
    return RecoveryScale.displayPercentageFromRaw(100 - fatigue);
  }

  int lastTrainedAt(MajorMuscleGroup muscle) =>
      (components[muscle] ?? const <WeightedMuscleRecovery>[])
          .map((component) => component.status.lastTrainedDate)
          .fold(0, max);

  DateTime? thresholdAt(
    MajorMuscleGroup muscle,
    int threshold, {
    DateTime? from,
  }) {
    final start = from ?? baseTime;
    if (percentageAt(muscle, start) >= threshold) return start;
    final key = (muscle, threshold);
    if (_thresholdCache.containsKey(key)) {
      final cached = _thresholdCache[key];
      return cached != null && cached.isAfter(start) ? cached : null;
    }
    var high = baseTime.add(const Duration(hours: 12));
    final limit = baseTime.add(const Duration(days: 90));
    while (percentageAt(muscle, high) < threshold && high.isBefore(limit)) {
      final span = high.difference(baseTime);
      high = baseTime.add(span * 2);
      if (high.isAfter(limit)) high = limit;
    }
    if (percentageAt(muscle, high) < threshold) {
      _thresholdCache[key] = null;
      return null;
    }
    var lowMillis = baseTime.millisecondsSinceEpoch;
    var highMillis = high.millisecondsSinceEpoch;
    // Millisecond precision is unnecessary for notifications; one minute
    // keeps the search cheap and stable.
    while (highMillis - lowMillis > Duration.millisecondsPerMinute) {
      final middle = lowMillis + ((highMillis - lowMillis) ~/ 2);
      if (percentageAt(muscle, DateTime.fromMillisecondsSinceEpoch(middle)) >=
          threshold) {
        highMillis = middle;
      } else {
        lowMillis = middle;
      }
    }
    final result = DateTime.fromMillisecondsSinceEpoch(highMillis);
    _thresholdCache[key] = result;
    return result;
  }

  DateTime? nextTransitionAfter(DateTime at) {
    DateTime? next;
    for (final muscle in MuscleExposureCalculator.majorMuscles) {
      final current = percentageAt(muscle, at);
      for (final threshold in const [
        RecoveryScale.redThreshold,
        RecoveryScale.readyThreshold,
      ]) {
        if (current >= threshold) continue;
        final crossing = thresholdAt(muscle, threshold, from: at);
        if (crossing != null &&
            crossing.isAfter(at) &&
            (next == null || crossing.isBefore(next))) {
          next = crossing;
        }
      }
    }
    return next;
  }
}
