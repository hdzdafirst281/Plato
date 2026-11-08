import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/stats_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/workout_history_screen.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:responsive_framework/responsive_framework.dart';

class _FakeStatsCubit extends Cubit<StatsState> implements StatsCubit {
  _FakeStatsCubit(List<WorkoutSession> workouts)
    : super(StatsState(workouts: workouts, isLoading: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileCubit extends Cubit<ProfileState> implements ProfileCubit {
  _FakeProfileCubit()
    : super(
        const ProfileState(
          userProfile: UserProfile(
            targetMacros: Macros(
              calories: 2000,
              protein: 150,
              carbs: 200,
              fat: 60,
            ),
            detailedBodyMetrics: BodyMetrics(),
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

WorkoutSession _session({required String id, required DateTime date}) {
  return WorkoutSession(
    id: id,
    name: id,
    startTime: date.millisecondsSinceEpoch,
    updatedAt: date.millisecondsSinceEpoch,
    sessionPayload: const WorkoutSessionPayload(exercises: []),
  );
}

void main() {
  test('history groups sessions by day, month, and year', () {
    final history = [
      _session(id: 'morning', date: DateTime(2025, 2, 10, 8)),
      _session(id: 'evening', date: DateTime(2025, 2, 10, 18)),
      _session(id: 'march', date: DateTime(2025, 3, 1)),
      _session(id: 'previous-year', date: DateTime(2024, 12, 20)),
    ];

    final days = groupWorkoutHistory(history, WorkoutHistoryGrouping.day);
    final months = groupWorkoutHistory(history, WorkoutHistoryGrouping.month);
    final years = groupWorkoutHistory(history, WorkoutHistoryGrouping.year);

    expect(days, hasLength(3));
    expect(days[DateTime(2025, 2, 10)], hasLength(2));
    expect(months, hasLength(3));
    expect(months[DateTime(2025, 2)], hasLength(2));
    expect(years, hasLength(2));
    expect(years[DateTime(2025)], hasLength(3));
  });

  test('history density increases with the time scale', () {
    expect(workoutHistoryColumnCount(WorkoutHistoryGrouping.day), 1);
    expect(workoutHistoryColumnCount(WorkoutHistoryGrouping.month), 3);
    expect(workoutHistoryColumnCount(WorkoutHistoryGrouping.year), 5);
  });

  test('history density adapts for tablet', () {
    expect(
      workoutHistoryColumnCount(WorkoutHistoryGrouping.day, isTablet: true),
      1,
    );
    expect(
      workoutHistoryColumnCount(WorkoutHistoryGrouping.month, isTablet: true),
      4,
    );
    expect(
      workoutHistoryColumnCount(WorkoutHistoryGrouping.year, isTablet: true),
      6,
    );
  });

  test('pinch zoom changes one grouping level and stops at the bounds', () {
    expect(
      workoutHistoryZoomTarget(WorkoutHistoryGrouping.year, zoomIn: true),
      WorkoutHistoryGrouping.month,
    );
    expect(
      workoutHistoryZoomTarget(WorkoutHistoryGrouping.month, zoomIn: true),
      WorkoutHistoryGrouping.day,
    );
    expect(
      workoutHistoryZoomTarget(WorkoutHistoryGrouping.day, zoomIn: false),
      WorkoutHistoryGrouping.month,
    );
    expect(
      workoutHistoryZoomTarget(WorkoutHistoryGrouping.month, zoomIn: false),
      WorkoutHistoryGrouping.year,
    );
    expect(
      workoutHistoryZoomTarget(WorkoutHistoryGrouping.day, zoomIn: true),
      isNull,
    );
    expect(
      workoutHistoryZoomTarget(WorkoutHistoryGrouping.year, zoomIn: false),
      isNull,
    );
  });

  test('pinch progress follows finger distance continuously', () {
    expect(workoutHistoryPinchProgress(1), 0);
    expect(workoutHistoryPinchProgress(0.86), closeTo(0.5, 0.0001));
    expect(workoutHistoryPinchProgress(1.14), closeTo(0.5, 0.0001));
    expect(workoutHistoryPinchProgress(0.72), 1);
    expect(workoutHistoryPinchProgress(1.28), 1);
  });

  test(
    'history card morph preserves both layouts and interpolates geometry',
    () {
      const from = Rect.fromLTWH(0, 100, 300, 160);
      const to = Rect.fromLTWH(208, 40, 92, 102);

      expect(workoutHistoryMorphRect(from, to, 0), from);
      expect(workoutHistoryMorphRect(from, to, 1), to);
      expect(
        workoutHistoryMorphRect(from, to, 0.5),
        const Rect.fromLTWH(104, 70, 196, 131),
      );
    },
  );

  testWidgets('pinch renders shared-card morph across month and year', (
    tester,
  ) async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('vi');
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final workouts = List.generate(
      12,
      (index) => _session(
        id: 'session-$index',
        date: DateTime(2026, 10, 31).subtract(Duration(days: index * 4)),
      ),
    );
    final statsCubit = _FakeStatsCubit(workouts);
    final profileCubit = _FakeProfileCubit();
    addTearDown(statsCubit.close);
    addTearDown(profileCubit.close);

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<StatsCubit>.value(value: statsCubit),
            BlocProvider<ProfileCubit>.value(value: profileCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 800, name: TABLET),
                Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
              ],
              child: child!,
            ),
            home: const WorkoutHistoryScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    final listRect = tester.getRect(find.byType(ListView));
    final sourceVisibleIds = workouts.map((session) => session.id).where((id) {
      final finder = find.text(id);
      return finder.evaluate().isNotEmpty &&
          tester.getRect(finder.first).overlaps(listRect);
    }).toList();
    expect(sourceVisibleIds, hasLength(greaterThanOrEqualTo(2)));

    final center = tester.getCenter(find.byType(ListView));
    final firstFinger = await tester.createGesture(pointer: 1);
    final secondFinger = await tester.createGesture(pointer: 2);
    await firstFinger.down(center - const Offset(60, 0));
    await secondFinger.down(center + const Offset(60, 0));
    await tester.pump();
    await firstFinger.moveTo(center - const Offset(45, 0));
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final interactiveMorph = find.byKey(
      const ValueKey('workout-history-morph'),
    );
    expect(interactiveMorph, findsOneWidget);
    final interactivePainter =
        tester.widget<CustomPaint>(interactiveMorph).painter as dynamic;
    expect(interactivePainter.progress as double, closeTo(0.45, 0.08));

    await firstFinger.moveTo(center - const Offset(20, 0));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();

    var sawMorph = interactiveMorph.evaluate().isNotEmpty;
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      sawMorph =
          sawMorph ||
          find
              .byKey(const ValueKey('workout-history-morph'))
              .evaluate()
              .isNotEmpty;
    }

    var control = tester.widget<SegmentedButton<WorkoutHistoryGrouping>>(
      find.byType(SegmentedButton<WorkoutHistoryGrouping>),
    );
    expect(sawMorph, isTrue);
    expect(control.selected, {WorkoutHistoryGrouping.month});
    final gridRect = tester.getRect(find.byType(CustomScrollView));
    for (final id in sourceVisibleIds) {
      final finder = find.text(id);
      expect(finder, findsOneWidget);
      final rect = tester.getRect(finder);
      expect(
        rect.overlaps(gridRect),
        isTrue,
        reason: '$id should remain visible: card=$rect viewport=$gridRect',
      );
    }
    final monthVisibleIds = workouts.map((session) => session.id).where((id) {
      final finder = find.text(id);
      return finder.evaluate().isNotEmpty &&
          tester.getRect(finder.first).overlaps(gridRect);
    }).toList();

    final gridCenter = tester.getCenter(find.byType(CustomScrollView));
    final thirdFinger = await tester.createGesture(pointer: 3);
    final fourthFinger = await tester.createGesture(pointer: 4);
    await thirdFinger.down(gridCenter - const Offset(60, 0));
    await fourthFinger.down(gridCenter + const Offset(60, 0));
    await tester.pump();
    await thirdFinger.moveTo(gridCenter - const Offset(20, 0));
    await tester.pump();
    await thirdFinger.up();
    await fourthFinger.up();

    var sawYearMorph = false;
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      sawYearMorph =
          sawYearMorph ||
          find
              .byKey(const ValueKey('workout-history-morph'))
              .evaluate()
              .isNotEmpty;
    }

    control = tester.widget<SegmentedButton<WorkoutHistoryGrouping>>(
      find.byType(SegmentedButton<WorkoutHistoryGrouping>),
    );
    expect(sawYearMorph, isTrue);
    expect(control.selected, {WorkoutHistoryGrouping.year});
    final yearRect = tester.getRect(find.byType(CustomScrollView));
    for (final id in monthVisibleIds) {
      final finder = find.text(id);
      expect(finder, findsOneWidget);
      expect(
        tester.getRect(finder).overlaps(yearRect),
        isTrue,
        reason: '$id should remain visible in year mode',
      );
    }

    final yearCenter = tester.getCenter(find.byType(CustomScrollView));
    final fifthFinger = await tester.createGesture(pointer: 5);
    final sixthFinger = await tester.createGesture(pointer: 6);
    await fifthFinger.down(yearCenter - const Offset(60, 0));
    await sixthFinger.down(yearCenter + const Offset(60, 0));
    await tester.pump();
    await fifthFinger.moveTo(yearCenter - const Offset(75, 0));
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await fifthFinger.up();
    await sixthFinger.up();
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    control = tester.widget<SegmentedButton<WorkoutHistoryGrouping>>(
      find.byType(SegmentedButton<WorkoutHistoryGrouping>),
    );
    expect(control.selected, {WorkoutHistoryGrouping.year});
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet day card renders the 2x2 metrics layout', (tester) async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('vi');
    tester.view.physicalSize = const Size(800, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final statsCubit = _FakeStatsCubit([
      _session(id: 'tablet-session', date: DateTime(2026, 11, 3, 18, 45)),
    ]);
    final profileCubit = _FakeProfileCubit();
    addTearDown(statsCubit.close);
    addTearDown(profileCubit.close);

    await tester.pumpWidget(
      TranslationProvider(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<StatsCubit>.value(value: statsCubit),
            BlocProvider<ProfileCubit>.value(value: profileCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 800, name: TABLET),
                Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
              ],
              child: child!,
            ),
            home: const WorkoutHistoryScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('18:45'), findsOneWidget);
    expect(find.text('tablet-session'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'history mode switch preserves the session near the viewport center',
    () {
      final anchor = workoutHistoryAnchorIndex(
        scrollOffset: 350,
        maxScrollExtent: 800,
        viewportDimension: 200,
        itemCount: 10,
      );

      expect(anchor, 4);
      expect(
        workoutHistoryOffsetForAnchor(
          anchorIndex: anchor,
          maxScrollExtent: 800,
          viewportDimension: 200,
          itemCount: 10,
        ),
        350,
      );
    },
  );

  test('history anchor uses the leading visible session', () {
    expect(
      workoutHistoryLeadingSessionId({
        'offscreen': const Rect.fromLTWH(0, -80, 100, 40),
        'oct-31': const Rect.fromLTWH(0, 20, 100, 80),
        'oct-30': const Rect.fromLTWH(110, 20, 100, 80),
        'oct-28': const Rect.fromLTWH(0, 110, 100, 80),
      }, const Size(320, 500)),
      'oct-31',
    );
  });

  test('card header follows the selected grouping', () {
    final session = _session(id: 'header', date: DateTime(2026, 11, 3, 18, 45));

    expect(
      workoutHistoryCardHeader(session, WorkoutHistoryGrouping.day, 'vi'),
      '18:45',
    );
    expect(
      workoutHistoryCardHeader(session, WorkoutHistoryGrouping.month, 'vi'),
      '03',
    );
    expect(
      workoutHistoryCardHeader(session, WorkoutHistoryGrouping.year, 'vi'),
      '03/11',
    );
  });

  test(
    'resolveWorkoutSessionStartTime recovers start time when date is midnight',
    () {
      final directSession = _session(
        id: 'has-time',
        date: DateTime(2025, 2, 20, 17, 30),
      );
      expect(
        resolveWorkoutSessionStartTime(directSession),
        DateTime(2025, 2, 20, 17, 30),
      );
      expect(
        workoutSessionHasSpecificTime(
          resolveWorkoutSessionStartTime(directSession),
        ),
        isTrue,
      );

      // Midnight start time with endTime and durationSeconds
      final midnightWithEndTime = WorkoutSession(
        id: 'midnight-end',
        name: 'Session',
        startTime: DateTime(2025, 2, 20).millisecondsSinceEpoch,
        endTime: DateTime(2025, 2, 20, 18, 30).millisecondsSinceEpoch,
        totalDurationSeconds: 3600, // 1 hour -> start was 17:30
        updatedAt: DateTime(2025, 2, 20).millisecondsSinceEpoch,
        sessionPayload: const WorkoutSessionPayload(exercises: []),
      );
      expect(
        resolveWorkoutSessionStartTime(midnightWithEndTime),
        DateTime(2025, 2, 20, 17, 30),
      );

      // Midnight start time without endTime but updatedAt on same day
      final midnightWithUpdatedAt = WorkoutSession(
        id: 'midnight-updated',
        name: 'Session',
        startTime: DateTime(2025, 2, 20).millisecondsSinceEpoch,
        totalDurationSeconds: 1800, // 30 min -> start was 08:30
        updatedAt: DateTime(2025, 2, 20, 9, 0).millisecondsSinceEpoch,
        sessionPayload: const WorkoutSessionPayload(exercises: []),
      );
      expect(
        resolveWorkoutSessionStartTime(midnightWithUpdatedAt),
        DateTime(2025, 2, 20, 8, 30),
      );

      // Truly date-only session (no time on end or updated)
      final dateOnlySession = _session(
        id: 'date-only',
        date: DateTime(2025, 2, 20),
      );
      expect(
        workoutSessionHasSpecificTime(
          resolveWorkoutSessionStartTime(dateOnlySession),
        ),
        isFalse,
      );
    },
  );
}
