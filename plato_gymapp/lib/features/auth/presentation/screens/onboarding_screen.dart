import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:plato_gymapp/features/auth/presentation/screens/auth_otp_screen.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_shake_wrapper.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/entities.dart';
import '../../../../core/designsystem/theme/app_theme.dart';
import '../../../../core/designsystem/components/gym_selection_components.dart'; 
import '../../../nutrition/presentation/components/nutrition_components.dart'; 
import '../../../nutrition/domain/nutrition_calculator.dart';
import '../bloc/onboarding_cubit.dart';
import '../components/onboarding_components.dart';
import '../../data/models/user_models.dart';
import '../../../nutrition/data/models/nutrition_models.dart';
import '../../../../core/database/enums.dart';
import 'package:intl/intl.dart';

import '../../../workout/data/models/workout_models.dart';
import '../../../workout/data/program_seeder.dart';
import '../../../workout/presentation/bloc/workout_cubit.dart';

class OnboardingState {
  final String name;
  final Gender gender;
  final String age;
  final String height;
  final String weight;
  final Set<String> injuries;
  final Set<String> dietary;
  final String otherInjury; 
  final String otherDiet;   
  final ActivityLevel activityLevel;
  final String experience;
  final WorkoutGoal workoutGoal;
  final NutritionGoal nutritionGoal;
  final String trainingFreq;
  final WorkoutEnvironment environment;
  final String dietPlan;
  final String targetWeight;
  final String targetDays;
  final String paceType;

  OnboardingState({
    this.name = "", this.gender = Gender.MALE, this.age = "", this.height = "", this.weight = "",
    this.injuries = const {"common.none"}, this.dietary = const {"common.none"}, 
    this.otherInjury = "", this.otherDiet = "", this.activityLevel = ActivityLevel.MODERATE,
    this.experience = "profile.level_newbie", this.workoutGoal = WorkoutGoal.STRENGTH,
    this.nutritionGoal = NutritionGoal.MAINTAIN_WEIGHT, 
    this.trainingFreq = "3-5", this.environment = WorkoutEnvironment.GYM,
    this.dietPlan = "profile.diet_plan_balanced", this.targetWeight = "", this.targetDays = "", this.paceType = 'normal',
  });

  OnboardingState copyWith({
    String? name, Gender? gender, String? age, String? height, String? weight,
    Set<String>? injuries, Set<String>? dietary, String? otherInjury, String? otherDiet,
    ActivityLevel? activityLevel, String? experience, WorkoutGoal? workoutGoal, 
    NutritionGoal? nutritionGoal, String? trainingFreq, 
    WorkoutEnvironment? environment, String? dietPlan, String? targetWeight, String? targetDays, String? paceType,
  }) {
    return OnboardingState(
      name: name ?? this.name, gender: gender ?? this.gender, age: age ?? this.age,
      height: height ?? this.height, weight: weight ?? this.weight,
      injuries: injuries ?? this.injuries, dietary: dietary ?? this.dietary,
      otherInjury: otherInjury ?? this.otherInjury, otherDiet: otherDiet ?? this.otherDiet,
      activityLevel: activityLevel ?? this.activityLevel, experience: experience ?? this.experience,
      workoutGoal: workoutGoal ?? this.workoutGoal, nutritionGoal: nutritionGoal ?? this.nutritionGoal,
      trainingFreq: trainingFreq ?? this.trainingFreq, environment: environment ?? this.environment, 
      dietPlan: dietPlan ?? this.dietPlan, targetWeight: targetWeight ?? this.targetWeight, 
      targetDays: targetDays ?? this.targetDays, paceType: paceType ?? this.paceType,
    );
  }
}

class ChatMessage {
  final String id;
  final String Function() textBuilder; 
  final bool isApp;
  final Widget Function(BuildContext)? customWidgetBuilder;
  final int? stepIndex;
  final bool isEditable;

  ChatMessage({
    required this.id, required this.textBuilder, this.isApp = true, 
    this.customWidgetBuilder, this.stepIndex, this.isEditable = false
  });

  ChatMessage copyWith({
    String Function()? textBuilder, 
    Widget Function(BuildContext)? customWidgetBuilder,
    bool clearCustomWidget = false, 
  }) {
    return ChatMessage(
      id: id, 
      textBuilder: textBuilder ?? this.textBuilder, 
      isApp: isApp, 
      customWidgetBuilder: clearCustomWidget ? null : (customWidgetBuilder ?? this.customWidgetBuilder), 
      stepIndex: stepIndex, 
      isEditable: isEditable
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinishOnboarding;
  const OnboardingScreen({super.key, required this.onFinishOnboarding});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _uuid = const Uuid();
  final List<ChatMessage> _messages = [];
  final ValueNotifier<double> _targetWeightNotifier = ValueNotifier<double>(0.0);
  
  final Map<int, GlobalKey> _stepKeys = {}; 
  final Map<int, GlobalKey> _botStepKeys = {}; 

  int _currentStep = 0;
  int _maxStepReached = 0;
  bool _isTyping = false;
  bool _isProcessingFinal = false;
  bool _isInputVisible = false; 

  bool _isTermsAgreed = false; 

  OnboardingState _draft = OnboardingState();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _otherInjuryCtrl = TextEditingController();
  final TextEditingController _otherDietCtrl = TextEditingController();

  String? _nameError;
  String? _ageError;
  String? _heightError;
  String? _weightError;
  String? _injuryError;
  String? _dietError;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _heightFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _otherInjuryFocus = FocusNode();
  final FocusNode _otherDietFocus = FocusNode();
  
  final ScrollController _injuryScrollCtrl = ScrollController();
  final ScrollController _dietScrollCtrl = ScrollController();

  int get parsedAge => int.tryParse(_draft.age) ?? 0;
  double get parsedHeight => double.tryParse(_draft.height) ?? 0.0;
  double get parsedWeight => double.tryParse(_draft.weight) ?? 0.0;
  double get parsedTargetWeight => double.tryParse(_draft.targetWeight) ?? parsedWeight;
  int get parsedTargetDays => int.tryParse(_draft.targetDays) ?? _calcMinDays(parsedTargetWeight);

  int _calcMinDays(double targetW) {
    return NutritionCalculator.calculateMinDays(parsedWeight, targetW);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startConversation();
    });
    
    _otherInjuryFocus.addListener(() {
      if (_otherInjuryFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (_injuryScrollCtrl.hasClients) {
            _injuryScrollCtrl.animateTo(_injuryScrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        });
      }
    });
    _otherDietFocus.addListener(() {
      if (_otherDietFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (_dietScrollCtrl.hasClients) {
            _dietScrollCtrl.animateTo(_dietScrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose(); _heightCtrl.dispose(); _weightCtrl.dispose();
    _otherInjuryCtrl.dispose(); _otherDietCtrl.dispose();
    _nameFocus.dispose(); _ageFocus.dispose(); _heightFocus.dispose(); _weightFocus.dispose();
    _otherInjuryFocus.dispose(); _otherDietFocus.dispose();
    _injuryScrollCtrl.dispose(); _dietScrollCtrl.dispose();
    _targetWeightNotifier.dispose();
    _stepKeys.clear();
    _botStepKeys.clear();
    super.dispose();
  }

  void _scrollToStep(int stepIndex, {double alignment = 0.95, int durationMs = 350}) {
    final key = _botStepKeys[stepIndex]; 
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOutCubic,
        alignment: alignment, 
      );
    }
  }

  int _calculateTargetDays(double w, double tw, String pace) {
    if (w == tw) return 0;
    int currentMinDays = NutritionCalculator.calculateMinDays(w, tw);
    int baseDays = ((tw - w).abs() / 0.5 * 7).round();
    if (baseDays == 0) baseDays = 1;
    
    int fastDays = max(1, currentMinDays);
    int normalDays = baseDays <= currentMinDays ? (currentMinDays * 1.5).round() : baseDays;
    int relaxedDays = (normalDays * 1.5).round();

    switch (pace) {
      case 'fast': return fastDays;
      case 'relaxed': return relaxedDays;
      case 'custom': return parsedTargetDays > 0 ? parsedTargetDays : normalDays;
      case 'normal':
      default:
        return normalDays;
    }
  }

  // 1. Hàm quy định text của User dựa trên state _draft (Luôn lấy data mới nhất)
  String Function() _getUserTextBuilder(int step) {
    return () {
      switch (step) {
        case 0: return _draft.name;
        case 1: return "- ${_draft.gender == Gender.MALE ? t.common.male : t.common.female}\n- $parsedAge ${t.profile.metric_age.toLowerCase()}";
        case 2:
          String formatVal(double val) => val % 1 == 0 ? val.toInt().toString() : val.toString();
          return "- ${formatVal(parsedHeight)} cm\n- ${formatVal(parsedWeight)} kg";
        case 3:
          String wGoalStr = _draft.workoutGoal == WorkoutGoal.BULK ? t.profile.goal_bulk : (_draft.workoutGoal == WorkoutGoal.CUT ? t.profile.goal_cut : t.profile.goal_strength);
          String nGoalStr = _draft.nutritionGoal == NutritionGoal.GAIN_WEIGHT ? t.profile.goal_gain_weight : (_draft.nutritionGoal == NutritionGoal.LOSE_WEIGHT ? t.profile.goal_lose_weight : t.profile.goal_maintain_weight);
          return "- $wGoalStr\n- $nGoalStr";
        case 4:
          String actStr = _draft.activityLevel == ActivityLevel.SEDENTARY ? t.profile.activity_sedentary : (_draft.activityLevel == ActivityLevel.LIGHT ? t.profile.activity_light : (_draft.activityLevel == ActivityLevel.MODERATE ? t.profile.activity_moderate : t.profile.activity_active));
          String expStr = _draft.experience == "profile.level_newbie" ? t.profile.level_newbie : (_draft.experience == "profile.level_intermediate" ? t.profile.level_intermediate : t.profile.level_advanced);
          return "- $actStr\n- $expStr";
        case 5:
          double tw = parsedTargetWeight;
          int d = parsedTargetDays;
          if (d <= 0 || tw == parsedWeight || _draft.nutritionGoal == NutritionGoal.MAINTAIN_WEIGHT) {
            return "- ${tw.toStringAsFixed(1)} kg\n- ${t.profile.goal_maintain_weight}";
          } else {
            DateTime now = DateTime.now();
            DateTime targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: d));
            return "- ${tw.toStringAsFixed(1)} kg\n- ${DateFormat('dd/MM/yy').format(targetDate)}";
          }
        case 6:
          String envStr = _draft.environment == WorkoutEnvironment.GYM ? t.profile.env_gym : (_draft.environment == WorkoutEnvironment.HOME_DUMBBELL ? t.profile.env_home_dumbbell : t.profile.env_home_bodyweight);
          String freqStr = _draft.trainingFreq == "1-3" ? t.profile.freq_low : (_draft.trainingFreq == "3-5" ? t.profile.freq_mid : t.profile.freq_high);
          return "- $envStr\n- $freqStr";
        case 7:
          List<String> injList = [];
          if (_draft.injuries.contains("common.none")) {
            injList.add(t.common.none);
          } else for (var key in _draft.injuries) { if (key == "common.other" && _draft.otherInjury.isNotEmpty) {
            injList.add(_draft.otherInjury);
          } else if (key != "common.other") injList.add(t.translateDynamic(key)); }
          List<String> dietList = [];
          if (_draft.dietary.contains("common.none")) {
            dietList.add(t.common.none);
          } else for (var key in _draft.dietary) { if (key == "common.other" && _draft.otherDiet.isNotEmpty) {
            dietList.add(_draft.otherDiet);
          } else if (key != "common.other") dietList.add(t.translateDynamic(key)); }
          return "- ${injList.join(', ')}\n- ${dietList.join(', ')}";
      default:
        return "";
      }
    };
  }

  // 2. Engine xử lý logic phân tầng khi thay đổi dữ liệu cũ
  void _runCascadingLogic(int editedStep) {
    double w = parsedWeight;
    double tw = parsedTargetWeight;
    bool wasMaintain = _draft.nutritionGoal == NutritionGoal.MAINTAIN_WEIGHT;

    if (editedStep == 2) {
      if (w == tw) {
        _draft = _draft.copyWith(nutritionGoal: NutritionGoal.MAINTAIN_WEIGHT, targetDays: "0");
      } else {
        _draft = _draft.copyWith(nutritionGoal: w > tw ? NutritionGoal.LOSE_WEIGHT : NutritionGoal.GAIN_WEIGHT);
        // Tự động nhảy về Normal nếu trước đó đang Giữ cân
        String nextPace = wasMaintain ? 'normal' : _draft.paceType; 
        _draft = _draft.copyWith(paceType: nextPace, targetDays: _calculateTargetDays(w, tw, nextPace).toString());
      }
    } else if (editedStep == 3) {
      if (_draft.nutritionGoal == NutritionGoal.MAINTAIN_WEIGHT) {
        _draft = _draft.copyWith(targetWeight: w.toStringAsFixed(1), targetDays: "0");
      } else {
        if (_draft.nutritionGoal == NutritionGoal.LOSE_WEIGHT && tw >= w) tw = w - 0.5;
        if (_draft.nutritionGoal == NutritionGoal.GAIN_WEIGHT && tw <= w) tw = w + 0.5;
        String nextPace = wasMaintain ? 'normal' : _draft.paceType;
        _draft = _draft.copyWith(targetWeight: tw.toStringAsFixed(1), paceType: nextPace, targetDays: _calculateTargetDays(w, tw, nextPace).toString());
      }
    }

    if (_maxStepReached >= 5) {
      bool isMaintain = _draft.nutritionGoal == NutritionGoal.MAINTAIN_WEIGHT;
      int userMsg5Idx = _messages.indexWhere((m) => m.stepIndex == 5 && !m.isApp);

      if (isMaintain) {
        if (userMsg5Idx != -1) _messages.removeAt(userMsg5Idx); 
        _draft = _draft.copyWith(targetWeight: parsedWeight.toStringAsFixed(1), targetDays: "0");
      } else {
        if (userMsg5Idx == -1) {
          int botMsg5Idx = _messages.indexWhere((m) => m.stepIndex == 5 && m.isApp);
          if (botMsg5Idx != -1) {
            _messages.insert(botMsg5Idx, ChatMessage(
              id: _uuid.v4(), textBuilder: _getUserTextBuilder(5), isApp: false, stepIndex: 5, isEditable: true
            ));
          }
        }
        
        tw = parsedTargetWeight; 
        if (_draft.nutritionGoal == NutritionGoal.LOSE_WEIGHT && tw >= w) tw = w - 0.5;
        if (_draft.nutritionGoal == NutritionGoal.GAIN_WEIGHT && tw <= w) tw = w + 0.5;
        
        // Tính lại số ngày 1 lần cuối phòng khi Target Weight bị ép giới hạn ở dòng trên
        String currentPace = _draft.paceType;
        _draft = _draft.copyWith(targetWeight: tw.toStringAsFixed(1), targetDays: _calculateTargetDays(w, tw, currentPace).toString());
        _targetWeightNotifier.value = tw;
      }
    }
  }

  // 3. Quét và cập nhật lại toàn bộ Chat History
  void _syncChatHistory() {
    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      if (!msg.isApp && msg.stepIndex != null) {
        _messages[i] = msg.copyWith(textBuilder: _getUserTextBuilder(msg.stepIndex!));
      } else if (msg.isApp) {
        if (msg.stepIndex == 5) { // Đồng bộ Bot Step 5
          bool isMaintain = _draft.nutritionGoal == NutritionGoal.MAINTAIN_WEIGHT;
          _messages[i] = msg.copyWith(
            textBuilder: () => isMaintain ? t.onboarding.msg_chat_5_skip_maintain(name: '{name}') : t.onboarding.msg_chat_5_target_weight(name: '{name}'),
            customWidgetBuilder: isMaintain ? null : (context) => ValueListenableBuilder<double>(
              valueListenable: _targetWeightNotifier,
              builder: (context, tw, child) => BMIVisualizer(bmiValue: NutritionCalculator.calculateBMI(tw, parsedHeight), title: t.nutrition.bmi_target)
            ),
            clearCustomWidget: isMaintain,
          );
        } else if (msg.stepIndex == 8 && msg.customWidgetBuilder != null) { // Đồng bộ Bot Summary (Step 8)
          _messages[i] = msg.copyWith(customWidgetBuilder: (context) => _buildSummaryCard(context));
        }
      }
    }
  }

  String _formatBotText(String text) {
    String n = _draft.name.trim();
    if (n.isEmpty) n = t.onboarding.label_you_fallback;
    return text.replaceAll("{name}", "<b>$n</b>");
  }

  void _addAppMessage(String Function() textBuilder, {Widget Function(BuildContext)? customWidgetBuilder, int? stepIndex}) {
    setState(() {
      _messages.insert(0, ChatMessage(id: _uuid.v4(), textBuilder: textBuilder, isApp: true, customWidgetBuilder: customWidgetBuilder, stepIndex: stepIndex));
    });
  }

  void _submitUserAnswer(int step) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (step < _maxStepReached) { // TRƯỜNG HỢP EDIT
      setState(() {
        _runCascadingLogic(step);
        _syncChatHistory();
        _isInputVisible = true; 
        
        // Điều hướng thông minh: 
        // Nếu thay đổi mục tiêu (Lose/Gain) mà vượt qua step 5 -> Cuộn xuống bắt user chọn lại Target Pace
        if (step == 3 && _maxStepReached >= 5 && _draft.nutritionGoal != NutritionGoal.MAINTAIN_WEIGHT) {
          _currentStep = 5;
        } else {
          _currentStep = _maxStepReached; 
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToStep(_currentStep, durationMs: 350); 
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _scrollToStep(_currentStep, durationMs: 150);
        });
      });
    } else { // TRƯỜNG HỢP TIẾP TỤC NORMAL FLOW
      if (!mounted) return;

      setState(() {
        _isInputVisible = false; 
        _messages.insert(0, ChatMessage(
          id: _uuid.v4(), textBuilder: _getUserTextBuilder(step), isApp: false, stepIndex: step, isEditable: true
        ));
        _maxStepReached++;
        _currentStep = _maxStepReached;
      });
      _nextBotQuestion(_maxStepReached);
    }
  }

  void _editStep(int stepToEdit) {
    setState(() {
      _currentStep = stepToEdit;
      _isInputVisible = true; 
      if (stepToEdit == 0) _nameCtrl.text = _draft.name;
      if (stepToEdit == 1) _ageCtrl.text = _draft.age;
      if (stepToEdit == 2) {
        _heightCtrl.text = _draft.height;
        _weightCtrl.text = _draft.weight;
      }
      if (stepToEdit == 5) {
        _targetWeightNotifier.value = parsedTargetWeight;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToStep(stepToEdit, durationMs: 350);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _scrollToStep(stepToEdit, durationMs: 150);
      });
    });
  }

  Future<void> _simulateTyping() async {
    setState(() => _isTyping = true);
    await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(400)));
    if (mounted) setState(() => _isTyping = false);
  }

  void _startConversation() async {
    await _simulateTyping();
    _addAppMessage(() => t.onboarding.msg_chat_0, stepIndex: 0);
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isInputVisible = true);
  }

  void _nextBotQuestion(int step) async {
    await _simulateTyping();

    switch (step) {
      case 1:
        _addAppMessage(() => t.onboarding.msg_chat_1(name: '{name}'), stepIndex: 1);
        break;
      case 2:
        _addAppMessage(() => t.onboarding.msg_chat_2, stepIndex: 2);
        break;
      case 3:
        _addAppMessage(() {
          // CHUYỂN TÍNH TOÁN VÀO BÊN TRONG ĐỂ DỮ LIỆU LUÔN FRESH
          double currentBmi = NutritionCalculator.calculateBMI(parsedWeight, parsedHeight);
          
          String healthCategory;
          Color indicatorColor;
          final colorScheme = Theme.of(context).colorScheme;
          final gymColors = Theme.of(context).gymColors;

          if (currentBmi < 18.5) {
            healthCategory = t.nutrition.bmi_underweight;
            indicatorColor = colorScheme.primary; 
          } else if (currentBmi < 25.0) {
            healthCategory = t.nutrition.bmi_normal;
            indicatorColor = gymColors.success; 
          } else if (currentBmi < 30.0) {
            healthCategory = t.nutrition.bmi_overweight;
            indicatorColor = gymColors.warning; 
          } else if (currentBmi < 35.0) {
            healthCategory = t.nutrition.bmi_obese;
            indicatorColor = gymColors.fireHexagon; 
          } else {
            healthCategory = t.nutrition.bmi_severe_obese;
            indicatorColor = colorScheme.error; 
          }

          String hexStr = indicatorColor.toARGB32().toRadixString(16).substring(2).toUpperCase();
          String formatVal(double val) => val % 1 == 0 ? val.toInt().toString() : val.toString();

          return t.onboarding.msg_chat_3_bmi(
            height: formatVal(parsedHeight),
            weight: formatVal(parsedWeight),
            bmi: '<c_$hexStr>${currentBmi.toStringAsFixed(1)}</c>',
            category: '<c_$hexStr>$healthCategory</c>'
          );
        });
        
        await _simulateTyping();
        _addAppMessage(() => t.onboarding.msg_chat_3_new_goal(name: '{name}'), stepIndex: 3);
        break;
      case 4:
        _addAppMessage(() => t.onboarding.msg_chat_4_activity, stepIndex: 4);
        break;
      case 5:
        if (_draft.nutritionGoal == NutritionGoal.MAINTAIN_WEIGHT) {
          _addAppMessage(() => t.onboarding.msg_chat_5_skip_maintain(name: '{name}'), stepIndex: 5);
          await Future.delayed(const Duration(milliseconds: 1500));
          
          _draft = _draft.copyWith(targetWeight: parsedWeight.toStringAsFixed(1), targetDays: "0");
          
          if (mounted) {
            setState(() {
              _maxStepReached++;
              _currentStep = _maxStepReached;
            });
            _nextBotQuestion(_maxStepReached); 
          }
          return; 
        }

        if (_draft.targetWeight.isEmpty) _draft = _draft.copyWith(targetWeight: _draft.weight);
        _targetWeightNotifier.value = parsedTargetWeight; 

        _addAppMessage(
          () => t.onboarding.msg_chat_5_target_weight(name: '{name}'),
          customWidgetBuilder: (context) => ValueListenableBuilder<double>(
            valueListenable: _targetWeightNotifier,
            builder: (context, tw, child) {
              double dynamicBMI = NutritionCalculator.calculateBMI(tw, parsedHeight);
              return BMIVisualizer(bmiValue: dynamicBMI, title: t.nutrition.bmi_target);
            }
          ),
          stepIndex: 5 
        );
        break;
      case 6:
        _addAppMessage(() => t.onboarding.msg_chat_6, stepIndex: 6);
        break;
      case 7:
        _addAppMessage(() => t.onboarding.msg_chat_7(name: '{name}'), stepIndex: 7);
        break;
      case 8:
        _addAppMessage(() => t.onboarding.msg_chat_8_done, customWidgetBuilder: (context) => _buildSummaryCard(context), stepIndex: 8);
        await _simulateTyping();
        _addAppMessage(() => t.onboarding.msg_chat_8_ready(name: '{name}'));
        setState(() => _isProcessingFinal = true); 
        break;
    }

    await Future.delayed(const Duration(milliseconds: 400)); 
    if (mounted) {
      setState(() => _isInputVisible = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToStep(step);
      });
    }
  }

  void _handleStep0Submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _nameError = t.onboarding.msg_error_name_empty);
      return;
    }
    setState(() => _nameError = null);
    _draft = _draft.copyWith(name: _nameCtrl.text.trim());
    _submitUserAnswer(0);
  }

  void _handleStep1Submit(Gender g) {
    final ageText = _ageCtrl.text.trim();
    if (ageText.isEmpty) {
      setState(() => _ageError = t.onboarding.msg_error_age_empty);
      return;
    }
    
    int age = int.tryParse(ageText) ?? 0;
    if (age < 13 || age > 100) {
      setState(() => _ageError = t.onboarding.msg_error_age_invalid);
      return;
    }
    
    setState(() => _ageError = null);
    _draft = _draft.copyWith(gender: g, age: age.toString());
    _submitUserAnswer(1);
  }

  void _handleStep2Submit() {
    final hText = _heightCtrl.text.trim();
    final wText = _weightCtrl.text.trim();
    bool hasError = false;

    if (hText.isEmpty) {
      setState(() => _heightError = t.onboarding.msg_error_height_empty);
      hasError = true;
    } else {
      double h = double.tryParse(hText) ?? 0;
      if (h < 100 || h > 250) { // Đồng bộ height với Profile
        setState(() => _heightError = t.onboarding.msg_error_height_invalid);
        hasError = true;
      } else {
        setState(() => _heightError = null);
      }
    }

    // CẬP NHẬT Ở ĐÂY
    if (wText.isEmpty) {
      setState(() => _weightError = t.onboarding.msg_error_weight_empty);
      hasError = true;
    } else {
      double w = double.tryParse(wText) ?? 0;
      if (w < 30 || w > 650) {
        setState(() => _weightError = t.onboarding.msg_error_weight_invalid);
        hasError = true;
      } else {
        setState(() => _weightError = null);
      }
    }

    if (hasError) return;

    _draft = _draft.copyWith(height: hText, weight: wText);
    
    
    _submitUserAnswer(2);
  }

  void _handleStep3Submit() {
    _submitUserAnswer(3);
  }

  void _handleStep4Submit() {
    _submitUserAnswer(4);
  }

  void _handleStep5Submit(double targetWeight, int days, String paceType) {
    _draft = _draft.copyWith(targetWeight: targetWeight.toStringAsFixed(1), targetDays: days.toString(), paceType: paceType);
    _submitUserAnswer(5);
  }

  void _handleStep6Submit() {
    _submitUserAnswer(6);
  }

  void _handleStep7Submit() {
    bool hasError = false;

    // Validate Other Injury
    if (_draft.injuries.contains("common.other")) {
      String txt = _otherInjuryCtrl.text.trim();
      if (txt.isEmpty) {
        setState(() => _injuryError = t.onboarding.msg_error_injury_empty);
        hasError = true;
      } else if (!RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(txt)) {
        setState(() => _injuryError = t.profile.msg_error_text_required);
        hasError = true;
      } else {
        setState(() => _injuryError = null);
      }
    } else {
      setState(() => _injuryError = null);
    }

    // Validate Other Diet
    if (_draft.dietary.contains("common.other")) {
      String txt = _otherDietCtrl.text.trim();
      if (txt.isEmpty) {
        setState(() => _dietError = t.onboarding.msg_error_diet_empty);
        hasError = true;
      } else if (!RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(txt)) {
        setState(() => _dietError = t.profile.msg_error_text_required);
        hasError = true;
      } else {
        setState(() => _dietError = null);
      }
    } else {
      setState(() => _dietError = null);
    }

    if (hasError) return;

    _draft = _draft.copyWith(otherInjury: _otherInjuryCtrl.text.trim(), otherDiet: _otherDietCtrl.text.trim());
    _submitUserAnswer(7);
  }

  Set<String> _toggleSetOption(Set<String> current, String key) {
    if (key == "common.none") return {"common.none"};
    var newSet = Set<String>.from(current)..remove("common.none");
    if (newSet.contains(key)) {
      newSet.remove(key);
    } else {
      newSet.add(key);
    }
    if (newSet.isEmpty) newSet.add("common.none");
    return newSet;
  }

  WorkoutProgramEntity? _getRealtimeRecommendedProgram() {
    String diff = "BEGINNER";
    if (_draft.experience == "profile.level_intermediate") diff = "INTERMEDIATE";
    if (_draft.experience == "profile.level_advanced") diff = "ADVANCED";

    final allPrograms = ProgramSeeder.getInitialPrograms();
    var matches = allPrograms.where((p) => p.difficulty == diff && p.environment == _draft.environment && p.goal == _draft.workoutGoal).toList();
    if (matches.isEmpty) {
      matches = allPrograms.where((p) => p.difficulty == diff && p.environment == _draft.environment).toList();
    }
    if (matches.isEmpty) {
      matches = allPrograms.where((p) => p.difficulty == diff).toList();
    }

    if (matches.isNotEmpty) {
      if (_draft.trainingFreq == "1-3") {
        return matches.firstWhere((p) => p.name.contains("fb"), orElse: () => matches.first);
      } else if (_draft.trainingFreq == "3-5") {
        return matches.firstWhere((p) => p.name.contains("ul") || p.name.contains("combo"), orElse: () => matches.first);
      } else {
        return matches.firstWhere((p) => p.name.contains("ppl"), orElse: () => matches.first);
      }
    }
    return null;
  }

  Macros _getRealtimeMacros() {
    double w = parsedWeight > 0 ? parsedWeight : 60;
    double h = parsedHeight > 0 ? parsedHeight : 170;
    int a = parsedAge > 0 ? parsedAge : 25;

    double bmr = NutritionCalculator.calculateBMR(w, h, a, _draft.gender, null);
    double tdee = NutritionCalculator.calculateTDEE(bmr, _draft.activityLevel);

    int currentMinDays = _calcMinDays(parsedTargetWeight);
    int safeDays = parsedTargetDays < currentMinDays ? currentMinDays : parsedTargetDays;
    if (safeDays <= 0) safeDays = 1;

    int targetCals = NutritionCalculator.calculateTargetCalories(
      bmr, tdee, w, parsedTargetWeight, safeDays, _draft.nutritionGoal
    );

    return NutritionCalculator.calculateMacros(w, targetCals, _draft.nutritionGoal);
  }

  void _finishOnboarding() async {
    final finalProgram = _getRealtimeRecommendedProgram();
    final finalMacros = _getRealtimeMacros();
    const dummyMetrics = BodyMetrics();
    
    List<String> finalInjuries = _draft.injuries.where((e) => e != "common.other").toList();
    if (_draft.injuries.contains("common.other") && _draft.otherInjury.isNotEmpty) {
       finalInjuries.add(_draft.otherInjury.trim());
    }
    
    List<String> finalDiets = _draft.dietary.where((e) => e != "common.other").toList();
    if (_draft.dietary.contains("common.other") && _draft.otherDiet.isNotEmpty) {
       finalDiets.add(_draft.otherDiet.trim());
    }

    final finalProfile = UserProfile(
      displayName: _draft.name,
      gender: _draft.gender,
      userAge: parsedAge,
      heightInCm: parsedHeight,
      weightInKg: parsedWeight,
      bodyFatPercentage: null, 
      workoutGoal: _draft.workoutGoal,
      nutritionGoal: _draft.nutritionGoal, 
      activityLevel: _draft.activityLevel,
      trainingDaysPerWeek: _draft.trainingFreq,
      reportedInjuries: finalInjuries,
      dietaryRestrictions: finalDiets,
      environment: _draft.environment,
      experienceLevel: _draft.experience,
      dietPlan: _draft.dietPlan,
      targetGoalWeightKg: parsedTargetWeight,
      targetMacros: finalMacros,
      detailedBodyMetrics: dummyMetrics,
    );

    if (finalProgram != null) {
      try {
        final rawRoutines = jsonDecode(finalProgram.routinesJson) as List;
        final parsedRoutines = rawRoutines.map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>)).toList();
        
        final workoutProgram = WorkoutProgram(
          id: finalProgram.id,
          name: finalProgram.name,
          description: finalProgram.description,
          environment: finalProgram.environment,
          difficulty: finalProgram.difficulty,
          goal: finalProgram.goal,
          routines: parsedRoutines,
        );
        await context.read<WorkoutCubit>().addProgramRoutines(workoutProgram);
      } catch (e) {
        debugPrint("Lỗi Parse Program: $e");
      }
    }

    if (mounted) {
      context.read<OnboardingCubit>().completeOnboarding(
        finalProfile, _draft.experience, parsedTargetDays, () {
          context.read<ProfileCubit>().refreshProfile();
          widget.onFinishOnboarding();
        }
      );
    }
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    await GymDialog.showCustom(
      context: context,
      titleWidget: Text(t.settings.title_language_dialog, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Symbols.language),
            title: const Text('Tiếng Việt'),
            trailing: LocaleSettings.currentLocale.languageCode == 'vi' ? Icon(Symbols.check, color: Theme.of(context).colorScheme.primary) : null,
            onTap: () {
              LocaleSettings.setLocale(AppLocale.vi);
              SharedPreferences.getInstance().then((prefs) => prefs.setString('app_lang', 'vi'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Symbols.language),
            title: const Text('English'),
            trailing: LocaleSettings.currentLocale.languageCode == 'en' ? Icon(Symbols.check, color: Theme.of(context).colorScheme.primary) : null,
            onTap: () {
              LocaleSettings.setLocale(AppLocale.en);
              SharedPreferences.getInstance().then((prefs) => prefs.setString('app_lang', 'en'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [],
    );
  }

  List<TextSpan> _buildRichSpans(String text, ColorScheme colorScheme) {
    final String appName = t.app_name;
    final String brandName = t.company_name;
    final List<TextSpan> spans = [];
    
    // Tìm các placeholder {app} và {brand}
    final regex = RegExp(r'(\{app\}|\{brand\})');
    final matches = regex.allMatches(text);
    
    int lastIndex = 0;
    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      final tag = match.group(0);
      if (tag == '{app}') {
        spans.add(TextSpan(text: appName, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)));
      } else if (tag == '{brand}') {
        spans.add(TextSpan(text: brandName, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)));
      }
      lastIndex = match.end;
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }
    return spans;
  }

  Future<void> _showTermsDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    await GymDialog.showCustom(
      context: context,
      titleWidget: RichText(
        text: TextSpan(
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface),
          children: _buildRichSpans(t.onboarding.title_terms(app: '{app}'), colorScheme),
        ),
      ),
      content: SizedBox(
        width: ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 600 : double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTermsSection(t.onboarding.terms_p1_title, [
              t.onboarding.terms_p1_desc1(app: '{app}'),
              t.onboarding.terms_p1_desc2,
              t.onboarding.terms_p1_desc3(app: '{app}'),
            ], colorScheme),
            _buildTermsSection(t.onboarding.terms_p2_title, [
              t.onboarding.terms_p2_desc1,
              t.onboarding.terms_p2_desc2,
              t.onboarding.terms_p2_desc3,
            ], colorScheme),
            _buildTermsSection(t.onboarding.terms_p3_title, [
              t.onboarding.terms_p3_desc1,
              t.onboarding.terms_p3_desc2(brand: '{brand}'),
              t.onboarding.terms_p3_desc3,
            ], colorScheme),
            _buildTermsSection(t.onboarding.terms_p4_title, [
              t.onboarding.terms_p4_desc1,
            ], colorScheme),
            _buildTermsSection(t.onboarding.terms_p5_title, [
              t.onboarding.terms_p5_desc1(app: '{app}'),
              t.onboarding.terms_p5_desc2(brand: '{brand}'),
            ], colorScheme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text(t.common.close, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary))
        )
      ],
    );
  }

  Future<void> _showEulaDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    await GymDialog.showCustom(
      context: context,
      titleWidget: RichText(
        text: TextSpan(
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface),
          children: _buildRichSpans(t.onboarding.title_eula(app: '{app}'), colorScheme),
        ),
      ),
      content: SizedBox(
        width: ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 600 : double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.onboarding.eula_updated, 
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            RichText(text: TextSpan(
              style: TextStyle(fontSize: 13, height: 1.5, color: colorScheme.onSurfaceVariant),
              children: _buildRichSpans(t.onboarding.eula_intro(app: '{app}', brand: '{brand}'), colorScheme),
            )),
            const SizedBox(height: 16),
            _buildTermsSection(t.onboarding.eula_p1_title, [
              t.onboarding.eula_p1_desc(app: '{app}'),
            ], colorScheme),
            _buildTermsSection(t.onboarding.eula_p2_title, [
              t.onboarding.eula_p2_desc1(app: '{app}'),
              t.onboarding.eula_p2_item1,
              t.onboarding.eula_p2_item2(app: '{app}', brand: '{brand}'),
              t.onboarding.eula_p2_item3,
              t.onboarding.eula_p2_desc2(brand: '{brand}'),
            ], colorScheme),
            _buildTermsSection(t.onboarding.eula_p3_title, [
              t.onboarding.eula_p3_desc1,
              t.onboarding.eula_p3_item1,
              t.onboarding.eula_p3_item2(app: '{app}'),
              t.onboarding.eula_p3_item3,
            ], colorScheme),
            _buildTermsSection(t.onboarding.eula_p4_title, [t.onboarding.eula_p4_desc], colorScheme),
            _buildTermsSection(t.onboarding.eula_p5_title, [
              t.onboarding.eula_p5_item1(app: '{app}'),
              t.onboarding.eula_p5_item2,
              t.onboarding.eula_p5_item3,
            ], colorScheme),
            _buildTermsSection(t.onboarding.eula_p6_title, [t.onboarding.eula_p6_desc], colorScheme),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), 
          child: Text(t.common.close, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)))
      ],
    );
  }

  Widget _buildTermsSection(String title, List<String> paragraphs, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.primary)),
          const SizedBox(height: 8),
          ...paragraphs.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, height: 1.5, color: colorScheme.onSurfaceVariant),
                children: _buildRichSpans(p, colorScheme),
              ),
            ),
          ))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double onboardingProgress = (_maxStepReached / 8.0).clamp(0.0, 1.0);

    return Scaffold(
      // Scaffold mặc định tự động đẩy nội dung khi bàn phím xuất hiện
      resizeToAvoidBottomInset: true, 
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
              clipBehavior: Clip.hardEdge,
              child: Image.asset('assets/logo/logo_plato.png', fit: BoxFit.cover, 
                errorBuilder: (context, error, stackTrace) => Icon(Symbols.exercise, color: colorScheme.onPrimaryContainer, size: 20)
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.onboarding.label_bot_name, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).gymColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(t.onboarding.label_bot_status, style: TextStyle(color: Theme.of(context).gymColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                )
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Symbols.language, color: colorScheme.primary),
            onPressed: () => _showLanguageDialog(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: onboardingProgress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.15), 
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 3.0,
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    reverse: true, 
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == 0) {
                        return TypingIndicatorWidget(colorScheme: colorScheme);
                      }
                      
                      int msgIndex = _isTyping ? index - 1 : index;
                      final msg = _messages[msgIndex];
                      
                      Widget childNode = ChatBubbleWidget(
                        key: ValueKey(msg.id), 
                        message: msg,
                        colorScheme: colorScheme,
                        formattedText: _formatBotText(msg.textBuilder()),
                        onEdit: msg.stepIndex != null ? () => _editStep(msg.stepIndex!) : null,
                      );

                      if (msg.isApp && msg.stepIndex != null) {
                        final botKey = _botStepKeys.putIfAbsent(msg.stepIndex!, () => GlobalKey());
                        childNode = KeyedSubtree(key: botKey, child: childNode);
                      }

                      if (!msg.isApp && msg.stepIndex != null) {
                        final bubbleKey = _stepKeys.putIfAbsent(msg.stepIndex!, () => GlobalKey());
                        
                        if (_currentStep == msg.stepIndex && _currentStep < _maxStepReached) {
                          childNode = Container(
                            key: bubbleKey,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                childNode, 
                                const SizedBox(height: 12),
                                Container(
                                  margin: const EdgeInsets.only(left: 32),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
                                  ),
                                  child: _buildInputAreaForStep(colorScheme),
                                )
                              ],
                            ),
                          );
                        } else {
                          childNode = KeyedSubtree(key: bubbleKey, child: childNode);
                        }
                      }
                      return childNode;
                    },
                  ),
                  
                  if (_currentStep >= _maxStepReached) 
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Material(
                          elevation: 4,
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () {
                              if (_isInputVisible) FocusManager.instance.primaryFocus?.unfocus();
                              setState(() => _isInputVisible = !_isInputVisible);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Icon(
                                _isInputVisible ? Symbols.keyboard_arrow_down : Symbols.keyboard_arrow_up,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            AnimatedSize(
              duration: const Duration(milliseconds: 400), 
              curve: Curves.easeOutCubic, 
              alignment: Alignment.bottomCenter, 
              child: (!_isInputVisible || _currentStep < _maxStepReached) 
                  ? const SizedBox(width: double.infinity, height: 0)
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
                      ),
                      child: ClipRect(
                        child: Padding(
                          // Padding bottom 24 ở đây chính là khoảng trống đẩy cách bàn phím mượt mà
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600), 
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                              return Stack(
                                alignment: Alignment.bottomCenter,
                                children: <Widget>[
                                  ...previousChildren,
                                  // ignore: use_null_aware_elements
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim, 
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim),
                                child: child,
                              )
                            ),
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              // ĐÃ XÓA: padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)
                              child: _buildInputAreaForStep(colorScheme),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputAreaForStep(ColorScheme colorScheme) {
    Widget? buildErrorWidget(String? errorMsg, ColorScheme colorScheme) {
      if (errorMsg == null) return null;
      return Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(Symbols.error, color: colorScheme.error, size: 14),
              ),
            ),
            TextSpan(text: errorMsg),
          ],
        ),
        style: TextStyle(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.w600),
      );
    }

    if (_isProcessingFinal && _currentStep == 8) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _isTermsAgreed,
                  activeColor: colorScheme.primary,
                  onChanged: (val) {
                    setState(() => _isTermsAgreed = val ?? false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    children: [
                      TextSpan(text: t.onboarding.label_agree_terms),
                      TextSpan(
                        text: t.onboarding.label_terms_link,
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () => _showTermsDialog(context),
                      ),
                      TextSpan(text: t.onboarding.label_and),
                      TextSpan(
                        text: t.onboarding.label_eula_link,
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () => _showEulaDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const ValueKey('stepFinal'),
            icon: const Icon(Symbols.rocket_launch),
            label: Text(t.onboarding.btn_start_journey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isTermsAgreed ? colorScheme.primary : colorScheme.surfaceContainerHighest, 
              foregroundColor: _isTermsAgreed ? colorScheme.onPrimary : colorScheme.onSurfaceVariant, 
              minimumSize: const Size(double.infinity, 56), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
            onPressed: _isTermsAgreed ? _finishOnboarding : null,
          ),
        ],
      );
    }

    switch (_currentStep) {
      case 0: 
        return Column(
          key: const ValueKey('step0'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            Row(
              children: [
                Expanded(
                  child: GymShakeWrapper(
                    hasError: _nameError != null,
                    child: TextField(
                      controller: _nameCtrl, focusNode: _nameFocus, textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() => _nameError = null), 
                      decoration: InputDecoration(
                        hintText: t.onboarding.hint_username, 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                        error: buildErrorWidget(_nameError, colorScheme),
                        filled: true, 
                        fillColor: colorScheme.surface, 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20)
                      ),
                      onSubmitted: (_) => _handleStep0Submit(),
                    ),
                  )
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                  child: IconButton(icon: Icon(Symbols.send, color: colorScheme.onPrimary, fill: 1.0), onPressed: _handleStep0Submit),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            // ĐÃ SỬA: Đổi Text và truyền chuẩn xác flowType: AuthFlowType.login
            TextButton.icon(
              onPressed: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                // Dùng Native Navigator để push đè lên với tham số luồng Đăng nhập
                final hasOldData = await Navigator.of(context, rootNavigator: false).push<bool>(
                  MaterialPageRoute(builder: (_) => const AuthOtpScreen(flowType: AuthFlowType.login))
                );
                
                if (hasOldData == true && mounted) {
                   widget.onFinishOnboarding();
                }
              },
              icon: const Icon(Symbols.login),
              label: Text(
                t.auth.btn_already_have_account,
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)
              ),
            )
          ],
        );

      case 1: 
        return Column(
          key: const ValueKey('step1'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.profile.metric_age, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 8),
            GymShakeWrapper(
              hasError: _ageError != null,
              child: TextField(
                controller: _ageCtrl, focusNode: _ageFocus, keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _ageError = null),
                decoration: InputDecoration(
                  hintText: t.onboarding.hint_age, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                  error: buildErrorWidget(_ageError, colorScheme),
                  filled: true, 
                  fillColor: colorScheme.surface, 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20)
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(t.profile.metric_gender, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: VisualChoiceCard(title: t.common.male, icon: Symbols.male, isSelected: _draft.gender == Gender.MALE, onTap: () => setState(() => _draft = _draft.copyWith(gender: Gender.MALE)))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: VisualChoiceCard(title: t.common.female, icon: Symbols.female, isSelected: _draft.gender == Gender.FEMALE, onTap: () => setState(() => _draft = _draft.copyWith(gender: Gender.FEMALE)))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 12.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 8.0)]).value),
                  Container(
                    height: ResponsiveValue<double>(context, defaultValue: 56.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 48.0)]).value, 
                    width: ResponsiveValue<double>(context, defaultValue: 56.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 48.0)]).value,
                    decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                    child: IconButton(icon: Icon(Symbols.send, color: colorScheme.onPrimary, fill: 1.0), onPressed: () => _handleStep1Submit(_draft.gender)),
                  )
                ],
              ),
            ),
          ],
        );

      case 2: 
        return Column(
          key: const ValueKey('step2'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.profile.metric_height, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                      const SizedBox(height: 8),
                      GymShakeWrapper(
                        hasError: _heightError != null,
                        child: TextField(
                          controller: _heightCtrl, focusNode: _heightFocus, keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() => _heightError = null),
                          decoration: InputDecoration(
                            hintText: t.onboarding.hint_height, 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                            error: buildErrorWidget(_heightError, colorScheme),
                            filled: true, 
                            fillColor: colorScheme.surface, 
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveValue<double>(context, defaultValue: 12.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 8.0)]).value),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.profile.metric_weight, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                      const SizedBox(height: 8),
                      GymShakeWrapper(
                        hasError: _weightError != null,
                        child: TextField(
                          controller: _weightCtrl, focusNode: _weightFocus, keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() => _weightError = null),
                          decoration: InputDecoration(
                            hintText: t.onboarding.hint_weight, 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                            error: buildErrorWidget(_weightError, colorScheme),
                            filled: true, 
                            fillColor: colorScheme.surface, 
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16)
                          ),
                          onSubmitted: (_) => _handleStep2Submit(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _handleStep2Submit,
              child: Text(t.common.next, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        );

      case 3:
        return Column(
          key: const ValueKey('step3'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.profile.goal_workout_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 8),
            IntrinsicHeight( 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: IconMiniCard(title: t.profile.goal_bulk, icon: Symbols.keyboard_double_arrow_up, isSelected: _draft.workoutGoal == WorkoutGoal.BULK, onTap: () => setState(() => _draft = _draft.copyWith(workoutGoal: WorkoutGoal.BULK)))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: IconMiniCard(title: t.profile.goal_cut, icon: Symbols.local_fire_department, isSelected: _draft.workoutGoal == WorkoutGoal.CUT, onTap: () => setState(() => _draft = _draft.copyWith(workoutGoal: WorkoutGoal.CUT)))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: IconMiniCard(title: t.profile.goal_strength, icon: Symbols.flash_on, isSelected: _draft.workoutGoal == WorkoutGoal.STRENGTH, onTap: () => setState(() => _draft = _draft.copyWith(workoutGoal: WorkoutGoal.STRENGTH)))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(t.profile.goal_nutrition_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 8),
            IntrinsicHeight( 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: IconMiniCard(title: t.profile.goal_gain_weight, icon: Symbols.trending_up, isSelected: _draft.nutritionGoal == NutritionGoal.GAIN_WEIGHT, onTap: () => setState(() => _draft = _draft.copyWith(nutritionGoal: NutritionGoal.GAIN_WEIGHT)))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: IconMiniCard(title: t.profile.goal_lose_weight, icon: Symbols.trending_down, isSelected: _draft.nutritionGoal == NutritionGoal.LOSE_WEIGHT, onTap: () => setState(() => _draft = _draft.copyWith(nutritionGoal: NutritionGoal.LOSE_WEIGHT)))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: IconMiniCard(title: t.profile.goal_maintain_weight, icon: Symbols.trending_flat, isSelected: _draft.nutritionGoal == NutritionGoal.MAINTAIN_WEIGHT, onTap: () => setState(() => _draft = _draft.copyWith(nutritionGoal: NutritionGoal.MAINTAIN_WEIGHT)))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _handleStep3Submit,
              child: Text(t.common.next, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        );

      case 4:
        return Column(
          key: const ValueKey('step4'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.profile.activity_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: IconMiniCard(title: t.profile.activity_sedentary, icon: Symbols.airline_seat_recline_normal, isSelected: _draft.activityLevel == ActivityLevel.SEDENTARY, onTap: () => setState(() => _draft = _draft.copyWith(activityLevel: ActivityLevel.SEDENTARY)))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: IconMiniCard(title: t.profile.activity_light, icon: Symbols.directions_walk, isSelected: _draft.activityLevel == ActivityLevel.LIGHT, onTap: () => setState(() => _draft = _draft.copyWith(activityLevel: ActivityLevel.LIGHT)))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: IconMiniCard(title: t.profile.activity_moderate, icon: Symbols.directions_run, isSelected: _draft.activityLevel == ActivityLevel.MODERATE, onTap: () => setState(() => _draft = _draft.copyWith(activityLevel: ActivityLevel.MODERATE)))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: IconMiniCard(title: t.profile.activity_active, icon: Symbols.sprint, isSelected: _draft.activityLevel == ActivityLevel.ACTIVE, onTap: () => setState(() => _draft = _draft.copyWith(activityLevel: ActivityLevel.ACTIVE)))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(t.profile.level_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: IconMiniCard(title: t.profile.level_newbie, icon: Symbols.star_border, isSelected: _draft.experience == "profile.level_newbie", onTap: () => setState(() => _draft = _draft.copyWith(experience: "profile.level_newbie")))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: IconMiniCard(title: t.profile.level_intermediate, icon: Symbols.star_half, isSelected: _draft.experience == "profile.level_intermediate", onTap: () => setState(() => _draft = _draft.copyWith(experience: "profile.level_intermediate")))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: IconMiniCard(title: t.profile.level_advanced, icon: Symbols.star, isSelected: _draft.experience == "profile.level_advanced", onTap: () => setState(() => _draft = _draft.copyWith(experience: "profile.level_advanced")))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _handleStep4Submit,
              child: Text(t.common.next, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        );

      case 5:
        return StatefulBuilder(
          key: const ValueKey('step5'),
          builder: (context, setLocalState) {
            double tw = double.tryParse(_draft.targetWeight) ?? parsedWeight;

            double minW = 30.0;
            double maxW = 650.0;
            
            if (_draft.nutritionGoal == NutritionGoal.LOSE_WEIGHT) {
               maxW = parsedWeight - 0.5;
               if (tw > maxW) tw = maxW;
            } else if (_draft.nutritionGoal == NutritionGoal.GAIN_WEIGHT) {
               minW = parsedWeight + 0.5;
               if (tw < minW) tw = minW;
            }

            if (tw.toStringAsFixed(1) != _draft.targetWeight) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 setState(() => _draft = _draft.copyWith(targetWeight: tw.toStringAsFixed(1)));
                 _targetWeightNotifier.value = tw; 
               });
            }

            int currentMinDays = _calcMinDays(tw);
            
            int baseDays = ((tw - parsedWeight).abs() / 0.5 * 7).round();
            if (baseDays == 0) baseDays = 1;
            
            int fastDays = max(1, currentMinDays);
            int normalDays = baseDays <= currentMinDays ? (currentMinDays * 1.5).round() : baseDays;
            int relaxedDays = (normalDays * 1.5).round();

            int savedDays = int.tryParse(_draft.targetDays) ?? 0;
            

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.profile.target_weight, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                const SizedBox(height: 24),
                
                GestureDetector(
                  onTap: () {
                    showManualWeightInputDialog(context, tw, minW, maxW, (newWeight) {
                      setLocalState(() => _draft = _draft.copyWith(targetWeight: newWeight.toStringAsFixed(1)));
                      _targetWeightNotifier.value = newWeight; 
                    });
                  },
                  child: Text(
                    '${tw.toStringAsFixed(1)} kg', 
                    style: TextStyle(color: Theme.of(context).gymColors.success, fontSize: ResponsiveValue<double>(context, defaultValue: 42.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 36.0)]).value, fontWeight: FontWeight.bold), 
                    textAlign: TextAlign.center
                  ),
                ),
                const SizedBox(height: 16),
                
                WeightRulerPicker(
                  value: tw, minWeight: minW, maxWeight: maxW,
                  onChanged: (val) {
                    setLocalState(() => _draft = _draft.copyWith(targetWeight: val.toStringAsFixed(1)));
                    _targetWeightNotifier.value = val; 
                  },
                ),
                const SizedBox(height: 32),
                
                Text(t.profile.target_pace, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                const SizedBox(height: 16),
                
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: ResponsiveValue<double>(context, defaultValue: 16.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 8.0)]).value,
                    mainAxisSpacing: ResponsiveValue<double>(context, defaultValue: 16.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 8.0)]).value,
                    mainAxisExtent: ResponsiveValue<double>(context, defaultValue: 90.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 105.0)]).value, 
                  ),
                  children: [
                    PaceCard(
                      title: t.profile.pace_fast,
                      subtitle: DateFormat('dd/MM/yy').format(DateTime.now().add(Duration(days: fastDays))),
                      isSelected: _draft.paceType == 'fast', 
                      isSubtitlePrimary: true,
                      onTap: () => _handleStep5Submit(tw, fastDays, 'fast')
                    ),
                    PaceCard(
                      title: t.profile.pace_normal,
                      subtitle: DateFormat('dd/MM/yy').format(DateTime.now().add(Duration(days: normalDays))),
                      isSelected: _draft.paceType == 'normal',
                      isSubtitlePrimary: true,
                      onTap: () => _handleStep5Submit(tw, normalDays, 'normal')
                    ),
                    PaceCard(
                      title: t.profile.pace_relaxed,
                      subtitle: DateFormat('dd/MM/yy').format(DateTime.now().add(Duration(days: relaxedDays))),
                      isSelected: _draft.paceType == 'relaxed',
                      isSubtitlePrimary: true,
                      onTap: () => _handleStep5Submit(tw, relaxedDays, 'relaxed')
                    ),
                    PaceCard(
                      topIcon: Symbols.calendar_month,
                      subtitle: _draft.paceType == 'custom' 
                          ? DateFormat('dd/MM/yy').format(DateTime.now().add(Duration(days: savedDays)))
                          : t.onboarding.label_select_date,
                      isSelected: _draft.paceType == 'custom',
                      isSubtitlePrimary: _draft.paceType == 'custom', 
                      onTap: () async {
                        DateTime now = DateTime.now();
                        DateTime todayMidnight = DateTime(now.year, now.month, now.day);
                        
                        DateTime? picked = await showDatePicker(
                          context: context, 
                          initialDate: todayMidnight.add(Duration(days: _draft.paceType == 'custom' ? savedDays : normalDays)),
                          firstDate: todayMidnight.add(Duration(days: fastDays)), 
                          lastDate: todayMidnight.add(const Duration(days: 1000)),
                        );
                        if (picked != null) {
                          int customDays = picked.difference(todayMidnight).inDays;
                          _handleStep5Submit(tw, customDays, 'custom');
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          }
        );

      case 6: 
        return Column(
          key: const ValueKey('step6'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.profile.env_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: VisualChoiceCard(title: t.profile.env_gym, icon: Symbols.domain, isSelected: _draft.environment == WorkoutEnvironment.GYM, onTap: () => setState(() => _draft = _draft.environment == WorkoutEnvironment.GYM ? _draft : _draft.copyWith(environment: WorkoutEnvironment.GYM)))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: VisualChoiceCard(title: t.profile.env_home_dumbbell, icon: Symbols.exercise, isSelected: _draft.environment == WorkoutEnvironment.HOME_DUMBBELL, onTap: () => setState(() => _draft = _draft.environment == WorkoutEnvironment.HOME_DUMBBELL ? _draft : _draft.copyWith(environment: WorkoutEnvironment.HOME_DUMBBELL)))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: VisualChoiceCard(title: t.profile.env_home_bodyweight, icon: Symbols.home, isSelected: _draft.environment == WorkoutEnvironment.HOME_BODYWEIGHT, onTap: () => setState(() => _draft = _draft.environment == WorkoutEnvironment.HOME_BODYWEIGHT ? _draft : _draft.copyWith(environment: WorkoutEnvironment.HOME_BODYWEIGHT)))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(t.profile.freq_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: IconMiniCard(title: t.profile.freq_low, icon: Symbols.signal_cellular_alt_1_bar, isSelected: _draft.trainingFreq == "1-3", onTap: () => setState(() => _draft = _draft.copyWith(trainingFreq: "1-3")))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: IconMiniCard(title: t.profile.freq_mid, icon: Symbols.signal_cellular_alt_2_bar, isSelected: _draft.trainingFreq == "3-5", onTap: () => setState(() => _draft = _draft.copyWith(trainingFreq: "3-5")))),
                  SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                  Expanded(child: IconMiniCard(title: t.profile.freq_high, icon: Symbols.signal_cellular_alt, isSelected: _draft.trainingFreq == "5-7", onTap: () => setState(() => _draft = _draft.copyWith(trainingFreq: "5-7")))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _handleStep6Submit,
              child: Text(t.common.next, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        );

      case 7: 
        final injuriesKeys = ["common.none", "profile.injury_knee", "profile.injury_back", "profile.injury_shoulder", "profile.injury_cardio", "profile.injury_blood_pressure", "profile.injury_diabetes", "profile.injury_cholesterol", "common.other"];
        final dietsKeys = ["common.none", "profile.diet_vegetarian", "profile.diet_vegan", "profile.diet_gluten", "profile.diet_peanut", "profile.diet_dairy", "profile.diet_meat", "common.other"];
        
        // [UI/UX FIX]: Phân biệt "Edit Mode" và "Initial Display"
        final bool isEditMode = _currentStep < _maxStepReached;
        final bool useVerticalLayout = isEditMode && ResponsiveBreakpoints.of(context).smallerThan(TABLET);

        // Sub-widget Chấn thương
        Widget buildInjuries() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.profile.injury_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: injuriesKeys.map((key) => GymMultiSelectChip(
                  label: t.translateDynamic(key), isSelected: _draft.injuries.contains(key),
                  onTap: () {
                    bool isSelectingOther = key == "common.other" && !_draft.injuries.contains("common.other");
                    setState(() => _draft = _draft.copyWith(injuries: _toggleSetOption(_draft.injuries, key)));
                    if (isSelectingOther) {
                      Future.delayed(const Duration(milliseconds: 100), () => _otherInjuryFocus.requestFocus());
                    }
                  }
                )).toList(),
              ),
              if (_draft.injuries.contains("common.other"))
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GymShakeWrapper(
                        hasError: _injuryError != null,
                        child: TextField(
                          controller: _otherInjuryCtrl, 
                          focusNode: _otherInjuryFocus,
                          onChanged: (_) => setState(() => _injuryError = null),
                          decoration: InputDecoration(
                            hintText: t.onboarding.hint_injury_other, 
                            isDense: true,
                            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                            error: buildErrorWidget(_injuryError, colorScheme),
                          )
                        ),
                      ),
                    ],
                  ),
                )
            ],
          );
        }

        // Sub-widget Chế độ ăn uống
        Widget buildDiets() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.profile.diet_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: dietsKeys.map((key) => GymMultiSelectChip(
                  label: t.translateDynamic(key), isSelected: _draft.dietary.contains(key),
                  onTap: () {
                    bool isSelectingOther = key == "common.other" && !_draft.dietary.contains("common.other");
                    setState(() => _draft = _draft.copyWith(dietary: _toggleSetOption(_draft.dietary, key)));
                    if (isSelectingOther) {
                      Future.delayed(const Duration(milliseconds: 100), () => _otherDietFocus.requestFocus());
                    }
                  }
                )).toList(),
              ),
              if (_draft.dietary.contains("common.other"))
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GymShakeWrapper(
                        hasError: _dietError != null,
                        child: TextField(
                          controller: _otherDietCtrl, 
                          focusNode: _otherDietFocus,
                          onChanged: (_) => setState(() => _dietError = null),
                          decoration: InputDecoration(
                            hintText: t.onboarding.hint_diet_other, 
                            isDense: true,
                            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                            error: buildErrorWidget(_dietError, colorScheme),
                          )
                        ),
                      ),
                    ],
                  ),
                )
            ],
          );
        }

        return Column(
          key: const ValueKey('step7'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (useVerticalLayout) ...[
              // Giao diện EDIT: Xếp dọc nếu là màn hình nhỏ
              buildInjuries(),
              const SizedBox(height: 24),
              buildDiets(),
            ] else ...[
              // Giao diện LẦN ĐẦU / TABLET: Ép buộc chia đôi màn hình 50/50
              ConstrainedBox(
                constraints: BoxConstraints(
                  // Giới hạn chiều cao độc lập cho danh sách cuộn, chừa chỗ cho nút Xong
                  maxHeight: ResponsiveValue<double>(context, defaultValue: 300.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 240.0)]).value
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _injuryScrollCtrl,
                        child: buildInjuries(),
                      ),
                    ),
                    SizedBox(width: ResponsiveValue<double>(context, defaultValue: 12.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 8.0)]).value),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _dietScrollCtrl,
                        child: buildDiets(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Nút "Xong" được đẩy ra NGOÀI ConstrainedBox để vĩnh viễn không bị đè
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _handleStep7Submit,
              child: Text(t.common.done, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSummaryCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final finalProgram = _getRealtimeRecommendedProgram();
    final finalMacros = _getRealtimeMacros(); 

    return Card(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3))),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.onboarding.title_step_target, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text("${finalMacros.calories.toInt()}", style: TextStyle(fontSize: ResponsiveValue<double>(context, defaultValue: 32.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 28.0)]).value, fontWeight: FontWeight.w900, color: colorScheme.primary, height: 1.0)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 8),
                  child: Text(t.onboarding.label_kcal_day, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: MacroItem(label: t.onboarding.label_macro_protein, value: "${finalMacros.protein.toInt()}g", color: Theme.of(context).gymColors.fireHexagon)),
                SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                Expanded(child: MacroItem(label: t.onboarding.label_macro_carbs, value: "${finalMacros.carbs.toInt()}g", color: Theme.of(context).gymColors.success)),
                SizedBox(width: ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value),
                Expanded(child: MacroItem(label: t.onboarding.label_macro_fat, value: "${finalMacros.fat.toInt()}g", color: Theme.of(context).gymColors.goldRank)),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
            Text(t.onboarding.title_program_ready, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                  child: Icon(Symbols.auto_awesome, color: colorScheme.onPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    finalProgram != null ? t.translateDynamic(finalProgram.name) : t.onboarding.name_custom_program, 
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: ResponsiveValue<double>(context, defaultValue: 16.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 14.0)]).value),
                    maxLines: 2,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

