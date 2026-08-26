import 'dart:async';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GymCountdownText extends StatefulWidget {
  final int targetMillis;
  final TextStyle style;
  final Color? highlightColor;
  
  // [FIX] Cung cấp builder để linh hoạt custom UI ở bất kì màn nào mà không phá vỡ logic cũ
  final Widget Function(BuildContext context, Duration timeLeft)? builder;

  const GymCountdownText({
    super.key, 
    required this.targetMillis,
    required this.style,
    this.highlightColor,
    this.builder,
  });

  @override
  State<GymCountdownText> createState() => _GymCountdownTextState();
}

class _GymCountdownTextState extends State<GymCountdownText> {
  late Timer _timer;
  int _diffMillis = 0;

  @override
  void initState() {
    super.initState();
    _calculateDiff();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateDiff());
  }

  void _calculateDiff() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = widget.targetMillis - now;
    
    if (diff != _diffMillis) {
      setState(() {
        _diffMillis = diff;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(context, Duration(milliseconds: math.max(0, _diffMillis)));
    }

    if (_diffMillis <= 0) {
      return Text(t.nutrition.label_goal_due, style: widget.style.copyWith(color: widget.highlightColor));
    }

    const int oneDayMillis = 24 * 60 * 60 * 1000;
    if (_diffMillis >= oneDayMillis) {
      final daysLeft = (_diffMillis / oneDayMillis).ceil();
      return Text(
        t.nutrition.format_goal_days_left(days: daysLeft.toString()),
        style: widget.style.copyWith(color: widget.highlightColor),
      );
    }

    // ==========================================
    // LOGIC MỚI: Đếm ngược < 24h
    // ==========================================
    final duration = Duration(milliseconds: _diffMillis);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    String timeText;
    
    // Dynamic rút gọn Key
    if (hours > 0) {
      timeText = t.common.time_h_m_s(
        h: hours.toString(),
        m: minutes.toString(),
        s: seconds.toString(),
      );
    } else if (minutes > 0) {
      timeText = t.common.time_m_s(
        m: minutes.toString(),
        s: seconds.toString(),
      );
    } else {
      timeText = t.common.time_s(
        s: seconds.toString(),
      );
    }

    // Đổi sang màu error khi ở trạng thái đếm ngược giờ/phút/giây
    final errorColor = Theme.of(context).colorScheme.error;

    return Text(
      timeText,
      style: widget.style.copyWith(color: errorColor),
    );
  }
}