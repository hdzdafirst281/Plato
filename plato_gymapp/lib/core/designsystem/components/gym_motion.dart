import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

final Map<Object, double> _playedMotionValues = <Object, double>{};

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
  static const Duration visualization = Duration(milliseconds: 800);
  static const Duration sequence = Duration(milliseconds: 720);
  static const Duration sequenceStartDelay = Duration(milliseconds: 80);

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

enum GymMotionEffect { fadeUp, fadeDown, fadeScale, slideFromEnd, fadeOnly }

/// Runs a screen's entrance from one controller so visual hierarchy stays in
/// order even when individual sections rebuild as their data arrives.
class GymMotionScope extends StatefulWidget {
  final Widget child;
  final bool active;
  final Duration duration;
  final Duration startDelay;
  final Object? playOnceKey;

  const GymMotionScope({
    super.key,
    required this.child,
    this.active = true,
    this.duration = GymMotion.sequence,
    this.startDelay = GymMotion.sequenceStartDelay,
    this.playOnceKey,
  });

  @override
  State<GymMotionScope> createState() => _GymMotionScopeState();
}

class _GymMotionScopeState extends State<GymMotionScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _startTimer;
  bool _played = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.playOnceKey case final key?) {
      final savedValue = _playedMotionValues[key];
      if (savedValue != null) {
        _controller.value = savedValue;
        _played = savedValue >= 1;
      }
    }
  }

  @override
  void didUpdateWidget(covariant GymMotionScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.active && !widget.active && !_played) {
      _startTimer?.cancel();
      _scheduled = false;
    } else if (!oldWidget.active && widget.active) {
      _tryStart();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryStart();
  }

  void _tryStart() {
    if (_played || _scheduled || !widget.active) return;

    if (GymMotion.reduceMotion(context)) {
      _controller.value = 1;
      _played = true;
      if (widget.playOnceKey case final key?) {
        _playedMotionValues[key] = 1;
      }
      return;
    }

    if (!TickerMode.valuesOf(context).enabled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _played) return;
      if (!widget.active) {
        _scheduled = false;
        return;
      }
      _startTimer = Timer(widget.startDelay, () {
        if (!mounted || _played) return;
        if (!widget.active) {
          _scheduled = false;
          return;
        }
        _played = true;
        _controller.forward().whenComplete(() {
          if (widget.playOnceKey case final key?) {
            _playedMotionValues[key] = 1;
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    if (widget.playOnceKey case final key?) {
      _playedMotionValues[key] = _controller.value;
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GymMotionTimeline(animation: _controller, child: widget.child);
  }
}

class _GymMotionTimeline extends InheritedWidget {
  final Animation<double> animation;

  const _GymMotionTimeline({required this.animation, required super.child});

  static _GymMotionTimeline? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GymMotionTimeline>();

  @override
  bool updateShouldNotify(_GymMotionTimeline oldWidget) =>
      oldWidget.animation != animation;
}

/// A semantic step in the nearest [GymMotionScope].
///
/// Stages are capped at five so a long list never creates a long-running
/// cascade. Items mounted after the timeline finishes render immediately.
class GymMotionItem extends StatelessWidget {
  final Widget child;
  final int stage;
  final GymMotionEffect effect;

  const GymMotionItem({
    super.key,
    required this.child,
    this.stage = 0,
    this.effect = GymMotionEffect.fadeUp,
  });

  @override
  Widget build(BuildContext context) {
    final timeline = _GymMotionTimeline.maybeOf(context);
    if (timeline == null) {
      return GymEntrance(
        delay: GymMotion.stagger(stage),
        effect: effect,
        child: child,
      );
    }

    final normalizedStage = stage.clamp(0, 5);
    final start = normalizedStage * 0.11;
    final end = math.min(start + 0.42, 1.0);
    final animation = CurvedAnimation(
      parent: timeline.animation,
      curve: Interval(start, end, curve: GymMotion.enterCurve),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => _buildMotionTransform(
        context: context,
        value: animation.value,
        effect: effect,
        child: child!,
      ),
    );
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
  final Offset? offset;
  final Curve curve;
  final GymMotionEffect effect;

  const GymEntrance({
    super.key,
    required this.child,
    this.duration = GymMotion.screen,
    this.delay = Duration.zero,
    this.offset,
    this.curve = GymMotion.enterCurve,
    this.effect = GymMotionEffect.fadeUp,
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
        return _buildMotionTransform(
          context: context,
          value: value,
          effect: widget.effect,
          customOffset: widget.offset,
          child: child!,
        );
      },
    );
  }
}

/// Retains the last painted value when an animated visualization is temporarily
/// removed from the tree (for example while its screen shows a loading state).
/// Keep this object in the owning screen State and pass it back on remount.
class GymMotionValue {
  double? _value;
}

typedef GymMotionValueBuilder =
    Widget Function(BuildContext context, double value, Widget? child);

/// Animates a numeric visual from its last painted value instead of replaying
/// from zero after a rebuild/remount.
class GymStableValueBuilder extends StatefulWidget {
  final GymMotionValue motionValue;
  final double value;
  final double initialValue;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Widget? child;
  final GymMotionValueBuilder builder;

  const GymStableValueBuilder({
    super.key,
    required this.motionValue,
    required this.value,
    required this.builder,
    this.initialValue = 0,
    this.duration = GymMotion.visualization,
    this.delay = Duration.zero,
    this.curve = GymMotion.enterCurve,
    this.child,
  });

  @override
  State<GymStableValueBuilder> createState() => _GymStableValueBuilderState();
}

class _GymStableValueBuilderState extends State<GymStableValueBuilder>
    with SingleTickerProviderStateMixin {
  static const double _epsilon = 0.000001;

  late final AnimationController _controller;
  late double _begin;
  late double _end;
  Timer? _delayTimer;
  bool _scheduled = false;
  bool _isFirstRun = false;

  @override
  void initState() {
    super.initState();
    _isFirstRun = widget.motionValue._value == null;
    _begin = widget.motionValue._value ?? widget.initialValue;
    _end = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (_isAtTarget) {
      _controller.value = 1;
      widget.motionValue._value = _end;
    }
  }

  bool get _isAtTarget => (_begin - _end).abs() <= _epsilon;

  double get _currentValue {
    final progress = widget.curve.transform(_controller.value);
    return lerpDouble(_begin, _end, progress) ?? _end;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryStart();
  }

  @override
  void didUpdateWidget(covariant GymStableValueBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentValue = _currentValue;
    oldWidget.motionValue._value = currentValue;

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }

    final ownerChanged = oldWidget.motionValue != widget.motionValue;
    if (!ownerChanged && oldWidget.value == widget.value) return;

    _delayTimer?.cancel();
    _scheduled = false;
    _isFirstRun = ownerChanged && widget.motionValue._value == null;
    _begin = ownerChanged
        ? (widget.motionValue._value ?? widget.initialValue)
        : currentValue;
    _end = widget.value;
    _controller.value = _isAtTarget ? 1 : 0;
    widget.motionValue._value = _begin;
    _tryStart();
  }

  void _tryStart() {
    if (_scheduled || _controller.isAnimating || _isAtTarget) return;

    if (GymMotion.reduceMotion(context)) {
      _jumpToEnd();
      return;
    }

    if (!TickerMode.valuesOf(context).enabled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final delay = _isFirstRun ? widget.delay : Duration.zero;
      if (delay == Duration.zero) {
        _play();
      } else {
        _delayTimer = Timer(delay, _play);
      }
    });
  }

  void _play() {
    if (!mounted) return;
    if (GymMotion.reduceMotion(context)) {
      _jumpToEnd();
      return;
    }
    if (!TickerMode.valuesOf(context).enabled) {
      _scheduled = false;
      return;
    }
    _scheduled = false;
    _isFirstRun = false;
    _controller.forward(from: 0);
  }

  void _jumpToEnd() {
    _delayTimer?.cancel();
    _scheduled = false;
    _isFirstRun = false;
    _begin = _end;
    _controller.value = 1;
    widget.motionValue._value = _end;
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    widget.motionValue._value = _currentValue;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final value = _currentValue;
        widget.motionValue._value = value;
        return widget.builder(context, value, child);
      },
    );
  }
}

Widget _buildMotionTransform({
  required BuildContext context,
  required double value,
  required GymMotionEffect effect,
  required Widget child,
  Offset? customOffset,
}) {
  if (value >= 1) return child;

  final textDirection = Directionality.of(context);
  final defaultOffset = switch (effect) {
    GymMotionEffect.fadeUp => const Offset(0, 12),
    GymMotionEffect.fadeDown => const Offset(0, -8),
    GymMotionEffect.slideFromEnd => Offset(
      textDirection == TextDirection.rtl ? -16 : 16,
      0,
    ),
    GymMotionEffect.fadeScale || GymMotionEffect.fadeOnly => Offset.zero,
  };
  final offset = customOffset ?? defaultOffset;
  final scale = effect == GymMotionEffect.fadeScale
      ? 0.97 + (0.03 * value)
      : 1.0;

  Widget transformedChild = child;
  if (effect == GymMotionEffect.fadeScale) {
    transformedChild = Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: transformedChild,
    );
  }
  if (offset != Offset.zero) {
    transformedChild = Transform.translate(
      offset: offset * (1 - value),
      transformHitTests: false,
      child: transformedChild,
    );
  }

  return Opacity(opacity: value, child: transformedChild);
}

/// Consistent route transition for drill-in screens. Main tab swipes keep their
/// native interactive movement and use [GymMotionScope] for internal hierarchy.
class GymPageTransitionsBuilder extends PageTransitionsBuilder {
  const GymPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (GymMotion.reduceMotion(context) || route.isFirst) return child;

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final curved = CurvedAnimation(
      parent: animation,
      curve: GymMotion.enterCurve,
      reverseCurve: GymMotion.exitCurve,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isRtl ? -0.035 : 0.035, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
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
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: keyedChild,
    );
  }
}
