import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/gamification/data/models/gamification_models.dart';
import 'package:plato_gymapp/features/gamification/presentation/components/workout_rewards_content.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

Quest _quest(int index) => Quest(
  id: 'q$index',
  title: 'Quest $index',
  description: '',
  target: 1,
  current: index < 4 ? 1 : 0,
  xpReward: 100,
  iconKey: '',
  type: QuestType.WORKOUT_COUNT,
  claimedReward: index < 4,
);

const _session = WorkoutSession(
  id: 'session',
  name: 'Workout',
  startTime: 1,
  updatedAt: 1,
  xpEarned: 50,
  sessionPayload: WorkoutSessionPayload(),
);

const _rank = RankScreenState(
  currentRankId: 2,
  totalRp: 100,
  cycleStartTimeMillis: 0,
  history: [],
);

WorkoutSession _sessionWithSets(int count) => WorkoutSession(
  id: 'session-with-sets',
  name: 'Workout',
  startTime: 1,
  updatedAt: 1,
  xpEarned: 50,
  sessionPayload: WorkoutSessionPayload(
    exercises: [
      WorkoutExercise(
        id: 'exercise',
        exercise: Exercise(
          id: 'exercise',
          name: 'Exercise',
          primaryMuscle: MuscleGroup.MIDDLE_CHEST,
          type: ExerciseType.REPS_ONLY,
          isDeleted: false,
        ),
        sets: List.generate(
          count,
          (index) => ExerciseSet(id: 'set-$index', reps: 1, isCompleted: true),
        ),
      ),
    ],
  ),
);

Widget _app({
  Future<void> Function()? onAutoClaimQuests,
  Future<void> Function()? onAutoClaimChest,
  WorkoutSession session = _session,
  List<Quest>? quests,
  RankScreenState? rank,
}) {
  final weeklyQuests = quests ?? List.generate(6, _quest);
  return TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          disableAnimations: true,
        ),
        child: WorkoutRewardsContent(
          session: session,
          workoutHistory: [session],
          stats: UserGamificationStats(
            currentXp: 200,
            weeklyQuests: weeklyQuests,
          ),
          rank: rank,
          animateWorkout: false,
          onClaim: (_) {},
          onAutoClaimQuests: onAutoClaimQuests,
          onAutoClaimChest: onAutoClaimChest,
          onContinue: () {},
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('weekly quests are summarized until details are requested', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byKey(const ValueKey('quests-summary-count')), findsOneWidget);
    expect(find.byKey(const ValueKey('quests-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('weekly-chest-card')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('weekly-chest-card')),
        matching: find.byKey(const ValueKey('quests-card')),
      ),
      findsNothing,
    );
    expect(find.text('4/6'), findsOneWidget);
    expect(find.byKey(const ValueKey('quest-q0')), findsNothing);
    expect(find.text(t.workout.tooltip_view_details), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle-quest-details')));
    await tester.pumpAndSettle();

    for (var i = 0; i < 6; i++) {
      expect(find.byKey(ValueKey('quest-q$i')), findsOneWidget);
    }
    expect(find.text(t.workout.btn_dtl_muscle_collapse), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      find.text(t.gamification.fmt_xp_progress(arg1: '200', arg2: '1000')),
      findsOneWidget,
    );
  });

  testWidgets('automatic rewards claim quests before the weekly chest', (
    tester,
  ) async {
    final calls = <String>[];
    final questsClaimed = Completer<void>();

    await tester.pumpWidget(
      _app(
        onAutoClaimQuests: () async {
          calls.add('quests');
          await questsClaimed.future;
          calls.add('quests-done');
        },
        onAutoClaimChest: () async => calls.add('chest'),
      ),
    );
    await tester.pump();

    expect(calls, ['quests']);

    questsClaimed.complete();
    await tester.pump();
    await tester.pump();

    expect(calls, ['quests', 'quests-done', 'chest']);
  });

  testWidgets('RP daily cap note only appears after the cap is reached', (
    tester,
  ) async {
    await tester.pumpWidget(_app(quests: const [], rank: _rank));
    await tester.pump();

    expect(find.text(t.rank.desc_info_daily_cap(max: 40)), findsNothing);
    expect(
      find.text(t.workout_rewards.msg_daily_rp_capped(max: 40)),
      findsNothing,
    );

    final cappedSession = _sessionWithSets(40);
    await tester.pumpWidget(
      _app(session: cappedSession, quests: const [], rank: _rank),
    );
    await tester.pump();

    expect(
      find.text(t.workout_rewards.msg_daily_rp_capped(max: 40)),
      findsOneWidget,
    );
  });
}
