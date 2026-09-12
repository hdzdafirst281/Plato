import 'package:flutter/material.dart';
import '../../../../../core/database/enums.dart';
import '../../../../../core/designsystem/theme/app_theme.dart';
import 'body_map_geometry.dart';

class BodyMapPainter extends CustomPainter {
  final Path borderPath;
  final Path skinPath;
  final Path hairBack;
  final Path hairFront;
  final List<MuscleRenderData> muscles;
  final Map<MuscleGroup, double> intensities;
  final HeatmapMode mode;
  final MuscleGroup? selected;
  final ColorScheme colorScheme;
  final GymColors gymColors;
  final double scale;
  final double dx;
  final double dy;
  final double animationProgress;

  BodyMapPainter({
    required this.borderPath,
    required this.skinPath,
    required this.hairBack,
    required this.hairFront,
    required this.muscles,
    required this.intensities,
    required this.mode,
    required this.selected,
    required this.colorScheme,
    required this.gymColors,
    required this.scale,
    required this.dx,
    required this.dy,
    required this.animationProgress,
  });

  Color _getAnimatedColor(Color targetColor, Color unusedColor) {
    return Color.lerp(unusedColor, targetColor, animationProgress) ??
        unusedColor;
  }

  Color _getIntensityColor(double val) {
    if (val <= 0) return Colors.transparent;
    if (val < 0.25) return gymColors.heatmapLow;
    if (val < 0.5) return gymColors.heatmapMed;
    if (val < 0.75) return gymColors.heatmapHigh;
    return gymColors.heatmapExtreme;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    canvas.drawPath(hairBack, Paint()..color = const Color(0xff64748b));
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = gymColors.heatmapBase
        ..style = PaintingStyle.fill,
    );
    canvas.save();
    canvas.clipPath(borderPath);
    for (var m in muscles) {
      final val = intensities[m.group] ?? 0.0;

      Color fill;
      if (val > 0) {
        final targetColor = mode == HeatmapMode.INTENSITY
            ? _getIntensityColor(val)
            : gymColors.heatmapFreqDone;
        fill = _getAnimatedColor(targetColor, gymColors.heatmapUnused);
      } else {
        fill = gymColors.heatmapUnused;
      }

      canvas.drawPath(
        m.path,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        m.path,
        Paint()
          ..color = colorScheme.surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 / scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();

    canvas.drawPath(
      skinPath,
      Paint()
        ..color = colorScheme.surface.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7 / scale,
    );
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = gymColors.heatmapBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 / scale,
    );
    canvas.drawPath(hairFront, Paint()..color = const Color(0xff64748b));
    canvas.save();
    canvas.clipPath(borderPath);
    for (final muscle in muscles.where((m) => m.group == selected)) {
      canvas.drawPath(
        muscle.path,
        Paint()
          ..color = gymColors.heatmapSelected
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 / scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BodyMapPainter oldDelegate) {
    return oldDelegate.borderPath != borderPath ||
        oldDelegate.skinPath != skinPath ||
        oldDelegate.hairBack != hairBack ||
        oldDelegate.hairFront != hairFront ||
        oldDelegate.muscles != muscles ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.gymColors != gymColors ||
        oldDelegate.intensities != intensities ||
        oldDelegate.dx != dx ||
        oldDelegate.dy != dy ||
        oldDelegate.mode != mode ||
        oldDelegate.selected != selected ||
        oldDelegate.scale != scale ||
        oldDelegate.animationProgress != animationProgress;
  }
}
