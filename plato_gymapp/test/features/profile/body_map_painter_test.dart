import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/profile/presentation/components/bodymap/body_map_geometry.dart';
import 'package:plato_gymapp/features/profile/presentation/components/bodymap/body_map_repository.dart';
import 'package:plato_gymapp/features/profile/presentation/components/bodymap/body_map_painter.dart';

void main() {
  test(
    'render female heatmap in both themes at every intensity and frequency',
    () async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const cell = Size(170, 340);
      var row = 0;
      for (final dark in [false, true]) {
        final scheme = dark
            ? const ColorScheme.dark()
            : const ColorScheme.light();
        final colors = dark ? gymColorsDark : gymColorsLight;
        for (final front in [true, false]) {
          final geometry = BodyMapRepository.resolve(
            Gender.FEMALE,
            front: front,
          );
          final muscles = geometry.muscles.entries
              .map((e) => MuscleRenderData(e.key, e.value, e.value.getBounds()))
              .toList();
          for (var col = 0; col < 6; col++) {
            final value = [0.0, 0.1, 0.3, 0.6, 1.0, 1.0][col];
            final painter = BodyMapPainter(
              borderPath: geometry.border,
              skinPath: geometry.skin,
              hairBack: geometry.hairBack,
              hairFront: geometry.hairFront,
              muscles: muscles,
              intensities: {
                for (final group in geometry.muscles.keys) group: value,
              },
              mode: col == 5 ? HeatmapMode.FREQUENCY : HeatmapMode.INTENSITY,
              selected: null,
              colorScheme: scheme,
              gymColors: colors,
              scale: cell.width / 1900,
              dx: 0,
              dy: 15,
              animationProgress: 1,
            );
            canvas.save();
            canvas.translate(col * cell.width, row * cell.height);
            canvas.drawRect(
              Offset.zero & cell,
              Paint()..color = scheme.surface,
            );
            painter.paint(canvas, cell);
            canvas.restore();
          }
          row++;
        }
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(1020, 1360);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('build/bodymap-review')
        ..createSync(recursive: true);
      File(
        '${dir.path}/heatmap-levels.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    },
  );
}
