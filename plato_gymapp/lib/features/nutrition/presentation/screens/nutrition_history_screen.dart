import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/designsystem/theme/app_theme.dart';
import '../../../../core/database/entities.dart';
import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../bloc/nutrition_cubit.dart';
import '../../data/models/nutrition_models.dart';
import '../components/nutrition_components.dart';

class NutritionHistoryScreen extends StatelessWidget {
  const NutritionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = context.watch<NutritionCubit>().state.nutritionHistory;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.nutrition.title_history,
        onBackClick: () => context.pop(),
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.history_toggle_off, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    t.nutrition.msg_empty_history,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final daily = history[index];
                return FadeInSlide(
                  delayIndex: index,
                  child: _HistoryCard(daily: daily),
                );
              },
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DailyNutrition daily;
  const _HistoryCard({required this.daily});

  Widget _buildMealSection(String title, List<FoodResult> foods, ColorScheme colorScheme) {
    if (foods.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 14)),
          const SizedBox(height: 8),
          ...foods.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.translateDynamic(f.foodName), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      // ĐÃ FIX: Sử dụng Component MacroText để đồng bộ màu và format
                      MacroText(
                        protein: f.calculatedTotalProtein, 
                        carbs: f.calculatedTotalCarbs, 
                        fat: f.calculatedTotalFat,
                        baseStyle: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ĐÃ FIX: Đồng bộ key format_kcal
                Text(t.nutrition.format_kcal(arg1: f.calculatedTotalCalories.toString()), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.primary)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;
    
    DateTime? date;
    try {
      date = DateFormat('yyyy-MM-dd').parse(daily.formattedDateString);
    } catch (_) {}
    
    final dateStr = date != null ? DateFormat('dd/MM/yyyy').format(date) : daily.formattedDateString;
    final totalFoodsCount = daily.allMeals.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Symbols.calendar_today, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Symbols.water_drop, size: 14, color: Colors.blue, fill: 1.0),
                    const SizedBox(width: 4),
                    Text('${daily.waterConsumedLiters.toStringAsFixed(1)}L', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _MacroStat(label: t.nutrition.label_dashboard_calories, value: '${daily.dailyTotalCalories}', suffix: 'kcal', color: colorScheme.primary)),
              // ĐÃ FIX: Đồng bộ màu sắc
              Expanded(child: _MacroStat(label: t.onboarding.label_macro_protein, value: '${daily.dailyTotalProtein}', suffix: 'g', color: gymColors.fireHexagon)),
              Expanded(child: _MacroStat(label: t.onboarding.label_macro_carbs, value: '${daily.dailyTotalCarbs}', suffix: 'g', color: gymColors.success)),
              Expanded(child: _MacroStat(label: t.onboarding.label_macro_fat, value: '${daily.dailyTotalFat}', suffix: 'g', color: gymColors.goldRank)),
            ],
          ),
          
          if (totalFoodsCount > 0) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            Text(
              t.nutrition.msg_total_foods_consumed(arg1: totalFoodsCount.toString()), 
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)
            ),
            
            _buildMealSection(t.nutrition.name_meal_breakfast, daily.breakfastMealsList, colorScheme),
            _buildMealSection(t.nutrition.name_meal_lunch, daily.lunchMealsList, colorScheme),
            _buildMealSection(t.nutrition.name_meal_dinner, daily.dinnerMealsList, colorScheme),
            _buildMealSection(t.nutrition.name_meal_snack, daily.snackMealsList, colorScheme),
          ]
        ],
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color color;

  const _MacroStat({required this.label, required this.value, required this.suffix, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(width: 2),
              Text(suffix, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}