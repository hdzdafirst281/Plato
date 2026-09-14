import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_notification.dart';

void main() {
  tearDown(GymTopNotification.clear);

  testWidgets('top feedback queues instead of dropping a second achievement', (
    tester,
  ) async {
    late BuildContext host;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            host = context;
            return const Scaffold();
          },
        ),
      ),
    );
    GymTopNotification.show(
      host,
      message: 'First',
      duration: const Duration(seconds: 2),
    );
    GymTopNotification.show(
      host,
      message: 'Second',
      duration: const Duration(seconds: 2),
    );
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    GymTopNotification.clear();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('account reset clears an overlay before its first frame', (
    tester,
  ) async {
    late BuildContext host;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            host = context;
            return const Scaffold();
          },
        ),
      ),
    );
    GymTopNotification.show(host, message: 'Old account');
    GymTopNotification.clear();
    await tester.pumpAndSettle();
    expect(find.text('Old account'), findsNothing);
    expect(GymTopNotification.isShowing, isFalse);
    expect(tester.takeException(), isNull);
  });
}
