import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';
import 'package:plato_gymapp/core/navigation/main_scaffold.dart';

void main() {
  Widget subject({
    required Widget child,
    bool disableAnimations = false,
    bool tickerEnabled = true,
  }) {
    return MaterialApp(
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: TickerMode(enabled: tickerEnabled, child: appChild!),
      ),
      home: Scaffold(body: child),
    );
  }

  testWidgets('entrance plays once and does not replay after rebuild', (
    tester,
  ) async {
    late StateSetter rebuild;
    await tester.pumpWidget(
      subject(
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return const GymEntrance(child: Text('Workout'));
          },
        ),
      ),
    );

    await tester.pump();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);

    await tester.pump(GymMotion.screen);
    expect(find.byType(Opacity), findsNothing);

    rebuild(() {});
    await tester.pump();
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('entrance waits until its ticker mode is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        tickerEnabled: false,
        child: const GymEntrance(child: Text('Workout')),
      ),
    );
    await tester.pump(GymMotion.screen);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);

    await tester.pumpWidget(
      subject(child: const GymEntrance(child: Text('Workout'))),
    );
    await tester.pump();
    await tester.pump(GymMotion.screen);
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('reduced motion renders the final state immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        disableAnimations: true,
        child: const GymEntrance(child: Text('Workout')),
      ),
    );

    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('content switcher fades between keyed states', (tester) async {
    await tester.pumpWidget(
      subject(
        child: const GymContentSwitcher(
          stateKey: 'loading',
          child: Text('Loading'),
        ),
      ),
    );

    await tester.pumpWidget(
      subject(
        child: const GymContentSwitcher(
          stateKey: 'content',
          child: Text('Ready'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Loading'), findsNothing);
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('screen scope reveals stages in visual hierarchy order', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        child: const GymMotionScope(
          startDelay: Duration.zero,
          child: Column(
            children: [
              GymMotionItem(child: Text('Title')),
              GymMotionItem(stage: 2, child: Text('Content')),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 100));

    final opacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .map((widget) => widget.opacity)
        .toList();
    expect(opacities[0], greaterThan(0));
    expect(opacities[1], 0);

    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<Opacity>(find.byType(Opacity))
          .every((widget) => widget.opacity == 1),
      isTrue,
    );
  });

  testWidgets('screen scope does not replay when async content changes', (
    tester,
  ) async {
    var loaded = false;
    late StateSetter setHostState;
    await tester.pumpWidget(
      subject(
        child: StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return GymMotionScope(
              startDelay: Duration.zero,
              child: GymMotionItem(
                stage: 2,
                child: Text(loaded ? 'Ready' : 'Loading'),
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(Opacity), findsNothing);

    setHostState(() => loaded = true);
    await tester.pump();

    expect(find.text('Ready'), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('play-once scope resumes instead of restarting after remount', (
    tester,
  ) async {
    final persistenceKey = Object();

    await tester.pumpWidget(
      subject(
        child: GymMotionScope(
          playOnceKey: persistenceKey,
          startDelay: Duration.zero,
          child: const GymMotionItem(child: Text('Profile')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    final valueBeforeRemount = tester
        .widget<Opacity>(find.byType(Opacity))
        .opacity;

    await tester.pumpWidget(subject(child: const SizedBox()));
    await tester.pumpWidget(
      subject(
        child: GymMotionScope(
          playOnceKey: persistenceKey,
          startDelay: Duration.zero,
          child: const GymMotionItem(child: Text('Profile')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Profile'), findsOneWidget);
    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      closeTo(valueBeforeRemount, 0.001),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('stable value animation resumes from its last painted frame', (
    tester,
  ) async {
    final motionValue = GymMotionValue();

    Widget animatedValue() => subject(
      child: GymStableValueBuilder(
        motionValue: motionValue,
        value: 1,
        duration: const Duration(seconds: 1),
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: const Text('XP'),
      ),
    );

    await tester.pumpWidget(animatedValue());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final valueBeforeRemount = tester
        .widget<Opacity>(find.byType(Opacity))
        .opacity;
    expect(valueBeforeRemount, greaterThan(0));
    expect(valueBeforeRemount, lessThan(1));

    await tester.pumpWidget(subject(child: const SizedBox()));
    await tester.pumpWidget(animatedValue());
    await tester.pump();

    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      closeTo(valueBeforeRemount, 0.001),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  testWidgets('stable value animation updates from the current frame', (
    tester,
  ) async {
    final motionValue = GymMotionValue();

    Widget animatedValue(double target) => subject(
      child: GymStableValueBuilder(
        motionValue: motionValue,
        value: target,
        duration: const Duration(seconds: 1),
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: const Text('RP'),
      ),
    );

    await tester.pumpWidget(animatedValue(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final valueBeforeUpdate = tester
        .widget<Opacity>(find.byType(Opacity))
        .opacity;

    await tester.pumpWidget(animatedValue(0.6));
    await tester.pump();

    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      closeTo(valueBeforeUpdate, 0.001),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.6);
  });

  testWidgets('podium waits for entrance then reveals ranks 3, 2, 1', (
    tester,
  ) async {
    var active = false;
    late StateSetter rebuild;
    final motions = {
      for (final rank in [3, 2, 1]) rank: GymMotionValue(),
    };
    final values = <int, double>{};

    await tester.pumpWidget(
      subject(
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return GymMotionScope(
              active: active,
              child: Row(
                children: [
                  for (final rank in [2, 1, 3])
                    GymStableValueBuilder(
                      motionValue: motions[rank]!,
                      value: 1,
                      waitForEntrance: true,
                      delay: GymMotion.visualization * (3 - rank),
                      curve: Curves.linear,
                      builder: (context, value, child) {
                        values[rank] = value;
                        return const SizedBox();
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );

    // A hidden leaderboard must not consume its podium delays.
    await tester.pump(const Duration(seconds: 3));
    expect(values.values, everyElement(0));
    rebuild(() => active = true);
    await tester.pump();
    await tester.pump(GymMotion.sequenceStartDelay);
    await tester.pump();
    await tester.pump(GymMotion.sequence);
    expect(values.values, everyElement(0));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();

    for (final rank in [3, 2, 1]) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(values[rank], greaterThan(0), reason: 'rank $rank is rising');
      for (var waiting = rank - 1; waiting >= 1; waiting--) {
        expect(values[waiting], 0, reason: 'rank $waiting must wait');
      }
      await tester.pump(const Duration(milliseconds: 700));
      expect(values[rank], 1, reason: 'rank $rank finishes its own step');
      await tester.pump();
    }

    rebuild(() {});
    await tester.pump();
    expect(values.values, everyElement(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('entrance-gated values respect reduced motion', (tester) async {
    double? renderedValue;
    await tester.pumpWidget(
      subject(
        disableAnimations: true,
        child: GymMotionScope(
          active: false,
          child: GymStableValueBuilder(
            motionValue: GymMotionValue(),
            value: 1,
            waitForEntrance: true,
            delay: const Duration(seconds: 2),
            builder: (context, value, child) {
              renderedValue = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(renderedValue, 1);
  });

  testWidgets('inactive screen scope waits for activation', (tester) async {
    var active = false;
    late StateSetter setHostState;
    await tester.pumpWidget(
      subject(
        child: StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return GymMotionScope(
              active: active,
              startDelay: Duration.zero,
              child: const GymMotionItem(child: Text('Workout')),
            );
          },
        ),
      ),
    );

    await tester.pump(GymMotion.sequence);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);

    setHostState(() => active = true);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('main tab entrance waits until tab motion settles', (
    tester,
  ) async {
    globalActiveTabIndex.value = 2;
    globalIsTabSwiping.value = true;
    addTearDown(() {
      globalActiveTabIndex.value = 0;
      globalIsTabSwiping.value = false;
    });

    await tester.pumpWidget(
      subject(
        child: const MainTabMotionScope(
          tabIndex: 2,
          child: GymMotionItem(child: Text('Gamification')),
        ),
      ),
    );
    await tester.pump(GymMotion.sequence);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);

    globalIsTabSwiping.value = false;
    await tester.pump();
    await tester.pump(GymMotion.sequenceStartDelay);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      greaterThan(0),
    );

    await tester.pumpAndSettle();
    expect(find.byType(Opacity), findsNothing);
  });
}
