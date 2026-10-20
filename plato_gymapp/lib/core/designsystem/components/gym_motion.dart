import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared motion language for the app.
///
/// Keep screen entrances subtle: one or two grouped elements per screen. Small
/// state changes should use [quick] or [content], while full-screen transitions
/// can use [screen].
abstract final class GymMotion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration content = Duration(milliseconds: 220);
  static const Duration screen = Duration(milliseconds: 320);
  static const Duration emphasized = Duration(milliseconds: 600);

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve stateCurve = Curves.easeInOutCubic;

  static const double entranceOffset = 10;

  /// A short, capped stagger prevents long lists from taking seconds to settle.
  static Duration stagger(int index) =>
      Duration(milliseconds: math.min(math.max(index, 0), 4) * 40);

  static bool reduceMotion(BuildContext context) {
    final accessibility = PlatformDispatcher.instance.accessibilityFeatures;
    return (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        accessibility.disableAnimations ||
        accessibility.reduceMotion;
  }
}

/// A one-shot, paint-only entrance that waits until its tab is actually active.
///
/// Rebuilding the child (for example from a Cubit update or a timer) does not
/// replay the animation. Offstage tabs wait for [TickerMode] to become enabled.
class GymEntrance extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;
  final Curve curve;

  const GymEntrance({
    super.key,
    required this.child,
    this.duration = GymMotion.screen,
    this.delay = Duration.zero,
    this.offset = const Offset(0, GymMotion.entranceOffset),
    this.curve = GymMotion.enterCurve,
  });

  @override
  State<GymEntrance> createState() => _GymEntranceState();
}

class _GymEntranceState extends State<GymEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  Timer? _delayTimer;
  bool _scheduled = false;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant GymEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.curve != widget.curve) _updateAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played || _scheduled) return;

    if (GymMotion.reduceMotion(context)) {
      _controller.value = 1;
      _played = true;
      return;
    }

    if (TickerMode.valuesOf(context).enabled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _played) return;
        if (widget.delay == Duration.zero) {
          _play();
        } else {
          _delayTimer = Timer(widget.delay, _play);
        }
      });
    }
  }

  void _updateAnimation() {
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  void _play() {
    if (!mounted || _played) return;
    _played = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final value = _animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              widget.offset.dx * (1 - value),
              widget.offset.dy * (1 - value),
            ),
            transformHitTests: false,
            child: child,
          ),
        );
      },
    );
  }
}

/// A consistent fade-through for loading, empty, error, and content states.
class GymContentSwitcher extends StatelessWidget {
  final Object stateKey;
  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  const GymContentSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
    this.duration = GymMotion.content,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final keyedChild = KeyedSubtree(key: ValueKey(stateKey), child: child);
    if (GymMotion.reduceMotion(context)) return keyedChild;

    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: GymMotion.quick,
      switchInCurve: GymMotion.enterCurve,
      switchOutCurve: GymMotion.exitCurve,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: alignment,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: keyedChild,
    );
  }
}
