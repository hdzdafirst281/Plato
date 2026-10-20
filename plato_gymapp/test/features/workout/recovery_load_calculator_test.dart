import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/recovery_load_calculator.dart';

void main() {
  Exercise exercise(String id, ExerciseType type) => Exercise(
    id: id,
    name: id,
    primaryMuscle: MuscleGroup.QUADS,
    secondaryMuscles: const [MuscleGroup.HAMSTRINGS],
    type: type,
    isDeleted: false,
  );

  WorkoutExercise workoutExercise(
    ExerciseType type,
    List<ExerciseSet> sets, {
    String id = 'exercise',
  }) => WorkoutExercise(
    id: 'workout-$id',
    exercise: exercise(id, type),
    sets: sets,
  );

  test('uses a distinct base unit for every exercise type', () {
    const working = ExerciseSet(
      id: 'set',
      weight: 20,
      reps: 5,
      durationTimeSeconds: 120,
      distanceInKm: 2.5,
      steps: 400,
      isCompleted: true,
    );

    expect(
      RecoveryLoadCalculator.exerciseVolume(
        workoutExercise(ExerciseType.WEIGHT_REPS, const [working]),
      ),
      100,
    );
    expect(
      RecoveryLoadCalculator.exerciseVolume(
        workoutExercise(ExerciseType.REPS_ONLY, const [working]),
      ),
      5,
    );
    expect(
      RecoveryLoadCalculator.exerciseVolume(
        workoutExercise(ExerciseType.TIME_ONLY, const [working]),
      ),
      120,
    );
    expect(
      RecoveryLoadCalculator.exerciseVolume(
        workoutExercise(ExerciseType.CARDIO_DISTANCE, const [working]),
      ),
      2.5,
    );
    expect(
      RecoveryLoadCalculator.exerciseVolume(
        workoutExercise(ExerciseType.CARDIO_STEPS, const [working]),
      ),
      400,
    );
  });

  test('ignores warm-up and incomplete sets in Recovery load', () {
    final result = RecoveryLoadCalculator.exerciseVolume(
      workoutExercise(ExerciseType.REPS_ONLY, const [
        ExerciseSet(id: 'working', reps: 8, isCompleted: true),
        ExerciseSet(
          id: 'warmup',
          reps: 20,
          isCompleted: true,
          type: SetType.WARMUP,
        ),
        ExerciseSet(id: 'incomplete', reps: 30),
      ]),
    );

    expect(result, 8);
  });

  test('derives cardio intensity from speed or cadence', () {
    final distance = workoutExercise(ExerciseType.CARDIO_DISTANCE, const [
      ExerciseSet(
        id: 'run',
        distanceInKm: 5,
        durationTimeSeconds: 1800,
        isCompleted: true,
      ),
    ]);
    final steps = workoutExercise(ExerciseType.CARDIO_STEPS, const [
      ExerciseSet(
        id: 'stairs',
        steps: 600,
        durationTimeSeconds: 300,
        isCompleted: true,
      ),
    ]);

    expect(RecoveryLoadCalculator.objectiveMetric(distance), closeTo(10, 0.01));
    expect(RecoveryLoadCalculator.objectiveMetric(steps), closeTo(120, 0.01));
    expect(
      RecoveryLoadCalculator.objectiveIntensity(
        currentMetric: 14,
        baselineMetric: 10,
      ),
      RecoveryLoadCalculator.maxObjectiveIntensity,
    );
  });

  test('set RPE overrides session RPE and is volume weighted', () {
    final exercise = workoutExercise(ExerciseType.REPS_ONLY, const [
      ExerciseSet(id: 'easy', reps: 10, rpe: 4, isCompleted: true),
      ExerciseSet(id: 'hard', reps: 30, rpe: 8, isCompleted: true),
    ]);

    expect(
      RecoveryLoadCalculator.exerciseRpe(exercise, sessionRpe: 6),
      closeTo(7, 0.001),
    );
  });

  test('effective session RPE falls back to entered set ratings', () {
    final payload = WorkoutSessionPayload(
      exercises: [
        workoutExercise(ExerciseType.REPS_ONLY, const [
          ExerciseSet(id: 'one', reps: 10, rpe: 6, isCompleted: true),
          ExerciseSet(id: 'two', reps: 10, rpe: 8, isCompleted: true),
        ]),
      ],
    );
    final advancedSession = WorkoutSession(
      id: 'advanced',
      name: 'Advanced',
      startTime: 1,
      updatedAt: 1,
      sessionPayload: payload,
    );
    final basicSession = advancedSession.copyWith(rpe: 9);

    expect(
      RecoveryLoadCalculator.effectiveSessionRpe(advancedSession),
      closeTo(7, 0.001),
    );
    expect(RecoveryLoadCalculator.effectiveSessionRpe(basicSession), 9);
  });
}
