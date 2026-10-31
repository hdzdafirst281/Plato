import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import 'package:plato_gymapp/features/gamification/domain/reward_progress.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

class RankZoneProgressBar extends StatelessWidget {
  final RankLevel rank;
  final num points;
  final GymMotionValue? motionValue;

  const RankZoneProgressBar({
    super.key,
    required this.rank,
    required this.points,
    this.motionValue,
  });

  @override
  Widget build(BuildContext context) {
    final scale = RewardRankScale(rank);
    final colors = Theme.of(context).colorScheme;
    final gym = Theme.of(context).gymColors;
    final position = scale.position(points);
    final displayedPoints = points.round();

    Widget bar(double markerPosition) => Semantics(
      label:
          '$displayedPoints RP, ${t.workout_rewards.zone_maintain} ${rank.maintainPoints}'
          '${scale.canPromote ? ', ${t.workout_rewards.zone_promote} ${rank.promotePoints}' : ''}',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: 16,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          if (scale.canDemote)
                            Expanded(
                              flex: (scale.maintain * 10000).round(),
                              child: Container(
                                key: const ValueKey('rank-zone-demote'),
                                color: colors.error,
                              ),
                            ),
                          Expanded(
                            flex: ((scale.promote - scale.maintain) * 10000)
                                .round(),
                            child: Container(
                              key: const ValueKey('rank-zone-maintain'),
                              color: gym.goldRank,
                            ),
                          ),
                          if (scale.canPromote)
                            Expanded(
                              flex: ((1 - scale.promote) * 10000).round(),
                              child: Container(
                                key: const ValueKey('rank-zone-promote'),
                                color: gym.success,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left:
                        markerPosition * math.max(0, constraints.maxWidth - 10),
                    child: Container(
                      key: const ValueKey('rp-marker'),
                      width: 10,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors.onSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          LayoutBuilder(
            builder: (context, constraints) {
              const labelWidth = 64.0;
              final maxLeft = math.max(0.0, constraints.maxWidth - labelWidth);
              double labelLeft(double ratio) =>
                  (constraints.maxWidth * ratio - labelWidth / 2)
                      .clamp(0.0, maxLeft)
                      .toDouble();

              return SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    if (scale.canDemote)
                      Positioned(
                        key: const ValueKey('rank-maintain-threshold'),
                        left: labelLeft(scale.maintain),
                        width: labelWidth,
                        child: Text(
                          '${rank.maintainPoints} RP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (scale.canPromote)
                      Positioned(
                        key: const ValueKey('rank-promote-threshold'),
                        left: labelLeft(scale.promote),
                        width: labelWidth,
                        child: Text(
                          '${rank.promotePoints} RP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: gym.success,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    if (motionValue == null) return bar(position);
    return GymStableValueBuilder(
      motionValue: motionValue!,
      value: position,
      duration: GymMotion.emphasized,
      builder: (context, value, child) => bar(value),
    );
  }
}
