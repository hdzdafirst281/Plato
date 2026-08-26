import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/navigation/app_router.dart';
import 'package:plato_gymapp/core/utils/search_utils.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/exercise_library_cubit.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart';

import '../../data/models/workout_models.dart';
import '../bloc/editor_cubit.dart';
import '../bloc/workout_cubit.dart';
import '../bloc/active_session_cubit.dart';
import '../components/workout_components.dart';
import '../components/workout_shared_ui.dart';
import 'exercise_library_screen.dart';
import '../../domain/workout_extensions.dart';

class RoutineScreen extends StatefulWidget {
  final bool isViewMode;

  const RoutineScreen({super.key, this.isViewMode = false});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen>
    with SingleTickerProviderStateMixin {
  final _uuid = const Uuid();
  late TextEditingController _nameController;
  List<WorkoutExercise> _routineExercises = [];
  bool _isSaving = false;
  bool _hasAttemptedSave = false;

  late bool _initialIsViewMode;
  late bool _currentIsViewMode;
  bool _initialized = false;

  bool _isReorderMode = false;
  bool _isExpandedMuscle = false;

  final ScrollController _scrollController = ScrollController();
  late AnimationController _overlayAnimController;

  String _originalName = "";
  String _rawOriginalName = "";
  List<WorkoutExercise> _originalExercises = [];

  @override
  void initState() {
    super.initState();
    _overlayAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _initialIsViewMode = widget.isViewMode;
    _currentIsViewMode = widget.isViewMode;

    final draft = context.read<EditorCubit>().state.routineToEdit;

    _rawOriginalName = draft?.name ?? "";
    String initialName = _rawOriginalName;

    if ((true)) {
      initialName = t.translateDynamic(initialName);
    }
    _nameController = TextEditingController(text: initialName);
    _originalName = initialName;

    if (draft != null) {
      final globalExercises = context
          .read<ExerciseLibraryCubit>()
          .state
          .exercises;
      _routineExercises = draft.sessionPayload.exercises.map((workoutEx) {
        final fullExercise = globalExercises.firstWhere(
          (e) => e.id == workoutEx.exercise.id,
          orElse: () => workoutEx.exercise,
        );
        return workoutEx.copyWith(exercise: fullExercise);
      }).toList();

      _originalExercises = List.from(
        _routineExercises.map(
          (e) => e.copyWith(sets: List.from(e.sets.map((s) => s.copyWith()))),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      try {
        final extraData = GoRouterState.of(context).extra;
        if (extraData is bool) {
          _initialIsViewMode = extraData;
          _currentIsViewMode = extraData;
        }
      } catch (e) {
        // Fallback
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _overlayAnimController.dispose();
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ExerciseSet? _getHistoricalSet(String exerciseName, int setIndex) {
    final history = context
        .read<WorkoutCubit>()
        .state
        .historicalWorkoutSessionsList;

    final sortedHistory = history.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final session = sortedHistory
        .where((s) => s.exercises.any((e) => e.exercise.name == exerciseName))
        .firstOrNull;
    final ex = session?.exercises.firstWhere(
      (e) => e.exercise.name == exerciseName,
    );

    if (ex != null && setIndex < ex.sets.length) return ex.sets[setIndex];
    return null;
  }

  bool _hasChanges() {
    if (_nameController.text.trim() != _originalName) return true;
    if (_routineExercises.length != _originalExercises.length) return true;

    for (int i = 0; i < _routineExercises.length; i++) {
      final currentEx = _routineExercises[i];
      final originalEx = _originalExercises[i];

      if (currentEx.exercise.id != originalEx.exercise.id) return true;
      if (currentEx.sets.length != originalEx.sets.length) return true;
      if (currentEx.supersetId != originalEx.supersetId) return true;

      if (currentEx.note != originalEx.note) return true;

      for (int j = 0; j < currentEx.sets.length; j++) {
        final currentSet = currentEx.sets[j];
        final originalSet = originalEx.sets[j];

        if (currentSet.weight != originalSet.weight ||
            currentSet.reps != originalSet.reps ||
            currentSet.distanceInKm != originalSet.distanceInKm ||
            currentSet.steps != originalSet.steps ||
            currentSet.durationTimeSeconds != originalSet.durationTimeSeconds ||
            currentSet.restTimeSeconds != originalSet.restTimeSeconds ||
            currentSet.type != originalSet.type) {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasValidationErrors() {
    if (_nameController.text.trim().isEmpty) return true;
    if (_routineExercises.isEmpty) return true;

    for (var ex in _routineExercises) {
      bool isWarmupEx =
          ex.exercise.id == 'd85332c1-01e4-4845-9d1d-bb814e36f7d2';
      for (var set in ex.sets) {
        switch (ex.exercise.type) {
          case ExerciseType.WEIGHT_REPS:
            if (set.reps < 0 ||
                set.reps > 999 ||
                set.weight < 0 ||
                set.weight >= 2000.0) {
              return true;
            }
            break;
          case ExerciseType.REPS_ONLY:
            if (set.reps < 0 || set.reps > 999) return true;
            break;
          case ExerciseType.TIME_ONLY:
            if (set.durationTimeSeconds < 0) return true;
            if (isWarmupEx && set.durationTimeSeconds >= 3600) return true;
            break;
          case ExerciseType.CARDIO_DISTANCE:
            if (set.distanceInKm < 0 || set.durationTimeSeconds < 0) {
              return true;
            }
            if (set.durationTimeSeconds > 0) {
              double speedKmH =
                  set.distanceInKm / (set.durationTimeSeconds / 3600.0);
              if (speedKmH >= 45.0) return true;
            }
            break;
          case ExerciseType.CARDIO_STEPS:
            if (set.steps < 0 || set.durationTimeSeconds < 0) return true;
            break;
        }
      }
    }
    return false;
  }

  void _showReorderDialog() {
    showDialog(
      context: context,
      builder: (_) =>
          GymReorderDialog<WorkoutExercise>(
                title: t.workout.title_routine_create_reorder,
                description: t.workout.desc_reorder_instruction,
                initialItems: _routineExercises,
                itemNameSelector: (item) =>
                    t.translateDynamic(item.exercise.name),
                idSelector: (item) => item.id,
                onSave: (reordered) {
                  setState(() {
                    _routineExercises = List.from(reordered);
                  });
                },
              )
              .animate()
              .fade(duration: 400.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.1, end: 0),
    );
  }

  void _handleLinkSuperset(String sourceId, List<String> targetIds) {
    setState(() {
      final sourceIndexRaw = _routineExercises.indexWhere(
        (e) => e.id == sourceId,
      );
      if (sourceIndexRaw == -1) return;

      final targets = _routineExercises
          .where((e) => targetIds.contains(e.id))
          .toList();
      final String sId =
          targets
              .firstWhere(
                (e) => e.supersetId != null,
                orElse: () => targets.first,
              )
              .supersetId ??
          _uuid.v4();

      final allTargetIdsInGroup = _routineExercises
          .where(
            (e) =>
                targetIds.contains(e.id) ||
                (e.supersetId != null && e.supersetId == sId),
          )
          .map((e) => e.id)
          .toList();

      final targetExercisesToMove = _routineExercises
          .where((e) => allTargetIdsInGroup.contains(e.id))
          .toList();
      _routineExercises.removeWhere((e) => allTargetIdsInGroup.contains(e.id));

      final sourceIndex = _routineExercises.indexWhere((e) => e.id == sourceId);
      _routineExercises[sourceIndex] = _routineExercises[sourceIndex].copyWith(
        supersetId: sId,
      );

      for (int i = 0; i < targetExercisesToMove.length; i++) {
        targetExercisesToMove[i] = targetExercisesToMove[i].copyWith(
          supersetId: sId,
        );
      }

      _routineExercises.insertAll(sourceIndex + 1, targetExercisesToMove);

      final finalSupersetExs = _routineExercises
          .where((e) => e.supersetId == sId)
          .toList();
      for (int i = 0; i < finalSupersetExs.length; i++) {
        final isLast = i == finalSupersetExs.length - 1;
        final exId = finalSupersetExs[i].id;
        final exIndexInMain = _routineExercises.indexWhere((e) => e.id == exId);

        final newRestTime = isLast
            ? (_routineExercises[exIndexInMain].restTimeSeconds == 0
                  ? 90
                  : _routineExercises[exIndexInMain].restTimeSeconds)
            : 0;
        final updatedSets = _routineExercises[exIndexInMain].sets
            .map((s) => s.copyWith(restTimeSeconds: newRestTime))
            .toList();

        _routineExercises[exIndexInMain] = _routineExercises[exIndexInMain]
            .copyWith(restTimeSeconds: newRestTime, sets: updatedSets);
      }
    });
  }

  void _handleRemoveSuperset(String exerciseId) {
    setState(() {
      final exIndex = _routineExercises.indexWhere((e) => e.id == exerciseId);
      if (exIndex == -1) return;

      final targetEx = _routineExercises[exIndex];
      if (targetEx.supersetId == null) return;

      final sId = targetEx.supersetId!;

      final newRestTime = targetEx.restTimeSeconds == 0
          ? 90
          : targetEx.restTimeSeconds;

      _routineExercises[exIndex] = targetEx.copyWith(
        supersetId: null,
        restTimeSeconds: newRestTime,
        sets: targetEx.sets
            .map((s) => s.copyWith(restTimeSeconds: newRestTime))
            .toList(),
      );

      final remaining = _routineExercises
          .where((e) => e.supersetId == sId)
          .toList();
      if (remaining.length == 1) {
        final lastExIndex = _routineExercises.indexWhere(
          (e) => e.id == remaining.first.id,
        );
        _routineExercises[lastExIndex] = _routineExercises[lastExIndex]
            .copyWith(supersetId: null);
      } else if (remaining.isNotEmpty) {
        final lastEx = remaining.last;
        final lastExIndex = _routineExercises.indexWhere(
          (e) => e.id == lastEx.id,
        );
        _routineExercises[lastExIndex] = lastEx.copyWith(
          sets: lastEx.sets
              .map(
                (s) => s.copyWith(
                  restTimeSeconds: s.restTimeSeconds == 0
                      ? 90
                      : s.restTimeSeconds,
                ),
              )
              .toList(),
        );
      }
    });
  }

  void _showSuccessDialogAndExit() {
    GymDialog.showSuccess(
      context: context,
      title: t.workout.title_create_routine_success,
      message: t.workout.msg_create_routine_success,
      buttonText: t.common.agree,
      onConfirm: () => context.pop(),
    );
  }

  void _handleSave() {
    if (_isSaving) return;

    FocusManager.instance.primaryFocus?.unfocus();

    // 1. ÄĂ¡nh dáº¥u user Ä‘Ă£ áº¥n Save Ä‘á»ƒ kĂ­ch hoáº¡t UI bĂ¡o lá»—i (náº¿u cĂ³)
    setState(() => _hasAttemptedSave = true);

    // 2. Æ¯U TIĂN BĂO Lá»–I: Check khĂ´ng cĂ³ bĂ i táº­p nĂ o
    if (_routineExercises.isEmpty) {
      GymSnackbar.show(
        context,
        message: t.workout.err_routine_exercises_empty,
        icon: Symbols.warning,
        accentColor: Theme.of(context).colorScheme.error,
      );
      return; // Cháº·n luá»“ng
    }

    String finalNameToSave = _nameController.text.trim();
    if (finalNameToSave == _originalName && _rawOriginalName.isNotEmpty) {
      finalNameToSave = _rawOriginalName;
    }

    // 3. Æ¯U TIĂN BĂO Lá»–I: TĂªn rá»—ng hoáº·c cĂ¡c thĂ´ng sá»‘ set bá»‹ lá»—i (Inline Error sáº½ tá»± hiá»‡n)
    if (finalNameToSave.isEmpty || _hasValidationErrors()) {
      return; // Cháº·n luá»“ng
    }

    // 4. CHECK THAY Äá»”I: Náº¿u KHĂ”NG CĂ“ lá»—i, kiá»ƒm tra xem cĂ³ thay Ä‘á»•i nĂ o so vá»›i gá»‘c khĂ´ng
    final draft = context.read<EditorCubit>().state.routineToEdit;
    final isNewFromHistory = draft?.id.startsWith('NEW_FROM_HISTORY_') ?? false;

    // Náº¿u Ä‘ang Edit (khĂ´ng pháº£i táº¡o má»›i) vĂ  KHĂ”NG CĂ“ THAY Äá»”I -> ThoĂ¡t luĂ´n, khĂ´ng gá»i API, khĂ´ng dialog
    if (draft != null && !isNewFromHistory && !_hasChanges()) {
      context.read<EditorCubit>().setRoutineToEdit(null);
      context.pop();
      return;
    }

    // 5. Náº¾U CĂ“ THAY Äá»”I -> Tiáº¿n hĂ nh lÆ°u
    setState(() => _isSaving = true);

    if (draft == null || isNewFromHistory) {
      context
          .read<EditorCubit>()
          .createRoutine(finalNameToSave, _routineExercises)
          .then((_) {
            if (!mounted) return;
            context.read<EditorCubit>().setRoutineToEdit(null);
            _showSuccessDialogAndExit();
          })
          .catchError((_) {
            setState(() => _isSaving = false);
          });
    } else {
      _showConfirmUpdateDialog(draft.id, finalNameToSave);
    }
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
      _handleSave();
    } else if (confirmed == false) {
      context.read<EditorCubit>().setRoutineToEdit(null);
      context.pop();
    }
  }

  void _showConfirmUpdateDialog(String draftId, String name) async {
    final confirmed = await GymDialog.showConfirm(
      context: context,
      title: t.workout.title_routine_create_confirm_update,
      message: t.workout.msg_routine_create_confirm_update,
      cancelText: t.common.cancel,
      confirmText: t.workout.title_routine_create_confirm_update,
    );

    if (confirmed == true && mounted) {
      context
          .read<EditorCubit>()
          .updateRoutine(draftId, name, _routineExercises)
          .then((_) {
            if (!mounted) return;
            context.read<EditorCubit>().setRoutineToEdit(null);
            context.pop();
          });
    } else if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _showDeleteRoutineConfirmDialog() async {
    final draft = context.read<EditorCubit>().state.routineToEdit;
    final confirmed = await GymDialog.showDestructive(
      context: context,
      title: t.workout.title_delete_confirm,
      message: t.workout.msg_delete_irreversible,
      cancelText: t.common.cancel,
      confirmText: t.common.delete,
    );

    if (confirmed == true && mounted) {
      if (draft != null) {
        context.read<WorkoutCubit>().deleteRoutine(draft.id);
      }
      context.read<EditorCubit>().setRoutineToEdit(null);
      context.pop();
    }
  }

  void _handleBackNavigation() {
    FocusManager.instance.primaryFocus?.unfocus();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;

      // Nếu đang ở chế độ chỉnh sửa và CÓ SỰ THAY ĐỔI -> Hiện Dialog Discard
      if (!_currentIsViewMode && _hasChanges()) {
        if (_hasValidationErrors()) {
          context.read<EditorCubit>().setRoutineToEdit(null);
          context.pop();
        } else {
          _showDiscardChangesDialog();
        }
      } else {
        // KHÔNG CÓ THAY ĐỔI (hoặc chỉ ở chế độ View) -> Thoát bình thường không hỏi
        if (!_currentIsViewMode && _initialIsViewMode) {
          setState(() => _currentIsViewMode = true);
        } else {
          context.read<EditorCubit>().setRoutineToEdit(null);
          context.pop();
        }
      }
    });
  }

  void _navigateToAddExercise() {
    context.pushNamed(
      'exercise_library',
      extra: {
        'mode': LibraryMode.multiSelect,
        'preSelectedIds': _routineExercises.map((e) => e.exercise.id).toList(),
        'onSelected': (List<Exercise> exercises) {
          // RATE LIMIT CHECK: Max 100 sets per routine
          int currentTotalSets = _routineExercises.fold(
            0,
            (sum, ex) => sum + ex.sets.length,
          );
          if (currentTotalSets + exercises.length > 100) {
            GymSnackbar.show(
              context,
              message: t.workout.err_max_sets_session,
              icon: Symbols.error, // Hoáº·c Symbols.error
              accentColor: Theme.of(context).colorScheme.error,
            );
            return;
          }

          final history = context
              .read<WorkoutCubit>()
              .state
              .historicalWorkoutSessionsList;
          final sortedHistory = history.toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));

          setState(() {
            for (var ex in exercises) {
              final lastMatchedSession = sortedHistory
                  .where(
                    (session) =>
                        session.exercises.any((e) => e.exercise.id == ex.id),
                  )
                  .firstOrNull;
              final histEx = lastMatchedSession?.exercises.firstWhere(
                (e) => e.exercise.id == ex.id,
              );

              List<ExerciseSet> newSets = [];
              if (histEx != null && histEx.sets.isNotEmpty) {
                newSets = histEx.sets
                    .map((s) => s.copyWith(id: _uuid.v4(), isCompleted: false))
                    .toList();
              } else {
                final initialSet = (ex.type == ExerciseType.CARDIO_DISTANCE)
                    ? ExerciseSet(id: _uuid.v4(), distanceInKm: 0.0)
                    : (ex.type == ExerciseType.CARDIO_STEPS)
                    ? ExerciseSet(id: _uuid.v4(), steps: 0)
                    : ExerciseSet(id: _uuid.v4(), weight: 0.0, reps: 0);
                newSets = [initialSet];
              }

              _routineExercises.add(
                WorkoutExercise(id: _uuid.v4(), exercise: ex, sets: newSets),
              );
            }
          });
        },
      },
    );
  }

  void _navigateToReplaceExercise(int indexToReplace) {
    final currentExercise = _routineExercises[indexToReplace].exercise;

    final globalExercises = context
        .read<ExerciseLibraryCubit>()
        .state
        .exercises;
    final fullExercise = globalExercises.firstWhere(
      (e) => e.id == currentExercise.id,
      orElse: () => currentExercise,
    );
    final existingIds = _routineExercises.map((e) => e.exercise.id).toList();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      context.pushNamed(
        'exercise_library',
        extra: {
          'mode': LibraryMode.singleSelect,
          'suggestedMuscle': fullExercise.primaryMuscle,
          'preSelectedIds': existingIds,
          'onSelected': (List<Exercise> exercises) {
            if (exercises.isEmpty) return;
            final ex = exercises.first;

            final history = context
                .read<WorkoutCubit>()
                .state
                .historicalWorkoutSessionsList;
            final sortedHistory = history.toList()
              ..sort((a, b) => b.startTime.compareTo(a.startTime));

            setState(() {
              final lastMatchedSession = sortedHistory
                  .where(
                    (session) =>
                        session.exercises.any((e) => e.exercise.id == ex.id),
                  )
                  .firstOrNull;
              final histEx = lastMatchedSession?.exercises.firstWhere(
                (e) => e.exercise.id == ex.id,
              );

              List<ExerciseSet> newSets = [];
              if (histEx != null && histEx.sets.isNotEmpty) {
                newSets = histEx.sets
                    .map((s) => s.copyWith(id: _uuid.v4(), isCompleted: false))
                    .toList();
              } else {
                final initialSet = (ex.type == ExerciseType.CARDIO_DISTANCE)
                    ? ExerciseSet(id: _uuid.v4(), distanceInKm: 0.0)
                    : (ex.type == ExerciseType.CARDIO_STEPS)
                    ? ExerciseSet(id: _uuid.v4(), steps: 0)
                    : ExerciseSet(id: _uuid.v4(), weight: 0.0, reps: 0);
                newSets = [initialSet];
              }

              _routineExercises[indexToReplace] = WorkoutExercise(
                id: _uuid.v4(),
                exercise: ex,
                sets: newSets,
              );
            });
          },
        },
      );
    });
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    ColorScheme colorScheme,
    bool isSaveEnabled,
  ) {
    if (_currentIsViewMode) {
      return [
        PopupMenuButton<String>(
          icon: Icon(Symbols.more_vert, color: colorScheme.onSurfaceVariant),
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          elevation: 4,
          onSelected: (value) {
            if (value == 'edit') {
              setState(() => _currentIsViewMode = false);
            } else if (value == 'delete') {
              _showDeleteRoutineConfirmDialog();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Symbols.edit, color: colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text(t.common.edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Symbols.delete, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    t.common.delete,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: _handleSave,
          child: Text(
            t.common.save,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final draft = context.watch<EditorCubit>().state.routineToEdit;

    final screenHeight = MediaQuery.of(context).size.height;

    final globalExercises = context
        .watch<ExerciseLibraryCubit>()
        .state
        .exercises;
    if (globalExercises.isNotEmpty && _routineExercises.isNotEmpty) {
      bool needsUpdate = false;
      for (int i = 0; i < _routineExercises.length; i++) {
        final currentEx = _routineExercises[i].exercise;
        final realEx = globalExercises.firstWhere(
          (e) => e.id == currentEx.id,
          orElse: () => currentEx,
        );

        if (currentEx.type != realEx.type) {
          _routineExercises[i] = _routineExercises[i].copyWith(
            exercise: realEx,
          );
          needsUpdate = true;
        }
      }
      if (needsUpdate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }

    final isNewFromHistory = draft?.id.startsWith('NEW_FROM_HISTORY_') ?? false;
    final isEditing = draft != null && !isNewFromHistory;

    final isSaveEnabled =
        _nameController.text.trim().isNotEmpty &&
        _routineExercises.isNotEmpty &&
        !_isSaving &&
        !_hasValidationErrors();

    String screenTitle = isEditing
        ? t.workout.title_routine_create_edit
        : t.workout.title_routine_create_new;
    if (_currentIsViewMode) screenTitle = _nameController.text.trim();

    final pureMuscleMap = _routineExercises.calculateMuscleDistribution(
      onlyCompletedSets: false,
    );
    final sortedMuscles = pureMuscleMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Widget muscleSection =
        Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.workout.title_detail_muscle_split,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      ...sortedMuscles
                          .take(
                            (_isExpandedMuscle ||
                                    ResponsiveBreakpoints.of(
                                      context,
                                    ).largerThan(MOBILE))
                                ? sortedMuscles.length
                                : 3,
                          )
                          .toList()
                          .asMap()
                          .entries
                          .map((entryMap) {
                            final index = entryMap.key;
                            final entry = entryMap.value;
                            return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            entry.key.getLocalizedName(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            t.workout
                                                .format_warning_recovery_percent(
                                                  arg1: entry.value
                                                      .toInt()
                                                      .toString(),
                                                ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child:
                                            LinearProgressIndicator(
                                              value: entry.value / 100,
                                              backgroundColor: colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.5),
                                              color: (entry.value / 100) >= 0.02
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurfaceVariant
                                                        .withValues(alpha: 0.3),
                                              minHeight: 8,
                                            ).animate().scaleX(
                                              duration: 800.ms,
                                              curve: Curves.easeOutCubic,
                                              alignment: Alignment.centerLeft,
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate(delay: (index * 100).ms)
                                .fade(
                                  duration: 400.ms,
                                  curve: Curves.easeOutCubic,
                                )
                                .slideY(begin: 0.1, end: 0);
                          }),
                      if (sortedMuscles.length > 3 &&
                          !ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(
                              () => _isExpandedMuscle = !_isExpandedMuscle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _isExpandedMuscle
                                        ? t.workout.btn_detail_muscle_collapse
                                        : t.workout.btn_detail_muscle_expand,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _isExpandedMuscle
                                        ? Symbols.expand_less
                                        : Symbols.expand_more,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fade(duration: 400.ms),
                    ],
                  ),
                ),
              ],
            )
            .animate(delay: 100.ms)
            .fade(duration: 400.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.1, end: 0);

    final bool isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    Widget? startButton;
    if (_currentIsViewMode && draft != null && !_isReorderMode) {
      startButton = ElevatedButton.icon(
        icon: const Icon(Symbols.play_arrow, fill: 1.0),
        label: Text(
          t.workout.btn_start_routine,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          handleStartWorkoutConflict(
            context: context,
            activeSessionCubit: context.read<ActiveSessionCubit>(),
            onConfirmStart: () {
              final mappedRoutine = draft.copyWith(
                sessionPayload: draft.sessionPayload.copyWith(
                  exercises: _routineExercises,
                ),
              );
              context.read<ActiveSessionCubit>().startRoutine(mappedRoutine);
              context.read<EditorCubit>().setRoutineToEdit(null);
              if (context.mounted) {
                context.pop();
              }
              AppRouter.expandWorkoutScreenNotifier.value = true;
            },
          );
        },
      );
    }

    Widget nameWidget = AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: (_currentIsViewMode || _isReorderMode)
          ? const SizedBox(width: double.infinity)
          : Builder(
              builder: (context) {
                final bool hasNameError =
                    _hasAttemptedSave && _nameController.text.trim().isEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 0 : 16.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            onChanged: (v) => setState(() {
                              _hasAttemptedSave = false;
                            }),
                            decoration: InputDecoration(
                              hintText: t.workout.hint_routine_create_name,
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Symbols.drive_file_rename_outline,
                                color: hasNameError
                                    ? colorScheme.error
                                    : colorScheme.primary,
                              ),
                              suffixIcon: _nameController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Symbols.clear,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _nameController.clear();
                                          _hasAttemptedSave = false;
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: hasNameError
                                      ? colorScheme.error
                                      : colorScheme.outlineVariant.withValues(
                                          alpha: 0.3,
                                        ),
                                  width: hasNameError ? 1.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: hasNameError
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, -0.2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: hasNameError
                                ? Padding(
                                    key: const ValueKey('name_error_ui'),
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      left: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Symbols.error_outline,
                                          color: colorScheme.error,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          t.workout.err_routine_name_empty,
                                          style: TextStyle(
                                            color: colorScheme.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('name_error_empty'),
                                    width: double.infinity,
                                    height: 0,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isReorderMode) {
          setState(() => _isReorderMode = false);
          return;
        }
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        resizeToAvoidBottomInset: true,
        appBar: _isReorderMode
            ? GymTopBar(
                title: t.workout.title_routine_create_reorder,
                onBackClick: () => setState(() => _isReorderMode = false),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _isReorderMode = false),
                    child: Text(
                      t.common.done,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              )
            : GymTopBar(
                title: screenTitle,
                onBackClick: _handleBackNavigation,
                actions: _buildAppBarActions(
                  context,
                  colorScheme,
                  isSaveEnabled,
                ),
              ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 1200 : 800),
            child: SafeArea(
              child: Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.axis == Axis.vertical) {
                        if (notification is ScrollUpdateNotification) {
                          if (notification.dragDetails == null) return false;
                          if (notification.scrollDelta != null) {
                            _overlayAnimController.value +=
                                notification.scrollDelta! / 150.0;
                          }
                        } else if (notification is OverscrollNotification) {
                          if (notification.dragDetails != null) {
                            _overlayAnimController.value +=
                                notification.overscroll / 150.0;
                          }
                        } else if (notification is ScrollEndNotification) {
                          if (_overlayAnimController.value > 0.0 &&
                              _overlayAnimController.value < 1.0) {
                            _overlayAnimController.animateTo(
                              _overlayAnimController.value > 0.5 ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        }
                      }
                      return false;
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isTablet)
                          Expanded(
                            flex: 4,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.only(
                                      top: 16,
                                      left: 16,
                                      right: 16,
                                      bottom: (startButton != null)
                                          ? 100.0
                                          : 16.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        nameWidget,
                                        if (sortedMuscles.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 24,
                                            ),
                                            child: muscleSection,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (startButton != null)
                                  Positioned(
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                    child: startButton,
                                  ),
                              ],
                            ),
                          ),
                        if (isTablet) const SizedBox(width: 24),
                        Expanded(
                          flex: isTablet ? 6 : 1,
                          child: Column(
                            children: [
                              if (!isTablet) nameWidget,
                              Expanded(
                                child: ReorderableListView.builder(
                                  scrollController: _scrollController,
                                  header:
                                      (!isTablet && sortedMuscles.isNotEmpty)
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 24,
                                          ),
                                          child: muscleSection,
                                        )
                                      : null,
                                  cacheExtent: 9999,
                                  padding: EdgeInsets.only(
                                    top: _isReorderMode ? 24 : 16,
                                    bottom: max(140.0, screenHeight * 0.2),
                                    left: 16,
                                    right: 16,
                                  ),
                                  itemCount: _routineExercises.length,
                                  buildDefaultDragHandles: false,

                                  proxyDecorator: (child, index, animation) {
                                    return AnimatedBuilder(
                                      animation: animation,
                                      builder: (context, _) {
                                        final double animValue = Curves
                                            .easeOutCubic
                                            .transform(animation.value);
                                        final double scale =
                                            1.0 + (0.02 * animValue);
                                        final double rotation =
                                            0.01 * animValue;

                                        return Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            // ignore: deprecated_member_use
                                            ..scale(scale)
                                            ..rotateZ(rotation),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.primary
                                                      .withValues(
                                                        alpha: 0.15 * animValue,
                                                      ),
                                                  blurRadius: 10 * animValue,
                                                  spreadRadius: 2 * animValue,
                                                  offset: Offset(
                                                    0,
                                                    4 * animValue,
                                                  ),
                                                ),
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(
                                                        alpha: 0.1 * animValue,
                                                      ),
                                                  blurRadius: 8 * animValue,
                                                  offset: Offset(
                                                    0,
                                                    2 * animValue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                    );
                                  },

                                  onReorderStart: (index) {
                                    if (_currentIsViewMode) return;
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    HapticFeedback.heavyImpact();
                                    Future.delayed(
                                      const Duration(milliseconds: 50),
                                      () => HapticFeedback.heavyImpact(),
                                    );
                                  },

                                  onReorderEnd: (index) {
                                    if (_currentIsViewMode) return;
                                    HapticFeedback.lightImpact();
                                  },

                                  onReorder: (oldIndex, newIndex) {
                                    if (_currentIsViewMode) return;

                                    int clampedNewIndex = newIndex;
                                    if (clampedNewIndex >
                                        _routineExercises.length) {
                                      clampedNewIndex =
                                          _routineExercises.length;
                                    }

                                    if (clampedNewIndex > oldIndex) {
                                      clampedNewIndex -= 1;
                                    }

                                    setState(() {
                                      final item = _routineExercises.removeAt(
                                        oldIndex,
                                      );
                                      _routineExercises.insert(
                                        clampedNewIndex,
                                        item,
                                      );
                                    });
                                  },

                                  itemBuilder: (context, index) {
                                    final item = _routineExercises[index];

                                    final cardNode =
                                        _RoutineExerciseCard(
                                              workoutExercise: item,
                                              exerciseIndex: index,
                                              isViewMode: _currentIsViewMode,
                                              isReorderMode: _isReorderMode,
                                              allExercises: _routineExercises,
                                              onRemove: () => setState(
                                                () => _routineExercises
                                                    .removeAt(index),
                                              ),
                                              onReplace: () =>
                                                  _navigateToReplaceExercise(
                                                    index,
                                                  ),
                                              onDialogReorder:
                                                  _showReorderDialog,
                                              onUpdate: (updatedEx) => setState(
                                                () => _routineExercises[index] =
                                                    updatedEx,
                                              ),
                                              getHistorySet: (setIdx) =>
                                                  _getHistoricalSet(
                                                    item.exercise.name,
                                                    setIdx,
                                                  ),
                                              onLinkSuperset:
                                                  _handleLinkSuperset,
                                              onRemoveSuperset:
                                                  _handleRemoveSuperset,
                                            )
                                            .animate(
                                              key: ValueKey(item.id),
                                              delay: (index * 100).ms,
                                            )
                                            .fade(
                                              duration: 400.ms,
                                              curve: Curves.easeOutCubic,
                                            )
                                            .slideY(begin: 0.1, end: 0);

                                    return ReorderableDragStartListener(
                                      key: ValueKey('${item.id}_drag'),
                                      index: index,
                                      enabled: _isReorderMode,
                                      child:
                                          ReorderableDelayedDragStartListener(
                                            key: ValueKey(
                                              '${item.id}_delay_drag',
                                            ),
                                            index: index,
                                            enabled:
                                                !_currentIsViewMode &&
                                                !_isReorderMode,
                                            child: cardNode,
                                          ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!isTablet && startButton != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: startButton,
                    ),

                  if (!_currentIsViewMode)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _overlayAnimController,
                        builder: (context, child) {
                          final isKeyboardOpen =
                              MediaQuery.of(context).viewInsets.bottom > 0;

                          final animValue = (isKeyboardOpen || _isReorderMode)
                              ? 1.0
                              : _overlayAnimController.value;

                          final bottomSafeArea = MediaQuery.of(
                            context,
                          ).padding.bottom;
                          final fabBottomOffset = bottomSafeArea > 0
                              ? bottomSafeArea + 16.0
                              : 24.0;

                          final fabRight =
                              dart_ui.lerpDouble(16.0, -100.0, animValue) ??
                              16.0;

                          return Stack(
                            children: [
                              Positioned.fill(
                                child: WorkoutExpandableActionFab(
                                  fabRightOffset: fabRight,
                                  fabBottomOffset: fabBottomOffset,
                                  isKeyboardOpen: isKeyboardOpen,
                                  cancelLabel: t.workout.btn_routine_delete,
                                  cancelIcon: Symbols.delete_outline,
                                  onAdd: _navigateToAddExercise,
                                  onReorder: () {
                                    HapticFeedback.heavyImpact();
                                    setState(() => _isReorderMode = true);
                                  },
                                  onCancel: () {
                                    HapticFeedback.heavyImpact();
                                    _showDeleteRoutineConfirmDialog();
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineExerciseCard extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final int exerciseIndex;
  final bool isViewMode;
  final bool isReorderMode;
  final List<WorkoutExercise> allExercises;
  final VoidCallback onRemove;
  final VoidCallback onReplace;
  final VoidCallback onDialogReorder;
  final Function(WorkoutExercise) onUpdate;
  final ExerciseSet? Function(int) getHistorySet;
  final Function(String, List<String>) onLinkSuperset;
  final Function(String) onRemoveSuperset;

  const _RoutineExerciseCard({
    required this.workoutExercise,
    required this.exerciseIndex,
    this.isViewMode = false,
    this.isReorderMode = false,
    required this.allExercises,
    required this.onRemove,
    required this.onReplace,
    required this.onDialogReorder,
    required this.onUpdate,
    required this.getHistorySet,
    required this.onLinkSuperset,
    required this.onRemoveSuperset,
  });

  @override
  State<_RoutineExerciseCard> createState() => _RoutineExerciseCardState();
}

class _RoutineExerciseCardState extends State<_RoutineExerciseCard> {
  final Map<String, String> _setErrors = {};

  late TextEditingController _noteController;
  late FocusNode _noteFocusNode;

  @override
  void initState() {
    super.initState();
    final initialNote =
        widget.workoutExercise.note ??
        widget.workoutExercise.exercise.userNote ??
        '';
    _noteController = TextEditingController(text: initialNote);
    _noteFocusNode = FocusNode();

    _noteFocusNode.addListener(() {
      if (!_noteFocusNode.hasFocus) {
        String finalNote = _noteController.text;
        if (finalNote.trim().isEmpty) {
          finalNote = "";
          if (_noteController.text.isNotEmpty) _noteController.text = "";
        } else {
          finalNote = finalNote.trim();
          if (_noteController.text != finalNote) {
            _noteController.text = finalNote;
          }
        }

        if (finalNote != (widget.workoutExercise.note ?? '')) {
          widget.onUpdate(widget.workoutExercise.copyWith(note: finalNote));
        }
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  // đŸ€ Bá»” SUNG: Render avatar linh hoáº¡t cho bĂ i táº­p thÆ°á»ng vĂ  Custom Exercise
  Widget _buildExerciseImage(
    Exercise exercise,
    double size,
    String displayName,
    ColorScheme colorScheme,
  ) {
    if (exercise.isCustom &&
        exercise.localImagePath != null &&
        exercise.localImagePath!.trim().isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.file(
            File(exercise.localImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackText(size, colorScheme, displayName),
          ),
        ),
      );
    }

    if (exercise.image != null && exercise.image!.trim().isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            exercise.image!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackText(size, colorScheme, displayName),
          ),
        ),
      );
    }

    return _buildFallbackText(size, colorScheme, displayName);
  }

  Widget _buildFallbackText(
    double size,
    ColorScheme colorScheme,
    String displayName,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        displayName.trim().isNotEmpty
            ? displayName.trim()[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.45,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _formatHistoryString(ExerciseSet? previousSet, ExerciseType exType) {
    if (previousSet == null) return "-";

    final w = previousSet.weight % 1 == 0
        ? previousSet.weight.toInt().toString()
        : previousSet.weight.toString();
    final r = previousSet.reps.toString();
    final d = previousSet.distanceInKm % 1 == 0
        ? previousSet.distanceInKm.toInt().toString()
        : previousSet.distanceInKm.toString();
    final st = previousSet.steps.toString();
    final timeStr = GymTimerHelper.formatCardioTime(
      previousSet.durationTimeSeconds,
    );

    switch (exType) {
      case ExerciseType.WEIGHT_REPS:
        if (previousSet.weight == 0 && previousSet.reps == 0) return "-";
        return "${w}kg x $r";
      case ExerciseType.REPS_ONLY:
        if (previousSet.reps == 0) return "-";
        return "x $r";
      case ExerciseType.TIME_ONLY:
        if (previousSet.durationTimeSeconds == 0) return "-";
        return timeStr;
      case ExerciseType.CARDIO_DISTANCE:
        if (previousSet.distanceInKm == 0 &&
            previousSet.durationTimeSeconds == 0) {
          return "-";
        }
        return t.workout.format_detail_set_distance_time(arg1: d, arg2: timeStr);
      case ExerciseType.CARDIO_STEPS:
        if (previousSet.steps == 0 && previousSet.durationTimeSeconds == 0) {
          return "-";
        }
        return t.workout.format_detail_set_steps_time(arg1: st, arg2: timeStr);
      
    }
  }

  void _clearError(String setId) {
    if (_setErrors.containsKey(setId)) {
      setState(() => _setErrors.remove(setId));
    }
  }

  void _handleSetDataChange(
    String setId,
    ExerciseType exType, {
    double? weight,
    int? reps,
    double? distance,
    int? steps,
    int? time,
  }) {
    final latestSet = widget.workoutExercise.sets.firstWhere(
      (s) => s.id == setId,
    );

    double fillWeight = weight ?? latestSet.weight;
    int fillReps = reps ?? latestSet.reps;
    double fillDistance = distance ?? latestSet.distanceInKm;
    int fillSteps = steps ?? latestSet.steps;
    int fillTime = time ?? latestSet.durationTimeSeconds;

    bool isValid = true;
    String errorValidationKey = "";
    bool isWarmupEx =
        widget.workoutExercise.exercise.id ==
        'd85332c1-01e4-4845-9d1d-bb814e36f7d2';

    if (exType == ExerciseType.WEIGHT_REPS) {
      if (fillReps < 0) {
        isValid = false;
        errorValidationKey = t.workout.err_invalid_reps;
      } else if (fillReps > 999) {
        isValid = false;
        errorValidationKey = t.workout.err_invalid_reps_max;
      } else if (fillWeight < 0) {
        isValid = false;
        errorValidationKey = t.workout.err_invalid_weight;
      } else if (fillWeight >= 2000.0) {
        isValid = false;
        errorValidationKey = t.workout.err_invalid_weight_max;
      }
    } else if (exType == ExerciseType.REPS_ONLY) {
      if (fillReps < 0) {
        isValid = false;
        errorValidationKey = t.workout.err_invalid_reps;
      } else if (fillReps > 999) {
        isValid = false;
        errorValidationKey = t.workout.err_invalid_reps_max;
      }
    } else if (exType == ExerciseType.TIME_ONLY) {
      if (fillTime < 0) {
        isValid = false;
        errorValidationKey = t.workout.err_time_zero;
      } else if (isWarmupEx && fillTime >= 3600) {
        isValid = false;
        errorValidationKey = t.workout.err_warmup_time_max;
      }
    } else if (exType == ExerciseType.CARDIO_DISTANCE) {
      if (fillDistance < 0 || fillTime < 0) {
        isValid = false;
        errorValidationKey = t.workout.err_invalid_distance_time;
      } else {
        if (fillTime > 0) {
          double speedKmH = fillDistance / (fillTime / 3600.0);
          if (speedKmH >= 45.0) {
            isValid = false;
            errorValidationKey = t.workout.err_invalid_speed_max;
          }
        }
      }
    } else if (exType == ExerciseType.CARDIO_STEPS) {
      if (fillSteps < 0 || fillTime < 0) {
        isValid = false;
        errorValidationKey = t.workout.err_invalid_steps_time;
      }
    }

    if (!isValid) {
      setState(() => _setErrors[setId] = errorValidationKey);
    } else {
      _clearError(setId);
    }

    final newSets = List<ExerciseSet>.from(widget.workoutExercise.sets);
    final idx = newSets.indexWhere((s) => s.id == setId);
    if (idx != -1) {
      newSets[idx] = newSets[idx].copyWith(
        weight: fillWeight,
        reps: fillReps,
        distanceInKm: fillDistance,
        steps: fillSteps,
        durationTimeSeconds: fillTime,
      );
      widget.onUpdate(widget.workoutExercise.copyWith(sets: newSets));
    }
  }

  void _showSupersetBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      builder: (ctx) => WorkoutSupersetBottomSheet(
        // Truyá»n data tá»« properties cá»§a tháº» bĂ i táº­p hiá»‡n táº¡i
        allExercises: widget.allExercises,
        baseExercise: widget.workoutExercise,
        onSave: (selectedIds) {
          // KĂ­ch hoáº¡t callback cá»§a Routine Screen (sáº½ Ä‘Æ°á»£c xá»­ lĂ½ bá»Ÿi EditorCubit)
          widget.onLinkSuperset(widget.workoutExercise.id, selectedIds);
        },
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName =
        t.translateDynamic(widget.workoutExercise.exercise.name);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
            child: _buildExerciseImage(
              widget.workoutExercise.exercise,
              36.0,
              displayName,
              colorScheme,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Icon(
              Symbols.drag_handle,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final exType = widget.workoutExercise.exercise.type;
    final currentRest =
        widget.workoutExercise.sets.firstOrNull?.restTimeSeconds ?? 90;

    final isTablet = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
    final double setRowHorizontalPadding = ResponsiveValue<double>(
      context,
      defaultValue: 16.0,
      conditionalValues: [
        Condition.smallerThan(name: TABLET, value: 12.0),
        Condition.smallerThan(name: MOBILE, value: 4.0),
      ],
    ).value;

    final bool isWarmupEx =
        widget.workoutExercise.exercise.id ==
        'd85332c1-01e4-4845-9d1d-bb814e36f7d2';

    final displayName =
        t.translateDynamic(widget.workoutExercise.exercise.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.pushNamed(
                    'exercise_details',
                    extra: widget.workoutExercise.exercise,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildExerciseImage(
                          widget.workoutExercise.exercise,
                          48.0,
                          displayName,
                          colorScheme,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.isViewMode)
              PopupMenuButton<String>(
                key: const ValueKey("edit_menu"),
                icon: Icon(
                  Symbols.more_horiz,
                  color: colorScheme.onSurfaceVariant,
                ),
                color: colorScheme.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    widget.onRemove();
                  } else if (value == 'replace')
                    widget.onReplace();
                  else if (value == 'reorder')
                    widget.onDialogReorder();
                  else if (value == 'superset_add')
                    _showSupersetBottomSheet(context);
                  else if (value == 'superset_remove')
                    widget.onRemoveSuperset(widget.workoutExercise.id);
                },
                itemBuilder: (context) {
                  final allExercises = widget.allExercises;
                  final bool canCreateSuperset = allExercises.length > 1;

                  return [
                    PopupMenuItem(
                      value: 'reorder',
                      child: Row(
                        children: [
                          Icon(
                            Symbols.drag_handle,
                            color: colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t.workout.title_routine_create_reorder,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'replace',
                      child: Row(
                        children: [
                          Icon(
                            Symbols.swap_horiz,
                            color: colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t.workout.menu_routine_create_replace,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),

                    if (canCreateSuperset &&
                        (widget.workoutExercise.supersetId == null ||
                            allExercises
                                    .where(
                                      (e) =>
                                          e.supersetId ==
                                          widget.workoutExercise.supersetId,
                                    )
                                    .length <
                                3))
                      PopupMenuItem(
                        value: 'superset_add',
                        child: Row(
                          children: [
                            Icon(
                              Symbols.link,
                              color: Theme.of(context).gymColors.accentTeal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t.workout.btn_superset_add,
                              style: TextStyle(
                                color: Theme.of(context).gymColors.accentTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.workoutExercise.supersetId != null)
                      PopupMenuItem(
                        value: 'superset_remove',
                        child: Row(
                          children: [
                            Icon(
                              Symbols.link_off,
                              color: Theme.of(context).gymColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t.workout.btn_superset_remove,
                              style: TextStyle(
                                color: Theme.of(context).gymColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Symbols.delete, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text(
                            t.common.delete,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
          ],
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.isViewMode
                            ? null
                            : () => GymTimerHelper.showRestTimePicker(
                                context,
                                currentRest,
                                (val) {
                                  final newSets = widget.workoutExercise.sets
                                      .map(
                                        (s) => s.copyWith(restTimeSeconds: val),
                                      )
                                      .toList();
                                  widget.onUpdate(
                                    widget.workoutExercise.copyWith(
                                      restTimeSeconds: val,
                                      sets: newSets,
                                    ),
                                  );
                                },
                              ),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                currentRest == 0
                                    ? Symbols.timer_off
                                    : Symbols.timer,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentRest == 0
                                    ? t.workout.label_rest_off
                                    : t.workout.format_routine_create_rest_time(
                                        arg1: GymTimerHelper.formatRestTime(
                                          currentRest,
                                        ),
                                      ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (widget.workoutExercise.supersetId != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).gymColors.accentTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => GymSetTypeHelper.showSetTypeInfoDialog(
                            context,
                            'S',
                            'workout.type_superset',
                            'workout.desc_superset',
                            Theme.of(context).gymColors.accentTeal,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Symbols.link,
                                  size: 14,
                                  color: Theme.of(context).gymColors.accentTeal,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t.workout.label_superset_badge,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).gymColors.accentTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (!(widget.isViewMode && _noteController.text.trim().isEmpty))
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _noteController,
                  focusNode: _noteFocusNode,
                  readOnly: widget.isViewMode,
                  scrollPadding: isTablet
                      ? const EdgeInsets.all(20.0)
                      : const EdgeInsets.only(bottom: 130.0),
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: t.workout.label_note_input,
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: 13,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Icon(
                        Symbols.edit_note,
                        size: 20,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 20,
                    ),
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: setRowHorizontalPadding,
                vertical: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        t.workout.col_routine_create_set.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    flex: 4,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        t.workout.col_routine_history.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  if (exType == ExerciseType.TIME_ONLY)
                    Expanded(
                      flex: 6,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          t.workout.col_routine_create_time.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (exType == ExerciseType.REPS_ONLY)
                    Expanded(
                      flex: 6,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          t.workout.col_routine_create_reps.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else ...[
                    Expanded(
                      flex: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          exType == ExerciseType.CARDIO_DISTANCE
                              ? t.workout.col_routine_create_km.toUpperCase()
                              : exType == ExerciseType.CARDIO_STEPS
                              ? t.workout.col_routine_create_steps.toUpperCase()
                              : t.workout.col_routine_create_kg.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          (exType == ExerciseType.CARDIO_DISTANCE ||
                                  exType == ExerciseType.CARDIO_STEPS)
                              ? t.workout.col_routine_create_time.toUpperCase()
                              : t.workout.col_routine_create_reps.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            ...widget.workoutExercise.sets.map((setData) {
              final setIndex = widget.workoutExercise.sets.indexOf(setData);
              final historySet = widget.getHistorySet(setIndex);

              final bool hasError = _setErrors.containsKey(setData.id);
              final String? errorKey = _setErrors[setData.id];

              return Builder(
                builder: (setContext) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GymSwipeToRevealAction(
                            key: ValueKey('swipe_${setData.id}'),
                            enabled:
                                !widget.isViewMode &&
                                widget.workoutExercise.sets.length > 1,
                            onDelete: () {
                              final newSets = List<ExerciseSet>.from(
                                widget.workoutExercise.sets,
                              )..removeAt(setIndex);
                              widget.onUpdate(
                                widget.workoutExercise.copyWith(sets: newSets),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: hasError
                                    ? Border.all(
                                        color: colorScheme.error,
                                        width: 1.5,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 1.5,
                                      ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: setRowHorizontalPadding,
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Center(
                                        child: Builder(
                                          builder: (context) {
                                            String setTypeLabel =
                                                "${setIndex + 1}";
                                            Color setTypeTextColor =
                                                colorScheme.onSurfaceVariant;
                                            Color setTypeBgColor =
                                                Colors.transparent;

                                            switch (setData.type) {
                                              case SetType.WARMUP:
                                                setTypeLabel = "W";
                                                setTypeTextColor = Theme.of(
                                                  context,
                                                ).gymColors.warning;
                                                setTypeBgColor =
                                                    Theme.of(context)
                                                        .gymColors
                                                        .warning
                                                        .withValues(alpha: 0.2);
                                                break;
                                              case SetType.DROPSET:
                                                setTypeLabel = "D";
                                                setTypeTextColor = Theme.of(
                                                  context,
                                                ).gymColors.accentPurple;
                                                setTypeBgColor =
                                                    Theme.of(context)
                                                        .gymColors
                                                        .accentPurple
                                                        .withValues(alpha: 0.2);
                                                break;
                                              case SetType.FAILURE:
                                                setTypeLabel = "F";
                                                setTypeTextColor =
                                                    colorScheme.error;
                                                setTypeBgColor = colorScheme
                                                    .error
                                                    .withValues(alpha: 0.2);
                                                break;
                                              case SetType.NORMAL:
                                              default:
                                                setTypeLabel =
                                                    "${setIndex + 1}";
                                                setTypeTextColor = colorScheme
                                                    .onSurfaceVariant;
                                                break;
                                            }

                                            return Container(
                                              width: 32,
                                              height: 32,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color:
                                                    setTypeBgColor !=
                                                        Colors.transparent
                                                    ? setTypeBgColor
                                                    : colorScheme.surface,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                shape: const CircleBorder(),
                                                child: InkWell(
                                                  customBorder:
                                                      const CircleBorder(),
                                                  onTap: widget.isViewMode
                                                      ? null
                                                      : () => GymSetTypeHelper.showSetTypeBottomSheet(
                                                          context,
                                                          setData.type,
                                                          setIndex,
                                                          (newType) {
                                                            final newSets =
                                                                List<
                                                                  ExerciseSet
                                                                >.from(
                                                                  widget
                                                                      .workoutExercise
                                                                      .sets,
                                                                );
                                                            final idx = newSets
                                                                .indexWhere(
                                                                  (s) =>
                                                                      s.id ==
                                                                      setData
                                                                          .id,
                                                                );
                                                            if (idx != -1) {
                                                              newSets[idx] =
                                                                  newSets[idx]
                                                                      .copyWith(
                                                                        type:
                                                                            newType,
                                                                      );
                                                              widget.onUpdate(
                                                                widget
                                                                    .workoutExercise
                                                                    .copyWith(
                                                                      sets:
                                                                          newSets,
                                                                    ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                  child: Center(
                                                    child: Text(
                                                      setTypeLabel,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 14,
                                                        color: setTypeTextColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    Expanded(
                                      flex: 4,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _formatHistoryString(
                                            historySet,
                                            exType,
                                          ),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    if (exType == ExerciseType.TIME_ONLY) ...[
                                      Expanded(
                                        flex: 6,
                                        child: Builder(
                                          builder: (context) {
                                            final isTimeEmpty =
                                                setData.durationTimeSeconds ==
                                                0;
                                            final displayTimeStr = isTimeEmpty
                                                ? "00:00"
                                                : GymTimerHelper.formatCardioTime(
                                                    setData.durationTimeSeconds,
                                                  );
                                            final textColor = isTimeEmpty
                                                ? colorScheme.onSurfaceVariant
                                                      .withValues(alpha: 0.5)
                                                : colorScheme.onSurface;

                                            return InkWell(
                                              onTap: widget.isViewMode
                                                  ? null
                                                  : () {
                                                      GymTimerHelper.showDurationPicker(
                                                        context: context,
                                                        currentDuration: setData
                                                            .durationTimeSeconds,
                                                        isWarmupEx: isWarmupEx,
                                                        validator: (fillTime) {
                                                          if (fillTime < 0) {
                                                            return t
                                                                .workout
                                                                .err_time_zero;
                                                          }
                                                          if (isWarmupEx &&
                                                              fillTime >= 3600) {
                                                            return t
                                                                .workout
                                                                .err_warmup_time_max;
                                                          }
                                                          return null;
                                                        },
                                                        onSave: (finalTime) {
                                                          _clearError(
                                                            setData.id,
                                                          );
                                                          _handleSetDataChange(
                                                            setData.id,
                                                            exType,
                                                            time: finalTime,
                                                          );
                                                        },
                                                      );
                                                    },
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                height: 36,
                                                alignment: Alignment.center,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    displayTimeStr,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ] else if (exType ==
                                        ExerciseType.REPS_ONLY) ...[
                                      Expanded(
                                        flex: 6,
                                        child: IgnorePointer(
                                          ignoring: widget.isViewMode,
                                          child: GymExcelCell(
                                            initialValue: setData.reps > 0
                                                ? setData.reps.toString()
                                                : "",
                                            placeholder: "-",
                                            isInteger: true,
                                            onChanged: (val) {
                                              final parsed = int.tryParse(val);
                                              _handleSetDataChange(
                                                setData.id,
                                                exType,
                                                reps:
                                                    (val.isNotEmpty &&
                                                        parsed == null)
                                                    ? -1
                                                    : (parsed ?? 0),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Expanded(
                                        flex: 3,
                                        child: IgnorePointer(
                                          ignoring: widget.isViewMode,
                                          child: GymExcelCell(
                                            initialValue:
                                                exType ==
                                                    ExerciseType.CARDIO_STEPS
                                                ? (setData.steps > 0
                                                      ? setData.steps.toString()
                                                      : "")
                                                : exType ==
                                                      ExerciseType
                                                          .CARDIO_DISTANCE
                                                ? (setData.distanceInKm > 0
                                                      ? (setData.distanceInKm %
                                                                    1 ==
                                                                0
                                                            ? setData
                                                                  .distanceInKm
                                                                  .toInt()
                                                                  .toString()
                                                            : setData
                                                                  .distanceInKm
                                                                  .toString())
                                                      : "")
                                                : (setData.weight > 0
                                                      ? (setData.weight % 1 == 0
                                                            ? setData.weight
                                                                  .toInt()
                                                                  .toString()
                                                            : setData.weight
                                                                  .toString())
                                                      : ""),
                                            placeholder: "-",
                                            isInteger:
                                                exType ==
                                                ExerciseType.CARDIO_STEPS,
                                            onChanged: (val) {
                                              if (exType ==
                                                  ExerciseType.CARDIO_STEPS) {
                                                final parsed = int.tryParse(
                                                  val,
                                                );
                                                _handleSetDataChange(
                                                  setData.id,
                                                  exType,
                                                  steps:
                                                      (val.isNotEmpty &&
                                                          parsed == null)
                                                      ? -1
                                                      : (parsed ?? 0),
                                                );
                                              } else if (exType ==
                                                  ExerciseType
                                                      .CARDIO_DISTANCE) {
                                                final parsed = double.tryParse(
                                                  val,
                                                );
                                                _handleSetDataChange(
                                                  setData.id,
                                                  exType,
                                                  distance:
                                                      (val.isNotEmpty &&
                                                          parsed == null)
                                                      ? -1.0
                                                      : (parsed ?? 0.0),
                                                );
                                              } else {
                                                final parsed = double.tryParse(
                                                  val,
                                                );
                                                _handleSetDataChange(
                                                  setData.id,
                                                  exType,
                                                  weight:
                                                      (val.isNotEmpty &&
                                                          parsed == null)
                                                      ? -1.0
                                                      : (parsed ?? 0.0),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      Expanded(
                                        flex: 3,
                                        child:
                                            (exType ==
                                                    ExerciseType
                                                        .CARDIO_DISTANCE ||
                                                exType ==
                                                    ExerciseType.CARDIO_STEPS)
                                            ? Builder(
                                                builder: (context) {
                                                  final isTimeEmpty =
                                                      setData
                                                          .durationTimeSeconds ==
                                                      0;
                                                  final displayTimeStr =
                                                      isTimeEmpty
                                                      ? "00:00"
                                                      : GymTimerHelper.formatCardioTime(
                                                          setData
                                                              .durationTimeSeconds,
                                                        );
                                                  final textColor = isTimeEmpty
                                                      ? colorScheme
                                                            .onSurfaceVariant
                                                            .withValues(
                                                              alpha: 0.5,
                                                            )
                                                      : colorScheme.onSurface;

                                                  return InkWell(
                                                    onTap: widget.isViewMode
                                                        ? null
                                                        : () {
                                                            GymTimerHelper.showDurationPicker(
                                                              context: context,
                                                              currentDuration:
                                                                  setData
                                                                      .durationTimeSeconds,
                                                              isWarmupEx:
                                                                  isWarmupEx,
                                                              validator: (fillTime) {
                                                                if (fillTime <
                                                                    0) {
                                                                  return t
                                                                      .workout
                                                                      .err_time_zero;
                                                                }
                                                                if (isWarmupEx &&
                                                                    fillTime >=
                                                                        3600) {
                                                                  return t
                                                                      .workout
                                                                      .err_warmup_time_max;
                                                                }
                                                                if (widget
                                                                            .workoutExercise
                                                                            .exercise
                                                                            .type ==
                                                                        ExerciseType
                                                                            .CARDIO_DISTANCE &&
                                                                    setData.distanceInKm >
                                                                        0 &&
                                                                    fillTime >
                                                                        0) {
                                                                  double
                                                                  speedKmH =
                                                                      setData
                                                                          .distanceInKm /
                                                                      (fillTime /
                                                                          3600.0);
                                                                  if (speedKmH >=
                                                                      45.0) {
                                                                    return t
                                                                        .workout
                                                                        .err_invalid_speed_max;
                                                                  }
                                                                }
                                                                return null;
                                                              },
                                                              onSave: (finalTime) {
                                                                _clearError(
                                                                  setData.id,
                                                                );
                                                                _handleSetDataChange(
                                                                  setData.id,
                                                                  exType,
                                                                  time:
                                                                      finalTime,
                                                                );
                                                              },
                                                            );
                                                          },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Container(
                                                      height: 36,
                                                      alignment:
                                                          Alignment.center,
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          displayTimeStr,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : IgnorePointer(
                                                ignoring: widget.isViewMode,
                                                child: GymExcelCell(
                                                  initialValue: setData.reps > 0
                                                      ? setData.reps.toString()
                                                      : "",
                                                  placeholder: "-",
                                                  isInteger: true,
                                                  onChanged: (val) {
                                                    final parsed = int.tryParse(
                                                      val,
                                                    );
                                                    _handleSetDataChange(
                                                      setData.id,
                                                      exType,
                                                      reps:
                                                          (val.isNotEmpty &&
                                                              parsed == null)
                                                          ? -1
                                                          : (parsed ?? 0),
                                                    );
                                                  },
                                                ),
                                              ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (hasError)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Symbols.error_outline,
                                  color: colorScheme.error,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  t.translateDynamic(errorKey!),
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fade().slideY(begin: -0.2, end: 0),
                      ],
                    ),
                  );
                },
              ).animate(key: ValueKey(setData.id), delay: (setIndex * 100).ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);
            }),

            if (!widget.isViewMode)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.08,
                      ),
                      foregroundColor: colorScheme.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () {
                      // RATE LIMIT CHECKS
                      int totalSessionSets = widget.allExercises.fold(
                        0,
                        (sum, ex) => sum + ex.sets.length,
                      );
                      if (totalSessionSets >= 100) {
                        GymSnackbar.show(
                          context,
                          message: t.workout.err_max_sets_session,
                          icon: Symbols.error,
                          accentColor: Theme.of(context).colorScheme.error,
                        );
                        return;
                      }
                      if (widget.workoutExercise.sets.length >= 50) {
                        GymSnackbar.show(
                          context,
                          message: t.workout.err_max_sets_exercise,
                          icon: Symbols.error,
                          accentColor: Theme.of(context).colorScheme.error,
                        );
                        return;
                      }

                      final lastSet = widget.workoutExercise.sets.lastOrNull;
                      final newSet =
                          lastSet?.copyWith(
                            id: const Uuid().v4(),
                            isCompleted: false,
                          ) ??
                          ExerciseSet(id: const Uuid().v4());
                      widget.onUpdate(
                        widget.workoutExercise.copyWith(
                          sets: [...widget.workoutExercise.sets, newSet],
                        ),
                      );
                    },
                    icon: const Icon(Symbols.add, size: 18),
                    label: Text(
                      t.workout.btn_routine_create_add_set,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: widget.isReorderMode
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        firstChild: _buildCompactHeader(context),
        secondChild: _buildFullCard(context),
      ),
    );
  }
}
