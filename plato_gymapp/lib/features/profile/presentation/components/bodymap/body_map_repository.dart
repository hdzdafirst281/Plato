import '../../../../../core/database/enums.dart';
import 'body_map_geometry.dart';
import 'generated/female_body_paths.dart';
import 'generated/male_body_paths.dart';

class BodyMapRepository {
  static final _cache = <(Gender, bool), BodyMapGeometry>{};

  // Both genders share the same muscle taxonomy and selector order.
  static Iterable<MuscleGroup> get frontGroups =>
      MaleBodyPaths.frontMuscles.keys;
  static Iterable<MuscleGroup> get backGroups => MaleBodyPaths.backMuscles.keys;

  static BodyMapGeometry resolve(Gender gender, {required bool front}) {
    return _cache.putIfAbsent((gender, front), () {
      if (gender == Gender.FEMALE) {
        return front
            ? BodyMapGeometry(
                FemaleBodyPaths.frontBorder,
                FemaleBodyPaths.frontSkin,
                FemaleBodyPaths.frontHairBack,
                FemaleBodyPaths.frontHairFront,
                FemaleBodyPaths.frontMuscles,
              )
            : BodyMapGeometry(
                FemaleBodyPaths.backBorder,
                FemaleBodyPaths.backSkin,
                FemaleBodyPaths.backHairBack,
                FemaleBodyPaths.backHairFront,
                FemaleBodyPaths.backMuscles,
              );
      }
      return front
          ? BodyMapGeometry(
              MaleBodyPaths.frontBorder,
              MaleBodyPaths.frontSkin,
              MaleBodyPaths.frontHairBack,
              MaleBodyPaths.frontHairFront,
              MaleBodyPaths.frontMuscles,
            )
          : BodyMapGeometry(
              MaleBodyPaths.backBorder,
              MaleBodyPaths.backSkin,
              MaleBodyPaths.backHairBack,
              MaleBodyPaths.backHairFront,
              MaleBodyPaths.backMuscles,
            );
    });
  }
}
