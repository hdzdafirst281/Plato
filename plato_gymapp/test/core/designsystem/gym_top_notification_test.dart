import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_notification.dart';

void main() {
  tearDown(GymTopNotification.clear);

  testWidgets('queued top notifications appear in order and complete', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    final first = GymTopNotification.show(
      context,
      message: 'First event',
      semanticLabel: 'First event',
      duration: const Duration(hours: 1),
      haptic: false,
    );
    final second = GymTopNotification.show(
      context,
      message: 'Second event',
      semanticLabel: 'Second event',
      duration: const Duration(hours: 1),
      haptic: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('First event'), findsOneWidget);
    expect(find.text('Second event'), findsNothing);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(await first, isTrue);
    expect(find.text('Second event'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(await second, isTrue);
    expect(GymTopNotification.isShowing, isFalse);
  });

  testWidgets('action remains accessible at large text scale', (tester) async {
    late BuildContext context;
    var actionCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    final result = GymTopNotification.show(
      context,
      message: 'Recovery information that can wrap safely on a small screen.',
      semanticLabel: 'Recovery information',
      actionLabel: 'View details',
      onAction: () => actionCalled = true,
      duration: const Duration(hours: 1),
      haptic: false,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('View details'), findsOneWidget);
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    expect(actionCalled, isTrue);
    expect(await result, isTrue);
  });

  testWidgets('icon is centered against message content instead of action', (
    tester,
  ) async {
    late BuildContext context;
    const contentKey = ValueKey('message-content');
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    final result = GymTopNotification.show(
      context,
      icon: Icons.celebration_outlined,
      customBody: const SizedBox(
        key: contentKey,
        height: 72,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Achievement title\nAchievement details'),
        ),
      ),
      actionLabel: 'View details',
      onAction: () {},
      duration: const Duration(hours: 1),
      haptic: false,
    );
    await tester.pumpAndSettle();

    final iconCenter = tester.getCenter(
      find.byIcon(Icons.celebration_outlined),
    );
    final contentCenter = tester.getCenter(find.byKey(contentKey));
    expect(iconCenter.dy, closeTo(contentCenter.dy, .5));

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });
}
