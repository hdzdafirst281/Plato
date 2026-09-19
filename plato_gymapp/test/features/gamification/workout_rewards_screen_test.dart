import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/features/gamification/domain/reward_progress.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/features/gamification/presentation/bloc/gamification_cubit.dart';
import 'package:plato_gymapp/features/gamification/presentation/bloc/rank_cubit.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/workout_cubit.dart';
import 'package:flutter/rendering.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/gamification/data/models/gamification_models.dart';
import 'package:plato_gymapp/features/gamification/presentation/screens/workout_rewards_screen.dart';
import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

final session = WorkoutSession(
  id: 'done',
  name: 'Upper body · Strength',
  startTime: 100,
  updatedAt: 100,
  xpEarned: 90,
  prCount: 2,
  sessionPayload: WorkoutSessionPayload(
    exercises: [
      WorkoutExercise(
        id: 'ex',
        exercise: Exercise(
          id: 'bench',
          name: 'Bench',
          type: ExerciseType.WEIGHT_REPS,
          isDeleted: false,
        ),
        sets: List.generate(
          18,
          (i) => ExerciseSet(id: '$i', reps: 8, isCompleted: true),
        ),
      ),
    ],
  ),
);
const quest = Quest(
  id: 'q1',
  title: 'gamification.title_quest_1',
  description: '',
  target: 3,
  current: 3,
  xpReward: 300,
  iconKey: 'workout_count',
  type: QuestType.WORKOUT_COUNT,
  claimedReward: false,
);
const stats = UserGamificationStats(
  level: 2,
  currentXp: 40,
  nextLevelXp: 1050,
  weeklyQuests: [quest],
);
const rank = RankScreenState(
  currentRankId: 1,
  totalRp: 46,
  cycleStartTimeMillis: 0,
  history: [],
);

class StubWorkouts extends Cubit<WorkoutState> implements WorkoutCubit {
  StubWorkouts()
    : super(
        WorkoutState(
          historicalWorkoutSessionsList: [session.copyWith(xpEarned: 0)],
        ),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubRewards extends Cubit<GamificationState>
    implements GamificationCubit {
  int refreshes = 0;
  StubRewards()
    : super(const GamificationState(stats: UserGamificationStats()));
  @override
  Future<void> refreshWeeklyQuests(List<WorkoutSession> sessions) async {
    refreshes++;
    expect(sessions.single.xpEarned, 90);
  }

  @override
  Future<void> refreshStateFromPrefs() async =>
      emit(const GamificationState(stats: stats));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubRank extends Cubit<RankScreenState?> implements RankCubit {
  StubRank() : super(null);
  @override
  Future<void> refreshRankData() async => emit(rank);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final boundary = GlobalKey();
  setUpAll(() async {
    final symbols =
        FontLoader(
          'packages/material_symbols_icons/MaterialSymbolsOutlined',
        )..addFont(
          rootBundle.load(
            'packages/material_symbols_icons/lib/fonts/MaterialSymbolsOutlined.ttf',
          ),
        );
    await symbols.load();
    // Load a local font for readable optional previews, without network calls.
    final font = File('C:/Windows/Fonts/arial.ttf');
    if (font.existsSync()) {
      final loader = FontLoader('RewardTestFont')
        ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
      await loader.load();
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
    EdgeInsets safeInsets = EdgeInsets.zero,
    Brightness brightness = Brightness.dark,
    bool reducedMotion = false,
    bool settle = true,
    UserGamificationStats data = stats,
    VoidCallback? onContinue,
    VoidCallback? onClaimChest,
    ValueChanged<Quest>? onClaim,
    String? claiming,
    RankScreenState? rankData = rank,
    List<Quest> beforeQuests = const [],
    int? streakWeeks,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme:
              (brightness == Brightness.dark
                      ? AppTheme.darkTheme
                      : AppTheme.lightTheme)
                  .copyWith(
                    textTheme:
                        (brightness == Brightness.dark
                                ? AppTheme.darkTheme
                                : AppTheme.lightTheme)
                            .textTheme
                            .apply(fontFamily: 'RewardTestFont'),
                  ),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: safeInsets,
              textScaler: TextScaler.linear(scale),
              disableAnimations: reducedMotion,
            ),
            child: RepaintBoundary(
              key: boundary,
              child: WorkoutRewardsContent(
                session: session,
                beforeQuests: beforeQuests,
                streakWeeks: streakWeeks,
                stats: data,
                rank: rankData,
                leveledUp: true,
                claimingQuestId: claiming,
                onClaim: onClaim ?? (_) {},
                onClaimChest: onClaimChest,
                onContinue: onContinue ?? () {},
              ),
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    } else {
      await tester.pump();
    }
  }

  for (final locale in AppLocale.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'scrolls without overflow at 320px and 2x text: $locale $brightness',
        (tester) async {
          LocaleSettings.setLocale(locale);
          await pump(
            tester,
            size: const Size(320, 568),
            scale: 2,
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
          expect(
            find.text(t.workout_rewards.summary).hitTestable(),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('quest-q1')),
            240,
          );
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey('quest-q1')).hitTestable(),
            findsOneWidget,
          );
        },
      );
    }
  }

  testWidgets('first tap skips without also continuing', (tester) async {
    int continued = 0;
    await pump(tester, settle: false, onContinue: () => continued++);
    await tester.tapAt(tester.getCenter(find.text(t.workout_rewards.summary)));
    expect(continued, 0);
    await tester.pump();
    await tester.tap(find.text(t.workout_rewards.summary));
    expect(continued, 1);
  });

  testWidgets('reduced motion shows final values and no active entrance', (
    tester,
  ) async {
    await pump(tester, reducedMotion: true);
    final fade = tester.widget<Opacity>(
      find.byKey(const ValueKey('reveal-xp')),
    );
    expect(fade.opacity, 1);
    expect(find.text('+90 XP'), findsOneWidget);
    expect(find.text('40 / 1050 XP'), findsOneWidget);
  });

  testWidgets('quest claim calls action and claimed state removes action', (
    tester,
  ) async {
    String? claimed;
    await pump(tester, onClaim: (q) => claimed = q.id);

    await tester.tap(find.byKey(const ValueKey('quest-q1')));
    expect(claimed, 'q1');
    await pump(
      tester,
      data: stats.copyWith(weeklyQuests: [quest.copyWith(claimedReward: true)]),
    );
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('quest-q1'))).onTap,
      isNull,
    );
  });

  testWidgets('zero quest target is safe; highest rank has no 99999 target', (
    tester,
  ) async {
    await pump(
      tester,
      data: stats.copyWith(weeklyQuests: [quest.copyWith(target: 0)]),
      rankData: rank.copyWith(currentRankId: 8, totalRp: 900),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('99999'), findsNothing);
    expect(find.byKey(const ValueKey('rank-zone-promote')), findsNothing);
    expect(find.byKey(const ValueKey('rank-zone-demote')), findsOneWidget);
  });

  testWidgets('missing workout ID gives a recoverable state', (tester) async {
    await tester.pumpWidget(MaterialApp(home: const WorkoutRewardsScreen()));
    await tester.pumpAndSettle();
    expect(find.text(t.workout_rewards.load_error), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'waits for save completion even if an intermediate workout is in history',
    (tester) async {
      final done = Completer<WorkoutSession?>();
      final workouts = StubWorkouts();
      final rewards = StubRewards();
      final ranking = StubRank();
      addTearDown(workouts.close);
      addTearDown(rewards.close);
      addTearDown(ranking.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<WorkoutCubit>.value(value: workouts),
            BlocProvider<GamificationCubit>.value(value: rewards),
            BlocProvider<RankCubit>.value(value: ranking),
          ],
          child: MaterialApp(
            home: WorkoutRewardsScreen(
              workoutId: 'done',
              completion: done.future,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('+0 XP'), findsNothing);
      expect(find.text(t.workout_rewards.loading), findsOneWidget);
      expect(rewards.refreshes, 0);
      done.complete(session);
      await tester.pumpAndSettle();
      expect(find.text('+90 XP'), findsOneWidget);
      expect(find.text('40 / 1050 XP'), findsOneWidget);
      expect(rewards.refreshes, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving during save causes no disposed-context work', (
    tester,
  ) async {
    final done = Completer<WorkoutSession?>();
    final workouts = StubWorkouts();
    final rewards = StubRewards();
    final ranking = StubRank();
    addTearDown(workouts.close);
    addTearDown(rewards.close);
    addTearDown(ranking.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WorkoutCubit>.value(value: workouts),
          BlocProvider<GamificationCubit>.value(value: rewards),
          BlocProvider<RankCubit>.value(value: ranking),
        ],
        child: MaterialApp(
          home: WorkoutRewardsScreen(
            workoutId: 'done',
            completion: done.future,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    done.complete(session);
    await tester.pump();
    expect(rewards.refreshes, 0);
    expect(tester.takeException(), isNull);
  });

  test('request handles save failures before route mounts', () async {
    final completion = Completer<WorkoutSession?>();
    final request = WorkoutRewardsRequest(
      workoutId: 'done',
      completion: completion.future,
    );
    completion.completeError(StateError('save failed'));
    await Future<void>.delayed(Duration.zero);
    await expectLater(request.completion, throwsStateError);
  });

  // testWidgets('compact layout omits completion header and skip button', (
  //   tester,
  // ) async {
  //   await pump(tester);
  //   expect(find.text(t.workout_rewards.eyebrow), findsNothing);
  //   expect(find.text(t.workout_rewards.skip), findsNothing);
  // });

  testWidgets(
    'weekly chest unlocks at five completed quests and is claimed once in UI',
    (tester) async {
      var claims = 0;
      final unlocked = stats.copyWith(
        weeklyQuests: List.generate(5, (i) => quest.copyWith(id: 'q$i')),
      );
      await pump(tester, data: unlocked, onClaimChest: () => claims++);
      final claim = find.byKey(const ValueKey('claim-chest'));

      await tester.tap(claim);
      expect(claims, 1);
      await pump(tester, data: unlocked.copyWith(isChestClaimed: true));
      expect(find.byKey(const ValueKey('claim-chest')), findsNothing);
      expect(find.byIcon(Symbols.check_circle), findsOneWidget);
    },
  );

  testWidgets(
    'locked chest explains remaining requirement without claim button',
    (tester) async {
      await pump(tester);
      expect(
        find.text('${t.workout_rewards.chest_title} · 1/5'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('claim-chest')), findsNothing);
    },
  );

  final allQuests = List.generate(
    6,
    (i) => quest.copyWith(
      id: 'q${i + 1}',
      type: QuestType.values[i],
      current: [3, 10000, 1, 120, 50, 15][i],
      target: [3, 10000, 1, 120, 50, 15][i],
    ),
  );
  final previous = allQuests
      .map((q) => q.copyWith(current: q.current ~/ 2))
      .toList();

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets(
      'all six quests, chest, streak, XP and RP fit without scrolling at $size',
      (tester) async {
        await pump(
          tester,
          size: size,
          safeInsets: const EdgeInsets.symmetric(vertical: 24),
          data: stats.copyWith(weeklyQuests: allQuests),
          streakWeeks: 4,
          beforeQuests: previous,
          rankData: rank.copyWith(currentRankId: 2, totalRp: 160),
        );
        final overflow = tester.takeException();
        if (overflow != null) {
          for (final id in ['streak', 'quests', 'chest', 'xp', 'rp']) {
            debugPrint('$id: ${tester.getSize(find.byKey(ValueKey('reveal-$id')))}');
          }
        }
        expect(overflow, isNull);
        expect(find.byType(Scrollable), findsNothing);
        for (final q in allQuests) {
          expect(
            find.byKey(ValueKey('quest-${q.id}')).hitTestable(),
            findsOneWidget,
          );
        }
        expect(
          find.byKey(const ValueKey('rp-marker')).hitTestable(),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('each section reveals before its own progress runs', (
    tester,
  ) async {
    await pump(
      tester,
      settle: false,
      beforeQuests: [quest.copyWith(current: 1)],
    );
    double reveal(String id) =>
        tester.widget<Opacity>(find.byKey(ValueKey('reveal-$id'))).opacity;
    double bar(String id) =>
        tester.widget<LinearProgressIndicator>(find.byKey(ValueKey(id))).value!;
    await tester.pump(const Duration(milliseconds: 420));
    expect(reveal('quests'), 1);
    expect(reveal('chest'), 0);
    expect(bar('quest-progress-q1'), closeTo(1 / 3, 0.001));
    await tester.pump(const Duration(milliseconds: 330));
    expect(bar('quest-progress-q1'), greaterThan(1 / 3));
    expect(bar('quest-progress-q1'), lessThan(1));
    expect(reveal('xp'), 0);
    await tester.pump(const Duration(milliseconds: 1440));
    expect(reveal('xp'), greaterThan(0));
    expect(reveal('rp'), 0);
    await tester.pumpAndSettle();
    expect(bar('xp-progress'), closeTo(40 / 1050, 0.001));
  });

  testWidgets('tap on a hidden claim only skips, then a second tap claims', (
    tester,
  ) async {
    var claims = 0;
    await pump(tester, settle: false, onClaim: (_) => claims++);
    await tester.tap(find.byKey(const ValueKey('quest-q1')));
    await tester.pump();
    expect(claims, 0);
    expect(
      tester.widget<Opacity>(find.byKey(const ValueKey('reveal-rp'))).opacity,
      1,
    );
    await tester.tap(find.byKey(const ValueKey('quest-q1')));
    expect(claims, 1);
  });

  test('RP zones use exact thresholds and XP crosses levels continuously', () {
    final scale = RewardRankScale(RankConfig.getRankById(2));
    expect(scale.position(50), scale.maintain);
    expect(scale.position(150), scale.promote);
    expect(RewardRankScale(RankConfig.getRankById(1)).canDemote, isFalse);
    expect(RewardRankScale(RankConfig.getRankById(8)).canPromote, isFalse);
    expect(RewardXpProgress.at(999), (1, 999));
    expect(RewardXpProgress.at(1000), (2, 0));
    expect(RewardXpProgress.at(2050), (3, 0));
  });

  testWidgets('optional Vietnamese previews', (tester) async {
    LocaleSettings.setLocale(AppLocale.vi);
    for (final brightness in Brightness.values) {
      await pump(
        tester,
        brightness: brightness,
        data: stats.copyWith(weeklyQuests: allQuests),
        beforeQuests: previous,
        streakWeeks: 4,
        rankData: rank.copyWith(currentRankId: 2, totalRp: 160),
      );
      if (const bool.fromEnvironment('REWARD_PREVIEWS')) {
        final render =
            boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'docs/review/workout-rewards-${brightness.name}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
  });
}
