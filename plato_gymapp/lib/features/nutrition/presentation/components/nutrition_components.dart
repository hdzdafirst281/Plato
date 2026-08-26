import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_countdown_text.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_bar.dart';
import 'package:plato_gymapp/core/designsystem/theme/colors.dart';
import 'package:plato_gymapp/features/nutrition/domain/nutrition_calculator.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_shake_wrapper.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../../../core/designsystem/theme/app_theme.dart';
import '../../../../core/database/enums.dart';

import '../../../auth/data/models/user_models.dart';
import '../../data/models/nutrition_models.dart';

// Helper: Format bỏ số 0 vô nghĩa
String _formatDouble(double value, {int decimals = 1}) {
  if (value % 1 == 0) return value.toInt().toString();
  String formatted = value.toStringAsFixed(decimals);
  if (formatted.contains('.')) {
    formatted = formatted
        .replaceAll(RegExp(r'0*$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
  return formatted;
}

// ========================================================
// 0. UNIFIED DIALOG SYSTEM
// ========================================================

// ========================================================
// 1. CÁC COMPONENT CƠ BẢN VÀ ANIMATION
// ========================================================

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final int delayIndex;

  const FadeInSlide({super.key, required this.child, this.delayIndex = 0});

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 100 * widget.delayIndex), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class GymTextField extends StatefulWidget {
  final String initialValue;
  final String unitText;
  final String labelText;
  final String? errorText;
  final Function(String) onChanged;
  final bool isNumber;
  final bool isInteger;

  const GymTextField({
    super.key,
    required this.initialValue,
    this.unitText = "",
    required this.labelText,
    this.errorText,
    required this.onChanged,
    this.isNumber = true,
    this.isInteger = false,
  });

  @override
  State<GymTextField> createState() => _GymTextFieldState();
}

class _GymTextFieldState extends State<GymTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant GymTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GymShakeWrapper(
      hasError: widget.errorText != null && widget.errorText!.isNotEmpty,
      child: TextFormField(
        controller: _controller,
        keyboardType: widget.isNumber
            ? (widget.isInteger
                  ? const TextInputType.numberWithOptions(decimal: false)
                  : const TextInputType.numberWithOptions(decimal: true))
            : TextInputType.text,
        inputFormatters: widget.isNumber
            ? (widget.isInteger
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])
            : [],
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
  
          error: (widget.errorText != null && widget.errorText!.isNotEmpty)
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
                            color: colorScheme.error,
                            size: 14,
                          ),
                        ),
                      ),
                      TextSpan(text: widget.errorText!),
                    ],
                  ),
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                )
              : null,
        errorMaxLines: 3,

        suffixText: widget.unitText,
        suffixStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
        filled: true,
        fillColor: colorScheme.surface, // Đã đổi nền thành surface theo yêu cầu
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      onChanged: widget.onChanged,
    ));
  }
}

class UniversalFoodStepper extends StatelessWidget {
  final double consumedAmount;
  final FoodUnit unit;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<double>? onManualInput;
  final String? Function(double)? validator;

  const UniversalFoodStepper({
    super.key,
    required this.consumedAmount,
    required this.unit,
    required this.onDecrease,
    required this.onIncrease,
    this.onManualInput,
    this.validator,
  });

  bool get _isScale => unit == FoodUnit.GRAM || unit == FoodUnit.ML;

  String get _displayValue {
    double val = _isScale ? consumedAmount * 100 : consumedAmount;
    if (val % 1 == 0) return val.toInt().toString();
    String formatted = val.toStringAsFixed(1);
    if (formatted.contains('.')) {
      formatted = formatted
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    return formatted;
  }

  String get _suffix {
    switch (unit) {
      case FoodUnit.GRAM:
        return t.nutrition.label_unit_gram;
      case FoodUnit.ML:
        return t.nutrition.label_unit_ml;
      case FoodUnit.QUANTITY:
        return t.nutrition.label_unit_quantity;
      case FoodUnit.SERVING:
        return t.nutrition.label_unit_serving;
      case FoodUnit.OZ:
        return t.nutrition.label_unit_oz;
      
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContinuousActionWrapper(
              onAction: onDecrease,
              child: InkWell(
                onTap: onDecrease,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Symbols.remove,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onManualInput != null
                  ? () => _showInputDialog(context)
                  : null,
              child: Container(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "$_displayValue $_suffix",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                    decoration: onManualInput != null
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
              ),
            ),

            ContinuousActionWrapper(
              onAction: onIncrease,
              child: InkWell(
                onTap: onIncrease,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Symbols.add,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    final TextEditingController ctrl = TextEditingController(
      text: _displayValue,
    );
    final errorNotifier = ValueNotifier<String?>(null);

    void validateRealTime(String v) {
      final val = double.tryParse(v);
      if (val == null) {
        errorNotifier.value = t.nutrition.error_invalid_number;
        return;
      }

      if (_isScale) {
        if (val < 1 || val > 5000) {
          errorNotifier.value = t.nutrition.err_portion_scale;
          return;
        }
      } else {
        if (val < 0.01 || val > 100) {
          errorNotifier.value = t.nutrition.err_portion_qty;
          return;
        }
      }

      double finalAmount = _isScale ? val / 100 : val;
      if (validator != null) {
        errorNotifier.value = validator!(finalAmount);
      } else {
        errorNotifier.value = null;
      }
    }

    GymDialog.showCustom(
      context: context,
      titleWidget: Text(
        "${t.nutrition.title_input_amount} ($_suffix)",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: ValueListenableBuilder<String?>(
        valueListenable: errorNotifier,
        builder: (context, errorMsg, child) {
          return TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            onChanged: validateRealTime,
            decoration: InputDecoration(
              suffixText: _suffix,
              error: errorMsg != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Symbols.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            errorMsg,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
              errorMaxLines: 3,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorMsg != null
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            t.common.cancel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: errorNotifier,
          builder: (context, errorMsg, child) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: errorMsg != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: errorMsg != null
                  ? null
                  : () {
                      final val = double.tryParse(ctrl.text);
                      if (val != null) {
                        onManualInput!(_isScale ? val / 100 : val);
                        Navigator.pop(context);
                      }
                    },
              child: Text(t.common.confirm),
            );
          },
        ),
      ],
    );
  }
}

// ========================================================
// 2. DASHBOARD, CHARTS VÀ TRACKER
// ========================================================

class MacroText extends StatelessWidget {
  final int? calories;
  final int protein;
  final int carbs;
  final int fat;
  final String? unitSuffix;
  final TextStyle? baseStyle;

  const MacroText({
    super.key,
    this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.unitSuffix,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;

    final colorP = gymColors.fireHexagon;
    final colorC = gymColors.success;
    final colorF = gymColors.goldRank;

    final defaultStyle = TextStyle(
      fontSize: 12,
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final textStyle = baseStyle ?? defaultStyle;

    return Wrap(
      spacing: 4.0,
      runSpacing: 2.0,
      children: [
        if (calories != null) ...[
          Text(
            t.nutrition.format_kcal(arg1: calories.toString()),
            style: textStyle,
          ),
          Text('|', style: textStyle),
        ],
        Text(
          t.nutrition.format_macro_p(arg1: protein.toString()),
          style: textStyle.copyWith(color: colorP),
        ),
        Text('•', style: textStyle),
        Text(
          t.nutrition.format_macro_c(arg1: carbs.toString()),
          style: textStyle.copyWith(color: colorC),
        ),
        Text('•', style: textStyle),
        Text(
          t.nutrition.format_macro_f(arg1: fat.toString()),
          style: textStyle.copyWith(color: colorF),
        ),
        if (unitSuffix != null) Text(unitSuffix!, style: textStyle),
      ],
    );
  }
}

// ========================================================
// NutritionDashboard
// ========================================================
class NutritionDashboard extends StatelessWidget {
  final DailyNutrition currentDaily;
  final Macros targetMacros;
  final bool isCustomMacros;
  final Function(Macros)? onEditMacros;
  final VoidCallback? onRevertSystem;

  const NutritionDashboard({
    super.key,
    required this.currentDaily,
    required this.targetMacros,
    this.isCustomMacros = false,
    this.onEditMacros,
    this.onRevertSystem,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;

    final consumedCal = currentDaily.dailyTotalCalories;
    final targetCal = targetMacros.calories;
    final calProgress = targetCal > 0
        ? (consumedCal / targetCal).clamp(0.0, 1.0)
        : 0.0;

    final isOver = consumedCal > targetCal;
    final calColor = isOver ? colorScheme.error : colorScheme.primary;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientStart = isDark ? nutritionBgStartDark : nutritionBgStartLight;
    final gradientEnd = isDark ? nutritionBgEndDark : nutritionBgEndLight;

    final responsivePadding = ResponsiveValue<double>(
      context,
      defaultValue: 16.0,
      conditionalValues: [Condition.smallerThan(name: MOBILE, value: 12.0)],
    ).value;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEditMacros != null
              ? () => _showEditMacrosDialog(
                  context,
                  targetMacros,
                  onEditMacros!,
                  onRevertSystem,
                )
              : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(responsivePadding),
            child: Builder(
              builder: (context) {
                final isTablet = ResponsiveBreakpoints.of(
                  context,
                ).largerThan(MOBILE);

                // 1. Tách riêng Badge Widget để tái sử dụng linh hoạt
                final badgeWidget = Container(
                  decoration: BoxDecoration(
                    color: isCustomMacros
                        ? gymColors.goldRank.withValues(alpha: 0.15)
                        : colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCustomMacros
                          ? gymColors.goldRank.withValues(alpha: 0.6)
                          : colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCustomMacros ? Symbols.tune : Symbols.auto_awesome,
                        size: 16,
                        color: isCustomMacros
                            ? gymColors.goldRank
                            : colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCustomMacros
                            ? t.nutrition.label_dashboard_custom.toUpperCase()
                            : t.nutrition.label_dashboard_system.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCustomMacros
                              ? gymColors.goldRank
                              : colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );

                // 2. Khối Vòng Calo & Text
                final ringAndText = [
                  Center(
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 6,
                              color: gymColors.nutritionEmpty,
                            ),
                          ),
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: calProgress),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  CircularProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.transparent,
                                    color: calColor,
                                    strokeWidth: 6,
                                    strokeCap: StrokeCap.round,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: calColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Symbols.bolt,
                              color: calColor,
                              size: 28,
                              fill: isOver ? 1.0 : 0.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.nutrition.label_consumed_vs_target,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          consumedCal.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          t.nutrition.format_dashboard_calories_suffix(
                            arg1: targetCal.toString(),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];

                // 3. Khối 3 thanh Macros
                final macrosRows = [
                  _MacroRow(
                    label: t.onboarding.label_macro_protein,
                    current: currentDaily.dailyTotalProtein,
                    target: targetMacros.protein,
                    color: gymColors.fireHexagon,
                  ),
                  const SizedBox(height: 12),
                  _MacroRow(
                    label: t.onboarding.label_macro_carbs,
                    current: currentDaily.dailyTotalCarbs,
                    target: targetMacros.carbs,
                    color: gymColors.success,
                  ),
                  const SizedBox(height: 12),
                  _MacroRow(
                    label: t.onboarding.label_macro_fat,
                    current: currentDaily.dailyTotalFat,
                    target: targetMacros.fat,
                    color: gymColors.goldRank,
                  ),
                ];

                // BỐ CỤC TABLET: Đẩy Badge sang phải
                if (isTablet) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Canh giữa cột vòng Calo
                          children: ringAndText,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child:
                                  badgeWidget, // Nhét badge lên góc phải của cột Macros
                            ),
                            const SizedBox(height: 12),
                            ...macrosRows,
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // BỐ CỤC MOBILE: Giữ nguyên trạng thái cũ
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...ringAndText,
                        const SizedBox(height: 12),
                        badgeWidget, // Trả badge về dưới Calo khi ở Mobile
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: macrosRows,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showEditMacrosDialog(
    BuildContext context,
    Macros currentTarget,
    Function(Macros) onSave,
    VoidCallback? onRevert,
  ) {
    final calCtrl = TextEditingController(
      text: currentTarget.calories.toString(),
    );
    final proCtrl = TextEditingController(
      text: currentTarget.protein.toString(),
    );
    final carbCtrl = TextEditingController(
      text: currentTarget.carbs.toString(),
    );
    final fatCtrl = TextEditingController(text: currentTarget.fat.toString());

    String? calError;
    String? proError;
    String? carbError;
    String? fatError;
    String? generalWarning;
    bool isSoftWarningConfirmed = false;

    GymDialog.showCustom(
      context: context,
      titleWidget: Text(
        t.nutrition.title_custom_macros,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      content: StatefulBuilder(
        builder: (context, setLocalState) {
          void clearErrors() {
            if (calError != null ||
                proError != null ||
                carbError != null ||
                fatError != null ||
                generalWarning != null) {
              setLocalState(() {
                calError = null;
                proError = null;
                carbError = null;
                fatError = null;
                generalWarning = null;
                isSoftWarningConfirmed = false;
              });
            }
          }

          Widget buildField(
            TextEditingController ctrl,
            String label,
            String unit,
            String? error,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GymTextField(
                initialValue: ctrl.text,
                labelText: label,
                unitText: unit,
                isInteger: true,
                errorText: error,
                onChanged: (v) {
                  ctrl.text = v;
                  clearErrors();
                },
              ),
            );
          }

          final colorScheme = Theme.of(context).colorScheme;
          final dialogWidth = ResponsiveValue<double>(
            context,
            defaultValue: 400.0,
            conditionalValues: [
              Condition.smallerThan(
                name: TABLET,
                value: MediaQuery.sizeOf(context).width,
              ),
            ],
          ).value;

          return SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (generalWarning != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).gymColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).gymColors.warning.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Symbols.warning_amber_rounded,
                          color: Theme.of(context).gymColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            generalWarning!,
                            style: TextStyle(
                              color: Theme.of(context).gymColors.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                buildField(
                  calCtrl,
                  t.nutrition.label_dashboard_calories,
                  'kcal',
                  calError,
                ),
                buildField(
                  proCtrl,
                  t.onboarding.label_macro_protein,
                  'g',
                  proError,
                ),
                buildField(
                  carbCtrl,
                  t.onboarding.label_macro_carbs,
                  'g',
                  carbError,
                ),
                buildField(fatCtrl, t.onboarding.label_macro_fat, 'g', fatError),

                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final double btnTextSize = ResponsiveValue<double>(
                      context,
                      defaultValue: 14.0,
                      conditionalValues: [
                        Condition.smallerThan(name: TABLET, value: 12.0),
                      ],
                    ).value;
                    final double btnIconSize = ResponsiveValue<double>(
                      context,
                      defaultValue: 18.0,
                      conditionalValues: [
                        Condition.smallerThan(name: TABLET, value: 16.0),
                      ],
                    ).value;
                    final double btnPadding = ResponsiveValue<double>(
                      context,
                      defaultValue: 16.0,
                      conditionalValues: [
                        Condition.smallerThan(name: TABLET, value: 12.0),
                      ],
                    ).value;
                    final double systemBtnPadding = ResponsiveValue<double>(
                      context,
                      defaultValue: 8.0,
                      conditionalValues: [
                        Condition.smallerThan(name: TABLET, value: 4.0),
                      ],
                    ).value;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (isCustomMacros && onRevert != null)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.only(
                                        right: systemBtnPadding,
                                        top: 8,
                                        bottom: 8,
                                      ),
                                    ),
                                    onPressed: () {
                                      onRevert();
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(
                                      Symbols.settings_backup_restore,
                                      size: btnIconSize,
                                      color: colorScheme.primary,
                                    ),
                                    label: Text(
                                      t.settings.btn_theme_system,
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: btnTextSize - 1,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: systemBtnPadding,
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        t.common.cancel,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                          fontSize: btnTextSize,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: btnPadding,
                                        ),
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        final cal =
                                            int.tryParse(calCtrl.text) ?? 0;
                                        final p =
                                            int.tryParse(proCtrl.text) ?? 0;
                                        final c =
                                            int.tryParse(carbCtrl.text) ?? 0;
                                        final f =
                                            int.tryParse(fatCtrl.text) ?? 0;

                                        bool hasValidationError = false;

                                        if (cal < 500 || cal > 20000) {
                                          calError =
                                              t.nutrition.err_macro_cal_target;
                                          hasValidationError = true;
                                        }
                                        if (p < 0 || p > 1000) {
                                          proError =
                                              t.nutrition.err_macro_pcf_target;
                                          hasValidationError = true;
                                        }
                                        if (c < 0 || c > 1000) {
                                          carbError =
                                              t.nutrition.err_macro_pcf_target;
                                          hasValidationError = true;
                                        }
                                        if (f < 0 || f > 1000) {
                                          fatError =
                                              t.nutrition.err_macro_pcf_target;
                                          hasValidationError = true;
                                        }

                                        if (hasValidationError) {
                                          setLocalState(() {});
                                          return;
                                        }

                                        int calculatedCal =
                                            (p * 4) + (c * 4) + (f * 9);
                                        double diff = cal > 0
                                            ? (calculatedCal - cal).abs() / cal
                                            : 0;

                                        if (diff > 0.20 &&
                                            !isSoftWarningConfirmed) {
                                          setLocalState(() {
                                            generalWarning = t
                                                .nutrition
                                                .err_macro_warning_target;
                                            isSoftWarningConfirmed = true;
                                          });
                                          return;
                                        }

                                        onSave(
                                          Macros(
                                            calories: cal,
                                            protein: p,
                                            carbs: c,
                                            fat: f,
                                          ),
                                        );
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        t.common.save,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: btnTextSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      actions: [],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isOver = current > target;
    final displayColor = isOver ? colorScheme.error : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: displayColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              t.nutrition.format_macro_ratio(
                arg1: current.toString(),
                arg2: target.toString(),
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: displayColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
            color: displayColor,
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

// ========================================================
// WaterTrackerCard
// ========================================================
class WaterTrackerCard extends StatelessWidget {
  final double currentLiters;
  final double targetLiters;
  final VoidCallback onAddWater;
  final VoidCallback onRemoveWater;
  final VoidCallback onTapCard;

  const WaterTrackerCard({
    super.key,
    required this.currentLiters,
    this.targetLiters = 2.5,
    required this.onAddWater,
    required this.onRemoveWater,
    required this.onTapCard,
  });

  String _formatDouble(double value, {int decimals = 1}) {
    return value
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
  }

  @override
  Widget build(BuildContext context) {
    final gymColors = Theme.of(context).gymColors;

    final Color accentBlue = gymColors.waterAccent;
    final Color emptyDropColor = gymColors.waterEmptyDrop;
    final Color emptyIconColor = accentBlue.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.5,
    );

    final int totalDrops = (targetLiters / 0.25).ceil();
    final int filledDrops = (currentLiters / 0.25).floor();
    final double progress = (currentLiters / targetLiters).clamp(0.0, 1.0);

    final bool isGoalReached = progress >= 1.0;

    final responsivePadding = ResponsiveValue<double>(
      context,
      defaultValue: 16.0,
      conditionalValues: [Condition.smallerThan(name: MOBILE, value: 12.0)],
    ).value;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gymColors.waterBgStart, gymColors.waterBgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapCard,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(responsivePadding),
            child: Builder(
              builder: (context) {
                final isTablet = ResponsiveBreakpoints.of(
                  context,
                ).largerThan(MOBILE);

                final waterInfoSection = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: isTablet
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 6,
                                color: emptyDropColor,
                              ),
                            ),
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) =>
                                    CircularProgressIndicator(
                                      value: value,
                                      backgroundColor: Colors.transparent,
                                      color: accentBlue,
                                      strokeWidth: 6,
                                      strokeCap: StrokeCap.round,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accentBlue.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Symbols.water_drop,
                                color: accentBlue,
                                size: 28,
                                fill: isGoalReached ? 1.0 : 0.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: isTablet
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.nutrition.title_water_tracker,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentBlue.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _formatDouble(currentLiters, decimals: 2),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: accentBlue,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                t.nutrition.format_water_target_suffix(
                                  arg1: _formatDouble(
                                    targetLiters,
                                    decimals: 2,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: accentBlue.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                final actionSection = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: List.generate(math.min(20, totalDrops), (
                        index,
                      ) {
                        final isFilled = index < filledDrops;
                        return Icon(
                          Symbols.water_drop,
                          size: 16,
                          color: isFilled ? accentBlue : emptyIconColor,
                          fill: isFilled ? 1.0 : 0.0,
                        );
                      }),
                    ),
                    if (!isTablet) const Spacer(),
                    if (isTablet) const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: emptyDropColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ContinuousActionWrapper(
                                onAction: onRemoveWater,
                                enabled: currentLiters > 0,
                                child: InkWell(
                                  onTap: onRemoveWater,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Center(
                                    child: Icon(
                                      Symbols.remove,
                                      color: accentBlue,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: accentBlue,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: accentBlue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ContinuousActionWrapper(
                                onAction: onAddWater,
                                child: InkWell(
                                  onTap: onAddWater,
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Center(
                                    child: Icon(
                                      Symbols.add,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                if (isTablet) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 4, child: waterInfoSection),
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: actionSection),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    waterInfoSection,
                    const SizedBox(height: 12),
                    Expanded(child: actionSection),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================================
// [NEW COMPONENT]: Pure Behavior Wrapper (Không dính dáng tới UI)
// ========================================================
class ContinuousActionWrapper extends StatefulWidget {
  final VoidCallback onAction;
  final Widget child;
  final bool enabled;

  const ContinuousActionWrapper({
    super.key,
    required this.onAction,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ContinuousActionWrapper> createState() =>
      _ContinuousActionWrapperState();
}

class _ContinuousActionWrapperState extends State<ContinuousActionWrapper> {
  Timer? _initialDelayTimer;
  Timer? _periodicTimer;

  void _startTimer() {
    if (!widget.enabled) return;
    // Delay 300ms để không đụng chạm với tap bình thường
    _initialDelayTimer = Timer(const Duration(milliseconds: 300), () {
      _periodicTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        if (!widget.enabled) {
          _stopTimer();
          return;
        }
        widget.onAction();
        HapticFeedback.heavyImpact(); // [UX] Rung nhẹ phản hồi
      });
    });
  }

  void _stopTimer() {
    _initialDelayTimer?.cancel();
    _periodicTimer?.cancel();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startTimer(),
      onLongPressEnd: (_) => _stopTimer(),
      onLongPressCancel: () => _stopTimer(),
      behavior: HitTestBehavior.deferToChild,
      child: widget.child,
    );
  }
}

// ========================================================
// WeightGoalChartCard
// ========================================================
class WeightGoalChartCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onUpdateWeight;
  final VoidCallback onEditGoal;

  const WeightGoalChartCard({
    super.key,
    required this.profile,
    required this.onUpdateWeight,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;

    // [ÉP KÍCH THƯỚC TABLET]: Tối ưu hóa cực hạn mọi khoảng trống dọc
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final double paddingVal = isTablet ? 16.0 : 20.0;
    final double chartHeight = isTablet ? 50.0 : 90.0; // Biểu đồ ép xuống 40
    final double spaceHeader = isTablet ? 12.0 : 20.0;
    final double spaceChart = isTablet ? 12.0 : 16.0;
    final double spaceFooter = isTablet ? 12.0 : 20.0;
    final double btnHeight = isTablet ? 42.0 : 50.0; // Nút nhấn thu hẹp

    final currentWt = profile.weightInKg;
    final targetWt = profile.targetGoalWeightKg ?? currentWt;
    final baseWt = profile.startingWeightKg ?? currentWt;

    final isMaintain = currentWt == targetWt;
    final isCut = targetWt < currentWt;

    final trendColor = isMaintain
        ? gymColors.goldRank
        : (isCut ? colorScheme.error : gymColors.success);
    final iconData = isMaintain
        ? Symbols.trending_flat
        : (isCut ? Symbols.trending_down : Symbols.trending_up);
    final titleLabel = isMaintain
        ? t.profile.goal_maintain_weight
        : (isCut ? t.profile.goal_lose_weight : t.profile.goal_gain_weight);

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final startMillis = profile.goalStartTimestampMillis ?? nowMillis;

    int endMillis = nowMillis + 86400000;
    if (profile.weeklyGoalRate != null &&
        profile.weeklyGoalRate! > 0 &&
        !isMaintain) {
      final totalGap = (targetWt - baseWt).abs();
      if (totalGap > 0) {
        final totalWeeks = totalGap / profile.weeklyGoalRate!;
        endMillis =
            startMillis + (totalWeeks * 7 * 24 * 60 * 60 * 1000).toInt();
      } else {
        endMillis = nowMillis;
      }
    }

    final dateFormat = DateFormat(
      "dd/MM/yy",
      TranslationProvider.of(context).flutterLocale.languageCode,
    );
    final currentDateStr = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(nowMillis),
    );

    final targetDateStr = profile.weeklyGoalRate != null && !isMaintain
        ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(endMillis))
        : "--/--/--";

    final gapFromBase = targetWt - baseWt;
    final progressRatio = gapFromBase != 0
        ? ((currentWt - baseWt) / gapFromBase).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(paddingVal), // Dùng responsive padding
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: trendColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        titleLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMaintain) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GymCountdownText(
                        targetMillis: endMillis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        highlightColor: trendColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    icon: Icon(
                      Symbols.edit,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: onEditGoal,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: spaceHeader,
          ), // Thay khoảng trắng tĩnh bằng biến responsive

          SizedBox(
            height: chartHeight, // Biểu đồ tự điều chỉnh 90 hoặc 40
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progressRatio),
              duration: const Duration(milliseconds: 1000),
              builder: (context, animValue, _) => CustomPaint(
                painter: _WeightGoalPainter(
                  isMaintain: isMaintain,
                  isCut: isCut,
                  progress: animValue,
                  trendColor: trendColor,
                ),
              ),
            ),
          ),
          SizedBox(
            height: spaceChart,
          ), // Thay khoảng trắng tĩnh bằng biến responsive

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t.nutrition.format_goal_current_date(arg1: currentDateStr),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      t.onboarding.format_kg(arg1: _formatDouble(currentWt)),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMaintain)
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          t.nutrition.format_goal_target_date(arg1: targetDateStr),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        t.onboarding.format_kg(arg1: _formatDouble(targetWt)),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(
            height: spaceFooter,
          ), // Thay khoảng trắng tĩnh bằng biến responsive

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: Size(
                double.infinity,
                btnHeight,
              ), // Button co lại trên Tablet
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onUpdateWeight,
            child: Text(
              t.nutrition.btn_goal_update_weight,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightGoalPainter extends CustomPainter {
  final bool isMaintain;
  final bool isCut;
  final double progress;
  final Color trendColor;

  _WeightGoalPainter({
    required this.isMaintain,
    required this.isCut,
    required this.progress,
    required this.trendColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintDashed = Paint()
      ..color = trendColor.withValues(alpha: 0.2)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final paintSolid = Paint()
      ..color = trendColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Chỉ dùng 1 cọ vẽ màu đặc duy nhất cho chấm
    final paintCircle = Paint()
      ..color = trendColor
      ..style = PaintingStyle.fill;

    final startY = isMaintain
        ? size.height / 2
        : (isCut ? size.height * 0.15 : size.height * 0.85);
    final endY = isMaintain
        ? size.height / 2
        : (isCut ? size.height * 0.85 : size.height * 0.15);

    canvas.drawLine(Offset(0, startY), Offset(size.width, endY), paintDashed);

    if (!isMaintain) {
      final curX = size.width * progress;
      final curY = startY + ((endY - startY) * progress);

      if (curX > 0) {
        canvas.drawLine(Offset(0, startY), Offset(curX, curY), paintSolid);
      }

      // Điểm bắt đầu
      canvas.drawCircle(Offset(0, startY), 4, paintCircle);
      // Điểm kết thúc (đích)
      canvas.drawCircle(
        Offset(size.width, endY),
        5,
        Paint()..color = trendColor.withValues(alpha: 0.5),
      );
      // Điểm hiện tại (Solid Dot) - kích thước 6 là tối ưu nhất khi không có ruột trắng
      canvas.drawCircle(Offset(curX, curY), 6, paintCircle);
    } else {
      // Chế độ Maintain (Solid Dot)
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        6,
        paintCircle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ========================================================
// 3. DIALOGS
// ========================================================

Future<void> showUpdateWeightDialog(
  BuildContext context, {
  required double currentWeight,
  required VoidCallback onDismiss,
  required Function(double) onConfirm,
}) async {
  final controller = TextEditingController(text: _formatDouble(currentWeight));
  bool showWarning = false;
  String? errorMsg;

  final double minWeight = 30.0;
  final double maxWeight = 650.0;
  final colorScheme = Theme.of(context).colorScheme;

  await GymDialog.showCustom(
    context: context,
    titleWidget: Text(
      t.nutrition.title_weight_dialog,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    content: StatefulBuilder(
      builder: (context, setLocalState) {
        void clearErrors() {
          if (showWarning) setLocalState(() => showWarning = false);
          if (errorMsg != null) setLocalState(() => errorMsg = null);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showWarning)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  border: Border.all(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Symbols.warning, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.nutrition.msg_weight_anti_cheat,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                t.nutrition.msg_weight_instruction,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

            const SizedBox(height: 16),

            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (_) => clearErrors(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: t.nutrition.label_weight_input,
                suffixText: "kg",
                errorText: errorMsg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: showWarning
                        ? colorScheme.error
                        : colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    onDismiss();
                    Navigator.pop(context);
                  },
                  child: Text(
                    t.common.cancel,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showWarning
                        ? colorScheme.error
                        : colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final val = double.tryParse(controller.text);

                    if (val == null) {
                      setLocalState(
                        () => errorMsg = t.nutrition.error_invalid_number,
                      );
                      return;
                    }
                    if (val < minWeight) {
                      setLocalState(
                        () => errorMsg = t.nutrition.error_min_weight(
                          arg1: _formatDouble(minWeight),
                        ),
                      );
                      return;
                    }
                    if (val > maxWeight) {
                      setLocalState(
                        () => errorMsg = t.nutrition.error_max_weight(
                          arg1: _formatDouble(maxWeight),
                        ),
                      );
                      return;
                    }

                    final change = (val - currentWeight).abs() / currentWeight;
                    if (change > 0.02 && !showWarning) {
                      setLocalState(() => showWarning = true);
                    } else {
                      onConfirm(val);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    showWarning
                        ? t.nutrition.btn_weight_save_anyway
                        : t.nutrition.btn_goal_update_weight,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
    actions: [],
  );
}

Future<void> showWaterSettingsDialog(
  BuildContext context, {
  required double currentWater,
  required double targetWater,
  required VoidCallback onDismiss,
  required Function(double, double) onConfirm,
}) async {
  final currentCtrl = TextEditingController(
    text: _formatDouble(currentWater, decimals: 2),
  );
  final targetCtrl = TextEditingController(
    text: _formatDouble(targetWater, decimals: 2),
  );
  String? errorMsg;
  final colorScheme = Theme.of(context).colorScheme;

  await GymDialog.showCustom(
    context: context,
    titleWidget: Text(
      t.nutrition.title_water_settings,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    content: StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: currentCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              onChanged: (v) {
                if (errorMsg != null) setLocalState(() => errorMsg = null);
              },
              decoration: InputDecoration(
                labelText: t.nutrition.label_water_consumed,
                suffixText: t.nutrition.unit_liters,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              onChanged: (v) {
                if (errorMsg != null) setLocalState(() => errorMsg = null);
              },
              decoration: InputDecoration(
                labelText: t.nutrition.label_water_target,
                suffixText: t.nutrition.unit_liters,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),

            if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.error_outline,
                      color: colorScheme.error,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        errorMsg!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    onDismiss();
                    Navigator.pop(context);
                  },
                  child: Text(
                    t.common.cancel,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final currVal =
                        double.tryParse(currentCtrl.text) ?? currentWater;
                    final targetVal =
                        double.tryParse(targetCtrl.text) ?? targetWater;

                    if (targetVal < 0.5 || targetVal > 10.0) {
                      setLocalState(
                        () => errorMsg = t.nutrition.err_water_target,
                      );
                      return;
                    }
                    if (currVal > 10.0) {
                      setLocalState(
                        () => errorMsg = t.nutrition.err_water_current,
                      );
                      return;
                    }

                    onConfirm(currVal, targetVal);
                    Navigator.pop(context);
                  },
                  child: Text(
                    t.common.save,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
    actions: [],
  );
}

class UpdateGoalDialog extends StatefulWidget {
  final UserProfile profile;
  final NutritionGoal? lockedGoal;
  final VoidCallback onDismiss;
  final Function(double targetWeight, int targetDays) onConfirm;

  const UpdateGoalDialog({
    super.key,
    required this.profile,
    this.lockedGoal,
    required this.onDismiss,
    required this.onConfirm,
  });

  @override
  State<UpdateGoalDialog> createState() => _UpdateGoalDialogState();
}

class _UpdateGoalDialogState extends State<UpdateGoalDialog> {
  late double _targetWeight;
  String _paceMode = "NORMAL";
  int _customDays = 0;

  late double _minWeight;
  late double _maxWeight;

  String? _errorMsg;
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();

    if (widget.lockedGoal == NutritionGoal.GAIN_WEIGHT) {
      _minWeight = widget.profile.weightInKg + 0.5;
      _maxWeight = 650.0;
    } else if (widget.lockedGoal == NutritionGoal.LOSE_WEIGHT) {
      _minWeight = 30.0;
      _maxWeight = widget.profile.weightInKg - 0.5;
    } else {
      _minWeight = 30.0;
      _maxWeight = 650.0;
    }

    double initialTarget =
        widget.profile.targetGoalWeightKg ?? widget.profile.weightInKg;
    _targetWeight = initialTarget.clamp(_minWeight, _maxWeight);
  }

  int get _minDays => NutritionCalculator.calculateMinDays(
    widget.profile.weightInKg,
    _targetWeight,
  );

  int get _baseDays {
    final gap = (_targetWeight - widget.profile.weightInKg).abs();
    if (gap == 0) return 1;
    return (gap / 0.5 * 7).round();
  }

  int get _fastDays => math.max(1, _minDays);

  int get _normalDays {
    final normal = _baseDays;
    if (normal <= _minDays) return (_minDays * 1.5).round();
    return normal;
  }

  int get _relaxedDays => (_normalDays * 1.5).round();

  int get _actualTargetDays {
    switch (_paceMode) {
      case "FAST":
        return _fastDays;
      case "NORMAL":
        return _normalDays;
      case "RELAXED":
        return _relaxedDays;
      case "CUSTOM":
        return math.max(_minDays, _customDays);
      default:
        return _normalDays;
    }
  }

  void _clearErrors() {
    if (_errorMsg != null) setState(() => _errorMsg = null);
    if (_showWarning) setState(() => _showWarning = false);
  }

  void _validateAndConfirm() {
    if (_errorMsg != null) {
      setState(() => _errorMsg = null);
    }

    if (_targetWeight != widget.profile.weightInKg && _paceMode == "CUSTOM") {
      if (_customDays < _minDays) {
        setState(
          () => _errorMsg = t.nutrition.error_pace_too_fast(
            arg1: _minDays.toString(),
          ),
        );
        return;
      }
    }

    final targetBmi =
        _targetWeight / math.pow((widget.profile.heightInCm / 100), 2);
    if ((targetBmi < 18.5 || targetBmi > 30.0) && !_showWarning) {
      setState(() => _showWarning = true);
      return;
    }

    widget.onConfirm(_targetWeight, _actualTargetDays);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Widget bmiAndWeightSection = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BMIVisualizer(
          bmiValue:
              _targetWeight / math.pow((widget.profile.heightInCm / 100), 2),
          title: t.nutrition.bmi_target,
        ),
        const SizedBox(height: 32),

        Text(
          t.profile.target_weight,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),

        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              showManualWeightInputDialog(
                context,
                _targetWeight,
                _minWeight,
                _maxWeight,
                (newWeight) {
                  setState(() {
                    _targetWeight = newWeight;
                    if (_paceMode == "CUSTOM") _paceMode = "NORMAL";
                    _clearErrors();
                  });
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                t.onboarding.format_kg(arg1: _formatDouble(_targetWeight)),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        WeightRulerPicker(
          value: _targetWeight,
          minWeight: _minWeight,
          maxWeight: _maxWeight,
          onChanged: (v) => setState(() {
            _targetWeight = v;
            if (_paceMode == "CUSTOM") _paceMode = "NORMAL";
            _clearErrors();
          }),
        ),
      ],
    );

    Widget paceSelectionSection;

    if (widget.profile.weightInKg != _targetWeight) {
      if (widget.profile.isCustomMacros) {
        paceSelectionSection = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).gymColors.goldRank.withValues(alpha: 0.1),
            border: Border.all(
              color: Theme.of(
                context,
              ).gymColors.goldRank.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Symbols.info,
                color: Theme.of(context).gymColors.goldRank,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  t.nutrition.msg_custom_macro_pace_hidden,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        paceSelectionSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.profile.target_pace,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 90,
              ),
              children: [
                _PaceCard(
                  title: t.profile.pace_fast,
                  subtitle: DateFormat(
                    'dd/MM/yy',
                  ).format(DateTime.now().add(Duration(days: _fastDays))),
                  isSelected: _paceMode == "FAST",
                  isSubtitlePrimary: true,
                  onTap: () {
                    setState(() => _paceMode = "FAST");
                    _clearErrors();
                  },
                ),
                _PaceCard(
                  title: t.profile.pace_normal,
                  subtitle: DateFormat(
                    'dd/MM/yy',
                  ).format(DateTime.now().add(Duration(days: _normalDays))),
                  isSelected: _paceMode == "NORMAL",
                  isSubtitlePrimary: true,
                  onTap: () {
                    setState(() => _paceMode = "NORMAL");
                    _clearErrors();
                  },
                ),
                _PaceCard(
                  title: t.profile.pace_relaxed,
                  subtitle: DateFormat(
                    'dd/MM/yy',
                  ).format(DateTime.now().add(Duration(days: _relaxedDays))),
                  isSelected: _paceMode == "RELAXED",
                  isSubtitlePrimary: true,
                  onTap: () {
                    setState(() => _paceMode = "RELAXED");
                    _clearErrors();
                  },
                ),
                _PaceCard(
                  topIcon: Symbols.calendar_month,
                  subtitle: _customDays > 0
                      ? DateFormat('dd/MM/yy').format(
                          DateTime.now().add(Duration(days: _customDays)),
                        )
                      : t.nutrition.label_target_custom_date,
                  isSelected: _paceMode == "CUSTOM",
                  isSubtitlePrimary: _customDays > 0,
                  onTap: () async {
                    _clearErrors();
                    final firstAllowedDate = DateTime.now().add(
                      Duration(days: _minDays),
                    );
                    DateTime initialPickerDate = DateTime.now().add(
                      Duration(days: _actualTargetDays),
                    );

                    if (initialPickerDate.isBefore(firstAllowedDate)) {
                      initialPickerDate = firstAllowedDate;
                    }

                    final date = await showDatePicker(
                      context: context,
                      initialDate: initialPickerDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 1000)),
                    );

                    if (!mounted) return;

                    if (date != null) {
                      setState(() {
                        final now = DateTime.now();
                        final todayMidnight = DateTime(
                          now.year,
                          now.month,
                          now.day,
                        );

                        _customDays = date.difference(todayMidnight).inDays;
                        _paceMode = "CUSTOM";
                      });
                    } else if (_customDays > 0) {
                      setState(() => _paceMode = "CUSTOM");
                    }
                  },
                ),
              ],
            ),
          ],
        );
      }
    } else {
      paceSelectionSection = Card(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        color: Theme.of(context).gymColors.success.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).gymColors.success.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Symbols.check_circle,
                color: Theme.of(context).gymColors.success,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  t.nutrition.msg_target_maintain_active,
                  style: TextStyle(
                    color: Theme.of(context).gymColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.nutrition.title_target_dialog,
        onBackClick: widget.onDismiss,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMsg != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.error_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade().slideY(begin: 0.2, end: 0),

              if (_showWarning && _errorMsg == null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).gymColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).gymColors.warning.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.warning_amber,
                        color: Theme.of(context).gymColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.nutrition.warning_unhealthy_target_bmi,
                          style: TextStyle(
                            color: Theme.of(context).gymColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade().slideY(begin: 0.2, end: 0),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showWarning
                      ? colorScheme.error
                      : colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                onPressed: _validateAndConfirm,
                child: Text(
                  _showWarning
                      ? t.nutrition.btn_weight_save_anyway
                      : t.common.confirm,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Builder(
          // [UI/UX FIX]: Dùng Builder kết hợp ResponsiveBreakpoints thay LayoutBuilder
          builder: (context) {
            final isTablet = ResponsiveBreakpoints.of(
              context,
            ).largerThan(MOBILE);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isTablet
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: bmiAndWeightSection
                                  .animate()
                                  .fade(
                                    duration: 400.ms,
                                    curve: Curves.easeOutCubic,
                                  )
                                  .slideY(begin: 0.1, end: 0),
                            ),
                            Container(
                              width: 1,
                              height: 300,
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                            ),
                            Expanded(
                              child: paceSelectionSection
                                  .animate(delay: 100.ms)
                                  .fade(
                                    duration: 400.ms,
                                    curve: Curves.easeOutCubic,
                                  )
                                  .slideY(begin: 0.1, end: 0),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          bmiAndWeightSection
                              .animate()
                              .fade(
                                duration: 400.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 48),
                          paceSelectionSection
                              .animate(delay: 100.ms)
                              .fade(
                                duration: 400.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .slideY(begin: 0.1, end: 0),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaceCard extends StatelessWidget {
  final String? title;
  final IconData? topIcon;
  final String subtitle;
  final bool isSelected;
  final bool isSubtitlePrimary;
  final VoidCallback onTap;

  const _PaceCard({
    this.title,
    this.topIcon,
    required this.subtitle,
    required this.isSelected,
    required this.isSubtitlePrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // [UI/UX FIX]: Scalable FontSize
    final titleFontSize = ResponsiveValue<double>(
      context,
      defaultValue: 13,
      conditionalValues: [Condition.smallerThan(name: MOBILE, value: 11)],
    ).value;
    final subFontSize = ResponsiveValue<double>(
      context,
      defaultValue: 12,
      conditionalValues: [Condition.smallerThan(name: MOBILE, value: 10)],
    ).value;

    return Material(
      elevation: isSelected ? 4 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      color: isSelected
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (topIcon != null)
                Icon(
                  topIcon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  size: 22,
                )
              else if (title != null)
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  maxLines: 2, // [UI/UX FIX]: Level 2 softWrap
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
                ),

              const SizedBox(height: 6),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary.withValues(alpha: 0.8)
                      : (isSubtitlePrimary
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant),
                  fontSize: subFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showGoalReviewDialog(
  BuildContext context, {
  required UserProfile profile,
  required Function(String) onAction,
  required Function(NutritionGoal) onSuccessGoal,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final currentWt = profile.weightInKg;
  final targetWt = profile.targetGoalWeightKg ?? currentWt;

  bool isMet = false;
  if (profile.nutritionGoal == NutritionGoal.LOSE_WEIGHT) {
    isMet = currentWt <= targetWt;
  } else if (profile.nutritionGoal == NutritionGoal.GAIN_WEIGHT)
    isMet = currentWt >= targetWt;
  else
    isMet = true;

  final bmi = currentWt / math.pow(profile.heightInCm / 100, 2);

  final isGainGoal = profile.nutritionGoal == NutritionGoal.GAIN_WEIGHT;
  final gainKey = isGainGoal
      ? 'nutrition.btn_review_continue_gain'
      : 'nutrition.btn_review_switch_gain';
  final loseKey = isGainGoal
      ? 'nutrition.btn_review_switch_lose'
      : 'nutrition.btn_review_continue_lose';

  await GymDialog.showCustom(
    context: context,
    titleWidget: Text(
      isMet ? t.nutrition.title_review_success : t.nutrition.title_review_expired,
      style: TextStyle(
        color: isMet
            ? Theme.of(context).gymColors.success
            : Theme.of(context).gymColors.warning,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMet) ...[
          BMIVisualizer(bmiValue: bmi, title: t.nutrition.bmi_target),
          const SizedBox(height: 16),
          Text(
            t.nutrition.format_review_congrats(arg1: _formatDouble(currentWt)),
          ),
          const SizedBox(height: 16),
          Text(
            t.nutrition.format_review_bmi_suggestion(arg1: _formatDouble(bmi)),
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          if (bmi < 25)
            ElevatedButton(
              onPressed: () {
                onSuccessGoal(NutritionGoal.GAIN_WEIGHT);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: Text(
                t.translateDynamic(gainKey),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (bmi >= 18.5)
            ElevatedButton(
              onPressed: () {
                onSuccessGoal(NutritionGoal.LOSE_WEIGHT);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: Text(
                t.translateDynamic(loseKey),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          ElevatedButton(
            onPressed: () {
              onSuccessGoal(NutritionGoal.MAINTAIN_WEIGHT);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurface,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: Text(
              t.nutrition.btn_review_maintain,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ] else ...[
          Text(
            t.nutrition.format_review_failed(
              arg1: _formatDouble(currentWt),
              arg2: _formatDouble(targetWt),
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            title: t.nutrition.btn_review_extend,
            desc: t.nutrition.desc_review_extend,
            onClick: () {
              onAction("EXTEND");
              Navigator.pop(context);
            },
          ),
          _ActionButton(
            title: t.nutrition.btn_review_diet_break,
            desc: t.nutrition.desc_review_diet_break,
            onClick: () {
              onAction("DIET_BREAK");
              Navigator.pop(context);
            },
          ),
          _ActionButton(
            title: t.nutrition.btn_review_accept,
            desc: t.nutrition.desc_review_accept,
            onClick: () {
              onAction("ACCEPT");
              Navigator.pop(context);
            },
          ),
        ],
      ],
    ),
    actions: [],
  );
}

class _ActionButton extends StatelessWidget {
  final String title;
  final String desc;
  final VoidCallback onClick;

  const _ActionButton({
    required this.title,
    required this.desc,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OutlinedButton(
        onPressed: onClick,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              desc,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================================
// 4. BMIVisualizer & WeightRulerPicker
// ========================================================

class BMIVisualizer extends StatelessWidget {
  final double bmiValue;
  final String? title;

  const BMIVisualizer({super.key, required this.bmiValue, this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;
    final displayTitle = title ?? t.nutrition.bmi_current;

    String healthCategory;
    Color indicatorColor;

    // Thay thế màu cứng bằng dải màu Theme chuẩn xác
    if (bmiValue < 18.5) {
      healthCategory = t.nutrition.bmi_underweight;
      indicatorColor = colorScheme.primary; // Xanh dương
    } else if (bmiValue < 25.0) {
      healthCategory = t.nutrition.bmi_normal;
      indicatorColor = gymColors.success; // Xanh lá
    } else if (bmiValue < 30.0) {
      healthCategory = t.nutrition.bmi_overweight;
      indicatorColor = gymColors.warning; // Vàng Cam
    } else if (bmiValue < 35.0) {
      healthCategory = t.nutrition.bmi_obese;
      indicatorColor = gymColors.fireHexagon; // Đỏ lửa
    } else {
      healthCategory = t.nutrition.bmi_severe_obese;
      indicatorColor = colorScheme.error; // Đỏ
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          displayTitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          bmiValue.toStringAsFixed(1),
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          children: [
            Text(
              t.nutrition.desc_bmi_prefix,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              healthCategory,
              style: TextStyle(
                color: indicatorColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 16,
              child: CustomPaint(
                painter: _BMICanvasPainter(
                  bmiValue: bmiValue,
                  indicatorColor: indicatorColor,
                  colorScheme: colorScheme,
                  gymColors: gymColors,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 35,
                  child: Text(
                    t.nutrition.bmi_underweight,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                  ),
                ),
                Expanded(
                  flex: 65,
                  child: Text(
                    t.nutrition.bmi_normal,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                  ),
                ),
                Expanded(
                  flex: 50,
                  child: Text(
                    t.nutrition.bmi_overweight,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                  ),
                ),
                Expanded(
                  flex: 50,
                  child: Text(
                    t.nutrition.bmi_obese,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                  ),
                ),
                Expanded(
                  flex: 50,
                  child: Text(
                    t.nutrition.bmi_severe_obese,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _BMICanvasPainter extends CustomPainter {
  final double bmiValue;
  final Color indicatorColor;
  final ColorScheme colorScheme;
  final GymColors gymColors;

  _BMICanvasPainter({
    required this.bmiValue,
    required this.indicatorColor,
    required this.colorScheme,
    required this.gymColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const minScale = 15.0;
    const maxScale = 40.0;
    const range = maxScale - minScale;

    double getPos(double val) =>
        ((val - minScale) / range).clamp(0.0, 1.0) * size.width;

    final p18_5 = getPos(18.5);
    final p25_0 = getPos(25.0);
    final p30_0 = getPos(30.0);
    final p35_0 = getPos(35.0);
    final userPos = getPos(bmiValue);

    const strokeWidth = 12.0;
    final cy = size.height / 2;
    final top = cy - strokeWidth / 2;
    final bottom = cy + strokeWidth / 2;

    // BƯỚC 1: Tạo viền cắt (Clip) bo tròn toàn bộ thanh
    final barRect = RRect.fromLTRBR(
      0,
      top,
      size.width,
      bottom,
      const Radius.circular(strokeWidth / 2),
    );
    canvas.save();
    canvas.clipRRect(barRect);

    // BƯỚC 2: Vẽ các hình chữ nhật (Rect) phẳng lỳ nằm sát nhau, viền ngoài cùng sẽ bị cắt gọt bởi ClipRRect ở trên
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = colorScheme.primary;
    canvas.drawRect(Rect.fromLTRB(0, top, p18_5, bottom), paint);

    paint.color = gymColors.success;
    canvas.drawRect(Rect.fromLTRB(p18_5, top, p25_0, bottom), paint);

    paint.color = gymColors.warning;
    canvas.drawRect(Rect.fromLTRB(p25_0, top, p30_0, bottom), paint);

    paint.color = gymColors.fireHexagon;
    canvas.drawRect(Rect.fromLTRB(p30_0, top, p35_0, bottom), paint);

    paint.color = colorScheme.error;
    canvas.drawRect(Rect.fromLTRB(p35_0, top, size.width, bottom), paint);

    canvas.restore(); // Gỡ Clip ra để có thể vẽ chữ và chấm tròn bên ngoài

    // Vẽ Label Text
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    void drawLabel(String text, double x) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), -16));
    }

    drawLabel("18.5", p18_5);
    drawLabel("25", p25_0);
    drawLabel("30", p30_0);
    drawLabel("35", p35_0);

    // Vẽ chấm Indicator của User
    canvas.drawCircle(Offset(userPos, cy), 14, Paint()..color = indicatorColor);
    canvas.drawCircle(Offset(userPos, cy), 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _BMICanvasPainter oldDelegate) {
    return oldDelegate.bmiValue != bmiValue ||
        oldDelegate.indicatorColor != indicatorColor;
  }
}

class WeightRulerPicker extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double minWeight;
  final double maxWeight;

  const WeightRulerPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.minWeight = 30.0,
    this.maxWeight = 650.0,
  });

  @override
  State<WeightRulerPicker> createState() => _WeightRulerPickerState();
}

class _WeightRulerPickerState extends State<WeightRulerPicker> {
  late double _visualValue;
  late double _emittedValue;

  @override
  void initState() {
    super.initState();
    _visualValue = widget.value;
    _emittedValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant WeightRulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _emittedValue) {
      setState(() {
        _visualValue = widget.value;
        _emittedValue = widget.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Giữ nguyên GestureDetector ở đây vì đây là component vuốt (drag) chứ không phải bấm (tap).
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _visualValue -= (details.delta.dx / 12.0) * 0.1;
          _visualValue = _visualValue.clamp(widget.minWeight, widget.maxWeight);

          double snappedValue = double.parse(_visualValue.toStringAsFixed(1));

          if (snappedValue != _emittedValue) {
            _emittedValue = snappedValue;
            HapticFeedback.selectionClick();
            widget.onChanged(_emittedValue);
          }
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          _visualValue = _emittedValue;
        });
      },
      child: SizedBox(
        height: 80,
        width: double.infinity,
        child: CustomPaint(
          painter: _RulerPainter(
            value: _visualValue,
            minWeight: widget.minWeight,
            maxWeight: widget.maxWeight,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double value;
  final double minWeight;
  final double maxWeight;
  final ColorScheme colorScheme;

  _RulerPainter({
    required this.value,
    required this.minWeight,
    required this.maxWeight,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tickDistance = 12.0;
    final centerOffset = size.width / 2;

    final exactIndex = value / 0.1;
    final visibleTicks = (size.width / 2 / tickDistance).toInt() + 1;

    final startIndex = math.max(
      (exactIndex - visibleTicks).toInt(),
      (minWeight / 0.1).toInt(),
    );
    final endIndex = math.min(
      (exactIndex + visibleTicks).toInt(),
      (maxWeight / 0.1).toInt(),
    );

    final longTickPaint = Paint()
      ..color = colorScheme.onSurface
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final shortTickPaint = Paint()
      ..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final indicatorPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = startIndex; i <= endIndex; i++) {
      final x = centerOffset + (i - exactIndex) * tickDistance;
      final isLong = i % 10 == 0;
      final tickHeight = isLong ? 32.0 : 16.0;

      final yEnd = size.height - 8.0;
      final yStart = yEnd - tickHeight;

      canvas.drawLine(
        Offset(x, yStart),
        Offset(x, yEnd),
        isLong ? longTickPaint : shortTickPaint,
      );

      if (isLong) {
        final kgVal = i ~/ 10;
        textPainter.text = TextSpan(
          text: kgVal.toString(),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - (textPainter.width / 2), yStart - textPainter.height - 8),
        );
      }
    }

    canvas.drawLine(
      Offset(centerOffset, size.height - 8 - 48),
      Offset(centerOffset, size.height - 8),
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Future<void> showManualWeightInputDialog(
  BuildContext context,
  double currentValue,
  double minWeight,
  double maxWeight,
  ValueChanged<double> onSubmitted,
) async {
  TextEditingController ctrl = TextEditingController(
    text: _formatDouble(currentValue),
  );
  final colorScheme = Theme.of(context).colorScheme;
  String? errorMsg;

  await GymDialog.showCustom(
    context: context,
    titleWidget: Text(
      t.nutrition.title_manual_weight_input,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    ),
    content: StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (v) {
                if (errorMsg != null) setLocalState(() => errorMsg = null);
              },
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                suffixText: 'kg',
                suffixStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                errorText: errorMsg,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    t.common.cancel,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    double? val = double.tryParse(ctrl.text);
                    if (val == null) {
                      setLocalState(
                        () => errorMsg = t.nutrition.error_invalid_number,
                      );
                      return;
                    }
                    if (val < minWeight) {
                      setLocalState(
                        () => errorMsg = t.nutrition.error_min_weight(
                          arg1: _formatDouble(minWeight),
                        ),
                      );
                      return;
                    }
                    if (val > maxWeight) {
                      setLocalState(
                        () => errorMsg = t.nutrition.error_max_weight(
                          arg1: _formatDouble(maxWeight),
                        ),
                      );
                      return;
                    }
                    onSubmitted(val);
                    Navigator.pop(context);
                  },
                  child: Text(t.common.confirm),
                ),
              ],
            ),
          ],
        );
      },
    ),
    actions: [],
  );
}
