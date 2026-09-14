import 'dart:math' as math;
import '../data/models/gamification_models.dart';
import 'rank_calculator.dart';

/// Converts lifetime XP while preserving level crossings during the count-up.
class RewardXpProgress {
  static int requirement(int level) => 1000 + (level - 1) * 50;

  static int total(UserGamificationStats stats) {
    final levels = stats.level - 1;
    return levels * 1000 + 25 * levels * (levels - 1) + stats.currentXp;
  }

  static (int level, int xp) at(int total) {
    var remaining = math.max(0, total);
    var level = 1;
    while (remaining >= requirement(level)) {
      remaining -= requirement(level);
      level++;
    }
    return (level, remaining);
  }
}

/// Same linear RP scale as the rank screen; boundaries are actual season rules.
class RewardRankScale {
  final RankLevel rank;
  RewardRankScale(this.rank);
  bool get canDemote => rank.id > RankConfig.hierarchy.first.id;
  bool get canPromote => RankConfig.getNextRank(rank.id) != null;
  double get maximum =>
      canPromote ? rank.promotePoints * 1.2 : rank.maintainPoints * 1.5;
  double get maintain => canDemote ? rank.maintainPoints / maximum : 0;
  double get promote => canPromote ? rank.promotePoints / maximum : 1;
  double position(num points) => (points / maximum).clamp(0.0, 1.0);
}
