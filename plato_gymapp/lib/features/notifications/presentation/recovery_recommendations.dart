import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/muscle_recovery_calculator.dart';
import 'package:plato_gymapp/features/workout/domain/streak_calculator.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/workout_cubit.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/editor_cubit.dart';
import '../data/notification_copy.dart';

class RecoveryRecommendations extends StatelessWidget {
  final WorkoutSession? routine;
  const RecoveryRecommendations({super.key, this.routine});
  @override
  Widget build(BuildContext context) {
    if (!NotificationCopy.available) return const SizedBox.shrink();
    final state = context.watch<WorkoutCubit>().state;
    final history = state.historicalWorkoutSessionsList
        .where(StreakCalculator.qualifies)
        .toList();
    if (history.isEmpty) return const SizedBox.shrink();
    final statuses = {
      for (final muscle in MuscleGroup.values)
        muscle: MuscleRecoveryCalculator.getRecoveryStatus(muscle, history),
    };
    final low =
        routine?.exercises
            .map((e) => e.exercise.primaryMuscle)
            .whereType<MuscleGroup>()
            .where((m) => statuses[m]!.recoveryPercentage < 40)
            .toSet() ??
        <MuscleGroup>{};
    if (routine != null) {
      if (low.isEmpty) return const SizedBox.shrink();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            NotificationCopy.text('notifications.body_recovery_low', {
              'muscles': low
                  .map(
                    (m) =>
                        t.translateDynamic('muscles.${m.name.toLowerCase()}'),
                  )
                  .join(', '),
            })!,
          ),
        ),
      );
    }
    final suitable = state.userCustomRoutinesList
        .where((r) {
          final muscles = r.exercises
              .map((e) => e.exercise.primaryMuscle)
              .whereType<MuscleGroup>()
              .toSet();
          return muscles.isNotEmpty &&
              muscles.every((m) => statuses[m]!.recoveryPercentage >= 80) &&
              muscles.any((m) => statuses[m]!.lastTrainedDate > 0);
        })
        .take(3)
        .toList();
    if (suitable.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.self_improvement),
            title: Text(
              NotificationCopy.text(
                'notifications.title_recovery_recommendation',
              )!,
            ),
          ),
          for (final r in suitable)
            ListTile(
              title: Text(t.translateDynamic(r.name)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.read<EditorCubit>().setRoutineToEdit(r);
                context.push('/workout/create_routine', extra: true);
              },
            ),
        ],
      ),
    );
  }
}
