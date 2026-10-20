import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/muscle_recovery_calculator.dart';

void main() {
  WorkoutExercise exercise({
    required String id,
    required MuscleGroup muscle,
    required int rpe,
    int reps = 10,
  }) => WorkoutExercise(
    id: 'workout-$id',
    exercise: Exercise(
      id: id,
      name: id,
      primaryMuscle: muscle,
      type: ExerciseType.REPS_ONLY,
      isDeleted: false,
    ),
    sets: [ExerciseSet(id: 'set-$id', reps: reps, rpe: rpe, isCompleted: true)],
  );

  WorkoutSession session({
    required int start,
    required int end,
    required List<WorkoutExercise> exercises,
    int? rpe,
  }) => WorkoutSession(
    id: 'session-$start',
    name: 'Session',
    startTime: start,
    endTime: end,
    totalDurationSeconds: (end - start) ~/ 1000,
    rpe: rpe,
    updatedAt: end,
    sessionPayload: WorkoutSessionPayload(exercises: exercises),
  );

  test('recovery clock starts at the end of the workout', () {
    final start = DateTime(2026, 1, 1, 10).millisecondsSinceEpoch;
    final end = DateTime(2026, 1, 1, 11).millisecondsSinceEpoch;
    final status = MuscleRecoveryCalculator.getRecoveryStatus(
      MuscleGroup.QUADS,
      [
        session(
          start: start,
          end: end,
          exercises: [exercise(id: 'squat', muscle: MuscleGroup.QUADS, rpe: 8)],
        ),
      ],
      at: DateTime.fromMillisecondsSinceEpoch(end),
    );

    expect(status.lastTrainedDate, end);
    expect(status.hoursSinceLastTrain, 0);
  });

  test('an unrelated heavy exercise does not dilute target-muscle fatigue', () {
    final start = DateTime(2026, 1, 1, 10).millisecondsSinceEpoch;
    final end = start + const Duration(hours: 1).inMilliseconds;
    final chest = exercise(
      id: 'press',
      muscle: MuscleGroup.MIDDLE_CHEST,
      rpe: 8,
    );
    final legs = exercise(
      id: 'squat',
      muscle: MuscleGroup.QUADS,
      rpe: 10,
      reps: 1000,
    );

    final chestOnly = MuscleRecoveryCalculator.getRecoveryStatus(
      MuscleGroup.MIDDLE_CHEST,
      [
        session(start: start, end: end, exercises: [chest]),
      ],
      at: DateTime.fromMillisecondsSinceEpoch(end),
    );
    final mixed = MuscleRecoveryCalculator.getRecoveryStatus(
      MuscleGroup.MIDDLE_CHEST,
      [
        session(start: start, end: end, exercises: [chest, legs]),
      ],
      at: DateTime.fromMillisecondsSinceEpoch(end),
    );

    expect(mixed.initialFatigue, closeTo(chestOnly.initialFatigue, 0.001));
  });

  test('higher set RPE creates more initial target-muscle fatigue', () {
    final start = DateTime(2026, 1, 1, 10).millisecondsSinceEpoch;
    final end = start + const Duration(hours: 1).inMilliseconds;

    MuscleRecoveryStatus calculate(int setRpe) =>
        MuscleRecoveryCalculator.getRecoveryStatus(MuscleGroup.QUADS, [
          session(
            start: start,
            end: end,
            rpe: 5,
            exercises: [
              exercise(id: 'squat', muscle: MuscleGroup.QUADS, rpe: setRpe),
            ],
          ),
        ], at: DateTime.fromMillisecondsSinceEpoch(end));

    expect(
      calculate(9).initialFatigue,
      greaterThan(calculate(5).initialFatigue),
    );
  });
}
