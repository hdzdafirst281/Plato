import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';

import '../../../../core/database/enums.dart';

class MuscleGroupPresentation {
  // --- ICON PATHS ---
  static const String chestIcon = "assets/svg/muscles/chest.svg";
  static const String backIcon = "assets/svg/muscles/back.svg";
  static const String legsIcon = "assets/svg/muscles/legs.svg";
  static const String shouldersIcon = "assets/svg/muscles/shoulders.svg";
  static const String coreIcon = "assets/svg/muscles/core.svg";
  static const String armsIcon = "assets/svg/muscles/arms.svg";

  // ========================================================================
  // 2. HELPER UI (Ánh xạ màu và tên)
  // ========================================================================
  static Color getColor(MajorMuscleGroup group, BuildContext context) {
    final theme = Theme.of(context);
    final gymColors = theme.gymColors;

    switch (group) {
      case MajorMuscleGroup.LEGS:
        return gymColors.warning;
      case MajorMuscleGroup.CHEST:
        return theme.colorScheme.primary;
      case MajorMuscleGroup.BACK:
        return gymColors.success;
      case MajorMuscleGroup.SHOULDERS:
        return gymColors.accentPurple;
      case MajorMuscleGroup.CORE:
        return theme.colorScheme.error;
      case MajorMuscleGroup.ARMS:
        return gymColors.accentTeal;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  static String getName(MajorMuscleGroup group) {
    return t.translateDynamic('muscles.${group.name.toLowerCase()}');
  }
}
