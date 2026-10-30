import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_scroll_to_top_button.dart';

void main() {
  test('scroll progress is clamped to the available extent', () {
    expect(gymScrollProgress(0, 1000), 0);
    expect(gymScrollProgress(500, 1000), 0.5);
    expect(gymScrollProgress(1200, 1000), 1);
    expect(gymScrollProgress(100, 0), 0);
  });

  test('scroll progress starts at the vertical center of the left edge', () {
    final metric = gymScrollProgressPath(
      const Size.square(48),
    ).computeMetrics().single;
    final start = metric.getTangentForOffset(0)!.position;

    expect(start.dx, closeTo(3.25, 0.001));
    expect(start.dy, closeTo(24, 0.001));
  });

  testWidgets('waits for scroll dimensions before reading progress', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: const [SizedBox(height: 2000)],
          ),
          floatingActionButton: GymScrollToTopButton(controller: controller),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('supports a controller attached to transitioning scroll views', (
    tester,
  ) async {
    final controller = ScrollController(initialScrollOffset: 500);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (var index = 0; index < 2; index++)
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: const [SizedBox(height: 2000)],
                  ),
                ),
            ],
          ),
          floatingActionButton: GymScrollToTopButton(controller: controller),
        ),
      ),
    );

    expect(controller.positions, hasLength(2));
    expect(
      tester.getSize(find.byKey(const ValueKey('gym-scroll-progress'))),
      const Size.square(48),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
