import 'package:flutter/material.dart';

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
