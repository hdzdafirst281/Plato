import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/database/entities.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/exercise_library_cubit.dart';

import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/database/enums.dart';

import '../../data/models/workout_models.dart';
import '../bloc/workout_cubit.dart';
import '../components/workout_components.dart'; 

class ExploreProgramsScreen extends StatefulWidget {
  const ExploreProgramsScreen({super.key});

  @override
  State<ExploreProgramsScreen> createState() => _ExploreProgramsScreenState();
}

class _ExploreProgramsScreenState extends State<ExploreProgramsScreen> {
  String? _filterLevel;
  WorkoutEnvironment? _filterEnv;
  WorkoutGoal? _filterGoal;
  
  bool _hideAddedPrograms = false;
  WorkoutProgram? _detailedProgram;

  @override
  void initState() {
    super.initState();
    context.read<WorkoutCubit>().triggerSyncPrograms();
  }

  String _translateLevel(String l) {
    if (l == "BEGINNER") return t.explore.lbl_filter_level_newbie;
    if (l == "ADVANCED") return t.explore.lbl_filter_level_advanced;
    return t.explore.lbl_filter_level_intermediate;
  }

  String _translateGoal(WorkoutGoal g) {
    if (g == WorkoutGoal.BULK) return t.profile.goal_bulk;
    if (g == WorkoutGoal.CUT) return t.profile.goal_cut;
    if (g == WorkoutGoal.STRENGTH) return t.profile.goal_strength;
    return g.name;
  }

  String _translateEnv(WorkoutEnvironment env) {
    if (env == WorkoutEnvironment.GYM) return t.profile.env_gym;
    if (env == WorkoutEnvironment.HOME_DUMBBELL) return t.profile.env_home_dumbbell;
    if (env == WorkoutEnvironment.HOME_BODYWEIGHT) return t.profile.env_home_bodyweight;
    return env.name;
  }

  void _showSuccessBottomSheet(WorkoutProgram prog) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).gymColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Symbols.check_circle, color: Theme.of(context).gymColors.success, size: 48),
            ),
            const SizedBox(height: 24),
            Text(t.explore.title_download_success, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(t.explore.msg_download_success(arg1: t.translateDynamic(prog.name)), textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(t.explore.btn_continue_exploring, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () {
                      Navigator.pop(ctx); 
                      context.pop(); 
                    },
                    child: Text(t.explore.btn_view_program, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final cloudPrograms = context.watch<WorkoutCubit>().state.exploreProgramsList; 
    
    final userLibraryRoutines = context.watch<WorkoutCubit>().state.userCustomRoutinesList; 
    final addedProgramNames = userLibraryRoutines.map((r) => r.programName).whereType<String>().toSet();

    final filteredPrograms = cloudPrograms.where((p) {
      final matchLevel = _filterLevel == null || p.difficulty == _filterLevel;
      final matchEnv = _filterEnv == null || p.environment == _filterEnv;
      final matchGoal = _filterGoal == null || p.goal == _filterGoal;
      final matchHidden = !_hideAddedPrograms || !addedProgramNames.contains(p.name);
      return matchLevel && matchEnv && matchGoal && matchHidden;
    }).toList();

    // ĐÃ FIX: Bọc Scaffold bằng PopScope để can thiệp vào hành vi Back của điện thoại
    return PopScope(
      canPop: _detailedProgram == null, // Chỉ cho phép văng ra ngoài nếu đang ở danh sách
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Nếu điện thoại phát lệnh Back mà canPop = false, ta bắt lệnh đó để chạy setState
        if (_detailedProgram != null) {
          setState(() => _detailedProgram = null);
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: GymTopBar(
          title: _detailedProgram != null ? t.translateDynamic(_detailedProgram!.name) : t.explore.title_main,
          onBackClick: () {
            if (_detailedProgram != null) {
              setState(() => _detailedProgram = null);
            } else {
              context.pop();
            }
          },
          actions: _detailedProgram != null ? [] : [
            IconButton(
              icon: Icon(_hideAddedPrograms ? Symbols.visibility_off : Symbols.visibility, color: colorScheme.primary),
              onPressed: () => setState(() => _hideAddedPrograms = !_hideAddedPrograms),
              tooltip: _hideAddedPrograms ? t.explore.tooltip_show_all : t.explore.tooltip_hide_added,
            )
          ],
        ),
        body: _detailedProgram != null 
          ? _ProgramDetailView(
              program: _detailedProgram!, 
              isAdded: addedProgramNames.contains(_detailedProgram!.name),
              translateEnv: _translateEnv,
              translateLevel: _translateLevel,
              onAdd: () {
                context.read<WorkoutCubit>().addProgramRoutines(_detailedProgram!);
                _showSuccessBottomSheet(_detailedProgram!);
              },
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCustomFilterMenu<WorkoutGoal>(
                          context: context,
                          activeValue: _filterGoal,
                          defaultHint: t.explore.lbl_filter_goal,
                          items: WorkoutGoal.values,
                          labelBuilder: _translateGoal,
                          onClear: () => setState(() => _filterGoal = null),
                          onSelected: (v) => setState(() => _filterGoal = v),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildCustomFilterMenu<String>(
                          context: context,
                          activeValue: _filterLevel,
                          defaultHint: t.explore.lbl_filter_level,
                          items: const ["BEGINNER", "INTERMEDIATE", "ADVANCED"],
                          labelBuilder: _translateLevel,
                          onClear: () => setState(() => _filterLevel = null),
                          onSelected: (v) => setState(() => _filterLevel = v),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildCustomFilterMenu<WorkoutEnvironment>(
                          context: context,
                          activeValue: _filterEnv,
                          defaultHint: t.explore.lbl_filter_env,
                          items: WorkoutEnvironment.values,
                          labelBuilder: _translateEnv,
                          onClear: () => setState(() => _filterEnv = null),
                          onSelected: (v) => setState(() => _filterEnv = v),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: filteredPrograms.isEmpty 
                    ? Center(child: Text(cloudPrograms.isEmpty ? t.explore.msg_loading : t.explore.msg_library_not_found, style: TextStyle(color: colorScheme.onSurfaceVariant)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPrograms.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final prog = filteredPrograms[index];
                          return _ProgramCard(
                            program: prog,
                            isAdded: addedProgramNames.contains(prog.name),
                            activeGoal: _filterGoal,
                            activeLevel: _filterLevel,
                            activeEnv: _filterEnv,
                            translateLevel: _translateLevel,
                            translateGoal: _translateGoal,
                            onClick: () => setState(() => _detailedProgram = prog),
                            onAdd: () {
                              context.read<WorkoutCubit>().addProgramRoutines(prog);
                              _showSuccessBottomSheet(prog);
                            },
                          );
                        },
                      ),
                )
              ],
            ),
      ),
    );
  }

  Widget _buildCustomFilterMenu<T>({
    required BuildContext context,
    required T? activeValue,
    required String defaultHint,
    required List<T> items,
    required String Function(T) labelBuilder,
    required VoidCallback onClear,
    required void Function(T) onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = activeValue != null;

    return MenuAnchor(
      builder: (context, controller, child) {
        final isExpanded = controller.isOpen;
        final borderColor = (isActive || isExpanded) ? colorScheme.primary : colorScheme.outlineVariant;
        final textColor = isActive ? colorScheme.primary : colorScheme.onSurface;

        return InkWell(
          onTap: () => isExpanded ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isActive ? labelBuilder(activeValue as T) : defaultHint,
                    style: TextStyle(fontSize: 11, color: textColor, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  GestureDetector(
                    onTap: () {
                      onClear();
                      controller.close();
                    },
                    child: Icon(Symbols.close, size: 16, color: colorScheme.primary),
                  )
                else
                  Icon(
                    isExpanded ? Symbols.arrow_drop_up : Symbols.arrow_drop_down,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        );
      },
      menuChildren: items.map((item) {
        return MenuItemButton(
          onPressed: () => onSelected(item),
          child: Text(labelBuilder(item), style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final WorkoutProgram program;
  final bool isAdded;
  final WorkoutGoal? activeGoal;
  final String? activeLevel;
  final WorkoutEnvironment? activeEnv;
  final VoidCallback onClick;
  final VoidCallback onAdd;
  final String Function(String) translateLevel;
  final String Function(WorkoutGoal) translateGoal;

  const _ProgramCard({
    required this.program, required this.isAdded,
    required this.onClick, required this.onAdd,
    this.activeGoal, this.activeLevel, this.activeEnv,
    required this.translateLevel, required this.translateGoal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    IconData getEnvIcon() {
      if (program.environment == WorkoutEnvironment.HOME_BODYWEIGHT) return Symbols.home;
      if (program.environment == WorkoutEnvironment.HOME_DUMBBELL) return Symbols.exercise;
      return Symbols.domain; 
    }

    final bgColor = isAdded ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : colorScheme.surface;
    final borderColor = isAdded ? colorScheme.outlineVariant.withValues(alpha: 0.2) : colorScheme.outline.withValues(alpha: 0.3);
    final textColor = isAdded ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6) : colorScheme.onSurface;
    final iconColor = isAdded ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5) : colorScheme.primary;
    final iconBgColor = isAdded ? colorScheme.onSurfaceVariant.withValues(alpha: 0.1) : colorScheme.primary.withValues(alpha: 0.15);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      elevation: isAdded ? 0 : 2, 
      color: bgColor, 
      child: InkWell(
        onTap: onClick, 
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(getEnvIcon(), color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.translateDynamic(program.name), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    const SizedBox(height: 4),
                    Text(t.translateDynamic(program.description), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: isAdded ? 0.5 : 1.0)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        ThemedTagChip(
                          text: translateGoal(program.goal),
                          color: activeGoal == program.goal 
                              ? colorScheme.primary.withValues(alpha: isAdded ? 0.5 : 1.0) 
                              : Colors.grey.shade600.withValues(alpha: isAdded ? 0.4 : 1.0),
                        ),
                        ThemedTagChip(
                          text: translateLevel(program.difficulty),
                          color: activeLevel == program.difficulty 
                              ? colorScheme.primary.withValues(alpha: isAdded ? 0.5 : 1.0) 
                              : Colors.grey.shade600.withValues(alpha: isAdded ? 0.4 : 1.0),
                        ),
                        ThemedTagChip(
                          text: t.explore.fmt_routines_count(arg1: program.routines.length.toString()),
                          color: Colors.grey.shade600.withValues(alpha: isAdded ? 0.4 : 1.0),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isAdded)
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.surfaceContainerHighest),
                  alignment: Alignment.center,
                  child: Icon(Symbols.check, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                )
              else
                IconButton(
                  onPressed: onAdd,
                  style: IconButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                  icon: const Icon(Symbols.add),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramDetailView extends StatelessWidget {
  final WorkoutProgram program;
  final bool isAdded;
  final String Function(String) translateLevel;
  final String Function(WorkoutEnvironment) translateEnv;
  final VoidCallback onAdd;

  const _ProgramDetailView({
    required this.program, required this.isAdded,
    required this.translateEnv, required this.translateLevel,
    required this.onAdd,
  });

  String _formatTimeStr(int seconds) {
    if (seconds <= 0) return "";
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final globalExercises = context.select<ExerciseLibraryCubit, List<Exercise>>((cubit) => cubit.state.exercises);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ThemedTagChip(text: translateEnv(program.environment), color: Theme.of(context).gymColors.success),
                      ThemedTagChip(text: translateLevel(program.difficulty), color: Theme.of(context).gymColors.warning),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(t.translateDynamic(program.description), style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 24),
                  Text(t.explore.title_program_details_count(arg1: program.routines.length.toString()), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            ...program.routines.map((routine) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.translateDynamic(routine.name), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 16),
                    ...routine.exercises.map((ex) {
                      
                      final fullExercise = globalExercises.firstWhere(
                          (e) => e.id == ex.exercise.id, 
                          orElse: () => ex.exercise
                      );
                      
                      final baseSet = ex.sets.firstOrNull;
                      String targetStr = "";
                      
                      if (baseSet != null) {
                         final timeStr = _formatTimeStr(baseSet.durationTimeSeconds);
                         
                         if (fullExercise.type == ExerciseType.TIME_ONLY) {
                           targetStr = timeStr;
                         } else if (fullExercise.type == ExerciseType.CARDIO_DISTANCE) {
                           targetStr = baseSet.distanceInKm > 0 ? "${baseSet.distanceInKm} km" : "";
                           if (timeStr.isNotEmpty) targetStr += (targetStr.isEmpty ? timeStr : " • $timeStr");
                         } else if (fullExercise.type == ExerciseType.CARDIO_STEPS) {
                           targetStr = baseSet.steps > 0 ? "${baseSet.steps} steps" : "";
                           if (timeStr.isNotEmpty) targetStr += (targetStr.isEmpty ? timeStr : " • $timeStr");
                         } else {
                           if (baseSet.reps > 0) {
                              targetStr = "${baseSet.reps} reps";
                           }
                         }
                      }
                      
                      final setStr = t.profile.fmt_history_sets(arg1: ex.sets.length.toString());
                      final finalDisplayStr = targetStr.isNotEmpty ? "$setStr • $targetStr" : setStr;

                      return InkWell(
                        onTap: () {
                          context.pushNamed('exercise_details', extra: fullExercise);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(Symbols.exercise, size: 16, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Text(t.translateDynamic(ex.exercise.name), maxLines: 2, overflow: TextOverflow.ellipsis),
                                )
                              ),
                              Text(finalDisplayStr, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                              const SizedBox(width: 8),
                              Icon(Symbols.chevron_right, size: 16, color: colorScheme.onSurfaceVariant)
                            ],
                          ),
                        ),
                      );
                    })
                  ],
                ),
              ),
            ))
          ],
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: Icon(isAdded ? Symbols.check : Symbols.add),
              label: Text(isAdded ? t.explore.btn_add_program_done : t.explore.btn_add_program_new, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: isAdded ? colorScheme.surfaceContainerHighest : colorScheme.primary,
                foregroundColor: isAdded ? colorScheme.onSurfaceVariant : colorScheme.onPrimary,
              ),
              onPressed: isAdded ? null : onAdd,
            ),
          ),
        )
      ],
    );
  }
}