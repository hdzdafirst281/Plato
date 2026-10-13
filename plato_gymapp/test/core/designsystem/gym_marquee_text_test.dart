import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_marquee_text.dart';

void main() {
  Widget subject(String text, double progress) {
    return MaterialApp(
      home: Center(
        child: SizedBox(
          width: 100,
          child: GymMarqueeText(
            text,
            animation: AlwaysStoppedAnimation(progress),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  testWidgets('keeps a fitting username static', (tester) async {
    await tester.pumpWidget(subject('Plato', 0.5));

    expect(find.text('Plato'), findsOneWidget);
    expect(find.byType(Transform), findsNothing);
  });

  testWidgets('scrolls an overflowing username without ellipsis', (
    tester,
  ) async {
    const name = 'Plato athlete with a very long username';
    await tester.pumpWidget(subject(name, 0.5));

    expect(find.text(name), findsOneWidget);
    expect(find.textContaining('...'), findsNothing);
    final transform = tester.widget<Transform>(find.byType(Transform));
    expect(transform.transform.storage[12], lessThan(0));
  });

  testWidgets('pauses at both ends and returns to the start', (tester) async {
    const name = 'Plato athlete with a very long username';

    Future<double> offsetAt(double progress) async {
      await tester.pumpWidget(subject(name, progress));
      return tester
          .widget<Transform>(find.byType(Transform))
          .transform
          .storage[12];
    }

    final startPause = await offsetAt(0.03);
    final end = await offsetAt(0.5);
    final endPause = await offsetAt(0.53);
    final returned = await offsetAt(1);

    expect(startPause, 0);
    expect(end, lessThan(0));
    expect(endPause, end);
    expect(returned, 0);
  });

  testWidgets('keeps finite layout inside a scrolling animated item', (
    tester,
  ) async {
    const name = 'Plato athlete with a very long username';
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    width: 100,
                    child: GymMarqueeText(
                      name,
                      animation: const AlwaysStoppedAnimation(0.5),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ).animate().fade().slideY(),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(GymMarqueeText)).isFinite, isTrue);
  });
}
