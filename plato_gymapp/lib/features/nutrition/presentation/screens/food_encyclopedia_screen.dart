import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';


import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/designsystem/components/gym_search_bar.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart';

import '../bloc/nutrition_cubit.dart';
import '../components/nutrition_components.dart';



class FoodEncyclopediaScreen extends StatefulWidget {
  final MealType mealType;
  final List<FoodResult> foodDatabase;
  final List<FoodResult> recentFoods;
  final Function(Map<FoodResult, double>) onAddFoods; 
  final Function(int) onQuickAdd; 
  final VoidCallback onBack;

  const FoodEncyclopediaScreen({
    super.key,
    required this.mealType,
    required this.foodDatabase,
    required this.recentFoods,
    required this.onAddFoods,
    required this.onQuickAdd, 
    required this.onBack,
  });

  @override
  State<FoodEncyclopediaScreen> createState() => _FoodEncyclopediaScreenState();
}

class _FoodEncyclopediaScreenState extends State<FoodEncyclopediaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";
  
  final Map<FoodResult, double> _selectedFoods = {}; 

  // Form Nhập nhanh
  String _quickName = "";
  String _quickCal = "";
  String _quickPro = "";
  String _quickCarb = "";
  String _quickFat = "";
  double _quickQty = 1.0;
  FoodUnit _quickUnit = FoodUnit.SERVING; 

  // Trạng thái Báo lỗi tách biệt (Inline Errors)
  String? _quickNameError;
  String? _quickCalError;
  String? _quickProError;
  String? _quickCarbError;
  String? _quickFatError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isCustomFood(FoodResult f) => f.id.startsWith('custom_');

  // HÀM KIỂM TRA LỖI NỘI TUYẾN DÀNH CHO NHẬP NHANH
  void _validateQuickAdd() {
    setState(() {
      // Name
      if (_quickName.trim().isEmpty) { _quickNameError = null; }
      else if (!RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(_quickName) || _quickName.length > 50) {
        _quickNameError = t.nutrition.err_food_name;
      } else { _quickNameError = null; }

      // Calories
      if (_quickCal.trim().isEmpty) { _quickCalError = null; }
      else {
        final cal = int.tryParse(_quickCal.trim()) ?? -1;
        if (cal < 1 || cal > 10000) {
          _quickCalError = t.nutrition.err_food_cal;
        } else {
          _quickCalError = null;
        }
      }

      // Protein
      if (_quickPro.trim().isEmpty) { _quickProError = null; }
      else {
        final p = int.tryParse(_quickPro.trim()) ?? -1;
        if (p < 0 || p > 500) {
          _quickProError = t.nutrition.err_food_pcf;
        } else {
          _quickProError = null;
        }
      }

      // Carbs
      if (_quickCarb.trim().isEmpty) { _quickCarbError = null; }
      else {
        final c = int.tryParse(_quickCarb.trim()) ?? -1;
        if (c < 0 || c > 500) {
          _quickCarbError = t.nutrition.err_food_pcf;
        } else {
          _quickCarbError = null;
        }
      }

      // Fat
      if (_quickFat.trim().isEmpty) { _quickFatError = null; }
      else {
        final f = int.tryParse(_quickFat.trim()) ?? -1;
        if (f < 0 || f > 500) {
          _quickFatError = t.nutrition.err_food_pcf;
        } else {
          _quickFatError = null;
        }
      }
    });
  }

  bool _isQuickAddValid() {
    if (_quickName.trim().isEmpty || _quickCal.trim().isEmpty || _quickPro.trim().isEmpty || _quickCarb.trim().isEmpty || _quickFat.trim().isEmpty) return false;
    return _quickNameError == null && _quickCalError == null && _quickProError == null && _quickCarbError == null && _quickFatError == null;
  }

  void _submitFullQuickAdd() {
    final cal = int.tryParse(_quickCal.trim()) ?? 0;
    if (cal <= 0) return;

    final customFood = FoodResult(
      id: "custom_${DateTime.now().millisecondsSinceEpoch}",
      foodName: _quickName.trim(),
      baseCalories: cal,
      baseProtein: int.tryParse(_quickPro.trim()) ?? 0,
      baseCarbs: int.tryParse(_quickCarb.trim()) ?? 0,
      baseFat: int.tryParse(_quickFat.trim()) ?? 0,
      measurementUnit: _quickUnit, 
      consumedAmount: 1.0, 
      assignedMealType: widget.mealType,
    );

    context.read<NutritionCubit>().saveCustomFoodBlueprint(customFood);
    widget.onAddFoods({customFood: _quickQty});
    context.pop();
  }

  // VALIDATION VẬT LÝ: Ràng buộc an toàn để truyền vào Stepper (Giới hạn tối đa của 1 Card)
  String? _validateFoodPortion(FoodResult food, double qty) {
    if (food.baseCalories * qty > 20000) return t.nutrition.err_food_exceed_cal;
    if (food.baseProtein * qty > 1000 || food.baseCarbs * qty > 1000 || food.baseFat * qty > 1000) {
      return t.nutrition.err_food_exceed_pcf;
    }
    return null;
  }

  void _showEditFoodSheet(FoodResult originalFood) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface, 
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)), 
      ),
      builder: (ctx) => _EditFoodBottomSheet(
        food: originalFood,
        onSave: (editedFood) {
          context.read<NutritionCubit>().saveCustomFoodBlueprint(editedFood);

          setState(() {
            final oldQty = _selectedFoods[originalFood];
            _selectedFoods.remove(originalFood);
            if (oldQty != null) _selectedFoods[editedFood] = oldQty;
          });
        },
      )
    );
  }

  void _showDeleteCustomFoodDialog(BuildContext context, FoodResult food, NutritionCubit cubit) async {
    final confirm = await GymDialog.showDestructive(
      context: context,
      title: t.common.title_delete_dialog_main,
      message: t.nutrition.msg_delete_cust_food,
      cancelText: t.common.cancel,
      confirmText: t.common.delete,
    );
    
    if (confirm == true) {
      cubit.deleteCustomFoodBlueprint(food.id);
      setState(() {
        _selectedFoods.remove(food);
      });
    }
  }

  String _getMealNameKey(MealType type) {
    switch (type) {
      case MealType.BREAKFAST: return t.nutrition.name_meal_breakfast;
      case MealType.LUNCH: return t.nutrition.name_meal_lunch;
      case MealType.DINNER: return t.nutrition.name_meal_dinner;
      case MealType.SNACK: return t.nutrition.name_meal_snack;
      
    }
  }

  String _translateFoodUnit(FoodUnit unit) {
    switch (unit) {
      case FoodUnit.GRAM: return t.nutrition.lbl_unit_gram;
      case FoodUnit.ML: return t.nutrition.lbl_unit_ml;
      case FoodUnit.QUANTITY: return t.nutrition.lbl_unit_quantity;
      case FoodUnit.SERVING: return t.nutrition.lbl_unit_serving;
      case FoodUnit.OZ: return t.nutrition.lbl_unit_oz;
      
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nutritionCubit = context.watch<NutritionCubit>();
    
    final foodDatabase = nutritionCubit.state.foodDatabase; 
    final recentFoods = nutritionCubit.state.recentFoods; 
    final alreadyConsumed = nutritionCubit.state.nutritionToday.getMealsForType(widget.mealType);

    final allFoods = [...foodDatabase, ...recentFoods]
        .fold<Map<String, FoodResult>>({}, (map, f) => map..putIfAbsent(f.id, () => f))
        .values.toList();

    final queryTokens = _searchQuery.removeAccents().toLowerCase().trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final filteredFoods = queryTokens.isEmpty 
        ? allFoods 
        : allFoods.where((f) {
            final normalizedName = t.translateDynamic(f.foodName).removeAccents().toLowerCase();
            return queryTokens.every((token) => normalizedName.contains(token));
          }).toList();

    final customFoods = filteredFoods.where(_isCustomFood).toList();
    final sqlFoods = filteredFoods.where((f) => !_isCustomFood(f)).toList();

    Widget buildLibrarySection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: GymSearchBar(
                searchQuery: _searchQuery,
                onSearchChange: (v) => setState(() => _searchQuery = v),
                placeholderText: t.nutrition.hint_food_search,
              ),
            ),
          ),
          
          Expanded(
            child: filteredFoods.isEmpty
                ? Center(child: Text(t.nutrition.msg_food_not_found, style: TextStyle(color: colorScheme.onSurfaceVariant)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (customFoods.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            t.nutrition.lbl_cust_foods, 
                            style: TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.bold, 
                              color: Theme.of(context).gymColors.goldRank, // Đã đồng bộ theo Theme
                            ),
                          ),
                        ),
                        ...customFoods.asMap().entries.map((entry) => _buildFoodCard(entry.value, alreadyConsumed, nutritionCubit, entry.key, colorScheme)),
                        const SizedBox(height: 16),
                      ],
                      
                      if (sqlFoods.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(t.nutrition.lbl_system_foods, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
                        ),
                        ...sqlFoods.asMap().entries.map((entry) => _buildFoodCard(entry.value, alreadyConsumed, nutritionCubit, entry.key + customFoods.length, colorScheme)),
                      ]
                    ],
                  ),
          ),
        ],
      );
    }

    Widget buildQuickAddSection() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.nutrition.title_food_quick_input, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary)),
              const SizedBox(height: 24),
              
              // SỬ DỤNG GYM TEXT FIELD CHO TẤT CẢ (HỖ TRỢ INLINE ERROR)
              GymTextField(
                initialValue: _quickName,
                labelText: t.nutrition.lbl_quick_food_name,
                errorText: _quickNameError,
                isNumber: false,
                onChanged: (v) { _quickName = v; _validateQuickAdd(); },
              ),
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: GymTextField(initialValue: _quickCal, labelText: t.nutrition.lbl_dash_calories, unitText: 'kcal', isInteger: true, errorText: _quickCalError, onChanged: (v) { _quickCal = v; _validateQuickAdd(); })),
                  const SizedBox(width: 16),
                  Expanded(child: GymTextField(initialValue: _quickPro, labelText: t.onboarding.lbl_macro_protein, unitText: 'g', isInteger: true, errorText: _quickProError, onChanged: (v) { _quickPro = v; _validateQuickAdd(); })),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: GymTextField(initialValue: _quickCarb, labelText: t.onboarding.lbl_macro_carbs, unitText: 'g', isInteger: true, errorText: _quickCarbError, onChanged: (v) { _quickCarb = v; _validateQuickAdd(); })),
                  const SizedBox(width: 16),
                  Expanded(child: GymTextField(initialValue: _quickFat, labelText: t.onboarding.lbl_macro_fat, unitText: 'g', isInteger: true, errorText: _quickFatError, onChanged: (v) { _quickFat = v; _validateQuickAdd(); })),
                ],
              ),
              
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(t.nutrition.lbl_quick_portion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(width: 16),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4), 
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: PopupMenuButton<FoodUnit>(
                            initialValue: _quickUnit,
                            position: PopupMenuPosition.under,
                            color: colorScheme.surface, 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)), 
                            ),
                            elevation: 4,
                            onSelected: (v) {
                              setState(() {
                                if ((_quickUnit == FoodUnit.GRAM || _quickUnit == FoodUnit.ML) && (v != FoodUnit.GRAM && v != FoodUnit.ML)) {
                                   _quickQty = 1.0; 
                                } else if ((_quickUnit != FoodUnit.GRAM && _quickUnit != FoodUnit.ML) && (v == FoodUnit.GRAM || v == FoodUnit.ML)) {
                                   _quickQty = 100.0;
                                }
                                _quickUnit = v;
                              });
                            },
                            itemBuilder: (context) => FoodUnit.values.map((u) => PopupMenuItem(
                              value: u,
                              child: Text(_translateFoodUnit(u), style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                            )).toList(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_translateFoodUnit(_quickUnit), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Icon(Symbols.unfold_more, color: colorScheme.primary, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Align(
                    alignment: Alignment.center,
                    child: UniversalFoodStepper(
                      consumedAmount: _quickQty,
                      unit: _quickUnit,
                      // Chỉ giới hạn điều hướng Scale ở QuickAdd vì lượng base chưa tồn tại để check validator
                      onDecrease: () => setState(() { 
                        double step = (_quickUnit == FoodUnit.GRAM || _quickUnit == FoodUnit.ML) ? 10.0 : 1.0;
                        if (_quickQty > step) {
                          _quickQty -= step;
                        } else if (_quickQty > 1) _quickQty -= 1;
                      }),
                      onIncrease: () => setState(() {
                        double step = (_quickUnit == FoodUnit.GRAM || _quickUnit == FoodUnit.ML) ? 10.0 : 1.0;
                        _quickQty += step;
                      }),
                      onManualInput: (newQty) => setState(() => _quickQty = newQty > 0 ? newQty : 1.0),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
                
              ElevatedButton.icon(
                icon: const Icon(Symbols.check),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary, 
                  foregroundColor: colorScheme.onPrimary, 
                  minimumSize: const Size(double.infinity, 56), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  disabledBackgroundColor: colorScheme.surfaceContainerHighest
                ),
                onPressed: _isQuickAddValid() ? _submitFullQuickAdd : null,
                label: Text(t.nutrition.btn_quick_save_log, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.nutrition.title_food_add_to_meal(arg1: _getMealNameKey(widget.mealType)),
        onBackClick: () => context.pop(),
      ),
      bottomNavigationBar: _selectedFoods.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary, 
                    foregroundColor: colorScheme.onPrimary, 
                    minimumSize: const Size(double.infinity, 56), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.1)
                  ),
                  onPressed: () {
                    widget.onAddFoods(_selectedFoods);
                    context.pop();
                  },
                  child: Text(t.nutrition.btn_food_add_selected(arg1: _selectedFoods.length.toString()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;

          if (isTablet) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: buildLibrarySection()),
                    Container(width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(vertical: 24)),
                    Expanded(flex: 1, child: buildQuickAddSection()),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                onTap: (_) => setState(() {}), 
                tabs: [
                  Tab(text: t.nutrition.tab_food_library),
                  Tab(text: t.nutrition.tab_food_quick_add),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    buildLibrarySection(),
                    buildQuickAddSection(),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildFoodCard(FoodResult food, List<FoodResult> alreadyConsumed, NutritionCubit nutritionCubit, int animIndex, ColorScheme colorScheme) {
    final existingItem = alreadyConsumed.cast<FoodResult?>().firstWhere(
      (f) => f?.foodName == food.foodName, 
      orElse: () => null
    );
    final isExisting = existingItem != null;
    final qty = isExisting ? existingItem.consumedAmount : (_selectedFoods[food] ?? 0.0);

    final unitLabel = (food.measurementUnit == FoodUnit.GRAM) ? t.nutrition.lbl_food_unit_100g :
                      (food.measurementUnit == FoodUnit.ML) ? t.nutrition.lbl_food_unit_100ml :
                      t.nutrition.fmt_food_unit_pieces(arg1: _translateFoodUnit(food.measurementUnit));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: qty > 0 ? colorScheme.primary.withValues(alpha: 0.5) : colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text(t.translateDynamic(food.foodName), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis)),
                
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isCustomFood(food))
                      IconButton(
                        icon: Icon(Symbols.delete_outline, size: 20, color: colorScheme.error),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showDeleteCustomFoodDialog(context, food, nutritionCubit),
                      ),
                    if (_isCustomFood(food)) const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Symbols.edit, size: 20, color: colorScheme.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showEditFoodSheet(food),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            MacroText(
              calories: food.baseCalories,
              protein: food.baseProtein,
              carbs: food.baseCarbs,
              fat: food.baseFat,
              unitSuffix: ' / $unitLabel',
              baseStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            
            if (qty > 0) ...[
              Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                    icon: const Icon(Symbols.remove_circle_outline, size: 18),
                    label: Text(t.nutrition.btn_deselect, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      if (isExisting) {
                        nutritionCubit.removeFoodFromLog(existingItem.id, widget.mealType);
                      } else {
                        setState(() => _selectedFoods.remove(food));
                      }
                    },
                  ),
                  
                  // TRUYỀN HÀM KIỂM TRA ĐỂ BÁO LỖI REAL-TIME TRONG DIALOG
                  UniversalFoodStepper(
                    consumedAmount: qty,
                    unit: food.measurementUnit,
                    validator: (val) => _validateFoodPortion(food, val),
                    onDecrease: () {
                      if (isExisting) {
                        if (qty <= 1.0) {
                          nutritionCubit.removeFoodFromLog(existingItem.id, widget.mealType);
                        } else {
                          nutritionCubit.updateFoodWeight(existingItem.id, widget.mealType, qty - 1.0);
                        }
                      } else {
                        setState(() {
                          if (qty <= 1.0) {
                            _selectedFoods.remove(food);
                          } else {
                            _selectedFoods[food] = qty - 1.0;
                          }
                        });
                      }
                    },
                    onIncrease: () {
                      final nextQty = qty + 1.0;
                      final err = _validateFoodPortion(food, nextQty);
                      if (err != null) {
                         GymSnackbar.show(
                           context,
                           message: err,
                           icon: Symbols.error,
                           accentColor: Theme.of(context).colorScheme.error,
                         );
                      } else {
                        if (isExisting) {
                          nutritionCubit.updateFoodWeight(existingItem.id, widget.mealType, nextQty);
                        } else {
                          setState(() => _selectedFoods[food] = nextQty);
                        }
                      }
                    },
                    onManualInput: (newQty) {
                      if (isExisting) {
                        nutritionCubit.updateFoodWeight(existingItem.id, widget.mealType, newQty);
                      } else {
                        setState(() => _selectedFoods[food] = newQty);
                      }
                    },
                  )
                ],
              )
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  icon: const Icon(Symbols.add, size: 18),
                  label: Text(t.nutrition.btn_add_food, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => setState(() => _selectedFoods[food] = 1.0),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _EditFoodBottomSheet extends StatefulWidget {
  final FoodResult food;
  final Function(FoodResult) onSave;

  const _EditFoodBottomSheet({required this.food, required this.onSave});

  @override
  State<_EditFoodBottomSheet> createState() => _EditFoodBottomSheetState();
}

class _EditFoodBottomSheetState extends State<_EditFoodBottomSheet> {
  late String _name;
  late String _cal;
  late String _pro;
  late String _carb;
  late String _fat;

  // Trạng thái Báo lỗi tách biệt (Inline Errors)
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
  }

  // VALIDATION VÀ SET ERROR STATE
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

  void _submit() {
    final newFood = FoodResult(
      id: widget.food.id.startsWith('custom_') ? widget.food.id : "custom_${DateTime.now().millisecondsSinceEpoch}",
      foodName: _name.trim(),
      baseCalories: int.tryParse(_cal.trim()) ?? 0,
      baseProtein: int.tryParse(_pro.trim()) ?? 0,
      baseCarbs: int.tryParse(_carb.trim()) ?? 0,
      baseFat: int.tryParse(_fat.trim()) ?? 0,
      measurementUnit: widget.food.measurementUnit,
      consumedAmount: widget.food.consumedAmount,
      assignedMealType: widget.food.assignedMealType,
    );
    widget.onSave(newFood);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 32,
      ),
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// NÂNG CẤP GYM TEXT FIELD LÊN STATEFUL WIDGET ĐỂ HỖ TRỢ INLINE ERRORS & TEXT/NUMBER
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
    this.isNumber = true, // Mặc định là Number
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
    if (widget.initialValue != oldWidget.initialValue && _controller.text != widget.initialValue) {
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
    
    return TextFormField(
      controller: _controller,
      keyboardType: widget.isNumber 
          ? (widget.isInteger ? const TextInputType.numberWithOptions(decimal: false) : const TextInputType.numberWithOptions(decimal: true))
          : TextInputType.text,
      inputFormatters: widget.isNumber 
          ? (widget.isInteger ? [FilteringTextInputFormatter.digitsOnly] : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))])
          : [], // Không giới hạn ký tự nếu là Field Text (như Tên món ăn)
      style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: widget.labelText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        
        // HỖ TRỢ RENDER LỖI INLINE (Đồng bộ với _ProfileTextField)
        error: widget.errorText != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Symbols.error_outline, color: colorScheme.error, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.errorText!,
                      style: TextStyle(color: colorScheme.error, fontSize: 12),
                    ),
                  ),
                ],
              )
            : null,
        errorMaxLines: 3,

        suffixText: widget.unitText,
        suffixStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.onSurfaceVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: widget.onChanged,
    );
  }
}

// BỔ SUNG REAL-TIME VALIDATOR VÀO STEPPER DIALOG
class UniversalFoodStepper extends StatelessWidget {
  final double consumedAmount; 
  final FoodUnit unit;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<double>? onManualInput;
  final String? Function(double)? validator; // Callback để bắt lỗi Logic Khẩu phần

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
      formatted = formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return formatted;
  }

  String get _suffix {
    switch (unit) {
      case FoodUnit.GRAM: return t.nutrition.lbl_unit_gram;
      case FoodUnit.ML: return t.nutrition.lbl_unit_ml;
      case FoodUnit.QUANTITY: return t.nutrition.lbl_unit_quantity;
      case FoodUnit.SERVING: return t.nutrition.lbl_unit_serving;
      case FoodUnit.OZ: return t.nutrition.lbl_unit_oz;
      
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Symbols.remove, size: 18, color: colorScheme.onSurfaceVariant),
            onPressed: onDecrease,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onManualInput != null ? () => _showInputDialog(context) : null,
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
                    decoration: onManualInput != null ? TextDecoration.underline : TextDecoration.none,
                    decorationStyle: TextDecorationStyle.dotted,
                  )
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Symbols.add, size: 18, color: colorScheme.primary),
            onPressed: onIncrease,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Future<void> _showInputDialog(BuildContext context) async {
    final TextEditingController ctrl = TextEditingController(text: _displayValue);
    final colorScheme = Theme.of(context).colorScheme;
    String? errorMsg;

    await GymDialog.showCustom(
      context: context,
      titleWidget: Text(
        "${t.nutrition.title_input_amount} ($_suffix)", 
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
      ),
      content: StatefulBuilder(
        builder: (context, setLocalState) {
          
          // REAL-TIME VALIDATION TRONG LÚC GÕ
          void validateRealTime(String v) {
            final val = double.tryParse(v);
            if (val == null) {
              setLocalState(() => errorMsg = t.nutrition.err_invalid_number);
              return;
            }
            
            // 1. Kiểm tra Scale Min/Max cơ bản
            if (_isScale) {
              if (val < 1 || val > 5000) {
                setLocalState(() => errorMsg = t.nutrition.err_portion_scale);
                return;
              }
            } else {
              if (val < 0.01 || val > 100) {
                setLocalState(() => errorMsg = t.nutrition.err_portion_qty);
                return;
              }
            }
            
            // 2. Chạy Custom Validator (Giới hạn 20K Calo / 1K Macros)
            double finalAmount = _isScale ? val / 100 : val;
            if (validator != null) {
               setLocalState(() => errorMsg = validator!(finalAmount));
            } else {
               setLocalState(() => errorMsg = null);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                onChanged: validateRealTime, // Gắn bắt lỗi tại đây
                decoration: InputDecoration(
                  suffixText: _suffix,
                  
                  // HIỂN THỊ ERROR NGAY BÊN DƯỚI ĐƯỜNG VIỀN INPUT
                  error: errorMsg != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Symbols.error_outline, color: colorScheme.error, size: 14),
                            const SizedBox(width: 4),
                            Flexible(child: Text(errorMsg!, style: TextStyle(color: colorScheme.error, fontSize: 12))),
                          ],
                        )
                      : null,
                  errorMaxLines: 3,

                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: errorMsg != null ? colorScheme.error : colorScheme.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.error, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.error, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t.common.cancel, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorMsg != null ? colorScheme.error : colorScheme.primary, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    // KHÓA NÚT CONFIRM NẾU CÓ LỖI
                    onPressed: errorMsg != null ? null : () {
                      final val = double.tryParse(ctrl.text);
                      if (val != null) {
                        double finalAmount = _isScale ? val / 100 : val;
                        onManualInput!(finalAmount);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(t.common.confirm),
                  )
                ]
              )
            ],
          );
        }
      ),
      actions: []
    );
  }
}