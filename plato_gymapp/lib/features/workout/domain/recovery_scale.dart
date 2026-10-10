import 'dart:math';

/// Public recovery scale shared by the chart, recommendations and OS
/// notifications. Below the ready threshold it preserves the normalized raw
/// score. Above it, progress follows elapsed exponential-decay time and reaches
/// 100 after one additional fatigue half-life, avoiding an asymptotic UI tail.
class RecoveryScale {
  static const redThreshold = 40;
  static const readyThreshold = 80;
  static const normalizationCeilingRawPercentage = 95.0;

  static double get readyFatigue =>
      100 - readyThreshold / 100 * normalizationCeilingRawPercentage;

  /// Once a muscle is ready, one more fatigue half-life is treated as fully
  /// recovered. Remaining fatigue is small enough that exposing the infinite
  /// mathematical tail no longer adds useful guidance to the user.
  static double get fullRecoveryFatigue => readyFatigue / 2;

  static double get fullRecoveryRawPercentage => 100 - fullRecoveryFatigue;

  /// Major groups average several detailed muscles. Keep conservative flooring
  /// around the 40/80 safety boundaries, but round a half-point-to-full result
  /// to 100 so a negligible secondary component cannot pin the group at 99.
  static int aggregateDisplayPercentage(double weightedAverage) {
    final clamped = weightedAverage.clamp(0.0, 100.0);
    return clamped >= 99.5 ? 100 : clamped.floor();
  }

  static int displayPercentageFromRaw(double rawPercentage) {
    final normalized = rawPercentage / normalizationCeilingRawPercentage * 100;
    if (normalized < readyThreshold) {
      return normalized.floor().clamp(0, readyThreshold - 1);
    }
    final fatigue = 100 - rawPercentage;
    if (fatigue <= fullRecoveryFatigue) return 100;
    final readyProgress =
        log(readyFatigue / fatigue) / log(readyFatigue / fullRecoveryFatigue);
    return (readyThreshold +
            (100 - readyThreshold) * readyProgress.clamp(0.0, 1.0))
        .floor()
        .clamp(readyThreshold, 99);
  }

  static double targetFatigueForDisplayPercentage(int displayPercentage) {
    final targetDisplay = displayPercentage.clamp(0, 100);
    if (targetDisplay <= readyThreshold) {
      return 100 - targetDisplay / 100 * normalizationCeilingRawPercentage;
    }
    final readyProgress =
        (targetDisplay - readyThreshold) / (100 - readyThreshold);
    return readyFatigue *
        pow(fullRecoveryFatigue / readyFatigue, readyProgress).toDouble();
  }
}
