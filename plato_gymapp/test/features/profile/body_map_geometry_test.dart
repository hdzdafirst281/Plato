import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/features/profile/presentation/components/bodymap/body_map_geometry.dart';
import 'package:plato_gymapp/features/profile/presentation/components/bodymap/body_map_repository.dart';

void main() {
  test(
    'all views preserve muscle taxonomy, finite bounds and common viewport',
    () {
      for (final gender in Gender.values) {
        for (final front in [true, false]) {
          final geometry = BodyMapRepository.resolve(gender, front: front);
          expect(
            geometry.muscles.keys.toSet(),
            (front
                    ? BodyMapRepository.frontGroups
                    : BodyMapRepository.backGroups)
                .toSet(),
          );
          for (final path in [
            geometry.border,
            geometry.skin,
            ...geometry.muscles.values,
          ]) {
            final bounds = path.getBounds();
            expect(bounds.isFinite, isTrue);
            expect(bounds.isEmpty, isFalse);
            expect(BodyMapGeometry.viewport.contains(bounds.topLeft), isTrue);
            expect(
              BodyMapGeometry.viewport.contains(bounds.bottomRight),
              isTrue,
            );
          }
          expect(
            identical(
              geometry,
              BodyMapRepository.resolve(gender, front: front),
            ),
            isTrue,
          );
          if (gender == Gender.FEMALE) {
            expect(geometry.hairFront.getBounds().bottom, lessThan(700));
            expect(geometry.hairBack.getBounds().bottom, lessThan(700));
            for (final hair in [geometry.hairFront, geometry.hairBack]) {
              for (final muscle in geometry.muscles.values) {
                expect(
                  Path.combine(
                    PathOperation.intersect,
                    hair,
                    muscle,
                  ).computeMetrics().isEmpty,
                  isTrue,
                  reason: 'Decorative hair must not cover muscle regions',
                );
              }
            }
          }
        }
      }
    },
  );

  test('muscle interiors stay inside the body silhouette', () {
    for (final gender in Gender.values) {
      for (final front in [true, false]) {
        final geometry = BodyMapRepository.resolve(gender, front: front);
        for (final entry in geometry.muscles.entries) {
          var inside = 0;
          var outside = 0;
          final bounds = entry.value.getBounds();
          for (double y = bounds.top + 2; y < bounds.bottom; y += 8) {
            for (double x = bounds.left + 2; x < bounds.right; x += 8) {
              final point = Offset(x, y);
              if (!entry.value.contains(point)) continue;
              inside++;
              if (!geometry.border.contains(point)) outside++;
            }
          }
          expect(inside, greaterThan(0));
          expect(
            outside / inside,
            lessThan(0.005),
            reason: '$gender $front ${entry.key}: $outside/$inside outside',
          );
        }
      }
    }
  });

  test(
    'female illustration is shorter and narrower in the shared viewport',
    () {
      for (final front in [true, false]) {
        final male = BodyMapRepository.resolve(Gender.MALE, front: front);
        final female = BodyMapRepository.resolve(Gender.FEMALE, front: front);
        expect(
          female.border.getBounds().height / male.border.getBounds().height,
          inInclusiveRange(.90 * 1.025, .96 * 1.025),
        );
        final group = front ? MuscleGroup.ABS : MuscleGroup.LOWER_BACK;
        expect(
          female.muscles[group]!.getBounds().width,
          lessThan(male.muscles[group]!.getBounds().width),
        );
      }
    },
  );

  test('female face stays blank, neck is proportionate and legs are closer', () {
    double widthAt(Path path, double y) {
      final points = <double>[];
      for (double x = 0; x < 1900; x += 2) {
        if (path.contains(Offset(x, y))) points.add(x);
      }
      expect(points, isNotEmpty);
      return points.last - points.first;
    }

    for (final front in [true, false]) {
      final female = BodyMapRepository.resolve(Gender.FEMALE, front: front);
      final male = BodyMapRepository.resolve(Gender.MALE, front: front);
      expect(
        female.skin.getBounds().top,
        inInclusiveRange(
          3345 + (660 - 3345) * 1.025,
          3345 + (710 - 3345) * 1.025,
        ),
        reason:
            'Neck detail begins below the blank face, at the shared jaw/nape landmark',
      );
      expect(
        widthAt(female.border, 700),
        lessThan(widthAt(female.border, 500) * .7),
      );
      expect(
        widthAt(female.border, 3100),
        lessThan(widthAt(male.border, 3100) * .6),
      );
      for (final contour in female.border.computeMetrics()) {
        for (double distance = 0; distance < contour.length; distance += 4) {
          final point = contour.getTangentForOffset(distance)!.position;
          if (point.dy < 650) {
            expect(
              point.dx,
              inInclusiveRange(800, 1100),
              reason: 'No stray curve from the neck to the canvas origin',
            );
          }
        }
      }
    }
  });

  test(
    'female neck and shoulder registration preserves complete trapezius',
    () {
      final front = BodyMapRepository.resolve(Gender.FEMALE, front: true);
      final back = BodyMapRepository.resolve(Gender.FEMALE, front: false);
      expect(
        front.border.getBounds().top,
        closeTo(back.border.getBounds().top, 1),
      );
      expect(
        front.border.getBounds().height,
        closeTo(back.border.getBounds().height, 5),
      );
      expect(
        front.muscles[MuscleGroup.FRONT_DELTS]!.getBounds().top,
        closeTo(back.muscles[MuscleGroup.REAR_DELTS]!.getBounds().top, 20),
      );
      expect(
        front.muscles[MuscleGroup.NECK]!.getBounds().height,
        greaterThan(170),
      );
      expect(
        back.muscles[MuscleGroup.TRAPS]!.getBounds().bottom,
        greaterThan(3345 + (1170 - 3345) * 1.025),
        reason: 'Keep middle/lower trapezius, not only the small upper slips',
      );
      expect(
        Path.combine(
          PathOperation.intersect,
          back.muscles[MuscleGroup.TRAPS]!,
          back.muscles[MuscleGroup.UPPER_BACK]!,
        ).computeMetrics().isEmpty,
        isTrue,
        reason: 'The same trapezius compartment must not have two hit targets',
      );

      for (final geometry in [front, back]) {
        for (final contour in geometry.skin.computeMetrics()) {
          for (double distance = 0; distance < contour.length; distance += 3) {
            final point = contour.getTangentForOffset(distance)!.position;
            if (point.dy > 1250) continue;
            final inside = [
              Offset.zero,
              const Offset(3, 0),
              const Offset(-3, 0),
              const Offset(0, 3),
              const Offset(0, -3),
            ].any((delta) => geometry.border.contains(point + delta));
            expect(
              inside,
              isTrue,
              reason: 'Neck/upper back detail outside silhouette: $point',
            );
          }
        }
      }
    },
  );

  test(
    'muscle regions have no material overlap, including within female traps',
    () {
      final conflicts = <String>[];
      for (final gender in Gender.values) {
        for (final front in [true, false]) {
          final geometry = BodyMapRepository.resolve(gender, front: front);
          final entries = geometry.muscles.entries.toList();
          for (var i = 0; i < entries.length; i++) {
            for (var j = i + 1; j < entries.length; j++) {
              final a = entries[i];
              final b = entries[j];
              final intersection = Path.combine(
                PathOperation.intersect,
                a.value,
                b.value,
              );
              final bounds = intersection.getBounds();
              var samples = 0;
              for (double y = bounds.top + 1; y < bounds.bottom; y += 3) {
                for (double x = bounds.left + 1; x < bounds.right; x += 3) {
                  if (intersection.contains(Offset(x, y))) samples++;
                }
              }
              if (samples > 3)
                conflicts.add(
                  '$gender $front ${a.key}/${b.key}: $samples samples',
                );
            }
          }
        }
      }
      expect(conflicts, isEmpty);
      final back = BodyMapRepository.resolve(Gender.FEMALE, front: false);
      expect(
        back.muscles[MuscleGroup.TRAPS]!.computeMetrics().length,
        4,
        reason:
            'Separate upper/lower trapezius per side, without crossing strips',
      );
    },
  );

  test('render review sheet', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xfff8fafc), BlendMode.src);
    var column = 0;
    for (final gender in Gender.values) {
      for (final front in [true, false]) {
        final g = BodyMapRepository.resolve(gender, front: front);
        canvas.save();
        canvas.translate(column++ * 300.0, 30);
        canvas.scale(300 / 1900);
        final hair = Paint()..color = const Color(0xff475569);
        canvas.drawPath(g.hairBack, hair);
        canvas.drawPath(g.border, Paint()..color = const Color(0xffe2e8f0));
        for (final entry in g.muscles.entries) {
          canvas.drawPath(
            entry.value,
            Paint()
              ..color = Colors
                  .primaries[entry.key.index % Colors.primaries.length]
                  .shade300,
          );
        }
        canvas.drawPath(
          g.skin,
          Paint()
            ..color = const Color(0x8064758b)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        canvas.drawPath(
          g.border,
          Paint()
            ..color = const Color(0xff64748b)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        canvas.drawPath(g.hairFront, hair);
        canvas.restore();
      }
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1200, 600);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/bodymap-review')..createSync(recursive: true);
    File(
      '${dir.path}/comparison.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
