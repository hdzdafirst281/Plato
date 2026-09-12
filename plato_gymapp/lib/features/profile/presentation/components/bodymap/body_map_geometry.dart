import 'dart:ui';
import 'package:path_drawing/path_drawing.dart';
import '../../../../../core/database/enums.dart';

/// Immutable geometry: decorative layers are deliberately excluded from muscles.
class BodyMapGeometry {
  static const viewport = Rect.fromLTWH(0, 0, 1900, 3500);
  final Path border;
  final Path skin;
  final Path hairBack;
  final Path hairFront;
  final Map<MuscleGroup, Path> muscles;

  BodyMapGeometry(
    String border,
    String skin,
    String hairBack,
    String hairFront,
    Map<MuscleGroup, String> muscles,
  ) : border = parseSvgPathData(border),
      skin = parseSvgPathData(skin),
      hairBack = hairBack.isEmpty ? Path() : parseSvgPathData(hairBack),
      hairFront = hairFront.isEmpty ? Path() : parseSvgPathData(hairFront),
      muscles = Map.unmodifiable(
        muscles.map((group, data) => MapEntry(group, parseSvgPathData(data))),
      );
}

class MuscleRenderData {
  final MuscleGroup group;
  final Path path;
  final Rect bounds;
  MuscleRenderData(this.group, this.path, this.bounds);
}
