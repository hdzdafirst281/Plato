import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';

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
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);

    rebuild(() {});
    await tester.pump();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
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
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
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

    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
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
}
