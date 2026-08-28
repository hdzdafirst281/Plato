import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/bloc/tour/tour_cubit.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_tour_target.dart';

import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/navigation/app_router.dart';
import 'package:plato_gymapp/core/navigation/main_scaffold.dart';
import 'package:plato_gymapp/core/utils/tour_keys.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart';

import '../../../profile/presentation/bloc/profile_cubit.dart'; 
import '../bloc/nutrition_cubit.dart';
import '../components/nutrition_components.dart'; 

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  double _waterTargetLiters = 2.5;
  Timer? _tourDelayTimer;
  final bool forceShowTour = false; // Debug flag

  @override
  void initState() {
    super.initState();
    _loadWaterTarget();

    globalActiveTabIndex.addListener(_checkAndTriggerTour);
    globalIsTabSwiping.addListener(_checkAndTriggerTour);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerTour();
    });
  }

  @override
  void dispose() {
    // [CRITICAL FIX]: Hủy hẹn giờ và mở khóa nếu màn hình bị đóng TRƯỚC KHI tour kịp chạy
    if (_tourDelayTimer?.isActive ?? false) {
      _tourDelayTimer?.cancel();
    }
    
    // [CRITIC DEBUG FIX 1]: Mở khóa an toàn
    if (AppRouter.isTourActive.value) {
      AppRouter.forceAbortTour();
    }
    
    globalActiveTabIndex.removeListener(_checkAndTriggerTour);
    globalIsTabSwiping.removeListener(_checkAndTriggerTour);
    super.dispose();
  }

  // Logic Trigger
  void _checkAndTriggerTour() {
    if (!mounted || AppRouter.isTourActive.value) return;
    
    final tourCubit = context.read<TourCubit>();
    if (tourCubit.state.hasSeenNutrition && !forceShowTour) return;
    
    if (globalActiveTabIndex.value == 1 && !globalIsTabSwiping.value) {
        // [EARLY LOCK]: Khóa UI ngay lập tức
        AppRouter.isTourActive.value = true; 

        _tourDelayTimer?.cancel();
        _tourDelayTimer = Timer(const Duration(milliseconds: 600), () {
          if (!mounted) {
            AppRouter.isTourActive.value = false;
            return;
          }
          _startTourSafely(tourCubit);
        });
    }
  }

  void _startTourSafely(TourCubit tourCubit) {
    if (!mounted) {
       AppRouter.isTourActive.value = false;
       return;
    }
    
    // ĐÃ XÓA: AppRouter.setAutoScroll(false); -> Đây là nguyên nhân khiến app tịt scroll

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      AppRouter.startTour(context, [
        TourKeys.nutritionHistoryBtn,
        TourKeys.nutritionDashboard,
        TourKeys.nutritionWaterTracker,
        TourKeys.nutritionWeightGoal,
        TourKeys.nutritionMealSection,
      ], 
      onCompleted: () {
        // ĐÃ XÓA: AppRouter.setAutoScroll(true);
        tourCubit.completeNutritionTour();
      });
    });
  }

  Future<void> _loadWaterTarget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterTargetLiters = prefs.getDouble('saved_water_target') ?? 2.5;
    });
  }

  Future<void> _saveWaterTarget(double newTarget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_water_target', newTarget);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final profile = context.watch<ProfileCubit>().state.userProfile;
    final nutritionState = context.watch<NutritionCubit>().state;
    final dailyData = nutritionState.nutritionToday;
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    int animIndex = 0; 
    
    final mealWidgets = [MealType.BREAKFAST, MealType.LUNCH, MealType.DINNER, MealType.SNACK]
        .asMap()
        .entries
        .map((entry) {
      final index = entry.key;
      final mealType = entry.value;

      final titleKey = (mealType == MealType.BREAKFAST) ? t.nutrition.name_meal_breakfast :
                       (mealType == MealType.LUNCH) ? t.nutrition.name_meal_lunch :
                       (mealType == MealType.DINNER) ? t.nutrition.name_meal_dinner : t.nutrition.name_meal_snack;
      final icon = (mealType == MealType.BREAKFAST) ? Symbols.breakfast_dining :
                   (mealType == MealType.LUNCH) ? Symbols.meal_lunch :
                   (mealType == MealType.DINNER) ? Symbols.meal_dinner : Symbols.fastfood;

      Widget cardWidget = _MealSectionCard(
        title: titleKey, icon: icon, mealType: mealType,
        consumedFoods: dailyData.getMealsForType(mealType),
        nutritionCubit: context.read<NutritionCubit>(),
      );

      // [ĐIỂM QUAN TRỌNG]: Chỉ bọc TourTarget cho thẻ đầu tiên (Bữa sáng)
      if (index == 0) {
        cardWidget = GymTourTarget(
          isActive: !context.read<TourCubit>().state.hasSeenNutrition || forceShowTour,
          tourKey: TourKeys.nutritionMealSection,
          title: t.tour.nutrition_meal_title,
          description: t.tour.nutrition_meal_desc,
          tooltipPosition: isTablet ? TooltipPosition.left : null,
          borderRadius: 24.0,
          targetPadding: EdgeInsets.zero,
          child: cardWidget,
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: cardWidget,
      ).animate(delay: (animIndex++ * 100).ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);
    }).toList();
    
    // Tối ưu Padding cho NARROW_MOBILE
    final horizontalPadding = ResponsiveValue<double>(
      context,
      defaultValue: 16.0,
      conditionalValues: [
        const Condition.smallerThan(name: MOBILE, value: 12.0),
      ],
    ).value;

    Widget buildDashboards() {
      final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

      final dashboardWidget = GymTourTarget(
        isActive: !context.read<TourCubit>().state.hasSeenNutrition || forceShowTour,
        tourKey: TourKeys.nutritionDashboard,
        title: t.tour.nutrition_dash_title,
        description: t.tour.nutrition_dash_desc,
        borderRadius: 24.0,
        targetPadding: EdgeInsets.zero,
        tooltipPosition: isTablet ? TooltipPosition.right : null,
        child: NutritionDashboard(
          currentDaily: dailyData,
          targetMacros: profile.targetMacros,
          isCustomMacros: profile.isCustomMacros,
          onEditMacros: (newCustomMacros) {
            context.read<ProfileCubit>().updateCustomTargetMacros(newCustomMacros);
          },
          onRevertSystem: () {
            final targetWt = profile.targetGoalWeightKg ?? profile.weightInKg;
            int days = 30;
            if (profile.weeklyGoalRate != null && profile.weeklyGoalRate! > 0) {
              days = ((targetWt - profile.weightInKg).abs() / profile.weeklyGoalRate! * 7).toInt();
            }
            if (days <= 0) days = 30;
            
            context.read<ProfileCubit>().updateGoalParameters(targetWt, days);
          },
        ),
      );

      final waterWidget = GymTourTarget(
        isActive: !context.read<TourCubit>().state.hasSeenNutrition || forceShowTour,
        tourKey: TourKeys.nutritionWaterTracker,
        title: t.tour.nutrition_water_title,
        description: t.tour.nutrition_water_desc,
        tooltipPosition: isTablet ? TooltipPosition.right : null,
        borderRadius: 24.0,
        targetPadding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              showWaterSettingsDialog(
                context,
                currentWater: dailyData.waterConsumedLiters,
                targetWater: _waterTargetLiters,
                onDismiss: () {},
                onConfirm: (newCurrent, newTarget) {
                  setState(() => _waterTargetLiters = newTarget);
                  _saveWaterTarget(newTarget);
                  
                  final diff = newCurrent - dailyData.waterConsumedLiters;
                  if (diff != 0) {
                    context.read<NutritionCubit>().addWater(diff);
                  }
                },
              );
            },
            child: WaterTrackerCard(
              currentLiters: dailyData.waterConsumedLiters,
              targetLiters: _waterTargetLiters,
              onTapCard: () {
                showWaterSettingsDialog(
                  context,
                  currentWater: dailyData.waterConsumedLiters,
                  targetWater: _waterTargetLiters,
                  onDismiss: () {},
                  onConfirm: (newCurrent, newTarget) {
                    setState(() => _waterTargetLiters = newTarget);
                    _saveWaterTarget(newTarget);
                    
                    final diff = newCurrent - dailyData.waterConsumedLiters;
                    if (diff != 0) {
                      context.read<NutritionCubit>().addWater(diff);
                    }
                  },
                );
              },
              onAddWater: () {
                if (dailyData.waterConsumedLiters < 10) {
                  context.read<NutritionCubit>().addWater(0.25);
                } else {
                  GymDialog.showInfo(
                    context: context,
                    icon: Symbols.water_drop,
                    iconColor: Theme.of(context).colorScheme.primary,
                    title: t.nutrition.title_water_limit,
                    message: t.nutrition.err_water_current,
                    buttonText: t.common.confirm,
                  );
                }
              },
              onRemoveWater: () {
                if (dailyData.waterConsumedLiters > 0) {
                  context.read<NutritionCubit>().addWater(-0.25);
                }
              },
            ),
          ),
        ),
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isTablet) ...[
            dashboardWidget.animate(delay: 0.ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            waterWidget.animate(delay: 50.ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0),
          ] else ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: dashboardWidget),
                  const SizedBox(width: 16),
                  Expanded(child: waterWidget),
                ],
              ),
            ).animate(delay: 0.ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0),
          ],
          
          const SizedBox(height: 24),

          GymTourTarget(
            isActive: !context.read<TourCubit>().state.hasSeenNutrition || forceShowTour,
            tourKey: TourKeys.nutritionWeightGoal,
            title: t.tour.nutrition_wt_title,
            description: t.tour.nutrition_wt_desc,
            tooltipPosition: isTablet ? TooltipPosition.right : null,
            borderRadius: 24.0,
            targetPadding: EdgeInsets.zero,
            child: WeightGoalChartCard(
              profile: profile,
              onUpdateWeight: () {
                showUpdateWeightDialog(
                  context,
                  currentWeight: profile.weightInKg,
                  onDismiss: () {},
                  onConfirm: (val) {
                    context.read<ProfileCubit>().updateCurrentWeight(val);
                  }
                );
              },
              onEditGoal: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (navContext) => UpdateGoalDialog(
                      profile: profile,
                      onDismiss: () => Navigator.of(navContext, rootNavigator: true).pop(),
                      onConfirm: (wt, days) {
                        if (profile.isCustomMacros) {
                           context.read<ProfileCubit>().updateTargetWeightKeepCustomMacros(wt);
                        } else {
                           context.read<ProfileCubit>().updateGoalParameters(wt, days);
                        }
                        Navigator.of(navContext, rootNavigator: true).pop();
                      },
                    ),
                  ),
                );
              },
            ),
          ).animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0)
        ],
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 56, 
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          t.nutrition.title_main,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 25, color: colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<NutritionCubit>().loadNutritionHistory();
              context.push('/nutrition/history');
            },
            icon: GymTourTarget(
              isActive: !context.read<TourCubit>().state.hasSeenNutrition || forceShowTour,
              tourKey: TourKeys.nutritionHistoryBtn,
              title: t.nutrition.title_history,
              description: t.tour.nutrition_history_desc,
              // FIX LỖI TRÀN VIỀN: Ép thành hình tròn khít
              customShapeBorder: const CircleBorder(), 
              // Thu hẹp padding tối đa để hộp tọa độ không lồi ra ngoài mép phải màn hình
              targetPadding: EdgeInsets.zero,
              child: Icon(Symbols.history, color: colorScheme.primary, size: 24),
            ),
          ),
          const SizedBox(width: 16), 
        ],
      ),
      body: SafeArea(
        child: isTablet 
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cột 1: Dashboard & Water (Cuộn độc lập)
                      Expanded(
                        flex: 1, 
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: buildDashboards(),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Cột 2: Bữa ăn (Cuộn độc lập)
                      Expanded(
                        flex: 1, 
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: mealWidgets,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildDashboards(),
                  const SizedBox(height: 24),
                  ...mealWidgets,
                  const SizedBox(height: 80), 
                ],
              ),
            ),
      ),
    );
  }
}

class _MealSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final MealType mealType;
  final List<FoodResult> consumedFoods;
  final NutritionCubit nutritionCubit;

  const _MealSectionCard({required this.title, required this.icon, required this.mealType, required this.consumedFoods, required this.nutritionCubit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalCal = consumedFoods.fold(0, (sum, f) => sum + f.calculatedTotalCalories);
    final totalP = consumedFoods.fold(0, (sum, f) => sum + f.calculatedTotalProtein);
    final totalC = consumedFoods.fold(0, (sum, f) => sum + f.calculatedTotalCarbs);
    final totalF = consumedFoods.fold(0, (sum, f) => sum + f.calculatedTotalFat);

    final cardPadding = ResponsiveValue<double>(
      context,
      defaultValue: 20.0,
      conditionalValues: [
        const Condition.smallerThan(name: MOBILE, value: 12.0),
      ],
    ).value;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(icon, color: colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    
                    // NÂNG CẤP: Hệ tư tưởng 3 cấp độ thông minh theo đặc tính chuỗi văn bản
                    Flexible(
                      child: title.trim().contains(' ')
                          ? Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                            ),
                    ),
                    IconButton(
                      icon: Icon(Symbols.content_copy, size: 18, color: colorScheme.primary),
                      tooltip: t.nutrition.btn_main_copy_yesterday,
                      onPressed: () async {
                        final success = await nutritionCubit.copyMealFromYesterday(mealType);
                        if (context.mounted) {
                          GymDialog.showInfo(
                            context: context,
                            icon: success ? Symbols.check_circle_outline : Symbols.info,
                            iconColor: success ? Theme.of(context).gymColors.success : colorScheme.primary,
                            title: t.nutrition.title_copy_meal,
                            message: success ? t.nutrition.msg_copy_success : t.nutrition.msg_copy_empty,
                            buttonText: t.common.confirm,
                          );
                        }
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (totalCal > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        t.nutrition.fmt_kcal(arg1: totalCal.toString()), 
                        style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 16)
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: MacroText(protein: totalP, carbs: totalC, fat: totalF),
                    ),
                  ],
                )
            ],
          ),
          const SizedBox(height: 16),

          if (consumedFoods.isEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.05), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openFoodSearch(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Symbols.add, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            t.nutrition.btn_meal_add_food, 
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                            softWrap: true,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            ...consumedFoods.map((food) => _FoodItemRow(food: food, mealType: mealType, nutritionCubit: nutritionCubit)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _openFoodSearch(context),
              icon: const Icon(Symbols.add_circle_outline),
              label: Text(t.nutrition.btn_meal_add_more, style: const TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            )
          ]
        ],
      ),
    );
  }

  void _openFoodSearch(BuildContext context) {
    context.push('/nutrition/food_encyclopedia/${mealType.name}');
  }
}

class _FoodItemRow extends StatelessWidget {
  final FoodResult food;
  final MealType mealType;
  final NutritionCubit nutritionCubit;

  const _FoodItemRow({required this.food, required this.mealType, required this.nutritionCubit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final String localizedName = t.translateDynamic(food.foodName);
    final String avatarLetter = localizedName.isNotEmpty ? localizedName[0].toUpperCase() : '?';
    
    final bool isScale = food.measurementUnit == FoodUnit.GRAM || food.measurementUnit == FoodUnit.ML;
    final double displayAmount = isScale ? food.consumedAmount * 100 : food.consumedAmount;
    
    String amountStr;
    if (displayAmount % 1 == 0) {
      amountStr = displayAmount.toInt().toString();
    } else {
      amountStr = displayAmount.toStringAsFixed(1);
      if (amountStr.contains('.')) {
        amountStr = amountStr.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    }

    String unitName;
    switch (food.measurementUnit) {
      case FoodUnit.GRAM: unitName = t.nutrition.lbl_unit_gram; break;
      case FoodUnit.ML: unitName = t.nutrition.lbl_unit_ml; break;
      case FoodUnit.QUANTITY: unitName = t.nutrition.lbl_unit_quantity; break;
      case FoodUnit.SERVING: unitName = t.nutrition.lbl_unit_serving; break;
      case FoodUnit.OZ: unitName = t.nutrition.lbl_unit_oz; break;
    }

    final String unitLabel = '$amountStr $unitName';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarLetter,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedName, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), 
                  maxLines: 2, 
                  softWrap: true,
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MacroText(
                    calories: food.calculatedTotalCalories, 
                    protein: food.calculatedTotalProtein, 
                    carbs: food.calculatedTotalCarbs, 
                    fat: food.calculatedTotalFat,
                    unitSuffix: ' / $unitLabel',
                  ),
                ),
              ],
            ),
          ),
          
          PopupMenuButton<String>(
            icon: Icon(Symbols.more_vert, color: colorScheme.onSurfaceVariant),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              if (value == 'edit') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: colorScheme.surface, 
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)), 
                  ),
                  builder: (ctx) => FoodBottomSheet(
                    food: food,
                    onSave: (updatedLogEntry, newBlueprint) {
                      // 1. Nếu có thay đổi Blueprint (Tên/Macros) => Lưu vào Database Custom Food
                      if (newBlueprint != null) {
                        nutritionCubit.saveCustomFoodBlueprint(newBlueprint);
                      }
                      // 2. BẤT KỂ là đổi số lượng hay Tên/Macros, Đều phải cập nhật lại Log Entry bằng hàm MỚI
                      nutritionCubit.updateFoodEntry(food.id, mealType, updatedLogEntry);
                    },
                  )
                );
              } else if (value == 'delete') {
                nutritionCubit.removeFoodFromLog(food.id, mealType);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Symbols.edit, size: 20, color: colorScheme.primary, fill: 1.0),
                    const SizedBox(width: 12),
                    Text(t.common.edit), 
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Symbols.delete, size: 20, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Text(t.common.delete, style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class FoodBottomSheet extends StatefulWidget {
  final FoodResult food;
  final Function(FoodResult updatedLogEntry, FoodResult? newBlueprint) onSave;

  const FoodBottomSheet({super.key, required this.food, required this.onSave});

  @override
  State<FoodBottomSheet> createState() => _FoodBottomSheetState();
}

class _FoodBottomSheetState extends State<FoodBottomSheet> {
  late String _name;
  late String _cal;
  late String _pro;
  late String _carb;
  late String _fat;
  late double _consumedAmount;

  String? _nameError;
  String? _calError;
  String? _proError;
  String? _carbError;
  String? _fatError;

  @override
  void initState() {
    super.initState();
    _name = t.translateDynamic(widget.food.foodName); 
    _cal = widget.food.baseCalories.toString();
    _pro = widget.food.baseProtein.toString();
    _carb = widget.food.baseCarbs.toString();
    _fat = widget.food.baseFat.toString();
    _consumedAmount = widget.food.consumedAmount;
  }

  void _validateEdit() {
    setState(() {
      if (_name.trim().isEmpty) { _nameError = null; }
      else if (!RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(_name) || _name.length > 50) { _nameError = t.nutrition.err_food_name; } 
      else { _nameError = null; }

      if (_cal.trim().isEmpty) { _calError = null; }
      else {
        final cal = int.tryParse(_cal.trim()) ?? -1;
        if (cal < 1 || cal > 10000) {
          _calError = t.nutrition.err_food_cal;
        } else {
          _calError = null;
        }
      }

      if (_pro.trim().isEmpty) { _proError = null; }
      else {
        final p = int.tryParse(_pro.trim()) ?? -1;
        if (p < 0 || p > 500) {
          _proError = t.nutrition.err_food_pcf;
        } else {
          _proError = null;
        }
      }

      if (_carb.trim().isEmpty) { _carbError = null; }
      else {
        final c = int.tryParse(_carb.trim()) ?? -1;
        if (c < 0 || c > 500) {
          _carbError = t.nutrition.err_food_pcf;
        } else {
          _carbError = null;
        }
      }

      if (_fat.trim().isEmpty) { _fatError = null; }
      else {
        final f = int.tryParse(_fat.trim()) ?? -1;
        if (f < 0 || f > 500) {
          _fatError = t.nutrition.err_food_pcf;
        } else {
          _fatError = null;
        }
      }
    });
  }

  bool _isEditValid() {
    if (_name.trim().isEmpty || _cal.trim().isEmpty || _pro.trim().isEmpty || _carb.trim().isEmpty || _fat.trim().isEmpty) return false;
    return _nameError == null && _calError == null && _proError == null && _carbError == null && _fatError == null;
  }

  String? _validatePortion(double qty) {
    final cal = int.tryParse(_cal.trim()) ?? 0;
    final pro = int.tryParse(_pro.trim()) ?? 0;
    final carb = int.tryParse(_carb.trim()) ?? 0;
    final fat = int.tryParse(_fat.trim()) ?? 0;

    if (cal * qty > 20000) return t.nutrition.err_food_exceed_cal;
    if (pro * qty > 1000 || carb * qty > 1000 || fat * qty > 1000) {
      return t.nutrition.err_food_exceed_pcf;
    }
    return null;
  }

  void _submit() {
    final bool isNameUnchanged = _name.trim() == t.translateDynamic(widget.food.foodName);
    final String finalFoodName = isNameUnchanged ? widget.food.foodName : _name.trim();

    bool isBlueprintChanged = !isNameUnchanged ||
                              _cal.trim() != widget.food.baseCalories.toString() ||
                              _pro.trim() != widget.food.baseProtein.toString() ||
                              _carb.trim() != widget.food.baseCarbs.toString() ||
                              _fat.trim() != widget.food.baseFat.toString();

    final updatedLogEntry = FoodResult(
      id: widget.food.id, 
      foodName: finalFoodName, 
      baseCalories: int.tryParse(_cal.trim()) ?? 0,
      baseProtein: int.tryParse(_pro.trim()) ?? 0,
      baseCarbs: int.tryParse(_carb.trim()) ?? 0,
      baseFat: int.tryParse(_fat.trim()) ?? 0,
      measurementUnit: widget.food.measurementUnit,
      consumedAmount: _consumedAmount, 
      assignedMealType: widget.food.assignedMealType,
    );

    FoodResult? newBlueprint;
    if (isBlueprintChanged) {
      newBlueprint = FoodResult(
        id: "custom_${DateTime.now().millisecondsSinceEpoch}", 
        foodName: finalFoodName,
        baseCalories: int.tryParse(_cal.trim()) ?? 0,
        baseProtein: int.tryParse(_pro.trim()) ?? 0,
        baseCarbs: int.tryParse(_carb.trim()) ?? 0,
        baseFat: int.tryParse(_fat.trim()) ?? 0,
        measurementUnit: widget.food.measurementUnit,
        consumedAmount: 1.0, 
        assignedMealType: widget.food.assignedMealType,
      );
    }

    widget.onSave(updatedLogEntry, newBlueprint);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // CẢI THIỆN ARCH: Bọc SingleChildScrollView để chống lỗi tràn màn hình khi mở bàn phím
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.nutrition.title_edit_food, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 24),
            
            GymTextField(
              initialValue: _name,
              labelText: t.nutrition.lbl_quick_food_name,
              errorText: _nameError,
              isNumber: false,
              onChanged: (v) { _name = v; _validateEdit(); },
            ),
            const SizedBox(height: 16),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: GymTextField(initialValue: _cal, labelText: t.nutrition.lbl_dash_calories, unitText: 'kcal', isInteger: true, errorText: _calError, onChanged: (v) { _cal = v; _validateEdit(); })),
                const SizedBox(width: 16),
                Expanded(child: GymTextField(initialValue: _pro, labelText: t.onboarding.lbl_macro_protein, unitText: 'g', isInteger: true, errorText: _proError, onChanged: (v) { _pro = v; _validateEdit(); })),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: GymTextField(initialValue: _carb, labelText: t.onboarding.lbl_macro_carbs, unitText: 'g', isInteger: true, errorText: _carbError, onChanged: (v) { _carb = v; _validateEdit(); })),
                const SizedBox(width: 16),
                Expanded(child: GymTextField(initialValue: _fat, labelText: t.onboarding.lbl_macro_fat, unitText: 'g', isInteger: true, errorText: _fatError, onChanged: (v) { _fat = v; _validateEdit(); })),
              ],
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.nutrition.lbl_quick_portion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                UniversalFoodStepper(
                  consumedAmount: _consumedAmount,
                  unit: widget.food.measurementUnit,
                  validator: _validatePortion,
                  onDecrease: () {
                    if (_consumedAmount > 1.0) {
                      setState(() => _consumedAmount -= 1.0);
                    }
                  },
                  onIncrease: () {
                    final nextQty = _consumedAmount + 1.0;
                    final err = _validatePortion(nextQty);
                    if (err != null) {
                      GymSnackbar.show(
                        context,
                        message: err,
                        icon: Symbols.error,
                        accentColor: Theme.of(context).colorScheme.error,
                      );
                    } else {
                      setState(() => _consumedAmount = nextQty);
                    }
                  },
                  onManualInput: (newQty) {
                    setState(() => _consumedAmount = newQty);
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),
              
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary, 
                foregroundColor: colorScheme.onPrimary, 
                minimumSize: const Size(double.infinity, 56), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                elevation: 4,
                disabledBackgroundColor: colorScheme.surfaceContainerHighest
              ),
              onPressed: _isEditValid() ? _submit : null,
              child: Text(t.common.save, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}