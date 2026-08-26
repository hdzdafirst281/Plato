import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Một wrapper widget dùng để thêm hiệu ứng rung (shake) và phản hồi xúc giác (HapticFeedback)
/// khi trạng thái lỗi `hasError` chuyển từ false sang true.
class GymShakeWrapper extends StatefulWidget {
  final bool hasError;
  final Widget child;

  const GymShakeWrapper({
    super.key,
    required this.hasError,
    required this.child,
  });

  @override
  State<GymShakeWrapper> createState() => _GymShakeWrapperState();
}

class _GymShakeWrapperState extends State<GymShakeWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GymShakeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      // Khi có lỗi mới xuất hiện
      HapticFeedback.heavyImpact();
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child.animate(
      controller: _controller,
      autoPlay: false,
    ).shakeX(
      hz: 6,
      amount: 4,
      duration: 300.ms,
      curve: Curves.easeInOutCubic,
    );
  }
}
