import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart'; 
import 'dart:math' as math;

import '../../../../core/designsystem/theme/shapes.dart';
import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/designsystem/components/gym_selection_components.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/worker/sync_manager.dart'; 
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_shake_wrapper.dart';

import '../../../auth/data/models/user_models.dart';
import '../../presentation/bloc/profile_cubit.dart';
import '../../../../features/nutrition/presentation/components/nutrition_components.dart';

// Helper Method để định dạng loại bỏ đuôi thập phân vô nghĩa (.0, .00)
String _formatDouble(double value, {int decimals = 1}) {
  if (value % 1 == 0) return value.toInt().toString();
  String formatted = value.toStringAsFixed(decimals);
  if (formatted.contains('.')) {
    formatted = formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return formatted;
}

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late UserProfile _draftProfile;
  late BodyMetrics _draftMetrics;
  late Set<String> _selectedInjuries;
  late Set<String> _selectedDiets;

  // Raw Input Strings to handle empty states without forcing 0
  late String _ageStr;
  late String _heightStr;
  late String _weightStr;

  // Raw Input Strings for Body Metrics
  late String _bodyFatStr;
  late String _neckStr, _shouldersStr, _chestStr, _waistStr, _hipsStr;
  late String _bicepsLStr, _bicepsRStr, _thighsLStr, _thighsRStr, _calvesLStr, _calvesRStr;

  final TextEditingController _otherInjuryCtrl = TextEditingController();
  final TextEditingController _otherDietCtrl = TextEditingController();
  
  final FocusNode _otherInjuryFocus = FocusNode();
  final FocusNode _otherDietFocus = FocusNode();
  
  bool _injuryOtherTouched = false;
  bool _dietOtherTouched = false;

  final injuriesKeys = ["common.none", "profile.injury_knee", "profile.injury_back", "profile.injury_shoulder", "profile.injury_cardio", "profile.injury_blood_pressure", "profile.injury_diabetes", "profile.injury_cholesterol", "common.other"];
  final dietsKeys = ["common.none", "profile.diet_vegetarian", "profile.diet_vegan", "profile.diet_gluten", "profile.diet_peanut", "profile.diet_dairy", "profile.diet_meat", "common.other"];

  // Validation States
  bool _isFormValid = true;
  String? _nameError;
  String? _ageError;
  String? _heightError;
  String? _weightError;
  String? _injuryError;
  String? _dietError;
  
  String? _bfError, _neckError, _shouldersError, _chestError, _waistError, _hipsError;
  String? _bicepsLError, _bicepsRError, _thighsLError, _thighsRError, _calvesLError, _calvesRError;
  
  bool _forcePop = false;

  @override
  void initState() {
    super.initState();

    final currentProfile = context.read<ProfileCubit>().state.userProfile;
    _draftProfile = currentProfile;
    _draftMetrics = currentProfile.detailedBodyMetrics;

    _ageStr = currentProfile.userAge > 0 ? currentProfile.userAge.toString() : "";
    _heightStr = currentProfile.heightInCm > 0 ? _formatDouble(currentProfile.heightInCm) : "";
    _weightStr = currentProfile.weightInKg > 0 ? _formatDouble(currentProfile.weightInKg) : "";

    // Khởi tạo trạng thái Rỗng nếu bằng 0
    _bodyFatStr = (_draftProfile.bodyFatPercentage != null && _draftProfile.bodyFatPercentage! > 0) 
        ? _formatDouble(_draftProfile.bodyFatPercentage!) 
        : "";
    _neckStr = _draftMetrics.neckCm > 0 ? _formatDouble(_draftMetrics.neckCm) : "";
    _shouldersStr = _draftMetrics.shouldersCm > 0 ? _formatDouble(_draftMetrics.shouldersCm) : "";
    _chestStr = _draftMetrics.chestCm > 0 ? _formatDouble(_draftMetrics.chestCm) : "";
    _waistStr = _draftMetrics.waistCm > 0 ? _formatDouble(_draftMetrics.waistCm) : "";
    _hipsStr = _draftMetrics.hipsCm > 0 ? _formatDouble(_draftMetrics.hipsCm) : "";
    _bicepsLStr = _draftMetrics.bicepsLeftCm > 0 ? _formatDouble(_draftMetrics.bicepsLeftCm) : "";
    _bicepsRStr = _draftMetrics.bicepsRightCm > 0 ? _formatDouble(_draftMetrics.bicepsRightCm) : "";
    _thighsLStr = _draftMetrics.thighLeftCm > 0 ? _formatDouble(_draftMetrics.thighLeftCm) : "";
    _thighsRStr = _draftMetrics.thighRightCm > 0 ? _formatDouble(_draftMetrics.thighRightCm) : "";
    _calvesLStr = _draftMetrics.calfLeftCm > 0 ? _formatDouble(_draftMetrics.calfLeftCm) : "";
    _calvesRStr = _draftMetrics.calfRightCm > 0 ? _formatDouble(_draftMetrics.calfRightCm) : "";

    final customInjuries = currentProfile.reportedInjuries.where((id) => !injuriesKeys.contains(id)).toList();
    _selectedInjuries = currentProfile.reportedInjuries.where((id) => injuriesKeys.contains(id)).toSet();
    if (customInjuries.isNotEmpty) {
      _selectedInjuries.add("common.other");
      _otherInjuryCtrl.text = customInjuries.first;
      _injuryOtherTouched = true;
    }
    if (_selectedInjuries.isEmpty) {
      _selectedInjuries.add("common.none");
    }

    final customDiets = currentProfile.dietaryRestrictions.where((id) => !dietsKeys.contains(id)).toList();
    _selectedDiets = currentProfile.dietaryRestrictions.where((id) => dietsKeys.contains(id)).toSet();
    if (customDiets.isNotEmpty) {
      _selectedDiets.add("common.other");
      _otherDietCtrl.text = customDiets.first;
      _dietOtherTouched = true;
    }
    if (_selectedDiets.isEmpty) {
      _selectedDiets.add("common.none");
    }

    _otherInjuryFocus.addListener(() {
      if (!_otherInjuryFocus.hasFocus) {
        setState(() {
          _injuryOtherTouched = true;
          _validateForm();
        });
      }
    });

    _otherDietFocus.addListener(() {
      if (!_otherDietFocus.hasFocus) {
        setState(() {
          _dietOtherTouched = true;
          _validateForm();
        });
      }
    });

    _validateForm(); 
  }

  @override
  void dispose() {
    _otherInjuryCtrl.dispose();
    _otherDietCtrl.dispose();
    _otherInjuryFocus.dispose();
    _otherDietFocus.dispose();
    super.dispose();
  }

  Set<String> _toggleSetOption(Set<String> current, String option) {
    if (option == "common.none") return {"common.none"};
    final newSet = Set<String>.from(current)..remove("common.none");
    if (newSet.contains(option)) {
      newSet.remove(option);
    } else {
      newSet.add(option);
    }
    if (newSet.isEmpty) {
      return {"common.none"};
    }
    return newSet;
  }

  String? _validateMeasurement(String val, double min, double max) {
    if (val.trim().isEmpty) return null; // Cho phép rỗng
    double? parsed = double.tryParse(val);
    if (parsed == null || parsed < min || parsed > max) {
      return t.profile.err_invalid_measurement; // Nằm ngoài phạm vi vật lý
    }
    return null;
  }

  void _validateForm() {
    bool valid = true;

    // Name
    if (_draftProfile.displayName.trim().isEmpty) {
      _nameError = t.onboarding.msg_error_name_empty;
      valid = false;
    } else {
      _nameError = null;
    }

    // Age
    if (_ageStr.trim().isEmpty) {
      _ageError = t.onboarding.msg_error_age_empty;
      valid = false;
    } else {
      int? age = int.tryParse(_ageStr);
      if (age == null || age < 13 || age > 100) {
        _ageError = t.onboarding.msg_error_age_invalid;
        valid = false;
      } else {
        _ageError = null;
      }
    }

    // Height
    if (_heightStr.trim().isEmpty) {
      _heightError = t.onboarding.msg_error_height_empty;
      valid = false;
    } else {
      double? h = double.tryParse(_heightStr);
      if (h == null || h < 100 || h > 250) {
        _heightError = t.onboarding.msg_error_height_invalid;
        valid = false;
      } else {
        _heightError = null;
      }
    }

    // Weight
    if (_weightStr.trim().isEmpty) {
      _weightError = t.onboarding.msg_error_weight_empty;
      valid = false;
    } else {
      double? w = double.tryParse(_weightStr);
      if (w == null || w < 30 || w > 650) {
        _weightError = t.onboarding.msg_error_weight_invalid;
        valid = false;
      } else {
        _weightError = null;
      }
    }

    // BodyFat & Measurements
    _bfError = _validateMeasurement(_bodyFatStr, 3, 100) != null ? t.profile.err_invalid_body_fat : null;
    _neckError = _validateMeasurement(_neckStr, 10, 500);
    _shouldersError = _validateMeasurement(_shouldersStr, 10, 500);
    _chestError = _validateMeasurement(_chestStr, 10, 500);
    _waistError = _validateMeasurement(_waistStr, 10, 500);
    _hipsError = _validateMeasurement(_hipsStr, 10, 500);
    _bicepsLError = _validateMeasurement(_bicepsLStr, 10, 500);
    _bicepsRError = _validateMeasurement(_bicepsRStr, 10, 500);
    _thighsLError = _validateMeasurement(_thighsLStr, 10, 500);
    _thighsRError = _validateMeasurement(_thighsRStr, 10, 500);
    _calvesLError = _validateMeasurement(_calvesLStr, 10, 500);
    _calvesRError = _validateMeasurement(_calvesRStr, 10, 500);

    if (_bfError != null || _neckError != null || _shouldersError != null || _chestError != null ||
        _waistError != null || _hipsError != null || _bicepsLError != null || _bicepsRError != null ||
        _thighsLError != null || _thighsRError != null || _calvesLError != null || _calvesRError != null) {
      valid = false;
    }

    // Other Injury (Bắt buộc phải chứa ít nhất 1 chữ cái)
    if (_selectedInjuries.contains("common.other")) {
      String txt = _otherInjuryCtrl.text.trim();
      if (txt.isEmpty) {
        if (_injuryOtherTouched) {
          _injuryError = t.onboarding.msg_error_injury_empty;
        } else {
          _injuryError = null;
        } 
        valid = false;
      } else if (!RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(txt)) {
        _injuryError = t.profile.msg_error_text_required;
        valid = false;
      } else {
        _injuryError = null;
      }
    }

    // Other Diet (Bắt buộc phải chứa ít nhất 1 chữ cái)
    if (_selectedDiets.contains("common.other")) {
      String txt = _otherDietCtrl.text.trim();
      if (txt.isEmpty) {
        if (_dietOtherTouched) {
          _dietError = t.onboarding.msg_error_diet_empty;
        } else {
          _dietError = null;
        }
        valid = false;
      } else if (!RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(txt)) {
        _dietError = t.profile.msg_error_text_required;
        valid = false;
      } else {
        _dietError = null;
      }
    }

    _isFormValid = valid;
  }

  // BUILD DRAFT CHUẨN XÁC ĐỂ LƯU VÀ ĐỂ SO SÁNH
  UserProfile _buildUpdatedProfile() {
    List<String> finalInjuries = _selectedInjuries.where((e) => e != "common.other").toList();
    if (_selectedInjuries.contains("common.other") && _otherInjuryCtrl.text.trim().isNotEmpty) {
      finalInjuries.add(_otherInjuryCtrl.text.trim());
    }
    if (finalInjuries.length == 1 && finalInjuries.first == "common.none") {
      finalInjuries = [];
    }

    List<String> finalDiets = _selectedDiets.where((e) => e != "common.other").toList();
    if (_selectedDiets.contains("common.other") && _otherDietCtrl.text.trim().isNotEmpty) {
      finalDiets.add(_otherDietCtrl.text.trim());
    }
    if (finalDiets.length == 1 && finalDiets.first == "common.none") {
      finalDiets = [];
    }

    // Apply raw string values back to domain model safely (Rỗng -> 0)
    double currentWeight = double.tryParse(_weightStr) ?? _draftProfile.weightInKg;
    final targetWt = _draftProfile.targetGoalWeightKg ?? currentWeight;
    NutritionGoal newNutritionGoal = NutritionGoal.MAINTAIN_WEIGHT;
    if (targetWt > currentWeight) newNutritionGoal = NutritionGoal.GAIN_WEIGHT;
    if (targetWt < currentWeight) newNutritionGoal = NutritionGoal.LOSE_WEIGHT;

    BodyMetrics updatedMetrics = _draftMetrics.copyWith(
      neckCm: double.tryParse(_neckStr) ?? 0.0,
      shouldersCm: double.tryParse(_shouldersStr) ?? 0.0,
      chestCm: double.tryParse(_chestStr) ?? 0.0,
      waistCm: double.tryParse(_waistStr) ?? 0.0,
      hipsCm: double.tryParse(_hipsStr) ?? 0.0,
      bicepsLeftCm: double.tryParse(_bicepsLStr) ?? 0.0,
      bicepsRightCm: double.tryParse(_bicepsRStr) ?? 0.0,
      thighLeftCm: double.tryParse(_thighsLStr) ?? 0.0,
      thighRightCm: double.tryParse(_thighsRStr) ?? 0.0,
      calfLeftCm: double.tryParse(_calvesLStr) ?? 0.0,
      calfRightCm: double.tryParse(_calvesRStr) ?? 0.0,
    );

    double? newBodyFat = double.tryParse(_bodyFatStr);
    if (newBodyFat == null && _draftProfile.bodyFatPercentage == 0.0) {
      newBodyFat = 0.0;
    }

    return _draftProfile.copyWith(
      userAge: int.tryParse(_ageStr) ?? _draftProfile.userAge,
      heightInCm: double.tryParse(_heightStr) ?? _draftProfile.heightInCm,
      weightInKg: currentWeight,
      bodyFatPercentage: newBodyFat,
      reportedInjuries: finalInjuries,
      dietaryRestrictions: finalDiets,
      detailedBodyMetrics: updatedMetrics,
      nutritionGoal: newNutritionGoal, 
    );
  }

  // KIỂM TRA DIRTY STATE (Có thay đổi hay không)
  bool get _hasChanges {
    final original = context.read<ProfileCubit>().state.userProfile;
    
    // Compare basic string inputs with exactly how they were initialized
    final initialAgeStr = original.userAge > 0 ? original.userAge.toString() : "";
    if (_ageStr != initialAgeStr) return true;

    final initialHeightStr = original.heightInCm > 0 ? _formatDouble(original.heightInCm) : "";
    if (_heightStr != initialHeightStr) return true;

    final initialWeightStr = original.weightInKg > 0 ? _formatDouble(original.weightInKg) : "";
    if (_weightStr != initialWeightStr) return true;

    final initialBodyFatStr = (original.bodyFatPercentage != null && original.bodyFatPercentage! > 0) 
        ? _formatDouble(original.bodyFatPercentage!) 
        : "";
    if (_bodyFatStr != initialBodyFatStr) return true;

    // Compare Body Metrics
    final metrics = original.detailedBodyMetrics;
    if (_neckStr != (metrics.neckCm > 0 ? _formatDouble(metrics.neckCm) : "")) return true;
    if (_shouldersStr != (metrics.shouldersCm > 0 ? _formatDouble(metrics.shouldersCm) : "")) return true;
    if (_chestStr != (metrics.chestCm > 0 ? _formatDouble(metrics.chestCm) : "")) return true;
    if (_waistStr != (metrics.waistCm > 0 ? _formatDouble(metrics.waistCm) : "")) return true;
    if (_hipsStr != (metrics.hipsCm > 0 ? _formatDouble(metrics.hipsCm) : "")) return true;
    if (_bicepsLStr != (metrics.bicepsLeftCm > 0 ? _formatDouble(metrics.bicepsLeftCm) : "")) return true;
    if (_bicepsRStr != (metrics.bicepsRightCm > 0 ? _formatDouble(metrics.bicepsRightCm) : "")) return true;
    if (_thighsLStr != (metrics.thighLeftCm > 0 ? _formatDouble(metrics.thighLeftCm) : "")) return true;
    if (_thighsRStr != (metrics.thighRightCm > 0 ? _formatDouble(metrics.thighRightCm) : "")) return true;
    if (_calvesLStr != (metrics.calfLeftCm > 0 ? _formatDouble(metrics.calfLeftCm) : "")) return true;
    if (_calvesRStr != (metrics.calfRightCm > 0 ? _formatDouble(metrics.calfRightCm) : "")) return true;

    // Compare enum and non-string fields in draftProfile
    if (original.displayName != _draftProfile.displayName) return true;
    if (original.gender != _draftProfile.gender) return true;
    if (original.workoutGoal != _draftProfile.workoutGoal) return true;
    if (original.dietPlan != _draftProfile.dietPlan) return true;
    if (original.activityLevel != _draftProfile.activityLevel) return true;
    if (original.environment != _draftProfile.environment) return true;
    if (original.targetGoalWeightKg != _draftProfile.targetGoalWeightKg) return true;

    // Compare lists
    final originalInjuries = original.reportedInjuries.where((id) => id != "common.none").toSet();
    final currentInjuries = _selectedInjuries.where((id) => id != "common.none").toSet();
    if (currentInjuries.contains("common.other") && _otherInjuryCtrl.text.trim().isNotEmpty) {
      currentInjuries.remove("common.other");
      currentInjuries.add(_otherInjuryCtrl.text.trim());
    }
    if (originalInjuries.length != currentInjuries.length || !originalInjuries.containsAll(currentInjuries)) return true;

    final originalDiets = original.dietaryRestrictions.where((id) => id != "common.none").toSet();
    final currentDiets = _selectedDiets.where((id) => id != "common.none").toSet();
    if (currentDiets.contains("common.other") && _otherDietCtrl.text.trim().isNotEmpty) {
      currentDiets.remove("common.other");
      currentDiets.add(_otherDietCtrl.text.trim());
    }
    if (originalDiets.length != currentDiets.length || !originalDiets.containsAll(currentDiets)) return true;

    return false;
  }

  void _showDiscardChangesDialog() async {
    final confirmed = await GymDialog.showConfirm(
      context: context,
      title: t.workout.title_unsaved_changes,
      message: t.workout.msg_unsaved_changes,
      cancelText: t.common.skip,
      confirmText: t.common.save,
    );

    if (!mounted) return;

    if (confirmed == true) {
      if (_isFormValid) {
        _handleSave();
      }
    } else if (confirmed == false) {
      setState(() {
        _forcePop = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  void _handleBackNavigation() {
    FocusManager.instance.primaryFocus?.unfocus();
    
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      
      if (_hasChanges && _isFormValid && !_forcePop) {
        _showDiscardChangesDialog();
      } else {
        setState(() {
          _forcePop = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pop();
        });
      }
    });
  }

  void _handleSave() async {
    FocusManager.instance.primaryFocus?.unfocus();
    
    final updatedProfile = _buildUpdatedProfile();
    context.read<ProfileCubit>().updateProfile(updatedProfile);
    
    await SyncManager.syncNow(); 
    
    if (mounted) {
      _showSuccessDialog(context);
    }
  }

  void _showSuccessDialog(BuildContext validContext) {
    GymDialog.showSuccess(
      context: validContext,
      title: t.profile.title_save_success,
      message: t.profile.msg_save_success,
      barrierDismissible: false,
      useRootNavigator: true,
      onConfirm: () => validContext.pop(),
    );
  }

  String _translateActivityLevel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.SEDENTARY: return t.profile.activity_sedentary;
      case ActivityLevel.LIGHT: return t.profile.activity_light;
      case ActivityLevel.MODERATE: return t.profile.activity_moderate;
      case ActivityLevel.ACTIVE: return t.profile.activity_active;
      
    }
  }

  String _translateWorkoutEnv(WorkoutEnvironment env) {
    switch (env) {
      case WorkoutEnvironment.GYM: return t.profile.env_gym;
      case WorkoutEnvironment.HOME_DUMBBELL: return t.profile.env_home_dumbbell;
      case WorkoutEnvironment.HOME_BODYWEIGHT: return t.profile.env_home_bodyweight;
      
    }
  }

  String _translateWorkoutGoal(WorkoutGoal goal) {
    switch (goal) {
      case WorkoutGoal.BULK: return t.profile.goal_bulk;
      case WorkoutGoal.CUT: return t.profile.goal_cut;
      case WorkoutGoal.STRENGTH: return t.profile.goal_strength;
      
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final dietPlansKeys = [
      "profile.diet_plan_balanced",
      "profile.diet_plan_high_protein",
      "profile.diet_plan_low_carb",
      "profile.diet_plan_keto",
      "profile.diet_plan_mediterranean",
      "profile.diet_plan_paleo",
      "profile.diet_plan_low_fat",
      "profile.diet_plan_dash",
    ];

    double currentWeight = double.tryParse(_weightStr) ?? _draftProfile.weightInKg;
    double heightMeters = double.tryParse(_heightStr) ?? _draftProfile.heightInCm;
    heightMeters = heightMeters > 0 ? heightMeters / 100 : 1.0;
    
    double currentBMI = (_draftProfile.targetGoalWeightKg ?? currentWeight) / math.pow(heightMeters, 2);

    final sectionBiometrics = _SectionCard(
      title: t.onboarding.title_step_biometrics, 
      icon: Symbols.person,
      // [THÊM MỚI]: Đưa phần chọn giới tính lên thanh tiêu đề (chỉ dùng Icon)
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // NÚT MALE
          GestureDetector(
            onTap: () => setState(() => _draftProfile = _draftProfile.copyWith(gender: Gender.MALE)),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // Áp dụng Background token
                color: _draftProfile.gender == Gender.MALE 
                    ? colorScheme.primary.withValues(alpha: 0.2) 
                    : colorScheme.surfaceContainerHighest,
                // Áp dụng Border Radius = 8
                borderRadius: BorderRadius.circular(8),
                // Áp dụng Border token
                border: Border.all(
                  color: _draftProfile.gender == Gender.MALE 
                      ? colorScheme.primary 
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                Symbols.male, 
                size: 22, 
                // Áp dụng Color token
                color: _draftProfile.gender == Gender.MALE 
                    ? colorScheme.primary 
                    : colorScheme.onSurfaceVariant
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // NÚT FEMALE
          GestureDetector(
            onTap: () => setState(() => _draftProfile = _draftProfile.copyWith(gender: Gender.FEMALE)),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _draftProfile.gender == Gender.FEMALE 
                    ? colorScheme.primary.withValues(alpha: 0.2) 
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _draftProfile.gender == Gender.FEMALE 
                      ? colorScheme.primary 
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                Symbols.female, 
                size: 22, 
                color: _draftProfile.gender == Gender.FEMALE 
                    ? colorScheme.primary 
                    : colorScheme.onSurfaceVariant
              ),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          // [THAY ĐỔI]: Hàng 1 (Tên hiển thị - Tuổi) tỉ lệ 7:3
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _ProfileTextField(
                  label: t.profile.metric_name, 
                  value: _draftProfile.displayName, 
                  errorText: _nameError,
                  onChanged: (v) => setState(() {
                    _draftProfile = _draftProfile.copyWith(displayName: v);
                    _validateForm();
                  })
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _ProfileTextField(
                  label: t.profile.metric_age, 
                  value: _ageStr, 
                  isNumber: true, 
                  isInteger: true, 
                  errorText: _ageError,
                  onChanged: (v) => setState(() {
                    _ageStr = v;
                    _validateForm();
                  })
                )
              ),
            ],
          ),
          const SizedBox(height: 16),
          // [THAY ĐỔI]: Hàng 2 (Chiều cao - Cân nặng) tỉ lệ 1:1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProfileTextField(
                  label: t.profile.metric_height, 
                  value: _heightStr, 
                  isNumber: true, 
                  errorText: _heightError,
                  onChanged: (v) => setState(() {
                    _heightStr = v;
                    _validateForm();
                  })
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileTextField(
                  label: t.profile.metric_weight, 
                  value: _weightStr, 
                  isNumber: true, 
                  errorText: _weightError,
                  onChanged: (v) => setState(() {
                    _weightStr = v;
                    _validateForm();
                  })
                )
              ),
            ],
          )
        ],
      )
    ).animate(delay: 0.ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);

    final sectionGoals = _SectionCard(
      title: t.onboarding.title_step_target, icon: Symbols.flag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.profile.goal_title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: WorkoutGoal.values.map((g) => GymSingleSelectChip(
              label: _translateWorkoutGoal(g), 
              isSelected: _draftProfile.workoutGoal == g, 
              onTap: () => setState(() => _draftProfile = _draftProfile.copyWith(workoutGoal: g))
            )).toList(),
          ),
          const SizedBox(height: 16),

          Text(t.profile.diet_plan_title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: dietPlansKeys.map((key) => GymSingleSelectChip(label: t.translateDynamic(key), isSelected: _draftProfile.dietPlan == key, onTap: () => setState(() => _draftProfile = _draftProfile.copyWith(dietPlan: key)))).toList(),
          ),
          const SizedBox(height: 24),

          Text(t.profile.target_weight, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          BMIVisualizer(bmiValue: currentBMI, title: t.nutrition.bmi_target),
          const SizedBox(height: 16),
          
          Center(
            child: GestureDetector(
              onTap: () {
                showManualWeightInputDialog(
                  context, 
                  _draftProfile.targetGoalWeightKg ?? currentWeight, 
                  30.0, 
                  650.0, 
                  (val) {
                    setState(() {
                      _draftProfile = _draftProfile.copyWith(targetGoalWeightKg: val);
                    });
                  }
                );
              },
              child: Text(
                t.onboarding.format_kg(arg1: _formatDouble(_draftProfile.targetGoalWeightKg ?? currentWeight)), 
                style: TextStyle(color: Theme.of(context).gymColors.success, fontSize: 42, fontWeight: FontWeight.bold), 
                textAlign: TextAlign.center
              ),
            ),
          ),
          
          WeightRulerPicker(
            value: _draftProfile.targetGoalWeightKg ?? currentWeight,
            minWeight: 30.0,
            maxWeight: 650.0,
            onChanged: (v) => setState(() => _draftProfile = _draftProfile.copyWith(targetGoalWeightKg: double.parse(v.toStringAsFixed(1)))),
          )
        ],
      )
    ).animate(delay: 100.ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);

    final sectionMetrics = _SectionCard(
      title: t.profile.title_settings_sec_metrics, icon: Symbols.straighten,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _ProfileTextField(label: t.profile.metric_body_fat, value: _bodyFatStr, errorText: _bfError, isNumber: true, onChanged: (v) => setState(() { _bodyFatStr = v; _validateForm(); }))),
            const SizedBox(width: 16),
            Expanded(child: _ProfileTextField(label: t.profile.measure_neck, value: _neckStr, errorText: _neckError, isNumber: true, onChanged: (v) => setState(() { _neckStr = v; _validateForm(); }))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _ProfileTextField(label: t.profile.measure_shoulders, value: _shouldersStr, errorText: _shouldersError, isNumber: true, onChanged: (v) => setState(() { _shouldersStr = v; _validateForm(); }))),
            const SizedBox(width: 16),
            Expanded(child: _ProfileTextField(label: t.profile.measure_chest, value: _chestStr, errorText: _chestError, isNumber: true, onChanged: (v) => setState(() { _chestStr = v; _validateForm(); }))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _ProfileTextField(label: t.profile.measure_waist, value: _waistStr, errorText: _waistError, isNumber: true, onChanged: (v) => setState(() { _waistStr = v; _validateForm(); }))),
            const SizedBox(width: 16),
            Expanded(child: _ProfileTextField(label: t.profile.measure_hips, value: _hipsStr, errorText: _hipsError, isNumber: true, onChanged: (v) => setState(() { _hipsStr = v; _validateForm(); }))),
          ]),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5), height: 1),
          ),

          Text(t.profile.measure_biceps, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _ProfileTextField(label: t.profile.side_left, value: _bicepsLStr, errorText: _bicepsLError, isNumber: true, onChanged: (v) => setState(() { _bicepsLStr = v; _validateForm(); }))),
            const SizedBox(width: 16),
            Expanded(child: _ProfileTextField(label: t.profile.side_right, value: _bicepsRStr, errorText: _bicepsRError, isNumber: true, onChanged: (v) => setState(() { _bicepsRStr = v; _validateForm(); }))),
          ]),
          
          const SizedBox(height: 16),
          Text(t.profile.measure_thighs, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _ProfileTextField(label: t.profile.side_left, value: _thighsLStr, errorText: _thighsLError, isNumber: true, onChanged: (v) => setState(() { _thighsLStr = v; _validateForm(); }))),
            const SizedBox(width: 16),
            Expanded(child: _ProfileTextField(label: t.profile.side_right, value: _thighsRStr, errorText: _thighsRError, isNumber: true, onChanged: (v) => setState(() { _thighsRStr = v; _validateForm(); }))),
          ]),
          
          const SizedBox(height: 16),
          Text(t.profile.measure_calves, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _ProfileTextField(label: t.profile.side_left, value: _calvesLStr, errorText: _calvesLError, isNumber: true, onChanged: (v) => setState(() { _calvesLStr = v; _validateForm(); }))),
            const SizedBox(width: 16),
            Expanded(child: _ProfileTextField(label: t.profile.side_right, value: _calvesRStr, errorText: _calvesRError, isNumber: true, onChanged: (v) => setState(() { _calvesRStr = v; _validateForm(); }))),
          ]),
        ],
      )
    ).animate(delay: 200.ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);

    final sectionLifestyle = _SectionCard(
      title: t.profile.title_settings_sec_lifestyle, icon: Symbols.directions_run,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.profile.activity_title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: ActivityLevel.values.map((e) => GymSingleSelectChip(label: _translateActivityLevel(e), isSelected: _draftProfile.activityLevel == e, onTap: () => setState(() => _draftProfile = _draftProfile.copyWith(activityLevel: e)))).toList()),
          const SizedBox(height: 16),

          Text(t.profile.env_title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: WorkoutEnvironment.values.map((e) => GymSingleSelectChip(label: _translateWorkoutEnv(e), isSelected: _draftProfile.environment == e, onTap: () => setState(() => _draftProfile = _draftProfile.copyWith(environment: e)))).toList()),
          const SizedBox(height: 16),

          Text(t.profile.freq_title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: ["1-3", "3-5", "5-7"].map((e) => GymSingleSelectChip(label: e, isSelected: _draftProfile.trainingDaysPerWeek == e, onTap: () => setState(() => _draftProfile = _draftProfile.copyWith(trainingDaysPerWeek: e)))).toList()),
        ],
      )
    ).animate(delay: 300.ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);

    final sectionHealth = _SectionCard(
      title: t.profile.title_settings_sec_health, icon: Symbols.medical_services,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.profile.injury_title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: injuriesKeys.map((key) => GymSingleSelectChip(
            label: t.translateDynamic(key), 
            isSelected: _selectedInjuries.contains(key), 
            onTap: () => setState(() {
              bool isSelectingOther = key == "common.other" && !_selectedInjuries.contains("common.other");
              _selectedInjuries = _toggleSetOption(_selectedInjuries, key);
              
              if (isSelectingOther) {
                _injuryOtherTouched = false; 
                _injuryError = null; 
                Future.delayed(const Duration(milliseconds: 100), () {
                  _otherInjuryFocus.requestFocus();
                });
              }
              _validateForm();
            })
          )).toList()),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _selectedInjuries.contains("common.other") 
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextField(
                      controller: _otherInjuryCtrl, 
                      focusNode: _otherInjuryFocus,
                      onChanged: (_) => setState(() { _validateForm(); }),
                      decoration: InputDecoration(
                        hintText: t.onboarding.hint_injury_other, 
                        hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                        error: _injuryError != null
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Symbols.error_outline, color: colorScheme.error, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(_injuryError!, style: TextStyle(color: colorScheme.error, fontSize: 12)),
                                  ),
                                ],
                              )
                            : null,
                        errorMaxLines: 3,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                      )
                    ),
                  ) 
                : const SizedBox(width: double.infinity),
          ),
          
          const SizedBox(height: 24),

          Text(t.profile.diet_title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: dietsKeys.map((key) => GymSingleSelectChip(
            label: t.translateDynamic(key), 
            isSelected: _selectedDiets.contains(key), 
            onTap: () => setState(() {
              bool isSelectingOther = key == "common.other" && !_selectedDiets.contains("common.other");
              _selectedDiets = _toggleSetOption(_selectedDiets, key);

              if (isSelectingOther) {
                _dietOtherTouched = false;
                _dietError = null;
                Future.delayed(const Duration(milliseconds: 100), () {
                  _otherDietFocus.requestFocus();
                });
              }
              _validateForm();
            })
          )).toList()),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _selectedDiets.contains("common.other") 
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextField(
                      controller: _otherDietCtrl, 
                      focusNode: _otherDietFocus,
                      onChanged: (_) => setState(() { _validateForm(); }),
                      decoration: InputDecoration(
                        hintText: t.onboarding.hint_diet_other, 
                        hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                        error: _dietError != null
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Symbols.error_outline, color: colorScheme.error, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(_dietError!, style: TextStyle(color: colorScheme.error, fontSize: 12)),
                                  ),
                                ],
                              )
                            : null,
                        errorMaxLines: 3,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                      )
                    ),
                  ) 
                : const SizedBox(width: double.infinity),
          ),
        ],
      )
    ).animate(delay: 400.ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);

    final canPop = _forcePop || !_hasChanges || !_isFormValid;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!canPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: GymTopBar(
          title: t.profile.title_settings_main,
          onBackClick: _handleBackNavigation,
          actions: [
          TextButton(
            onPressed: (_hasChanges && _isFormValid) ? _handleSave : null, 
            child: Text(
              t.common.save, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: (_hasChanges && _isFormValid) ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5), 
                fontSize: 16
              )
            )
          )
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;

            if (isTablet) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              sectionBiometrics,
                              const SizedBox(height: 24),
                              sectionMetrics,
                              const SizedBox(height: 24),
                              sectionHealth,
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              sectionGoals,
                              const SizedBox(height: 24),
                              sectionLifestyle,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                sectionBiometrics,
                const SizedBox(height: 16),
                sectionGoals,
                const SizedBox(height: 16),
                sectionMetrics,
                const SizedBox(height: 16),
                sectionLifestyle,
                const SizedBox(height: 16),
                sectionHealth,
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.icon, required this.child, this.trailing,});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppShapes.large.borderRadius,
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(24), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40, 
                  decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),

                // ignore: use_null_aware_elements
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 24), 
            child
          ],
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatefulWidget {
  final String label;
  final String value;
  final bool isNumber;
  final bool isInteger; // Strictly prevent dots internally or reset to 0
  final String? errorText; 
  final Function(String) onChanged;

  const _ProfileTextField({
    required this.label, 
    required this.value, 
    this.isNumber = false, 
    this.isInteger = false,
    this.errorText,
    required this.onChanged
  });

  @override
  State<_ProfileTextField> createState() => _ProfileTextFieldState();
}

class _ProfileTextFieldState extends State<_ProfileTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _ProfileTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (_controller.text != widget.value) {
        _controller.text = widget.value;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GymShakeWrapper(
      hasError: widget.errorText != null,
      child: TextFormField(
        controller: _controller,
        keyboardType: widget.isInteger 
            ? const TextInputType.numberWithOptions(decimal: false) 
            : (widget.isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
        
        inputFormatters: widget.isInteger 
            ? [FilteringTextInputFormatter.digitsOnly]
            : (widget.isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : []),

        decoration: InputDecoration(
          labelText: widget.label,
          error: widget.errorText != null
              ? Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Icon(
                            Symbols.error, 
                            color: Theme.of(context).colorScheme.error, 
                            size: 14
                          ),
                        ),
                      ),
                      TextSpan(text: widget.errorText!),
                    ],
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error, 
                    fontSize: 12,
                    height: 1.2,
                  ),
                )
              : null,
          errorMaxLines: 6,
          labelStyle: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5))
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5)
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5)
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}