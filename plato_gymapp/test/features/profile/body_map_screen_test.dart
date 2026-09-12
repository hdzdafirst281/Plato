import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/profile/presentation/components/bodymap/body_map_painter.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/stats/heatmap_detail_screen.dart';

void main() {
  for (final gender in Gender.values) {
    for (final brightness in Brightness.values) {
      for (final size in [
        const Size(320, 640),
        const Size(360, 740),
        const Size(390, 844),
        const Size(1024, 768),
        const Size(844, 390),
      ]) {
        testWidgets(
          '$gender $brightness $size renders and selects each visible muscle',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              MaterialApp(
                theme: brightness == Brightness.light
                    ? AppTheme.lightTheme
                    : AppTheme.darkTheme,
                home: HeatmapDetailScreen(
                  gender: gender,
                  workouts: const [],
                  onBack: () {},
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            for (final side in ['front', 'back']) {
              final finder = find.byKey(ValueKey('body-map-$side'));
              final painter =
                  tester.widget<CustomPaint>(finder).painter! as BodyMapPainter;
              final origin = tester.getTopLeft(finder);
              for (final muscle in painter.muscles) {
                Offset? target;
                // Find a point that belongs to this group under actual first-hit ordering.
                final bounds = muscle.bounds;
                for (
                  var y = bounds.top + 2;
                  y < bounds.bottom && target == null;
                  y += math.max(3, bounds.height / 35)
                ) {
                  for (
                    var x = bounds.left + 2;
                    x < bounds.right;
                    x += math.max(3, bounds.width / 35)
                  ) {
                    final point = Offset(x, y);
                    if (!painter.borderPath.contains(point)) continue;
                    final hits = painter.muscles.where(
                      (m) => m.path.contains(point),
                    );
                    if (hits.isNotEmpty && hits.first.group == muscle.group) {
                      target = point;
                      break;
                    }
                  }
                }
                expect(
                  target,
                  isNotNull,
                  reason: '${muscle.group} must have a selectable region',
                );
                await tester.tapAt(
                  origin +
                      Offset(painter.dx, painter.dy) +
                      target! * painter.scale,
                );
                await tester.pumpAndSettle();
                final updated =
                    tester.widget<CustomPaint>(finder).painter!
                        as BodyMapPainter;
                expect(updated.selected, muscle.group);
                // Clear selection so a shared front/back group never toggles off unexpectedly.
                await tester.tapAt(
                  origin +
                      Offset(painter.dx, painter.dy) +
                      target * painter.scale,
                );
                await tester.pumpAndSettle();
              }
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'gender updates replace geometry without changing canvas layout',
    (tester) async {
      Future<void> show(Gender gender) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: HeatmapDetailScreen(
              gender: gender,
              workouts: const [],
              onBack: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(Gender.MALE);
      final finder = find.byKey(const ValueKey('body-map-front'));
      final size = tester.getSize(finder);
      final male =
          tester.widget<CustomPaint>(finder).painter! as BodyMapPainter;
      await show(Gender.FEMALE);
      final female =
          tester.widget<CustomPaint>(finder).painter! as BodyMapPainter;
      expect(tester.getSize(finder), size);
      expect(female.scale, male.scale);
      expect(identical(female.borderPath, male.borderPath), isFalse);
      expect(female.shouldRepaint(male), isTrue);
    },
  );
}
