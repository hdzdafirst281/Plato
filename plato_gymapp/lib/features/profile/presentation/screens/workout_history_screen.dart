import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_marquee_text.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_scroll_to_top_button.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/utils/measurement_units.dart';
import 'package:plato_gymapp/core/worker/sync_manager.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/stats_cubit.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/presentation/components/workout_section_header.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:responsive_framework/responsive_framework.dart';

enum WorkoutHistoryGrouping { day, month, year }

DateTime resolveWorkoutSessionStartTime(WorkoutSession session) {
  final start = DateTime.fromMillisecondsSinceEpoch(session.startTime);
  if (start.hour != 0 || start.minute != 0) {
    return start;
  }
  if (session.endTime != null && session.endTime! > 0) {
    final end = DateTime.fromMillisecondsSinceEpoch(session.endTime!);
    if (end.hour != 0 || end.minute != 0) {
      if (session.totalDurationSeconds > 0) {
        return end.subtract(Duration(seconds: session.totalDurationSeconds));
      }
      return end;
    }
  }
  if (session.updatedAt > 0) {
    final updated = DateTime.fromMillisecondsSinceEpoch(session.updatedAt);
    if (updated.year == start.year &&
        updated.month == start.month &&
        updated.day == start.day &&
        (updated.hour != 0 || updated.minute != 0)) {
      if (session.totalDurationSeconds > 0) {
        return updated.subtract(
          Duration(seconds: session.totalDurationSeconds),
        );
      }
      return updated;
    }
  }
  return start;
}

bool workoutSessionHasSpecificTime(DateTime dateTime) =>
    dateTime.hour != 0 || dateTime.minute != 0;

String workoutHistoryCardHeader(
  WorkoutSession session,
  WorkoutHistoryGrouping grouping,
  String locale,
) {
  final date = resolveWorkoutSessionStartTime(session);
  return switch (grouping) {
    WorkoutHistoryGrouping.day =>
      workoutSessionHasSpecificTime(date)
          ? DateFormat.Hm(locale).format(date)
          : '--:--',
    WorkoutHistoryGrouping.month => date.day.toString().padLeft(2, '0'),
    WorkoutHistoryGrouping.year => DateFormat('dd/MM', locale).format(date),
  };
}

Map<DateTime, List<WorkoutSession>> groupWorkoutHistory(
  List<WorkoutSession> history,
  WorkoutHistoryGrouping grouping,
) {
  final groups = <DateTime, List<WorkoutSession>>{};
  for (final session in history) {
    final date = resolveWorkoutSessionStartTime(session);
    final key = switch (grouping) {
      WorkoutHistoryGrouping.day => DateTime(date.year, date.month, date.day),
      WorkoutHistoryGrouping.month => DateTime(date.year, date.month),
      WorkoutHistoryGrouping.year => DateTime(date.year),
    };
    groups.putIfAbsent(key, () => []).add(session);
  }
  return groups;
}

int workoutHistoryColumnCount(
  WorkoutHistoryGrouping grouping, {
  bool isTablet = false,
}) => switch (grouping) {
  WorkoutHistoryGrouping.day => 1,
  WorkoutHistoryGrouping.month => isTablet ? 4 : 3,
  WorkoutHistoryGrouping.year => isTablet ? 6 : 5,
};

int workoutHistoryAnchorIndex({
  required double scrollOffset,
  required double maxScrollExtent,
  required double viewportDimension,
  required int itemCount,
}) {
  if (itemCount <= 1 || viewportDimension <= 0) return 0;
  final contentExtent = maxScrollExtent + viewportDimension;
  final center = (scrollOffset + viewportDimension / 2).clamp(
    0.0,
    contentExtent,
  );
  return (center / contentExtent * itemCount)
      .floor()
      .clamp(0, itemCount - 1)
      .toInt();
}

double workoutHistoryOffsetForAnchor({
  required int anchorIndex,
  required double maxScrollExtent,
  required double viewportDimension,
  required int itemCount,
}) {
  if (itemCount <= 1 || viewportDimension <= 0) return 0;
  final contentExtent = maxScrollExtent + viewportDimension;
  final anchorCenter = (anchorIndex + 0.5) / itemCount * contentExtent;
  return (anchorCenter - viewportDimension / 2)
      .clamp(0.0, maxScrollExtent)
      .toDouble();
}

double workoutHistoryPinchProgress(double scale) =>
    ((scale - 1).abs() / 0.28).clamp(0.0, 1.0).toDouble();

double workoutHistoryTargetReveal(double progress) {
  final value = ((progress - 0.92) / 0.08).clamp(0.0, 1.0).toDouble();
  return value * value * (3 - 2 * value);
}

double workoutHistoryHeaderSlideProgress(double progress) {
  final value = progress.clamp(0.0, 1.0).toDouble();
  return value * value * (3 - 2 * value);
}

String? workoutHistoryLeadingSessionId(
  Map<String, Rect> sessionRects,
  Size viewportSize,
) {
  final viewport = Offset.zero & viewportSize;
  final visible =
      sessionRects.entries
          .where((entry) => entry.value.overlaps(viewport))
          .toList()
        ..sort((first, second) {
          final vertical = first.value.top.compareTo(second.value.top);
          return vertical != 0
              ? vertical
              : first.value.left.compareTo(second.value.left);
        });
  return visible.isEmpty ? null : visible.first.key;
}

WorkoutHistoryGrouping? workoutHistoryZoomTarget(
  WorkoutHistoryGrouping grouping, {
  required bool zoomIn,
}) => switch ((grouping, zoomIn)) {
  (WorkoutHistoryGrouping.year, true) => WorkoutHistoryGrouping.month,
  (WorkoutHistoryGrouping.month, true) => WorkoutHistoryGrouping.day,
  (WorkoutHistoryGrouping.day, false) => WorkoutHistoryGrouping.month,
  (WorkoutHistoryGrouping.month, false) => WorkoutHistoryGrouping.year,
  _ => null,
};

Rect workoutHistoryMorphRect(Rect from, Rect to, double progress) =>
    Rect.lerp(from, to, progress.clamp(0.0, 1.0))!;

class _HistoryCardGeometry {
  final Rect rect;
  final String header;
  final String name;
  final bool hasPR;

  const _HistoryCardGeometry({
    required this.rect,
    required this.header,
    required this.name,
    required this.hasPR,
  });
}

class _HistorySessionAnchor {
  final String id;
  final double top;
  final List<String> visibleIds;

  const _HistorySessionAnchor({
    required this.id,
    required this.top,
    required this.visibleIds,
  });
}

class _HistoryPeriodGeometry {
  final Rect rect;
  final String label;

  const _HistoryPeriodGeometry({required this.rect, required this.label});
}

class _HistoryGeometry {
  final Size logicalSize;
  final WorkoutHistoryGrouping grouping;
  final Map<String, _HistoryCardGeometry> cards;
  final Map<String, _HistoryPeriodGeometry> periods;

  const _HistoryGeometry({
    required this.logicalSize,
    required this.grouping,
    required this.cards,
    required this.periods,
  });
}

class _HistoryMorphPainter extends CustomPainter {
  final _HistoryGeometry from;
  final _HistoryGeometry to;
  final double progress;
  final double fromScale;
  final Alignment focalAlignment;
  final Color surfaceColor;
  final Color outlineColor;
  final Color primaryColor;
  final Color tertiaryColor;
  final Color textColor;
  final Color goldColor;
  final TextStyle periodTextStyle;

  const _HistoryMorphPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.fromScale,
    required this.focalAlignment,
    required this.surfaceColor,
    required this.outlineColor,
    required this.primaryColor,
    required this.tertiaryColor,
    required this.textColor,
    required this.goldColor,
    required this.periodTextStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final viewport = Offset.zero & size;
    final focalPoint = focalAlignment.withinRect(viewport);
    final settledScale = fromScale + (1 - fromScale) * progress;
    final fromBounds = _scaleRect(viewport, focalPoint, settledScale);
    final overlayOpacity = 1 - workoutHistoryTargetReveal(progress);

    _drawCards(canvas, fromBounds, viewport, overlayOpacity);
    _drawPeriods(canvas, fromBounds, viewport, overlayOpacity);
  }

  void _drawCards(
    Canvas canvas,
    Rect fromBounds,
    Rect toBounds,
    double overlayOpacity,
  ) {
    final ids = <String>{...from.cards.keys, ...to.cards.keys};
    for (final id in ids) {
      final oldCard = from.cards[id];
      final newCard = to.cards[id];
      if (oldCard != null && newCard != null) {
        final oldRect = _mapRect(oldCard.rect, from.logicalSize, fromBounds);
        final newRect = _mapRect(newCard.rect, to.logicalSize, toBounds);
        _drawCard(
          canvas,
          workoutHistoryMorphRect(oldRect, newRect, progress),
          newCard.name,
          oldCard.header,
          newCard.header,
          progress,
          oldCard.hasPR || newCard.hasPR,
          overlayOpacity,
        );
      } else if (oldCard != null) {
        _drawCard(
          canvas,
          _mapRect(oldCard.rect, from.logicalSize, fromBounds),
          oldCard.name,
          oldCard.header,
          oldCard.header,
          0,
          oldCard.hasPR,
          (1 - progress) * overlayOpacity,
        );
      } else if (newCard != null) {
        _drawCard(
          canvas,
          _mapRect(newCard.rect, to.logicalSize, toBounds),
          newCard.name,
          newCard.header,
          newCard.header,
          1,
          newCard.hasPR,
          progress * overlayOpacity,
        );
      }
    }
  }

  void _drawCard(
    Canvas canvas,
    Rect rect,
    String name,
    String fromHeader,
    String toHeader,
    double headerProgress,
    bool hasPR,
    double opacity,
  ) {
    if (opacity <= 0 || rect.isEmpty) return;
    final radius = (rect.shortestSide * 0.14).clamp(12.0, 18.0);
    final padding = (rect.shortestSide * 0.1).clamp(7.0, 16.0);
    final headerSize = (rect.width * 0.12).clamp(11.0, 16.0);
    final nameSize = (rect.width * 0.1).clamp(10.0, 16.0);
    final cardColor = hasPR
        ? Color.lerp(surfaceColor, goldColor, 0.08)!
        : surfaceColor;
    final borderColor = hasPR ? goldColor : outlineColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = cardColor.withValues(alpha: opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..color = borderColor.withValues(alpha: opacity * (hasPR ? 0.55 : 0.35))
        ..style = PaintingStyle.stroke
        ..strokeWidth = hasPR ? 1.5 : 1,
    );

    void paintText(
      String value,
      Offset offset,
      TextStyle style,
      double textOpacity,
    ) {
      if (textOpacity <= 0) return;
      final painter =
          TextPainter(
            text: TextSpan(
              text: value,
              style: style.copyWith(
                color: style.color?.withValues(alpha: opacity * textOpacity),
              ),
            ),
            maxLines: 1,
            ellipsis: '…',
            textDirection: ui.TextDirection.ltr,
          )..layout(
            maxWidth: (rect.width - padding * 2).clamp(0.0, double.infinity),
          );
      painter.paint(canvas, offset);
    }

    final headerStyle = TextStyle(
      color: primaryColor,
      fontSize: headerSize,
      fontWeight: FontWeight.w900,
    );
    if (fromHeader == toHeader) {
      paintText(
        fromHeader,
        rect.topLeft + Offset(padding, padding),
        headerStyle,
        1,
      );
    } else {
      paintText(
        fromHeader,
        rect.topLeft + Offset(padding, padding),
        headerStyle,
        1 - headerProgress,
      );
      paintText(
        toHeader,
        rect.topLeft + Offset(padding, padding),
        headerStyle,
        headerProgress,
      );
    }
    paintText(
      name,
      rect.topLeft + Offset(padding, padding + headerSize + 5),
      TextStyle(
        color: textColor,
        fontSize: nameSize,
        fontWeight: FontWeight.w900,
      ),
      1,
    );
  }

  void _drawPeriods(
    Canvas canvas,
    Rect fromBounds,
    Rect toBounds,
    double overlayOpacity,
  ) {
    final ids = <String>{...from.periods.keys, ...to.periods.keys};
    for (final id in ids) {
      final oldPeriod = from.periods[id];
      final newPeriod = to.periods[id];
      if (oldPeriod != null && newPeriod != null) {
        final oldRect = _mapRect(oldPeriod.rect, from.logicalSize, fromBounds);
        final newRect = _mapRect(newPeriod.rect, to.logicalSize, toBounds);
        final rect = workoutHistoryMorphRect(oldRect, newRect, progress);
        _drawPeriodHeader(
          canvas,
          rect,
          oldPeriod.label,
          newPeriod.label,
          progress,
          overlayOpacity,
        );
      } else if (oldPeriod != null) {
        final rect = _mapRect(oldPeriod.rect, from.logicalSize, fromBounds);
        _drawPeriodHeader(
          canvas,
          rect,
          oldPeriod.label,
          oldPeriod.label,
          0,
          (1 - progress) * overlayOpacity,
        );
      } else if (newPeriod != null) {
        final rect = _mapRect(newPeriod.rect, to.logicalSize, toBounds);
        _drawPeriodHeader(
          canvas,
          rect,
          newPeriod.label,
          newPeriod.label,
          1,
          progress * overlayOpacity,
        );
      }
    }
  }

  void _drawPeriodHeader(
    Canvas canvas,
    Rect rect,
    String fromLabel,
    String toLabel,
    double labelProgress,
    double opacity,
  ) {
    if (opacity <= 0 || rect.isEmpty) return;
    final barRect = Rect.fromLTWH(rect.left + 4, rect.top + 16, 4, 34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(999)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withValues(alpha: opacity),
            tertiaryColor.withValues(alpha: opacity),
          ],
        ).createShader(barRect),
    );

    final labelRect = Rect.fromLTWH(
      barRect.right + 10,
      barRect.top,
      (rect.right - barRect.right - 14).clamp(0.0, double.infinity),
      barRect.height,
    );
    if (labelRect.isEmpty) return;

    void paintLabel(String label, double dy) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: periodTextStyle.copyWith(
            color: textColor.withValues(alpha: opacity),
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: labelRect.width);
      painter.paint(
        canvas,
        Offset(
          labelRect.left,
          labelRect.top + (labelRect.height - painter.height) / 2 + dy,
        ),
      );
    }

    canvas.save();
    canvas.clipRect(labelRect);
    if (fromLabel == toLabel) {
      paintLabel(fromLabel, 0);
    } else {
      final slide = workoutHistoryHeaderSlideProgress(labelProgress);
      final direction = to.grouping.index > from.grouping.index ? -1.0 : 1.0;
      paintLabel(fromLabel, direction * labelRect.height * slide);
      paintLabel(toLabel, -direction * labelRect.height * (1 - slide));
    }
    canvas.restore();
  }

  Rect _mapRect(Rect rect, Size sourceSize, Rect destination) {
    final scaleX = destination.width / sourceSize.width;
    final scaleY = destination.height / sourceSize.height;
    return Rect.fromLTRB(
      destination.left + rect.left * scaleX,
      destination.top + rect.top * scaleY,
      destination.left + rect.right * scaleX,
      destination.top + rect.bottom * scaleY,
    );
  }

  Rect _scaleRect(Rect rect, Offset focalPoint, double scale) =>
      Rect.fromCenter(
        center: focalPoint + (rect.center - focalPoint) * scale,
        width: rect.width * scale,
        height: rect.height * scale,
      );

  @override
  bool shouldRepaint(covariant _HistoryMorphPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.progress != progress ||
      oldDelegate.fromScale != fromScale ||
      oldDelegate.focalAlignment != focalAlignment ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.tertiaryColor != tertiaryColor ||
      oldDelegate.textColor != textColor ||
      oldDelegate.goldColor != goldColor ||
      oldDelegate.periodTextStyle != periodTextStyle;
}

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _marqueeAnimation;
  late final AnimationController _zoomAnimation;
  late final AnimationController _detailAnimation;
  Animation<double> _contentScale = const AlwaysStoppedAnimation(1);
  WorkoutHistoryGrouping _grouping = WorkoutHistoryGrouping.day;
  List<WorkoutSession>? _lastHistory;
  List<WorkoutSession> _sortedHistory = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _historyViewportKey = GlobalKey();
  final GlobalKey _historyBoundaryKey = GlobalKey();
  final Map<String, GlobalKey> _sessionKeys = {};
  final Map<String, GlobalKey> _periodKeys = {};
  final Map<String, String> _periodLabels = {};
  bool _isChangingGrouping = false;
  int _groupingChangeToken = 0;
  _HistoryGeometry? _transitionFrom;
  _HistoryGeometry? _transitionTo;
  double _transitionStartScale = 1;

  @override
  void initState() {
    super.initState();
    _marqueeAnimation = AnimationController(
      vsync: this,
      duration: GymMarqueeText.cycleDuration,
    )..repeat();
    _zoomAnimation = AnimationController(
      vsync: this,
      duration: GymMotion.content,
      value: 1,
    );
    _detailAnimation = AnimationController(
      vsync: this,
      duration: GymMotion.quick,
      value: 1,
    );
  }

  final Map<int, Offset> _touchPoints = {};
  double? _pinchStartDistance;
  bool _isPinching = false;
  double _pinchBaseScale = 1;
  double _gestureScale = 1;
  Alignment _gestureAlignment = Alignment.center;
  final ValueNotifier<int> _pinchVisualTick = ValueNotifier(0);
  WorkoutHistoryGrouping? _pinchSourceGrouping;
  WorkoutHistoryGrouping? _pinchTargetGrouping;
  _HistoryGeometry? _pinchSourceGeometry;
  _HistorySessionAnchor? _pinchAnchor;
  double _pinchProgress = 0;
  bool _pinchTransitionReady = false;
  bool _pinchReleased = false;
  bool _isFinishingPinch = false;
  bool _resumeMarqueeAfterPinch = false;

  Future<void> _refresh() => SyncManager.syncNow();

  void _selectGrouping(WorkoutHistoryGrouping grouping) {
    _gestureAlignment = Alignment.center;
    unawaited(_changeGrouping(grouping));
  }

  Future<void> _changeGrouping(
    WorkoutHistoryGrouping grouping, {
    double? gestureScale,
  }) async {
    if (grouping == _grouping || _isChangingGrouping) return;
    final anchor = _leadingSessionAnchor();
    final anchorId = anchor?.id;
    final anchorIndex = anchorId == null
        ? _currentAnchorIndex()
        : _sortedHistory.indexWhere((session) => session.id == anchorId);
    final token = ++_groupingChangeToken;
    final reduceMotion = GymMotion.reduceMotion(context);
    final fromGeometry = reduceMotion ? null : _captureGeometry();
    final resumeMarquee = !reduceMotion && _marqueeAnimation.isAnimating;
    if (resumeMarquee) _marqueeAnimation.stop();

    setState(() {
      _isChangingGrouping = true;
      _transitionFrom = fromGeometry;
      _transitionTo = null;
      _transitionStartScale = gestureScale ?? 1;
      _grouping = grouping;
      _isPinching = false;
      _detailAnimation.value = 1;
      _zoomAnimation.duration = GymMotion.screen;
      _zoomAnimation.value = reduceMotion ? 1 : 0;
      _contentScale = const AlwaysStoppedAnimation(1);
    });
    if (!await _positionGrouping(anchor, anchorIndex, token)) return;

    final toGeometry = reduceMotion ? null : _captureGeometry();
    if (fromGeometry != null && toGeometry != null) {
      setState(() => _transitionTo = toGeometry);
      try {
        await _zoomAnimation.animateTo(1, curve: GymMotion.enterCurve).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted || token != _groupingChangeToken) return;

    setState(() {
      _transitionFrom = null;
      _transitionTo = null;
      _isChangingGrouping = false;
      _pinchBaseScale = 1;
      _gestureScale = 1;
      _contentScale = const AlwaysStoppedAnimation(1);
    });
    if (resumeMarquee) _marqueeAnimation.repeat();
  }

  Future<void> _prepareInteractivePinch(
    WorkoutHistoryGrouping target,
    double visualScale,
  ) async {
    if (_pinchTargetGrouping != null || _isChangingGrouping) return;
    final sourceGeometry = _pinchSourceGeometry;
    final anchor = _pinchAnchor;
    if (sourceGeometry == null) return;

    _pinchTargetGrouping = target;
    final anchorIndex = anchor == null
        ? _currentAnchorIndex()
        : _sortedHistory.indexWhere((session) => session.id == anchor.id);
    final token = ++_groupingChangeToken;
    _resumeMarqueeAfterPinch = _marqueeAnimation.isAnimating;
    if (_resumeMarqueeAfterPinch) _marqueeAnimation.stop();

    setState(() {
      _isChangingGrouping = true;
      _transitionFrom = sourceGeometry;
      _transitionTo = null;
      _transitionStartScale = visualScale;
      _grouping = target;
      _zoomAnimation.duration = GymMotion.screen;
      _zoomAnimation.value = 0;
      _contentScale = const AlwaysStoppedAnimation(1);
    });

    if (!await _positionGrouping(anchor, anchorIndex, token)) return;
    final targetGeometry = _captureGeometry();
    if (targetGeometry == null) {
      _completeInteractivePinch();
      return;
    }
    setState(() {
      _transitionTo = targetGeometry;
      _pinchTransitionReady = true;
      _detailAnimation.value = 1;
      _zoomAnimation.value = _pinchProgress;
    });
    if (_pinchReleased) unawaited(_finishInteractivePinch());
  }

  Future<void> _finishInteractivePinch() async {
    if (!_pinchTransitionReady || _isFinishingPinch) return;
    _isFinishingPinch = true;
    final commit = _pinchProgress >= 0.45;
    final token = _groupingChangeToken;
    final targetValue = commit ? 1.0 : 0.0;
    final remaining = (_zoomAnimation.value - targetValue).abs();
    _zoomAnimation.duration = Duration(
      milliseconds: (90 + 150 * remaining).round(),
    );
    unawaited(_detailAnimation.animateTo(1, curve: GymMotion.stateCurve));
    try {
      await _zoomAnimation
          .animateTo(targetValue, curve: GymMotion.stateCurve)
          .orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted || token != _groupingChangeToken) return;

    if (!commit) {
      final sourceGrouping = _pinchSourceGrouping;
      final anchor = _pinchAnchor;
      if (sourceGrouping != null) {
        final anchorIndex = anchor == null
            ? _currentAnchorIndex()
            : _sortedHistory.indexWhere((session) => session.id == anchor.id);
        setState(() {
          _grouping = sourceGrouping;
          _transitionTo = null;
          _transitionStartScale = 1;
          _zoomAnimation.value = 0;
        });
        if (!await _positionGrouping(anchor, anchorIndex, token)) return;
      }
    }

    _completeInteractivePinch();
  }

  void _completeInteractivePinch() {
    if (!mounted) return;
    setState(() {
      _transitionFrom = null;
      _transitionTo = null;
      _isChangingGrouping = false;
      _isPinching = false;
      _pinchBaseScale = 1;
      _gestureScale = 1;
      _contentScale = const AlwaysStoppedAnimation(1);
      _detailAnimation.value = 1;
    });
    if (_resumeMarqueeAfterPinch) _marqueeAnimation.repeat();
    _pinchSourceGrouping = null;
    _pinchTargetGrouping = null;
    _pinchSourceGeometry = null;
    _pinchAnchor = null;
    _pinchProgress = 0;
    _pinchTransitionReady = false;
    _pinchReleased = false;
    _isFinishingPinch = false;
    _resumeMarqueeAfterPinch = false;
  }

  Future<bool> _positionGrouping(
    _HistorySessionAnchor? anchor,
    int anchorIndex,
    int token,
  ) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || token != _groupingChangeToken) return false;

    final position = _readyScrollPosition;
    if (position != null) {
      position.jumpTo(
        workoutHistoryOffsetForAnchor(
          anchorIndex: anchorIndex < 0 ? 0 : anchorIndex,
          maxScrollExtent: position.maxScrollExtent,
          viewportDimension: position.viewportDimension,
          itemCount: _sortedHistory.length,
        ),
      );
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || token != _groupingChangeToken) return false;
    final anchorContext = anchor == null
        ? null
        : _sessionKeys[anchor.id]?.currentContext;
    if (anchorContext != null && anchorContext.mounted) {
      final viewport = _historyBoundaryKey.currentContext?.findRenderObject();
      final alignment = viewport is RenderBox
          ? (anchor!.top / viewport.size.height).clamp(0.0, 1.0)
          : 0.0;
      await Scrollable.ensureVisible(
        anchorContext,
        alignment: alignment,
        duration: Duration.zero,
      );
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || token != _groupingChangeToken) return false;
    if (anchor != null) _restoreSessionAnchor(anchor);
    await WidgetsBinding.instance.endOfFrame;
    if (anchor != null) {
      final viewport = _historyBoundaryKey.currentContext?.findRenderObject();
      final settledPosition = _readyScrollPosition;
      if (viewport is RenderBox && settledPosition != null) {
        _keepAnchorSessionsVisible(anchor, viewport, settledPosition);
      }
    }
    await WidgetsBinding.instance.endOfFrame;
    return mounted && token == _groupingChangeToken;
  }

  _HistorySessionAnchor? _leadingSessionAnchor() {
    final viewport = _historyBoundaryKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached) return null;

    final rects = <String, Rect>{};
    for (final entry in _sessionKeys.entries) {
      final renderObject = entry.value.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;
      rects[entry.key] =
          viewport.globalToLocal(renderObject.localToGlobal(Offset.zero)) &
          renderObject.size;
    }
    final id = workoutHistoryLeadingSessionId(rects, viewport.size);
    final viewportRect = Offset.zero & viewport.size;
    final visibleIds = rects.entries
        .where((entry) => entry.value.overlaps(viewportRect))
        .map((entry) => entry.key)
        .toList();
    return id == null
        ? null
        : _HistorySessionAnchor(
            id: id,
            top: rects[id]!.top,
            visibleIds: visibleIds,
          );
  }

  void _restoreSessionAnchor(_HistorySessionAnchor anchor) {
    final viewport = _historyBoundaryKey.currentContext?.findRenderObject();
    final target = _sessionKeys[anchor.id]?.currentContext?.findRenderObject();
    final position = _readyScrollPosition;
    if (viewport is! RenderBox ||
        !viewport.attached ||
        target is! RenderBox ||
        !target.attached ||
        position == null) {
      return;
    }

    final targetTop = viewport
        .globalToLocal(target.localToGlobal(Offset.zero))
        .dy;
    final offset = (position.pixels + targetTop - anchor.top)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    position.jumpTo(offset);
  }

  void _keepAnchorSessionsVisible(
    _HistorySessionAnchor anchor,
    RenderBox viewport,
    ScrollPosition position,
  ) {
    final rects = <Rect>[];
    for (final id in anchor.visibleIds) {
      final target = _sessionKeys[id]?.currentContext?.findRenderObject();
      if (target is RenderBox && target.attached) {
        rects.add(
          viewport.globalToLocal(target.localToGlobal(Offset.zero)) &
              target.size,
        );
      }
    }
    if (rects.isEmpty) return;
    final top = rects.map((rect) => rect.top).reduce(math.min);
    final bottom = rects.map((rect) => rect.bottom).reduce(math.max);
    if (bottom - top > viewport.size.height) return;
    final correction = top < 0
        ? top
        : bottom > viewport.size.height
        ? bottom - viewport.size.height
        : 0.0;
    if (correction == 0) return;
    position.jumpTo(
      (position.pixels + correction)
          .clamp(0.0, position.maxScrollExtent)
          .toDouble(),
    );
  }

  _HistoryGeometry? _captureGeometry() {
    final viewport = _historyBoundaryKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached || viewport.size.isEmpty) {
      return null;
    }

    final sessionsById = {
      for (final session in _sortedHistory) session.id: session,
    };
    final locale = TranslationProvider.of(context).flutterLocale.languageCode;
    final cards = <String, _HistoryCardGeometry>{};
    for (final entry in _visibleRects(viewport, _sessionKeys).entries) {
      final session = sessionsById[entry.key];
      if (session == null) continue;
      cards[entry.key] = _HistoryCardGeometry(
        rect: entry.value,
        header: workoutHistoryCardHeader(session, _grouping, locale),
        name: t.translateDynamic(session.name).toString(),
        hasPR: session.prCount > 0,
      );
    }

    final periods = <String, _HistoryPeriodGeometry>{};
    for (final entry in _visibleRects(viewport, _periodKeys).entries) {
      final label = _periodLabels[entry.key];
      if (label == null) continue;
      periods[entry.key] = _HistoryPeriodGeometry(
        rect: entry.value,
        label: label,
      );
    }

    return _HistoryGeometry(
      logicalSize: viewport.size,
      grouping: _grouping,
      cards: cards,
      periods: periods,
    );
  }

  Map<String, Rect> _visibleRects(
    RenderBox viewport,
    Map<String, GlobalKey> keys,
  ) {
    final viewportRect = Offset.zero & viewport.size;
    final rects = <String, Rect>{};
    for (final entry in keys.entries) {
      final renderObject = entry.value.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;
      final topLeft = viewport.globalToLocal(
        renderObject.localToGlobal(Offset.zero),
      );
      final rect = topLeft & renderObject.size;
      final isFullyVisible =
          rect.left >= viewportRect.left &&
          rect.top >= viewportRect.top &&
          rect.right <= viewportRect.right &&
          rect.bottom <= viewportRect.bottom;
      if (isFullyVisible) rects[entry.key] = rect;
    }
    return rects;
  }

  GlobalKey _sessionKey(String id) =>
      _sessionKeys.putIfAbsent(id, GlobalKey.new);

  GlobalKey _periodKey(String id, String label) {
    _periodLabels[id] = label;
    return _periodKeys.putIfAbsent(id, GlobalKey.new);
  }

  int _currentAnchorIndex() {
    final position = _readyScrollPosition;
    if (position == null) return 0;
    return workoutHistoryAnchorIndex(
      scrollOffset: position.pixels,
      maxScrollExtent: position.maxScrollExtent,
      viewportDimension: position.viewportDimension,
      itemCount: _sortedHistory.length,
    );
  }

  ScrollPosition? get _readyScrollPosition {
    ScrollPosition? readyPosition;
    for (final position in _scrollController.positions) {
      if (position.hasPixels && position.hasContentDimensions) {
        readyPosition = position;
      }
    }
    return readyPosition;
  }

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _detailAnimation.dispose();
    _marqueeAnimation.dispose();
    _scrollController.dispose();
    _pinchVisualTick.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isChangingGrouping) return;
    _touchPoints[event.pointer] = event.position;
    if (_touchPoints.length == 2) {
      _zoomAnimation.stop();
      _detailAnimation.stop();
      _pinchStartDistance = _currentPinchDistance();
      _pinchSourceGrouping = _grouping;
      _pinchTargetGrouping = null;
      _pinchSourceGeometry = GymMotion.reduceMotion(context)
          ? null
          : _captureGeometry();
      _pinchAnchor = _leadingSessionAnchor();
      _pinchProgress = 0;
      _pinchTransitionReady = false;
      _pinchReleased = false;
      _isFinishingPinch = false;
      setState(() {
        _isPinching = true;
        _pinchBaseScale = _contentScale.value;
        _gestureScale = _pinchBaseScale;
        _gestureAlignment = _currentPinchAlignment();
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_touchPoints.containsKey(event.pointer)) return;
    _touchPoints[event.pointer] = event.position;
    if (_touchPoints.length != 2 ||
        _pinchStartDistance == null ||
        _isFinishingPinch) {
      return;
    }

    final rawScale = _currentPinchDistance() / _pinchStartDistance!;
    final visualScale = (_pinchBaseScale * rawScale)
        .clamp(0.78, 1.22)
        .toDouble();
    _pinchProgress = workoutHistoryPinchProgress(rawScale);
    if (!_pinchTransitionReady) {
      _detailAnimation.value = 1 - _pinchProgress;
    }
    _gestureScale = visualScale;
    _gestureAlignment = _currentPinchAlignment();
    _pinchVisualTick.value++;

    if (_pinchTransitionReady) {
      _zoomAnimation.value = _pinchProgress;
      return;
    }

    final sourceGrouping = _pinchSourceGrouping;
    if (sourceGrouping == null || _pinchProgress < 0.08) return;
    final target = workoutHistoryZoomTarget(
      sourceGrouping,
      zoomIn: rawScale > 1,
    );
    if (target == null) return;
    if (GymMotion.reduceMotion(context)) {
      if (_pinchProgress >= 0.45 && !_isChangingGrouping) {
        unawaited(_changeGrouping(target));
      }
      return;
    }
    unawaited(_prepareInteractivePinch(target, visualScale));
  }

  void _onPointerEnd(PointerEvent event) {
    _touchPoints.remove(event.pointer);
    if (_touchPoints.length < 2) {
      _pinchStartDistance = null;
      if (_pinchTargetGrouping != null) {
        _pinchReleased = true;
        if (_pinchTransitionReady) unawaited(_finishInteractivePinch());
      } else if (_isPinching && !_isChangingGrouping) {
        _settlePinchScale();
      }
    }
  }

  double _currentPinchDistance() {
    final points = _touchPoints.values.take(2).toList();
    return (points.first - points.last).distance;
  }

  Alignment _currentPinchAlignment() {
    final viewport = _historyViewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached || viewport.size.isEmpty) {
      return Alignment.center;
    }
    final points = _touchPoints.values.take(2).toList();
    final focalPoint = viewport.globalToLocal((points.first + points.last) / 2);
    return Alignment(
      (focalPoint.dx / viewport.size.width * 2 - 1).clamp(-1.0, 1.0),
      (focalPoint.dy / viewport.size.height * 2 - 1).clamp(-1.0, 1.0),
    );
  }

  void _settlePinchScale() {
    if (GymMotion.reduceMotion(context)) {
      setState(() {
        _isPinching = false;
        _pinchBaseScale = 1;
        _gestureScale = 1;
        _contentScale = const AlwaysStoppedAnimation(1);
        _detailAnimation.value = 1;
        _zoomAnimation.value = 1;
      });
      return;
    }
    final scaleCurve = CurvedAnimation(
      parent: _zoomAnimation,
      curve: GymMotion.stateCurve,
    );
    setState(() {
      _isPinching = false;
      _zoomAnimation.duration = GymMotion.quick;
      _contentScale = Tween<double>(
        begin: _gestureScale,
        end: 1,
      ).animate(scaleCurve);
    });
    unawaited(_detailAnimation.animateTo(1, curve: GymMotion.stateCurve));
    unawaited(_zoomAnimation.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;
    final rawHistory = context.select<StatsCubit, List<WorkoutSession>>(
      (cubit) => cubit.state.workouts,
    );
    if (!identical(rawHistory, _lastHistory)) {
      _lastHistory = rawHistory;
      _sortedHistory = List<WorkoutSession>.from(rawHistory)
        ..sort(
          (a, b) => resolveWorkoutSessionStartTime(
            b,
          ).compareTo(resolveWorkoutSessionStartTime(a)),
        );
      final ids = rawHistory.map((session) => session.id).toSet();
      _sessionKeys.removeWhere((id, _) => !ids.contains(id));
      _periodKeys.removeWhere((id, _) => !ids.contains(id));
      _periodLabels.removeWhere((id, _) => !ids.contains(id));
    }

    final history = _sortedHistory;
    final groups = groupWorkoutHistory(history, _grouping);
    final units = MeasurementFormatter(
      context.select<ProfileCubit, MeasurementPreferences>(
        (cubit) => cubit.state.userProfile.measurementPreferences,
      ),
    );
    final locale = TranslationProvider.of(context).flutterLocale.languageCode;
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.profile.title_workout_history,
        onBackClick: () => context.pop(),
      ),
      floatingActionButton: GymScrollToTopButton(controller: _scrollController),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: GymMotionScope(
              playOnceKey: 'profile-workout-history',
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerEnd,
                onPointerCancel: _onPointerEnd,
                child: Column(
                  children: [
                    GymMotionItem(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          isTablet ? 12 : 16,
                          16,
                          isTablet ? 6 : 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (isTablet)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _HistorySummary(
                                      grouping: _grouping,
                                      groupCount: groups.length,
                                      workoutCount: history.length,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 360,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        _GroupingControl(
                                          grouping: _grouping,
                                          onChanged: _selectGrouping,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.profile.desc_workout_history,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _HistorySummary(
                                grouping: _grouping,
                                groupCount: groups.length,
                                workoutCount: history.length,
                              ),
                              const SizedBox(height: 12),
                              _GroupingControl(
                                grouping: _grouping,
                                onChanged: _selectGrouping,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.profile.desc_workout_history,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox.expand(
                        key: _historyViewportKey,
                        child: IgnorePointer(
                          ignoring: _isChangingGrouping,
                          child: ClipRect(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _zoomAnimation,
                                _pinchVisualTick,
                              ]),
                              child: RepaintBoundary(
                                key: _historyBoundaryKey,
                                child: _buildHistoryContent(
                                  key: ValueKey(_grouping),
                                  history: history,
                                  groups: groups,
                                  units: units,
                                  locale: locale,
                                  isTablet: isTablet,
                                  detailOpacity: _detailAnimation,
                                ),
                              ),
                              builder: (context, child) {
                                final fromGeometry = _transitionFrom;
                                final toGeometry = _transitionTo;
                                final hasGeometry =
                                    _isChangingGrouping && fromGeometry != null;
                                final progress = _zoomAnimation.value;
                                final reveal = _isChangingGrouping
                                    ? workoutHistoryTargetReveal(
                                        _zoomAnimation.value,
                                      )
                                    : 1.0;
                                final contentScale = hasGeometry
                                    ? 1.0
                                    : _isPinching
                                    ? _gestureScale
                                    : _contentScale.value;

                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Opacity(
                                      opacity: hasGeometry ? reveal : 1,
                                      child: Transform.scale(
                                        scale: contentScale,
                                        alignment: _gestureAlignment,
                                        child: child,
                                      ),
                                    ),
                                    if (hasGeometry)
                                      IgnorePointer(
                                        child: CustomPaint(
                                          key: const ValueKey(
                                            'workout-history-morph',
                                          ),
                                          painter: _HistoryMorphPainter(
                                            from: fromGeometry,
                                            to: toGeometry ?? fromGeometry,
                                            progress: toGeometry == null
                                                ? 0
                                                : progress,
                                            fromScale: _transitionStartScale,
                                            focalAlignment: _gestureAlignment,
                                            surfaceColor: colorScheme.surface,
                                            outlineColor:
                                                colorScheme.outlineVariant,
                                            primaryColor: colorScheme.primary,
                                            tertiaryColor: colorScheme.tertiary,
                                            textColor: colorScheme.onSurface,
                                            goldColor: gymColors.goldRank,
                                            periodTextStyle:
                                                Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme.onSurface,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ) ??
                                                const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          isComplex: false,
                                          willChange: true,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryContent({
    required Key key,
    required List<WorkoutSession> history,
    required Map<DateTime, List<WorkoutSession>> groups,
    required MeasurementFormatter units,
    required String locale,
    required bool isTablet,
    required Animation<double> detailOpacity,
  }) {
    if (_sortedHistory.isEmpty) {
      return _HistoryEmptyState(key: key);
    }

    if (_grouping == WorkoutHistoryGrouping.day) {
      return _DayHistoryList(
        key: key,
        controller: _scrollController,
        history: history,
        units: units,
        locale: locale,
        onRefresh: _refresh,
        sessionKey: _sessionKey,
        periodKey: _periodKey,
        isTablet: isTablet,
        marqueeAnimation: _marqueeAnimation,
        detailOpacity: detailOpacity,
      );
    }

    return _CompactHistoryGrid(
      key: key,
      controller: _scrollController,
      groups: groups,
      grouping: _grouping,
      units: units,
      locale: locale,
      onRefresh: _refresh,
      sessionKey: _sessionKey,
      periodKey: _periodKey,
      isTablet: isTablet,
      marqueeAnimation: _marqueeAnimation,
      detailOpacity: detailOpacity,
    );
  }
}

class _HistorySummary extends StatelessWidget {
  final WorkoutHistoryGrouping grouping;
  final int groupCount;
  final int workoutCount;

  const _HistorySummary({
    required this.grouping,
    required this.groupCount,
    required this.workoutCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final value = switch (grouping) {
      WorkoutHistoryGrouping.day => t.profile.fmt_history_total(
        arg1: workoutCount.toString(),
      ),
      WorkoutHistoryGrouping.month => t.profile.fmt_history_months(
        arg1: groupCount.toString(),
      ),
      WorkoutHistoryGrouping.year => t.profile.fmt_history_years(
        arg1: groupCount.toString(),
      ),
    };
    final valueText = Text(
      value,
      key: ValueKey(grouping),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.16),
            colorScheme.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Symbols.history, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GymMotion.reduceMotion(context)
                ? valueText
                : AnimatedSwitcher(
                    duration: GymMotion.screen,
                    reverseDuration: GymMotion.content,
                    switchInCurve: GymMotion.enterCurve,
                    switchOutCurve: GymMotion.exitCurve,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previousChildren, ?currentChild],
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: valueText,
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupingControl extends StatelessWidget {
  final WorkoutHistoryGrouping grouping;
  final ValueChanged<WorkoutHistoryGrouping> onChanged;

  const _GroupingControl({required this.grouping, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<WorkoutHistoryGrouping>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: WorkoutHistoryGrouping.day,
            label: Text(t.profile.history_group_day),
          ),
          ButtonSegment(
            value: WorkoutHistoryGrouping.month,
            label: Text(t.calendar.view_month),
          ),
          ButtonSegment(
            value: WorkoutHistoryGrouping.year,
            label: Text(t.calendar.view_year),
          ),
        ],
        selected: {grouping},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _DayHistoryList extends StatelessWidget {
  final ScrollController controller;
  final List<WorkoutSession> history;
  final MeasurementFormatter units;
  final String locale;
  final RefreshCallback onRefresh;
  final Key Function(String id) sessionKey;
  final Key Function(String id, String label) periodKey;
  final bool isTablet;
  final Animation<double> marqueeAnimation;
  final Animation<double> detailOpacity;

  const _DayHistoryList({
    super.key,
    required this.controller,
    required this.history,
    required this.units,
    required this.locale,
    required this.onRefresh,
    required this.sessionKey,
    required this.periodKey,
    required this.marqueeAnimation,
    required this.detailOpacity,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final session = history[index];
          final date = resolveWorkoutSessionStartTime(session);
          final showDate =
              index == 0 ||
              !_isSameDay(
                date,
                resolveWorkoutSessionStartTime(history[index - 1]),
              );
          final periodLabel = DateFormat.yMMMMEEEEd(locale).format(date);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 680 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDate)
                    _PeriodHeader(
                      key: periodKey(session.id, periodLabel),
                      label: periodLabel,
                      detailOpacity: detailOpacity,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorkoutHistoryCard(
                      key: sessionKey(session.id),
                      session: session,
                      grouping: WorkoutHistoryGrouping.day,
                      units: units,
                      locale: locale,
                      isTablet: isTablet,
                      marqueeAnimation: marqueeAnimation,
                      detailOpacity: detailOpacity,
                      onTap: () =>
                          context.push('/workout/workout_detail/${session.id}'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _CompactHistoryGrid extends StatelessWidget {
  final ScrollController controller;
  final Map<DateTime, List<WorkoutSession>> groups;
  final WorkoutHistoryGrouping grouping;
  final MeasurementFormatter units;
  final String locale;
  final RefreshCallback onRefresh;
  final Key Function(String id) sessionKey;
  final Key Function(String id, String label) periodKey;
  final bool isTablet;
  final Animation<double> marqueeAnimation;
  final Animation<double> detailOpacity;

  const _CompactHistoryGrid({
    super.key,
    required this.controller,
    required this.groups,
    required this.grouping,
    required this.units,
    required this.locale,
    required this.onRefresh,
    required this.sessionKey,
    required this.periodKey,
    required this.marqueeAnimation,
    required this.detailOpacity,
    this.isTablet = false,
  });

  String _buildPeriodSubtitle(List<WorkoutSession> sessions) {
    final sessionCount = sessions.length;
    final totalSeconds = sessions.fold<int>(
      0,
      (sum, session) => sum + session.totalDurationSeconds,
    );
    final countLabel = '$sessionCount ${t.profile.lbl_stats_workouts}';
    final timeLabel = _formatDuration(totalSeconds);
    return '$countLabel • $timeLabel';
  }

  String _buildPeriodLabel(DateTime period) =>
      grouping == WorkoutHistoryGrouping.year
      ? period.year.toString()
      : DateFormat.yMMMM(locale).format(period);

  @override
  Widget build(BuildContext context) {
    final periods = groups.entries.toList()
      ..sort((first, second) => second.key.compareTo(first.key));
    final columns = workoutHistoryColumnCount(grouping, isTablet: isTablet);
    final isYear = grouping == WorkoutHistoryGrouping.year;
    final cardExtent = isYear
        ? (isTablet ? 78.0 : 102.0)
        : (isTablet ? 128.0 : 154.0);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          for (final entry in periods) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverToBoxAdapter(
                child: _PeriodHeader(
                  key: periodKey(
                    entry.value.first.id,
                    _buildPeriodLabel(entry.key),
                  ),
                  label: _buildPeriodLabel(entry.key),
                  subtitle: _buildPeriodSubtitle(entry.value),
                  detailOpacity: detailOpacity,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: cardExtent,
                  crossAxisSpacing: isYear ? 6 : 10,
                  mainAxisSpacing: isYear ? 6 : 10,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final session = entry.value[index];
                  return _WorkoutHistoryCard(
                    key: sessionKey(session.id),
                    session: session,
                    grouping: grouping,
                    units: units,
                    locale: locale,
                    isTablet: isTablet,
                    marqueeAnimation: marqueeAnimation,
                    detailOpacity: detailOpacity,
                    onTap: () =>
                        context.push('/workout/workout_detail/${session.id}'),
                  );
                }, childCount: entry.value.length),
              ),
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Animation<double> detailOpacity;

  const _PeriodHeader({
    super.key,
    required this.label,
    required this.detailOpacity,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WorkoutSectionHeader(
      title: label,
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      trailing: subtitle != null
          ? FadeTransition(
              opacity: detailOpacity,
              child: Text(
                subtitle!,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}

class _WorkoutHistoryCard extends StatelessWidget {
  final WorkoutSession session;
  final WorkoutHistoryGrouping grouping;
  final MeasurementFormatter units;
  final String locale;
  final bool isTablet;
  final VoidCallback onTap;
  final Animation<double> marqueeAnimation;
  final Animation<double> detailOpacity;

  const _WorkoutHistoryCard({
    super.key,
    required this.session,
    required this.grouping,
    required this.units,
    required this.locale,
    this.isTablet = false,
    required this.onTap,
    required this.marqueeAnimation,
    required this.detailOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;
    final date = resolveWorkoutSessionStartTime(session);
    final hasSpecificTime = workoutSessionHasSpecificTime(date);
    final isDay = grouping == WorkoutHistoryGrouping.day;
    final isYear = grouping == WorkoutHistoryGrouping.year;
    final hasPR = session.prCount > 0;
    final name = t.translateDynamic(session.name).toString();
    final dateLabel = workoutHistoryCardHeader(session, grouping, locale);
    final exerciseCount = session.exercises.length;
    final exerciseCountLabel =
        '$exerciseCount ${locale == 'vi' ? 'bài' : 'ex'}';
    final monthDetails = [
      if (hasSpecificTime) DateFormat.Hm(locale).format(date),
      exerciseCountLabel,
    ].join(' • ');
    final exerciseNames = session.exercises
        .take(3)
        .map((item) => t.translateDynamic(item.exercise.name).toString())
        .toList();
    final remainingExercises = exerciseCount - exerciseNames.length;
    final preview = [
      ...exerciseNames,
      if (remainingExercises > 0)
        t.profile.fmt_history_more_exercises(
          arg1: remainingExercises.toString(),
        ),
    ].join(' • ');
    final volumeOrSets = session.totalVolume > 0
        ? units.formatWeight(session.totalVolume)
        : t.profile.fmt_history_sets(arg1: session.totalSets.toString());
    final radius = isDay ? 18.0 : (isYear ? 12.0 : 16.0);
    const padding = 10.0;
    final dateSize = isDay ? 15.0 : (isYear ? 12.0 : 18.0);
    final nameSize = isDay ? 16.0 : (isYear ? 11.0 : 12.0);
    final nameWidget = GymMarqueeText(
      name,
      animation: marqueeAnimation,
      style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w900),
    );
    final detailsWidget = Text(
      monthDetails,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
    final dateWidget = Row(
      children: [
        Expanded(
          child: Text(
            dateLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: dateSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (hasPR) ...[
          const SizedBox(width: 4),
          Icon(
            Symbols.emoji_events,
            color: gymColors.goldRank,
            size: isYear ? 13 : 16,
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      label: '$name, ${DateFormat.yMMMMd(locale).add_Hm().format(date)}',
      excludeSemantics: true,
      child: Material(
        color: hasPR
            ? gymColors.goldRank.withValues(alpha: 0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: hasPR
                  ? gymColors.goldRank.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: hasPR
                    ? gymColors.goldRank.withValues(alpha: 0.55)
                    : colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: hasPR ? 1.5 : 1.0,
              ),
              boxShadow: hasPR
                  ? [
                      BoxShadow(
                        color: gymColors.goldRank.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDay) ...[
                  FadeTransition(opacity: detailOpacity, child: dateWidget),
                  const SizedBox(height: 6),
                  if (isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              nameWidget,
                              if (preview.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                FadeTransition(
                                  opacity: detailOpacity,
                                  child: Text(
                                    preview,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        FadeTransition(
                          opacity: detailOpacity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _HistoryMetric(
                                    icon: Symbols.schedule,
                                    value: _formatDuration(
                                      session.totalDurationSeconds,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _HistoryMetric(
                                    icon: Symbols.format_list_bulleted,
                                    value: exerciseCount.toString(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _HistoryMetric(
                                    icon: Symbols.exercise,
                                    value: volumeOrSets,
                                  ),
                                  if (hasPR) ...[
                                    const SizedBox(width: 6),
                                    _HistoryMetric(
                                      icon: Symbols.emoji_events,
                                      value: session.prCount.toString(),
                                      color: gymColors.goldRank,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    nameWidget,
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: detailOpacity,
                      child: SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [
                              _HistoryMetric(
                                icon: Symbols.exercise,
                                value: volumeOrSets,
                              ),
                              const SizedBox(width: 6),
                              _HistoryMetric(
                                icon: Symbols.format_list_bulleted,
                                value: exerciseCount.toString(),
                              ),
                              const SizedBox(width: 6),
                              _HistoryMetric(
                                icon: Symbols.schedule,
                                value: _formatDuration(
                                  session.totalDurationSeconds,
                                ),
                              ),
                              if (hasPR) ...[
                                const SizedBox(width: 6),
                                _HistoryMetric(
                                  icon: Symbols.emoji_events,
                                  value: session.prCount.toString(),
                                  color: gymColors.goldRank,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: detailOpacity,
                        child: Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ] else ...[
                  FadeTransition(opacity: detailOpacity, child: dateWidget),
                  SizedBox(height: isYear ? 4 : 6),
                  nameWidget,
                  Expanded(
                    child: FadeTransition(
                      opacity: detailOpacity,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: isYear ? const SizedBox.shrink() : detailsWidget,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return hours > 0
      ? t.common.time_h_m(h: hours.toString(), m: minutes.toString())
      : t.common.time_m(m: minutes.toString());
}

class _HistoryMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;

  const _HistoryMetric({required this.icon, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = color ?? colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.history_toggle_off,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              t.profile.msg_history_empty,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
