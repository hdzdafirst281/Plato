import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_animated_progress_bar.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';

void main() {
  Widget subject(GymMotionValue motionValue) {
    return MaterialApp(
      home: Scaffold(
        body: GymAnimatedProgressBar(
          progress: 1,
          color: Colors.blue,
          trackColor: Colors.grey,
          animationDuration: 1000,
          motionValue: motionValue,
        ),
      ),
    );
  }

  testWidgets('stable progress resumes instead of replaying after remount', (
    tester,
  ) async {
    final motionValue = GymMotionValue();

    await tester.pumpWidget(subject(motionValue));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final valueBeforeRemount = tester
        .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .widthFactor!;

    expect(valueBeforeRemount, greaterThan(0));
    expect(valueBeforeRemount, lessThan(1));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpWidget(subject(motionValue));
    await tester.pump();

    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      closeTo(valueBeforeRemount, 0.001),
    );

    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      1,
    );
  });
}
