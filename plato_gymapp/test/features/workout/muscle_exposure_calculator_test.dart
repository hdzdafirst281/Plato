import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/muscle_exposure_calculator.dart';

void main() {
  WorkoutExercise exercise({
    required String id,
    required MuscleGroup primary,
    required int completedSets,
    List<MuscleGroup> secondaries = const [],
  }) => WorkoutExercise(
    id: 'workout-$id',
    exercise: Exercise(
      id: id,
      name: id,
      primaryMuscle: primary,
      secondaryMuscles: secondaries,
      type: ExerciseType.REPS_ONLY,
      isDeleted: false,
    ),
    sets: [
      for (var index = 0; index < completedSets; index++)
        ExerciseSet(id: '$id-$index', reps: 10, isCompleted: true),
    ],
  );

  test('session heatmap ranks muscle exposure relative to that session', () {
    final intensities = MuscleExposureCalculator.sessionHeatmapIntensities([
      exercise(
        id: 'press',
        primary: MuscleGroup.MIDDLE_CHEST,
        completedSets: 6,
        secondaries: const [MuscleGroup.TRICEPS],
      ),
      exercise(id: 'row', primary: MuscleGroup.LATS, completedSets: 3),
      exercise(id: 'squat', primary: MuscleGroup.QUADS, completedSets: 1),
    ]);

    expect(
      intensities[MuscleGroup.MIDDLE_CHEST],
      MuscleExposureCalculator.sessionHeatmapHigh,
    );
    expect(
      intensities[MuscleGroup.LATS],
      MuscleExposureCalculator.sessionHeatmapMedium,
    );
    expect(
      intensities[MuscleGroup.QUADS],
      MuscleExposureCalculator.sessionHeatmapLow,
    );
    expect(
      intensities[MuscleGroup.TRICEPS],
      MuscleExposureCalculator.sessionHeatmapMedium,
    );
    expect(intensities, isNot(contains(MuscleGroup.BICEPS)));
  });

  test('session heatmap ignores warm-up and incomplete sets', () {
    final base = exercise(
      id: 'press',
      primary: MuscleGroup.MIDDLE_CHEST,
      completedSets: 0,
    );
    final intensities = MuscleExposureCalculator.sessionHeatmapIntensities([
      base.copyWith(
        sets: const [
          ExerciseSet(
            id: 'warmup',
            reps: 10,
            isCompleted: true,
            type: SetType.WARMUP,
          ),
          ExerciseSet(id: 'incomplete', reps: 10),
        ],
      ),
    ]);

    expect(intensities, isEmpty);
  });
}
