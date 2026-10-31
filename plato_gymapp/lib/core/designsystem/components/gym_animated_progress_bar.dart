import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'gym_motion.dart';

class GymAnimatedProgressBar extends StatelessWidget {
  final double progress; // Giá trị từ 0.0 đến 1.0
  final Color color;
  final Color trackColor;
  final double height;
  final int animationDuration;
  final GymMotionValue? motionValue;

  const GymAnimatedProgressBar({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    this.height = 8.0,
    this.animationDuration = 600,
    this.motionValue,
  });

  @override
  Widget build(BuildContext context) {
    // Đảm bảo progress luôn nằm trong khoảng 0 -> 1
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(height / 2), // Bo tròn 2 đầu
      ),
      alignment: Alignment.centerLeft, // Đảm bảo thanh chạy từ trái qua phải
      child: motionValue == null
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: clampedProgress),
              duration: GymMotion.reduceMotion(context)
                  ? Duration.zero
                  : Duration(milliseconds: animationDuration),
              curve: GymMotion.enterCurve,
              builder: (context, value, child) => _buildFill(value),
            )
          : GymStableValueBuilder(
              motionValue: motionValue!,
              value: clampedProgress,
              duration: Duration(milliseconds: animationDuration),
              builder: (context, value, child) => _buildFill(value),
            ),
    );
  }

  Widget _buildFill(double value) {
    return FractionallySizedBox(
      widthFactor: value,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

class GymLabeledGradientProgressBar extends StatelessWidget {
  final double progress;
  final String label;
  final double height;
  final GymMotionValue? motionValue;

  const GymLabeledGradientProgressBar({
    super.key,
    required this.progress,
    required this.label,
    this.height = 18,
    this.motionValue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gym = Theme.of(context).gymColors;
    final value = progress.clamp(0.0, 1.0);
    final gradient = LinearGradient(
      colors: [gym.xpGradientStart, gym.xpGradientEnd],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    Widget fill(double progress) => Transform.scale(
      alignment: Alignment.centerLeft,
      scaleX: progress,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: gym.xpGradientEnd.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              if (motionValue == null)
                fill(value)
              else
                GymStableValueBuilder(
                  motionValue: motionValue!,
                  value: value,
                  duration: GymMotion.visualization,
                  builder: (context, progress, child) => fill(progress),
                ),
              Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                      Shadow(color: Colors.black45, blurRadius: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
