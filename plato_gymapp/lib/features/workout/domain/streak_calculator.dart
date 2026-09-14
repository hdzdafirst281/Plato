import 'package:plato_gymapp/core/database/enums.dart';
import '../data/models/workout_models.dart';

class StreakCalculator {
  static bool qualifies(WorkoutSession workout) =>
      !workout.isDeleted &&
      workout.endTime != null &&
      workout.exercises.any(
        (exercise) => exercise.sets.any(
          (set) =>
              set.isCompleted &&
              switch (exercise.exercise.type) {
                ExerciseType.WEIGHT_REPS ||
                ExerciseType.REPS_ONLY => set.reps > 0,
                ExerciseType.TIME_ONLY => set.durationTimeSeconds > 0,
                ExerciseType.CARDIO_DISTANCE => set.distanceInKm > 0,
                ExerciseType.CARDIO_STEPS => set.steps > 0,
              },
        ),
      );

  static DateTime weekStart(DateTime day) =>
      DateTime(day.year, day.month, day.day - day.weekday + 1);

  static Set<DateTime> weeks(
    List<WorkoutSession> history,
    DateTime now,
  ) => history
      .where((w) => qualifies(w) && w.startTime <= now.millisecondsSinceEpoch)
      .map((w) => weekStart(DateTime.fromMillisecondsSinceEpoch(w.startTime)))
      .toSet();

  static int longest(List<WorkoutSession> history, DateTime now) {
    final ordered = weeks(history, now).toList()..sort();
    var longest = 0;
    var streak = 0;
    DateTime? previous;
    for (final week in ordered) {
      streak =
          previous != null &&
              DateTime(previous.year, previous.month, previous.day + 7) == week
          ? streak + 1
          : 1;
      if (streak > longest) longest = streak;
      previous = week;
    }
    return longest;
  }

  static int count(List<WorkoutSession> history, DateTime now) {
    final activeWeeks = weeks(history, now);
    var week = weekStart(now);
    var count = 0;
    if (!activeWeeks.contains(week))
      week = DateTime(week.year, week.month, week.day - 7);
    while (activeWeeks.contains(week)) {
      count++;
      week = DateTime(week.year, week.month, week.day - 7);
    }
    return count;
  }
}
