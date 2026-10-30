import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
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

enum WorkoutHistoryGrouping { day, month, year }

Map<DateTime, List<WorkoutSession>> groupWorkoutHistory(
  List<WorkoutSession> history,
  WorkoutHistoryGrouping grouping,
) {
  final groups = <DateTime, List<WorkoutSession>>{};
  for (final session in history) {
    final date = DateTime.fromMillisecondsSinceEpoch(session.startTime);
    final key = switch (grouping) {
      WorkoutHistoryGrouping.day => DateTime(date.year, date.month, date.day),
      WorkoutHistoryGrouping.month => DateTime(date.year, date.month),
      WorkoutHistoryGrouping.year => DateTime(date.year),
    };
    groups.putIfAbsent(key, () => []).add(session);
  }
  return groups;
}

int workoutHistoryColumnCount(WorkoutHistoryGrouping grouping) =>
    switch (grouping) {
      WorkoutHistoryGrouping.day => 1,
      WorkoutHistoryGrouping.month => 3,
      WorkoutHistoryGrouping.year => 5,
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

String? workoutHistoryClosestSessionId(
  Map<String, double> sessionCenters,
  double viewportCenter,
) {
  String? closestId;
  var closestDistance = double.infinity;
  for (final entry in sessionCenters.entries) {
    final distance = (entry.value - viewportCenter).abs();
    if (distance < closestDistance) {
      closestDistance = distance;
      closestId = entry.key;
    }
  }
  return closestId;
}

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  WorkoutHistoryGrouping _grouping = WorkoutHistoryGrouping.day;
  List<WorkoutSession>? _lastHistory;
  List<WorkoutSession> _sortedHistory = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _historyViewportKey = GlobalKey();
  final Map<String, GlobalKey> _sessionKeys = {};
  bool _isChangingGrouping = false;
  int _groupingChangeToken = 0;

  final Map<int, Offset> _touchPoints = {};
  double? _pinchStartDistance;
  bool _pinchHandled = false;

  Future<void> _refresh() => SyncManager.syncNow();

  void _selectGrouping(WorkoutHistoryGrouping grouping) =>
      unawaited(_changeGrouping(grouping));

  Future<void> _changeGrouping(WorkoutHistoryGrouping grouping) async {
    if (grouping == _grouping && !_isChangingGrouping) return;
    final anchorId = _centerSessionId();
    final anchorIndex = anchorId == null
        ? _currentAnchorIndex()
        : _sortedHistory.indexWhere((session) => session.id == anchorId);
    final token = ++_groupingChangeToken;
    final reduceMotion = GymMotion.reduceMotion(context);

    setState(() => _isChangingGrouping = true);
    if (!reduceMotion) await Future<void>.delayed(GymMotion.quick);
    if (!mounted || token != _groupingChangeToken) return;

    setState(() => _grouping = grouping);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || token != _groupingChangeToken) return;

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
    if (!mounted || token != _groupingChangeToken) return;
    final anchorContext = anchorId == null
        ? null
        : _sessionKeys[anchorId]?.currentContext;
    if (anchorContext != null && anchorContext.mounted) {
      await Scrollable.ensureVisible(
        anchorContext,
        alignment: 0.5,
        duration: Duration.zero,
      );
    }

    if (!mounted || token != _groupingChangeToken) return;
    setState(() => _isChangingGrouping = false);
  }

  String? _centerSessionId() {
    final viewport = _historyViewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached) return null;
    final viewportCenter = viewport
        .localToGlobal(Offset(0, viewport.size.height / 2))
        .dy;
    final centers = <String, double>{};
    for (final entry in _sessionKeys.entries) {
      final renderObject = entry.value.currentContext?.findRenderObject();
      if (renderObject is RenderBox && renderObject.attached) {
        centers[entry.key] = renderObject
            .localToGlobal(Offset(0, renderObject.size.height / 2))
            .dy;
      }
    }
    return workoutHistoryClosestSessionId(centers, viewportCenter);
  }

  GlobalKey _sessionKey(String id) =>
      _sessionKeys.putIfAbsent(id, GlobalKey.new);

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

  void _zoomIn() {
    if (_grouping == WorkoutHistoryGrouping.year) {
      unawaited(_changeGrouping(WorkoutHistoryGrouping.month));
    } else if (_grouping == WorkoutHistoryGrouping.month) {
      unawaited(_changeGrouping(WorkoutHistoryGrouping.day));
    }
  }

  void _zoomOut() {
    if (_grouping == WorkoutHistoryGrouping.day) {
      unawaited(_changeGrouping(WorkoutHistoryGrouping.month));
    } else if (_grouping == WorkoutHistoryGrouping.month) {
      unawaited(_changeGrouping(WorkoutHistoryGrouping.year));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _touchPoints[event.pointer] = event.position;
    if (_touchPoints.length == 2) {
      _pinchStartDistance = _currentPinchDistance();
      _pinchHandled = false;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_touchPoints.containsKey(event.pointer)) return;
    _touchPoints[event.pointer] = event.position;
    if (_touchPoints.length != 2 ||
        _pinchStartDistance == null ||
        _pinchHandled) {
      return;
    }

    final scale = _currentPinchDistance() / _pinchStartDistance!;
    if (scale >= 1.18) {
      _pinchHandled = true;
      _zoomIn();
    } else if (scale <= 0.82) {
      _pinchHandled = true;
      _zoomOut();
    }
  }

  void _onPointerEnd(PointerEvent event) {
    _touchPoints.remove(event.pointer);
    if (_touchPoints.length < 2) {
      _pinchStartDistance = null;
      _pinchHandled = false;
    }
  }

  double _currentPinchDistance() {
    final points = _touchPoints.values.take(2).toList();
    return (points.first - points.last).distance;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rawHistory = context.select<StatsCubit, List<WorkoutSession>>(
      (cubit) => cubit.state.workouts,
    );
    if (!identical(rawHistory, _lastHistory)) {
      _lastHistory = rawHistory;
      _sortedHistory = List<WorkoutSession>.from(rawHistory)
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      final ids = rawHistory.map((session) => session.id).toSet();
      _sessionKeys.removeWhere((id, _) => !ids.contains(id));
    }

    final history = _sortedHistory;
    final groups = groupWorkoutHistory(history, _grouping);
    final units = MeasurementFormatter(
      context.select<ProfileCubit, MeasurementPreferences>(
        (cubit) => cubit.state.userProfile.measurementPreferences,
      ),
    );
    final locale = TranslationProvider.of(context).flutterLocale.languageCode;

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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          children: [
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
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox.expand(
                        key: _historyViewportKey,
                        child: IgnorePointer(
                          ignoring: _isChangingGrouping,
                          child: AnimatedOpacity(
                            opacity: _isChangingGrouping ? 0 : 1,
                            duration: GymMotion.reduceMotion(context)
                                ? Duration.zero
                                : GymMotion.quick,
                            curve: GymMotion.stateCurve,
                            child: _buildHistoryContent(
                              key: ValueKey(_grouping),
                              history: history,
                              groups: groups,
                              units: units,
                              locale: locale,
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
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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

  const _DayHistoryList({
    super.key,
    required this.controller,
    required this.history,
    required this.units,
    required this.locale,
    required this.onRefresh,
    required this.sessionKey,
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
          final date = DateTime.fromMillisecondsSinceEpoch(session.startTime);
          final showDate =
              index == 0 ||
              !_isSameDay(
                date,
                DateTime.fromMillisecondsSinceEpoch(
                  history[index - 1].startTime,
                ),
              );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDate)
                _PeriodHeader(label: DateFormat.yMMMMd(locale).format(date)),
              _WorkoutHistoryCard(
                key: sessionKey(session.id),
                session: session,
                units: units,
                locale: locale,
                onTap: () =>
                    context.push('/workout/workout_detail/${session.id}'),
              ),
            ],
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

  const _CompactHistoryGrid({
    super.key,
    required this.controller,
    required this.groups,
    required this.grouping,
    required this.units,
    required this.locale,
    required this.onRefresh,
    required this.sessionKey,
  });

  @override
  Widget build(BuildContext context) {
    final periods = groups.entries.toList()
      ..sort((first, second) => second.key.compareTo(first.key));
    final columns = workoutHistoryColumnCount(grouping);
    final isYear = grouping == WorkoutHistoryGrouping.year;

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
                  label: grouping == WorkoutHistoryGrouping.year
                      ? entry.key.year.toString()
                      : DateFormat.yMMMM(locale).format(entry.key),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: isYear ? 112 : 154,
                  crossAxisSpacing: isYear ? 6 : 10,
                  mainAxisSpacing: isYear ? 6 : 10,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final session = entry.value[index];
                  return _CompactWorkoutHistoryCard(
                    key: sessionKey(session.id),
                    session: session,
                    grouping: grouping,
                    units: units,
                    locale: locale,
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

  const _PeriodHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return WorkoutSectionHeader(
      title: label,
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
    );
  }
}

class _CompactWorkoutHistoryCard extends StatelessWidget {
  final WorkoutSession session;
  final WorkoutHistoryGrouping grouping;
  final MeasurementFormatter units;
  final String locale;
  final VoidCallback onTap;

  const _CompactWorkoutHistoryCard({
    super.key,
    required this.session,
    required this.grouping,
    required this.units,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.fromMillisecondsSinceEpoch(session.startTime);
    final isYear = grouping == WorkoutHistoryGrouping.year;
    final name = t.translateDynamic(session.name).toString();
    final dateLabel = isYear
        ? DateFormat('dd/MM', locale).format(date)
        : date.day.toString().padLeft(2, '0');
    final volumeOrSets = session.totalVolume > 0
        ? units.formatWeight(session.totalVolume)
        : t.profile.fmt_history_sets(arg1: session.totalSets.toString());

    return Semantics(
      button: true,
      label: '$name, ${DateFormat.yMMMMd(locale).add_Hm().format(date)}',
      excludeSemantics: true,
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(isYear ? 12 : 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isYear ? 12 : 16),
          child: Ink(
            padding: EdgeInsets.all(isYear ? 7 : 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isYear ? 12 : 16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  maxLines: 1,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: isYear ? 12 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: isYear ? 3 : 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isYear ? 9 : 12,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Text(
                  DateFormat.Hm(locale).format(date),
                  maxLines: 1,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: isYear ? 9 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isYear) ...[
                  const SizedBox(height: 4),
                  Text(
                    volumeOrSets,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

class _WorkoutHistoryCard extends StatelessWidget {
  final WorkoutSession session;
  final MeasurementFormatter units;
  final String locale;
  final VoidCallback onTap;

  const _WorkoutHistoryCard({
    super.key,
    required this.session,
    required this.units,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;
    final date = DateTime.fromMillisecondsSinceEpoch(session.startTime);
    final exerciseNames = session.exercises
        .take(3)
        .map((item) => t.translateDynamic(item.exercise.name).toString())
        .toList();
    final remainingExercises = session.exercises.length - exerciseNames.length;
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

    return Semantics(
      button: true,
      label: t.translateDynamic(session.name).toString(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          date.day.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.translateDynamic(session.name).toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'EEE, dd MMM • HH:mm',
                                locale,
                              ).format(date),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Symbols.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HistoryMetric(
                        icon: Symbols.schedule,
                        value: _formatDuration(session.totalDurationSeconds),
                      ),
                      _HistoryMetric(
                        icon: Symbols.exercise,
                        value: volumeOrSets,
                      ),
                      _HistoryMetric(
                        icon: Symbols.format_list_bulleted,
                        value: session.exercises.length.toString(),
                      ),
                      if (session.prCount > 0)
                        _HistoryMetric(
                          icon: Symbols.emoji_events,
                          value: session.prCount.toString(),
                          color: gymColors.goldRank,
                        ),
                    ],
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
