import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:plato_gymapp/core/utils/search_utils.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/exercise_library_cubit.dart';

import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart';


class CreateCustomExerciseScreen extends StatefulWidget {
  final Exercise? exerciseToEdit;

  const CreateCustomExerciseScreen({super.key, this.exerciseToEdit});

  @override
  State<CreateCustomExerciseScreen> createState() => _CreateCustomExerciseScreenState();
}

class _CreateCustomExerciseScreenState extends State<CreateCustomExerciseScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _instructionCtrl;
  
  ExerciseType _selectedType = ExerciseType.WEIGHT_REPS;
  MuscleGroup? _selectedPrimaryMuscle;
  List<MuscleGroup> _selectedSecondaryMuscles = [];
  Equipment? _selectedEquipment;
  String? _localImagePath;

  bool _isSaving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.exerciseToEdit?.name ?? "");
    _instructionCtrl = TextEditingController(text: widget.exerciseToEdit?.instructions ?? "");
    
    if (widget.exerciseToEdit != null) {
      _selectedType = widget.exerciseToEdit!.type;
      _selectedPrimaryMuscle = widget.exerciseToEdit!.primaryMuscle;
      _selectedSecondaryMuscles = List.from(widget.exerciseToEdit!.secondaryMuscles ?? []);
      _selectedEquipment = widget.exerciseToEdit!.equipment;
      _localImagePath = widget.exerciseToEdit!.localImagePath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _instructionCtrl.dispose();
    super.dispose();
  }

  // Lọc thiết bị hợp lý dựa trên loại bài tập
  List<Equipment> get _availableEquipments {
    return Equipment.values.where((eq) {
      final name = eq.name.toLowerCase();
      
      if (_selectedType == ExerciseType.WEIGHT_REPS) {
        // Tạ & Số lần: Không đi kèm bodyweight hoặc none
        return name != 'bodyweight' && name != 'none';
      } 
      
      if (_selectedType == ExerciseType.CARDIO_DISTANCE || _selectedType == ExerciseType.CARDIO_STEPS) {
        // Cardio: Loại bỏ tạ đơn, tạ đòn, cáp...
        if (name == 'barbell' || name == 'dumbbell' || name == 'kettlebell' || name == 'cable' || name == 'ez_bar') return false;
      }
      
      return true; // Các trường hợp còn lại cho phép
    }).toList();
  }

  // ĐỒNG BỘ: Getter kiểm tra validation real-time để enable/disable nút Save
  bool get _isSaveEnabled {
    final name = _nameCtrl.text.trim();
    return name.isNotEmpty && 
           _nameError == null && 
           _selectedPrimaryMuscle != null && 
           _selectedEquipment != null && 
           !_isSaving;
  }

  void _validateName(String value) {
    if (value.trim().length > 100) {
      setState(() => _nameError = t.explore.err_custom_exercise_name_too_long);
    } else if (_nameError != null) {
      setState(() => _nameError = null);
    } else {
      // Trigger rebuild to update _isSaveEnabled state when typing valid characters
      setState(() {}); 
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.png";
      final String savedPath = "${appDir.path}/$fileName";
      
      final File localFile = await File(image.path).copy(savedPath);
      
      setState(() {
        _localImagePath = localFile.path;
      });
    }
  }

  void _saveExercise() async {
    if (!_isSaveEnabled) return;

    setState(() => _isSaving = true);

    final exerciseId = widget.exerciseToEdit?.id ?? "custom_${DateTime.now().millisecondsSinceEpoch}";

    final newExercise = Exercise(
      id: exerciseId,
      name: _nameCtrl.text.trim(),
      type: _selectedType,
      primaryMuscle: _selectedPrimaryMuscle,
      secondaryMuscles: _selectedSecondaryMuscles,
      equipment: _selectedEquipment,
      instructions: _instructionCtrl.text.trim(),
      isCustom: true,
      localImagePath: _localImagePath,
      isDeleted: false,
    );

    if (widget.exerciseToEdit != null) {
      await context.read<ExerciseLibraryCubit>().updateCustomExercise(newExercise);
    } else {
      await context.read<ExerciseLibraryCubit>().createNewCustomExercise(newExercise);
    }

    if (mounted) {
      Navigator.pop(context, newExercise);
    }
  }

  // ===================== UI HELPERS =====================

  void _showSingleSelectSheet<T>({
    required String title,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) labelBuilder,
    required void Function(T) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2)),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (ctx, index) {
                      final item = items[index];
                      final isSelected = item == selectedItem;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        title: Text(labelBuilder(item), style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal, fontSize: 16)),
                        trailing: isSelected ? Icon(Symbols.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                        onTap: () {
                          onSelected(item);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMultiSelectSheet<T>({
    required String title,
    required List<T> items,
    required List<T> selectedItems,
    required String Function(T) labelBuilder,
    required void Function(List<T>) onSaved,
  }) {
    List<T> tempSelected = List.from(selectedItems);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.common.cancel, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
                          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {
                              onSaved(tempSelected);
                              Navigator.pop(ctx);
                            }, 
                            child: Text(t.common.save, style: const TextStyle(fontWeight: FontWeight.bold))
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2)),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (ctx, index) {
                          final item = items[index];
                          final isSelected = tempSelected.contains(item);
                          return CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                            title: Text(labelBuilder(item), style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal, fontSize: 16)),
                            value: isSelected,
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setStateSheet(() {
                                if (val == true) {
                                  tempSelected.add(item);
                                } else {
                                  tempSelected.remove(item);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          }
        );
      },
    );
  }

  Widget _buildSelectorField({
    required String label,
    required String? valueText,
    required String hintText,
    required VoidCallback onTap,
    bool isMandatory = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValue = valueText != null && valueText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
            if (isMandatory) Text(' *', style: TextStyle(color: colorScheme.error, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus(); 
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hasValue ? valueText : hintText, 
                    style: TextStyle(
                      fontWeight: hasValue ? FontWeight.bold : FontWeight.normal, 
                      fontSize: 16,
                      color: hasValue ? colorScheme.onSurface : colorScheme.onSurfaceVariant
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  )
                ),
                Icon(Symbols.unfold_more, color: colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.exerciseToEdit != null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: isEditing ? t.explore.title_edit_custom_exercise : t.explore.title_create_custom_exercise,
        onBackClick: () => Navigator.pop(context),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. CHỌN ẢNH
                Center(
                  child: GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus(); 
                      _pickImage();
                    },
                    child: Container(
                      height: 200, width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5), style: BorderStyle.solid),
                      ),
                      child: _localImagePath != null && _localImagePath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(File(_localImagePath!), fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Symbols.add_photo_alternate, size: 48, color: colorScheme.primary.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                Text(t.explore.label_custom_exercise_add_image, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 2. TÊN BÀI TẬP (Bắt buộc)
                Row(
                  children: [
                    Text(t.explore.label_custom_exercise_name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
                    Text(' *', style: TextStyle(color: colorScheme.error, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    // ĐỒNG BỘ: Viền đỏ nếu có lỗi
                    border: _nameError != null ? Border.all(color: colorScheme.error, width: 1.5) : Border.all(color: Colors.transparent, width: 1.5),
                  ),
                  child: TextField(
                    controller: _nameCtrl,
                    onChanged: _validateName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: t.explore.hint_custom_exercise_name,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                // ĐỒNG BỘ: Hiển thị lỗi có animation giống RoutineScreen
                if (_nameError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 16, top: 8),
                    child: Row(
                      children: [
                        Icon(Symbols.error_outline, color: colorScheme.error, size: 14),
                        const SizedBox(width: 4),
                        Text(_nameError!, style: TextStyle(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ).animate().fade().slideY(begin: -0.2, end: 0),
                const SizedBox(height: 24),

                // 3. LOẠI BÀI TẬP (Bắt buộc)
                _buildSelectorField(
                  label: t.explore.label_custom_exercise_type,
                  valueText: t.translateDynamic('exercises.type_${_selectedType.name.toLowerCase()}'),
                  hintText: '',
                  isMandatory: true,
                  onTap: () => _showSingleSelectSheet<ExerciseType>(
                    title: t.explore.label_custom_exercise_type,
                    items: ExerciseType.values,
                    selectedItem: _selectedType,
                    labelBuilder: (item) => t.translateDynamic('exercises.type_${item.name.toLowerCase()}'),
                    onSelected: (val) {
                      setState(() {
                        _selectedType = val;
                        if (_selectedEquipment != null && !_availableEquipments.contains(_selectedEquipment)) {
                          _selectedEquipment = null; 
                        }
                      });
                    }
                  )
                ),
                const SizedBox(height: 24),

                // 4. THIẾT BỊ (Bắt buộc)
                _buildSelectorField(
                  label: t.explore.label_filter_equipment,
                  valueText: _selectedEquipment != null ? t.translateDynamic('equipment.${_selectedEquipment!.name.toLowerCase()}') : null,
                  hintText: t.explore.label_custom_exercise_none,
                  isMandatory: true,
                  onTap: () => _showSingleSelectSheet<Equipment>(
                    title: t.explore.label_filter_equipment,
                    items: _availableEquipments, 
                    selectedItem: _selectedEquipment,
                    labelBuilder: (e) => t.translateDynamic('equipment.${e.name.toLowerCase()}'),
                    onSelected: (val) => setState(() => _selectedEquipment = val)
                  )
                ),
                const SizedBox(height: 24),

                // 5. NHÓM CƠ CHÍNH (Bắt buộc)
                _buildSelectorField(
                  label: t.explore.label_filter_muscle,
                  valueText: _selectedPrimaryMuscle?.getLocalizedName(),
                  hintText: t.explore.label_custom_exercise_none,
                  isMandatory: true,
                  onTap: () => _showSingleSelectSheet<MuscleGroup>(
                    title: t.explore.label_filter_muscle,
                    items: MuscleGroup.values,
                    selectedItem: _selectedPrimaryMuscle,
                    labelBuilder: (m) => m.getLocalizedName(),
                    onSelected: (val) {
                      setState(() {
                        _selectedPrimaryMuscle = val;
                        if (_selectedSecondaryMuscles.contains(val)) {
                          _selectedSecondaryMuscles.remove(val);
                        }
                      });
                    }
                  )
                ),
                const SizedBox(height: 24),

                // 6. NHÓM CƠ PHỤ (Tuỳ chọn)
                _buildSelectorField(
                  label: t.explore.label_secondary_muscle,
                  valueText: _selectedSecondaryMuscles.isNotEmpty 
                    ? _selectedSecondaryMuscles.map((m) => m.getLocalizedName()).join(', ') 
                    : null,
                  hintText: t.explore.label_custom_exercise_none,
                  isMandatory: false,
                  onTap: () => _showMultiSelectSheet<MuscleGroup>(
                    title: t.explore.label_secondary_muscle,
                    items: MuscleGroup.values.where((m) => m != _selectedPrimaryMuscle).toList(),
                    selectedItems: _selectedSecondaryMuscles,
                    labelBuilder: (m) => m.getLocalizedName(),
                    onSaved: (val) => setState(() => _selectedSecondaryMuscles = val)
                  )
                ),
                const SizedBox(height: 24),

                // 7. GHI CHÚ (Tuỳ chọn)
                Text(t.explore.title_exercise_detail_instructions, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextField(
                  controller: _instructionCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: t.explore.hint_custom_exercise_instructions,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 48),

                // NÚT LƯU (ĐỒNG BỘ: Vô hiệu hoá nếu chưa hợp lệ)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaveEnabled ? colorScheme.primary : colorScheme.surfaceContainerHighest, 
                    foregroundColor: _isSaveEnabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: _isSaveEnabled ? 4 : 0,
                  ),
                  onPressed: _isSaveEnabled ? _saveExercise : null,
                  child: _isSaving 
                      ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 3))
                      : Text(t.common.save, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}