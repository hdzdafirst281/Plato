import 'package:flutter/material.dart';

class GymAnimatedProgressBar extends StatelessWidget {
  final double progress; // Giá trị từ 0.0 đến 1.0
  final Color color;
  final Color trackColor;
  final double height;
  final int animationDuration;

  const GymAnimatedProgressBar({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    this.height = 8.0,
    this.animationDuration = 1000,
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
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: clampedProgress),
        duration: Duration(milliseconds: animationDuration),
        curve: Curves.easeOutCubic, // Hiệu ứng chậm dần ở cuối
        builder: (context, value, child) {
          return FractionallySizedBox(
            widthFactor: value, // Lấp đầy % chiều rộng theo animation
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          );
        },
      ),
    );
  }
}