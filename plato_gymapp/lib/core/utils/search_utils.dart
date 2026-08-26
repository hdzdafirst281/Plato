import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import '../database/enums.dart';
import '../database/entities.dart';

// ========================================================
// 1. EXTENSION: XỬ LÝ CHUỖI (BỎ DẤU TIẾNG VIỆT)
// ========================================================
extension StringAccentExtension on String {
  String removeAccents() {
    var result = this;
    const withDiacritics = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    
    for (int i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result;
  }
}

// ========================================================
// 2. EXTENSION: DỊCH THUẬT NHÓM CƠ TỪ ENUM (ĐÃ FIX AN TOÀN)
// ========================================================

/// Dịch thuật cho Nhóm cơ chi tiết (MuscleGroup)
extension MuscleGroupLocalization on MuscleGroup {
  String getLocalizedName() {
    try {
      switch (this) {
        // CHEST
        case MuscleGroup.UPPER_CHEST: return t.muscles.upper_chest;
        case MuscleGroup.MIDDLE_CHEST: return t.muscles.middle_chest;
        case MuscleGroup.LOWER_CHEST: return t.muscles.lower_chest;

        // BACK
        case MuscleGroup.LATS: return t.muscles.lats;
        case MuscleGroup.UPPER_BACK: return t.muscles.upper_back;
        case MuscleGroup.LOWER_BACK: return t.muscles.lower_back;

        // SHOULDERS
        case MuscleGroup.FRONT_DELTS: return t.muscles.front_delts;
        case MuscleGroup.SIDE_DELTS: return t.muscles.side_delts;
        case MuscleGroup.REAR_DELTS: return t.muscles.rear_delts;
        case MuscleGroup.TRAPS: return t.muscles.traps;
        case MuscleGroup.NECK: return t.muscles.neck;

        // ARMS
        case MuscleGroup.BICEPS: return t.muscles.biceps;
        case MuscleGroup.TRICEPS: return t.muscles.triceps;
        case MuscleGroup.FOREARMS: return t.muscles.forearms;

        // LEGS
        case MuscleGroup.QUADS: return t.muscles.quads;
        case MuscleGroup.HAMSTRINGS: return t.muscles.hamstrings;
        case MuscleGroup.GLUTES: return t.muscles.glutes;
        case MuscleGroup.CALVES: return t.muscles.calves;
        case MuscleGroup.ADDUCTORS: return t.muscles.adductors;
        case MuscleGroup.ABDUCTORS: return t.muscles.abductors;

        // CORE
        case MuscleGroup.ABS: return t.muscles.abs;
        case MuscleGroup.OBLIQUES: return t.muscles.obliques;

        // OTHER
        case MuscleGroup.FULL_BODY: return t.muscles.full_body;
        case MuscleGroup.CARDIO: return t.muscles.cardio;
      }
    } catch (e) {
      // ĐÃ FIX TẬN GỐC: Nếu bạn lỡ quên định nghĩa key trong file JSON, 
      // hệ thống sẽ in ra tên Enum gốc thay vì làm Crash App!
      return name;
    }
  }
}

/// Dịch thuật cho Nhóm cơ chính (MajorMuscleGroup)
extension MajorMuscleGroupLocalization on MajorMuscleGroup {
  String getLocalizedName() {
    try {
      switch (this) {
        case MajorMuscleGroup.CHEST: return t.muscles.chest;
        case MajorMuscleGroup.BACK: return t.muscles.back;
        case MajorMuscleGroup.LEGS: return t.muscles.legs;
        case MajorMuscleGroup.SHOULDERS: return t.muscles.shoulders;
        case MajorMuscleGroup.ARMS: return t.muscles.arms;
        case MajorMuscleGroup.CORE: return t.muscles.core;
        case MajorMuscleGroup.FULL_BODY: return t.muscles.full_body;
        case MajorMuscleGroup.CARDIO: return t.muscles.cardio;
      }
    } catch (e) {
      return name;
    }
  }
}

// ========================================================
// 3. EXTENSION: TÌM KIẾM BÀI TẬP THÔNG MINH
// ========================================================
extension ExerciseListFilter on List<Exercise> {
  List<Exercise> smartFilter({required String searchQuery, MajorMuscleGroup? targetMajorMuscle}) {
    if (searchQuery.trim().isEmpty && targetMajorMuscle == null) return this;

    final tokens = searchQuery.removeAccents().toLowerCase().trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

    return where((exercise) {
      // Dịch exercise.name ra ngôn ngữ hiện tại trước khi bỏ dấu để so khớp
      final normalizedName = t.translateDynamic(exercise.name).removeAccents().toLowerCase();
      final normalizedMuscle = exercise.primaryMuscle?.getLocalizedName().removeAccents().toLowerCase() ?? '';
      
      final searchableHaystack = "$normalizedName $normalizedMuscle";

      final isMatchingSearch = tokens.isEmpty || tokens.every((token) => searchableHaystack.contains(token));
      final isMatchingMuscle = targetMajorMuscle == null || exercise.primaryMuscle?.major == targetMajorMuscle;

      return isMatchingSearch && isMatchingMuscle;
    }).toList();
  }
}