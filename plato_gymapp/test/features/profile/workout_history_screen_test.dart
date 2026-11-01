import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/workout_history_screen.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';

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

  test('history anchor uses the rendered session closest to center', () {
    expect(
      workoutHistoryClosestSessionId({
        'apr-14': 180,
        'apr-15': 305,
        'apr-16': 430,
      }, 300),
      'apr-15',
    );
  });

  test('resolveWorkoutSessionStartTime recovers start time when date is midnight', () {
    final directSession = _session(
      id: 'has-time',
      date: DateTime(2025, 2, 20, 17, 30),
    );
    expect(
      resolveWorkoutSessionStartTime(directSession),
      DateTime(2025, 2, 20, 17, 30),
    );
    expect(
      workoutSessionHasSpecificTime(resolveWorkoutSessionStartTime(directSession)),
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
      workoutSessionHasSpecificTime(resolveWorkoutSessionStartTime(dateOnlySession)),
      isFalse,
    );
  });
}
