import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';
import 'dart:async';
import '../../../../core/database/enums.dart';
import 'dart:math';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:plato_gymapp/core/bloc/tour/tour_cubit.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

import 'package:plato_gymapp/core/designsystem/components/gym_tour_target.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/navigation/app_router.dart';
import 'package:plato_gymapp/core/utils/tour_keys.dart';
import 'package:plato_gymapp/features/workout/domain/workout_extensions.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/exercise_library_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/database/entities.dart';
import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/designsystem/components/gym_shimmer.dart';

import '../../data/models/workout_models.dart';
import '../bloc/active_session_cubit.dart';
import '../bloc/workout_cubit.dart';
import '../components/workout_components.dart';
import '../components/workout_shared_ui.dart';
import 'exercise_library_screen.dart';

class LogWorkoutScreen extends StatefulWidget {
  final VoidCallback onMinimize;
  final ValueNotifier<bool> isExpandedNotifier;

  const LogWorkoutScreen({
    super.key,
    required this.onMinimize,
    required this.isExpandedNotifier,
  });

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final bool debugForceLoading = false; // TODO(Debug): Đổi thành false khi build Production
  bool _isReorderMode = false;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showFloatingStats = ValueNotifier(false);
  Timer? _focusDebounceTimer;
  Timer? _tourDelayTimer;
  final bool forceShowTour = false; // Debug flag của bạn

  late final ActiveSessionCubit _activeSessionCubit;
  
  late final AnimationController _overlayAnimController;
  final Map<String, GlobalKey> _exerciseKeys = {};

  double _cachedTotalVol = 0;
  int _cachedTotalSets = 0;
  int _cachedTotalReps = 0;
  double _cachedTotalDist = 0;
  int _cachedTotalSteps = 0;
  int _cachedTotalPRs = 0; 
  int _cachedTotalExercises = 0;
  int _cachedSessionHash = 0;

  bool _hasScheduledInitialFocus = false;
  bool _wasKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    
    _activeSessionCubit = context.read<ActiveSessionCubit>();
    _activeSessionCubit.triggerAutoFinishDialog.addListener(_onAutoFinishTriggered);
    
    _overlayAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _activeSessionCubit.resumeWorkoutTimer();
    
    widget.isExpandedNotifier.addListener(_onExpandedChanged);
    
    if (widget.isExpandedNotifier.value) {
      _scheduleFocus(delayMs: 400, animated: true);
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialSetup(); 
    });
  }

  void _onExpandedChanged() {
    if (widget.isExpandedNotifier.value) {
      _scheduleFocus(delayMs: 400, animated: true);
    }
  }

  Future<void> _handleInitialSetup() async {
    if (!mounted) return;
    
    // Gọi hàm check Tour ngay khi màn hình khởi tạo xong
    _checkAndTriggerTour();
  }

  void _checkAndTriggerTour() {
    if (!mounted) return;
    
    final cubit = context.read<ActiveSessionCubit>();
    final session = cubit.state.activeWorkout;
    // Bỏ qua nếu chưa có session hoặc tour khác đang chạy
    if (session == null || AppRouter.isTourActive.value) return; 
    
    final tourCubit = context.read<TourCubit>();
    
    // Case 6: Đã xem tất cả ở buổi tập trước
    if (tourCubit.state.hasSeenLogWorkout && tourCubit.state.hasSeenTimerPlayBtn && !forceShowTour) return;
    
    // Nếu đã xem cơ bản thì không chạy ở init nữa (Timer sẽ do UI component kích hoạt khi cuộn tới/thêm)
    if (tourCubit.state.hasSeenLogWorkout && !forceShowTour) return;

    if (session.exercises.isEmpty) {
      // Case 1: Trống -> Thêm bài Warmup (Type Time)
      final globalExercises = context.read<ExerciseLibraryCubit>().state.exercises;
      if (globalExercises.isNotEmpty) {
        final timeExercise = globalExercises.firstWhere(
          (ex) => ex.type == ExerciseType.TIME_ONLY || 
                  ex.type == ExerciseType.CARDIO_DISTANCE || 
                  ex.type == ExerciseType.CARDIO_STEPS,
          orElse: () => globalExercises.first,
        );
        cubit.addExercisesToActiveWorkout([timeExercise]);
        
        _scheduleTour(tourCubit, includeTimer: true);
      }
    } else {
      // Case 2, 3, 4: Đã có bài
      final firstEx = session.exercises.first;
      final t = firstEx.exercise.type;
      final isFirstCardio = t == ExerciseType.TIME_ONLY || 
                            t == ExerciseType.CARDIO_DISTANCE || 
                            t == ExerciseType.CARDIO_STEPS;
                            
      // Case 2: Time ở #1 -> includeTimer = true
      // Case 3, 4: Time ở #5 hoặc không có -> includeTimer = false
      _scheduleTour(tourCubit, includeTimer: isFirstCardio);
    }
  }

  void _scheduleTour(TourCubit tourCubit, {required bool includeTimer}) {
    AppRouter.isTourActive.value = true;
    _tourDelayTimer?.cancel();
    // Tăng delay lên 750ms để đảm bảo Page Transition Animation chạy xong hoàn toàn
    // Tránh việc Showcase tính toán tọa độ đè lên main thread đang render animation gây khựng/lag (frame skip)
    _tourDelayTimer = Timer(const Duration(milliseconds: 750), () {
      if (!mounted) {
        AppRouter.isTourActive.value = false;
        return;
      }
      _startTourSafely(tourCubit, includeTimer: includeTimer);
    });
  }

  void _startTourSafely(TourCubit tourCubit, {required bool includeTimer}) {
    if (!mounted || !widget.isExpandedNotifier.value) {
      AppRouter.isTourActive.value = false;
      return;
    }
    
    final tourKeys = [
      TourKeys.logWorkoutMinimize,
      TourKeys.logWorkoutDashboard,
      TourKeys.logWorkoutExerciseOptionsBtn,
      TourKeys.logWorkoutSetRow,
    ];
    
    if (includeTimer) {
      tourKeys.add(TourKeys.logWorkoutTimerPlayBtn);
    }
    
    tourKeys.add(TourKeys.logWorkoutFabAdd);

    AppRouter.startTour(
      context, 
      tourKeys,
      onCompleted: () {
        // Chỉ lưu khi Tour chạy xong hoặc bị Skip
        tourCubit.completeLogWorkoutTour();
        if (includeTimer) {
          tourCubit.completeTimerPlayBtnTour();
        }
      }
    );
  }

  ShowCaseWidgetState? _showcaseState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      // ignore: deprecated_member_use
      _showcaseState = ShowCaseWidget.of(context);
    } catch (_) {}
  }

  @override
  void dispose() {
    _activeSessionCubit.triggerAutoFinishDialog.removeListener(_onAutoFinishTriggered);
    _tourDelayTimer?.cancel();
    AppRouter.isTourActive.value = false; 
    
    widget.isExpandedNotifier.removeListener(_onExpandedChanged); 
    // ignore: deprecated_member_use
    _showcaseState?.dismiss();
    _focusDebounceTimer?.cancel(); 
    WidgetsBinding.instance.removeObserver(this); 
    _overlayAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.isExpandedNotifier.value) {
        _scheduleFocus(delayMs: 0, animated: true);
      }
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.platformDispatcher.implicitView?.viewInsets.bottom ?? 0.0;
    final isKeyboardOpen = bottomInset > 0.0;
    if (_wasKeyboardOpen && !isKeyboardOpen) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _wasKeyboardOpen = isKeyboardOpen;
  }

  void _scheduleFocus({int delayMs = 50, bool animated = true}) {
    if (!mounted) return;
    
    _focusDebounceTimer?.cancel();

    if (delayMs <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveTarget(attempts: 0, animated: animated);
      });
      return;
    }
    
    _focusDebounceTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveTarget(attempts: 0, animated: animated);
      });
    });
  }

  void _scrollToActiveTarget({int attempts = 0, bool animated = true}) {
    if (!mounted) return;
    final cubit = context.read<ActiveSessionCubit>();
    final session = cubit.state.activeWorkout;
    if (session == null || session.exercises.isEmpty) return;
    
    final targetData = cubit.getNextTarget();
    final String targetExId = targetData?.exercise.id ?? session.exercises.last.id;
    
    final key = _exerciseKeys[targetExId];
    
    if (key != null && key.currentContext != null) {
      try {
        Scrollable.ensureVisible(
          key.currentContext!,
          alignment: 0.5, 
          duration: animated ? const Duration(milliseconds: 250) : Duration.zero,
          curve: Curves.easeOutCubic,
        );
      } catch (e) {
        debugPrint("Focus Error: $e");
      }
    } else {
      if (attempts < 3) { 
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveTarget(attempts: attempts + 1, animated: animated);
        });
      } else if (_scrollController.hasClients) {
         if (animated) {
           _scrollController.animateTo(
             _scrollController.position.maxScrollExtent,
             duration: const Duration(milliseconds: 250),
             curve: Curves.easeOutCubic
           );
         } else {
           _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
         }
      }
    }
  }

  void _calculateStatsOnce(WorkoutSession session) {
    final currentHash = session.sessionPayload.exercises.hashCode;
    if (_cachedSessionHash == currentHash) return;
    
    _cachedTotalVol = 0; _cachedTotalSets = 0; _cachedTotalReps = 0; 
    _cachedTotalDist = 0; _cachedTotalSteps = 0;
    _cachedTotalExercises = session.exercises.length;

    final history = context.read<WorkoutCubit>().state.historicalWorkoutSessionsList;
    _cachedTotalPRs = session.calculateTotalPRs(history);
    
    for (var ex in session.exercises) {
      for (var s in ex.sets.where((set) => set.isCompleted)) {
        _cachedTotalSets++; 
        _cachedTotalVol += (s.weight * s.reps); 
        _cachedTotalReps += s.reps; 
        _cachedTotalDist += s.distanceInKm; 
        _cachedTotalSteps += s.steps;
      }
    }
    _cachedSessionHash = currentHash;
  }

  void _handleDoneClick(WorkoutSession currentSession) {
    final activeCubit = context.read<ActiveSessionCubit>();
    final totalActiveDuration = activeCubit.state.workoutTimerSeconds;
    int completedValidSets = 0;
    for (var ex in currentSession.exercises) {
      completedValidSets += ex.sets.where((s) => s.isCompleted).length;
    }

    if (completedValidSets == 0) {
      _showNoExerciseCompletedDialog();
      return;
    }

    if (totalActiveDuration < 600) {
      _showGhostWorkoutDialog();
      return;
    }

    final hasIncomplete = currentSession.exercises.any((ex) => ex.sets.any((s) => !s.isCompleted));
    if (hasIncomplete) {
      _showIncompleteWarningDialog();
    } else {
      _showFinishConfirmationDialog(activeCubit);
    }
  }

  void _showFinishConfirmationDialog(ActiveSessionCubit cubit) async {
    final confirmed = await GymDialog.showConfirm(
      context: context,
      title: t.workout.title_auto_finish,
      message: t.workout.msg_finish_workout_confirm,
    );
    if (confirmed == true && mounted) {
      await _processFinishWorkout(cubit);
    }
  }

  void _showGhostWorkoutDialog() async {
    final confirmed = await GymDialog.showDestructive(
      context: context,
      title: t.workout.title_ghost_workout,
      message: t.workout.msg_ghost_workout,
      cancelText: t.workout.btn_mini_player_resume,
      confirmText: t.workout.btn_log_delete_finish,
    );
    if (confirmed == true && mounted) {
      context.read<ActiveSessionCubit>().cleanupActiveWorkout();
      await _processFinishWorkout(context.read<ActiveSessionCubit>());
    }
  }

  void _showNoExerciseCompletedDialog() {
    GymDialog.showInfo(
      context: context,
      title: t.workout.title_no_ex_workout,
      message: t.workout.msg_no_ex_workout,
      buttonText: t.common.confirm,
      icon: Symbols.warning,
      iconColor: Theme.of(context).colorScheme.error,
      buttonColor: Theme.of(context).colorScheme.error,
    );
  }

  Future<void> _executeFinishTransition(ActiveSessionCubit cubit, {required bool saveStructure}) async {
    final router = GoRouter.of(context);
    final workoutId = cubit.state.activeWorkout?.id; 

    widget.onMinimize(); 
    
    // Navigate immediately to trigger Skeleton Loading in session_summary_screen
    router.pushNamed('session_summary', extra: workoutId);
    
    // Process finish asynchronously
    await cubit.finishWorkout(saveStructure: saveStructure);
  }

  Future<void> _processFinishWorkout(ActiveSessionCubit cubit) async {
    final diff = cubit.checkStructuralChanges();
    if (diff['hasChanges'] == true) {
      _showStructuralUpdateDialog(cubit, diff);
    } else {
      await _executeFinishTransition(cubit, saveStructure: false);
    }
  }

  void _onAutoFinishTriggered() {
    if (_activeSessionCubit.triggerAutoFinishDialog.value) {
      // Tắt cờ để không bị gọi lại nhiều lần
      _activeSessionCubit.triggerAutoFinishDialog.value = false;

      final currentSession = _activeSessionCubit.state.activeWorkout;
      if (currentSession != null) {
        int completedValidSets = 0;
        for (var ex in currentSession.exercises) {
          completedValidSets += ex.sets.where((s) => s.isCompleted).length;
        }

        if (completedValidSets == 0) {
          _activeSessionCubit.cleanupActiveWorkout();
          _showAutoCancelGhostDialog();
          return;
        }
      }

      _showAutoFinishDialog();
    }
  }

  void _showAutoCancelGhostDialog() {
    if (!mounted) return;
    GymDialog.showInfo(
      context: context,
      title: t.workout.title_ghost_workout,
      message: t.translateDynamic('workout.msg_auto_cancel_ghost'),
      buttonText: t.common.confirm,
      icon: Symbols.cancel,
      iconColor: Theme.of(context).gymColors.warning,
      onConfirm: () => widget.onMinimize(),
    );
  }

  void _showAutoFinishDialog() async {
    // Tránh lỗi gọi dialog khi màn hình đã đóng
    if (!mounted) return; 

    final confirmed = await GymDialog.showConfirm(
      context: context,
      title: t.workout.title_auto_finish,
      message: t.workout.desc_auto_finish,
      cancelText: t.workout.btn_keep_training,
      confirmText: t.workout.btn_finish_now,
      icon: Symbols.check_circle,
      iconColor: Theme.of(context).gymColors.success,
    );

    if (confirmed == true && mounted) {
      _processFinishWorkout(_activeSessionCubit);
    }
  }

  Widget _buildCompactFloatingBar(BuildContext context, ColorScheme colorScheme, List<Map<String, dynamic>> extraStats) {
    Widget? thirdMetricWidget;
    if (_cachedTotalVol > 0) {
      thirdMetricWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.exercise, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('${_fmtDouble(_cachedTotalVol)}kg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface)),
            ),
          ),
        ]
      );
    } else if (_cachedTotalReps > 0) {
      thirdMetricWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.repeat, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                t.explore.fmt_ex_dtl_reps_only(arg1: _cachedTotalReps.toString()), 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface)
              ),
            ),
          ),
        ]
      );
    } else if (_cachedTotalDist > 0) {
      thirdMetricWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.directions_run, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('${_fmtDouble(_cachedTotalDist)}km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface)),
            ),
          ),
        ]
      );
    } else if (_cachedTotalSteps > 0) {
      thirdMetricWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.directions_walk, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('$_cachedTotalSteps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface)),
            ),
          ),
        ]
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 3), blurRadius: 8)
        ],
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.3), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), 
          child: Material(
            color: colorScheme.onSurface.withValues(alpha: 0.03), 
            child: InkWell(
              onTap: () => _showExtraStatsSheet(context, extraStats), 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlocSelector<ActiveSessionCubit, ActiveSessionState, int>(
                          selector: (state) => state.workoutTimerSeconds,
                          builder: (context, seconds) {
                            final timerColor = seconds > 240 * 60 ? colorScheme.error : 
                                               (seconds > 120 * 60 ? Theme.of(context).gymColors.warning : colorScheme.primary);
                            return Row(
                              children: [
                                Icon(Symbols.timer, size: 18, color: timerColor),
                                const SizedBox(width: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(GymTimerHelper.formatTime(seconds), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: timerColor)),
                                ),
                              ],
                            );
                          }
                        ),
                        if (_cachedTotalPRs > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Symbols.trophy, size: 18, color: Theme.of(context).gymColors.goldRank, fill: 1.0),
                          const SizedBox(width: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('$_cachedTotalPRs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).gymColors.goldRank)),
                          ),
                        ]
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (thirdMetricWidget != null) ...[
                          thirdMetricWidget,
                          const SizedBox(width: 12),
                        ],
                        if (_cachedTotalExercises > 0) ...[
                          Icon(Symbols.format_list_bulleted, size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('$_cachedTotalExercises', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface)),
                          ),
                        ]
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyExerciseState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.exercise, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            t.workout.msg_log_empty, 
            textAlign: TextAlign.center, 
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15, height: 1.5, fontWeight: FontWeight.bold)
          ),
        ],
      ).animate().fade().slideY(begin: 0.1, end: 0),
    );
  }

  void _showStructuralUpdateDialog(ActiveSessionCubit cubit, Map<String, dynamic> diff) {
    final colorScheme = Theme.of(context).colorScheme;

    List<Widget> changeWidgets = [];
    if (diff['reordered'] == true) {
      changeWidgets.add(_buildDiffRow(Symbols.swap_vert, t.workout.msg_diff_reordered, colorScheme.primary));
    }
    if (diff['added'] > 0) {
      changeWidgets.add(_buildDiffRow(Symbols.add_circle, t.workout.msg_diff_added(count: diff['added'].toString()), Theme.of(context).gymColors.success));
    }
    if (diff['removed'] > 0) {
      changeWidgets.add(_buildDiffRow(Symbols.remove_circle, t.workout.msg_diff_removed(count: diff['removed'].toString()), Colors.redAccent));
    }
    if (diff['replaced'] > 0) {
      changeWidgets.add(_buildDiffRow(Symbols.published_with_changes, t.workout.msg_diff_replaced(count: diff['replaced'].toString()), Theme.of(context).gymColors.warning));
    }

    GymDialog.showCustom(
      context: context,
      titleWidget: Row(
        children: [
          Icon(Symbols.info, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(t.workout.title_update_routine, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.workout.msg_diff_intro, style: TextStyle(color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: changeWidgets,
            ),
          ),
          const SizedBox(height: 16),
          Text(t.workout.msg_diff_prompt_save, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop(); 
            await _executeFinishTransition(cubit, saveStructure: false);
          },
          child: Text(t.workout.btn_do_not_save, style: TextStyle(color: colorScheme.onSurfaceVariant))
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await _executeFinishTransition(cubit, saveStructure: true);
          },
          child: Text(t.workout.btn_save_changes, style: const TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildDiffRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  void _showIncompleteWarningDialog() async {
    final confirmed = await GymDialog.showDestructive(
      context: context,
      title: t.workout.title_log_incomplete,
      message: t.workout.msg_log_incomplete,
      cancelText: t.common.cancel,
      confirmText: t.workout.btn_log_delete_finish,
    );

    if (confirmed == true && mounted) {
      context.read<ActiveSessionCubit>().cleanupActiveWorkout();
      await _processFinishWorkout(context.read<ActiveSessionCubit>());
    }
  }

  void _showCancelDialog() async {
    final confirmed = await GymDialog.showDestructive(
      context: context,
      title: t.workout.title_log_cancel_confirm,
      message: t.workout.msg_log_cancel_confirm,
      cancelText: t.common.back,
      confirmText: t.workout.btn_log_cancel,
    );

    if (confirmed == true && mounted) {
      context.read<ActiveSessionCubit>().cancelWorkout();
      widget.onMinimize();
    }
  }

  void _navigateToAddExercise(WorkoutSession currentSession) async {
    final colorScheme = Theme.of(context).colorScheme;
    await context.pushNamed(
      'exercise_library',
      extra: {
        'mode': LibraryMode.multiSelect,
        'preSelectedIds': currentSession.exercises.map((e) => e.exercise.id).toList(), 
        'onSelected': (List<Exercise> exs) {
          // RATE LIMIT CHECK: Max 100 sets per active session
          int currentTotalSets = currentSession.exercises.fold(0, (sum, ex) => sum + ex.sets.length);
          if (currentTotalSets + exs.length > 100) {
            GymSnackbar.show(
              context, 
              message: t.workout.err_max_sets_ssn,
              icon: Symbols.error,
              accentColor: colorScheme.error,
            );
            return;
          }

          context.read<ActiveSessionCubit>().addExercisesToActiveWorkout(exs);
        }
      }
    );
  }

  String _fmtDouble(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

  void _showExtraStatsSheet(BuildContext context, List<Map<String, dynamic>> extraStats) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeCubit = context.read<ActiveSessionCubit>(); 

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.workout.title_dtl_main, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
                const SizedBox(height: 24),
                
                BlocBuilder<ActiveSessionCubit, ActiveSessionState>(
                  bloc: activeCubit, 
                  buildWhen: (previous, current) => previous.workoutTimerSeconds != current.workoutTimerSeconds,
                  builder: (context, state) {
                    final fullStats = [
                      {
                        'label': t.common.time, 
                        'value': GymTimerHelper.formatTime(state.workoutTimerSeconds), 
                        'icon': Symbols.timer
                      },
                      ...extraStats
                    ];
  
                    final bool isNarrow = ResponsiveBreakpoints.of(context).smallerThan(MOBILE);
                    final int crossAxisCount = isNarrow ? 2 : 3; 
                    final List<Widget> rows = [];
                    
                    for (int i = 0; i < fullStats.length; i += crossAxisCount) {
                      final rowChildren = <Widget>[];
                      for (int j = 0; j < crossAxisCount; j++) {
                        if (i + j < fullStats.length) {
                          final stat = fullStats[i + j];
                          final isPR = stat['icon'] == Symbols.trophy;
                          final iconBgColor = isPR ? Theme.of(context).gymColors.goldRank.withValues(alpha: 0.15) : colorScheme.primary.withValues(alpha: 0.1);
                          final iconColor = isPR ? Theme.of(context).gymColors.goldRank : colorScheme.primary;
                          final textColor = isPR ? Theme.of(context).gymColors.goldRank : colorScheme.onSurface;
                          final labelColor = isPR ? Theme.of(context).gymColors.goldRank.withValues(alpha: 0.8) : colorScheme.onSurfaceVariant;
  
                          rowChildren.add(
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                                    child: Icon(stat['icon'] as IconData, color: iconColor, size: 26),
                                  ),
                                  const SizedBox(height: 12),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      stat['value'] as String, 
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stat['label'] as String, 
                                    style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          rowChildren.add(const Expanded(child: SizedBox.shrink()));
                        }
                      }
  
                      rows.add(
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: rowChildren,
                        )
                      );
                      
                      if (i + crossAxisCount < fullStats.length) {
                        rows.add(const SizedBox(height: 28)); 
                      }
                    }
  
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: rows,
                    );
                  }
                ),
              ]
            )
          ),
        )
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final hasSession = context.select((ActiveSessionCubit cubit) => cubit.state.activeWorkout != null);
    if (!hasSession) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: GymTopBar(title: '', onBackClick: widget.onMinimize),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final currentSession = context.read<ActiveSessionCubit>().state.activeWorkout!;

_calculateStatsOnce(currentSession);

    int totalSetsCount = 0;
    int completedSetsCount = 0;
    for (var ex in currentSession.exercises) {
      totalSetsCount += ex.sets.length;
      completedSetsCount += ex.sets.where((s) => s.isCompleted).length;
    }
    final double workoutProgress = totalSetsCount == 0 ? 0.0 : (completedSetsCount / totalSetsCount);

    List<Map<String, dynamic>> extraStats = [];
    if (_cachedTotalVol > 0) extraStats.add({'label': t.stats.lbl_metric_volume, 'value': '${_fmtDouble(_cachedTotalVol)} kg', 'icon': Symbols.exercise});
    if (_cachedTotalSets > 0) extraStats.add({'label': t.workout.lbl_dtl_stat_sets, 'value': '$_cachedTotalSets', 'icon': Symbols.format_list_numbered});
    if (_cachedTotalReps > 0) extraStats.add({'label': t.stats.lbl_metric_reps, 'value': '$_cachedTotalReps', 'icon': Symbols.repeat});
    if (_cachedTotalDist > 0) extraStats.add({'label': t.common.distance, 'value': '${_fmtDouble(_cachedTotalDist)} km', 'icon': Symbols.directions_run});
    if (_cachedTotalSteps > 0) extraStats.add({'label': t.common.steps, 'value': '$_cachedTotalSteps', 'icon': Symbols.directions_walk});
    if (_cachedTotalExercises > 0) extraStats.add({'label': t.profile.btn_menu_exercises, 'value': '$_cachedTotalExercises', 'icon': Symbols.format_list_bulleted});
    if (_cachedTotalPRs > 0) extraStats.add({'label': t.gamification.title_main, 'value': '$_cachedTotalPRs', 'icon': Symbols.trophy});



    Widget buildStatsBoard(bool isTablet) {
      return BlocBuilder<ActiveSessionCubit, ActiveSessionState>(
        buildWhen: (prev, curr) => prev.activeWorkout != curr.activeWorkout,
        builder: (context, state) {
          final session = state.activeWorkout;
          if (session == null) return const SizedBox.shrink();

          _calculateStatsOnce(session);

          List<Map<String, dynamic>> extraStats = [];
          if (_cachedTotalVol > 0) extraStats.add({'label': t.stats.lbl_metric_volume, 'value': '${_fmtDouble(_cachedTotalVol)} kg', 'icon': Symbols.exercise});
          if (_cachedTotalSets > 0) extraStats.add({'label': t.workout.lbl_dtl_stat_sets, 'value': '$_cachedTotalSets', 'icon': Symbols.format_list_numbered});
          if (_cachedTotalReps > 0) extraStats.add({'label': t.stats.lbl_metric_reps, 'value': '$_cachedTotalReps', 'icon': Symbols.repeat});
          if (_cachedTotalDist > 0) extraStats.add({'label': t.common.distance, 'value': '${_fmtDouble(_cachedTotalDist)} km', 'icon': Symbols.directions_run});
          if (_cachedTotalSteps > 0) extraStats.add({'label': t.common.steps, 'value': '$_cachedTotalSteps', 'icon': Symbols.directions_walk});
          if (_cachedTotalExercises > 0) extraStats.add({'label': t.profile.btn_menu_exercises, 'value': '$_cachedTotalExercises', 'icon': Symbols.format_list_bulleted});
          if (_cachedTotalPRs > 0) extraStats.add({'label': t.gamification.title_main, 'value': '$_cachedTotalPRs', 'icon': Symbols.trophy});

      final showMoreBtn = extraStats.length > 2;
      Map<String, dynamic>? midStat;
          if (_cachedTotalVol > 0) {
            midStat = {'label': t.stats.lbl_metric_volume, 'value': '${_fmtDouble(_cachedTotalVol)} kg', 'icon': Symbols.exercise};
          } else if (_cachedTotalDist > 0) midStat = {'label': t.common.distance, 'value': '${_fmtDouble(_cachedTotalDist)} km', 'icon': Symbols.directions_run};
          else if (_cachedTotalSteps > 0) midStat = {'label': t.common.steps, 'value': '$_cachedTotalSteps', 'icon': Symbols.directions_walk};
          else if (_cachedTotalReps > 0) midStat = {'label': t.stats.lbl_metric_reps, 'value': '$_cachedTotalReps', 'icon': Symbols.repeat};

      final allStatWidgets = <Widget>[
        BlocSelector<ActiveSessionCubit, ActiveSessionState, int>(
          selector: (state) => state.workoutTimerSeconds,
          builder: (context, seconds) {
            final timerColor = seconds > 240 * 60 ? colorScheme.error : 
                               (seconds > 120 * 60 ? Theme.of(context).gymColors.warning : colorScheme.primary);
            return WorkoutStatItem(label: t.common.time, value: GymTimerHelper.formatTime(seconds), icon: Symbols.timer, color: timerColor);
          }
        ),
      ];

      if (_cachedTotalExercises > 0) {
        allStatWidgets.add(
          WorkoutStatItem(
            label: t.profile.btn_menu_exercises, 
            value: "$_cachedTotalExercises", 
            icon: Symbols.format_list_bulleted
          ),
        );
        allStatWidgets.add(WorkoutStatItem(label: t.common.set.toUpperCase(), value: "$_cachedTotalSets", icon: Symbols.format_list_numbered));
        
        if (_cachedTotalVol > 0) allStatWidgets.add(WorkoutStatItem(label: t.stats.lbl_metric_volume, value: '${_fmtDouble(_cachedTotalVol)} kg', icon: Symbols.exercise));
        if (_cachedTotalReps > 0) allStatWidgets.add(WorkoutStatItem(label: t.stats.lbl_metric_reps, value: '$_cachedTotalReps', icon: Symbols.repeat));
        if (_cachedTotalDist > 0) allStatWidgets.add(WorkoutStatItem(label: t.common.distance, value: '${_fmtDouble(_cachedTotalDist)} km', icon: Symbols.directions_run));
        if (_cachedTotalSteps > 0) allStatWidgets.add(WorkoutStatItem(label: t.common.steps, value: '$_cachedTotalSteps', icon: Symbols.directions_walk));
        
        if (_cachedTotalPRs > 0) {
          allStatWidgets.add(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text('$_cachedTotalPRs', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).gymColors.goldRank))),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Symbols.trophy, size: 16, color: Theme.of(context).gymColors.goldRank, fill: 1.0),
                    const SizedBox(width: 6),
                    Text(t.gamification.title_main, style: TextStyle(fontSize: 12, color: Theme.of(context).gymColors.goldRank.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            )
          );
        }
      }

      Widget content;

      if (isTablet) {
        final rows = <Widget>[];
        for (int i = 0; i < allStatWidgets.length; i += 2) {
          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: allStatWidgets[i]),
                if (i + 1 < allStatWidgets.length)
                  Expanded(child: allStatWidgets[i + 1])
                else
                  Expanded(child: const SizedBox.shrink()),
              ],
            )
          );
          if (i + 2 < allStatWidgets.length) {
            rows.add(const SizedBox(height: 24)); 
          }
        }
        content = Column(mainAxisSize: MainAxisSize.min, children: rows);
      } else {
        // [FIX UX/PERF]: Thay Column bằng Row cố định chiều cao.
        // Xóa bỏ hoàn toàn phần render nút more_horiz làm giãn layout.
        content = Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: allStatWidgets[0]), 
            if (_cachedTotalExercises > 0 && midStat != null)
              Expanded(child: WorkoutStatItem(label: midStat['label'], value: midStat['value'], icon: midStat['icon'])),
            if (_cachedTotalExercises > 0 && allStatWidgets.length > 1)
              Expanded(child: allStatWidgets[1]), 
          ],
        );
      }

      // [FIX UX/PERF]: Bọc toàn bộ Card bằng InkWell và dùng Stack để hiển thị Icon báo hiệu
      Widget boardWidget = Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        // Xóa padding tĩnh ở Container để chuyển vào bên trong InkWell (tạo hiệu ứng tap đẹp hơn)
        decoration: BoxDecoration(
          color: colorScheme.surface, 
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            // Kích hoạt tap mở BottomSheet nếu đang ở Mobile và có nhiều số liệu
            onTap: (!isTablet && showMoreBtn) ? () => _showExtraStatsSheet(context, extraStats) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  content,
                  // Icon góc phải báo hiệu người dùng có thể bấm vào thẻ
                  if (!isTablet && showMoreBtn)
                    Positioned(
                      right: 16,
                      top: -4,
                      child: Icon(
                        Symbols.open_in_new, 
                        size: 16, 
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      );

      return GymTourTarget(
        isActive: !context.read<TourCubit>().state.hasSeenLogWorkout || forceShowTour,
        tourKey: TourKeys.logWorkoutDashboard,
        title: t.tour.log_dash_title,
        description: t.tour.log_dash_desc,
        tooltipPosition: isTablet ? TooltipPosition.right : null,
        borderRadius: 24.0,
        targetPadding: EdgeInsets.zero,
        child: boardWidget,
      );
          }
        );
    }

    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AppRouter.abortTour(context);
        widget.onMinimize(); 
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<ActiveSessionCubit, ActiveSessionState>(
            listenWhen: (previous, current) => previous.restTimerSeconds > 0 && current.restTimerSeconds == 0,
            listener: (context, state) {},
          ),
          
          BlocListener<ActiveSessionCubit, ActiveSessionState>(
            listenWhen: (previous, current) => previous.activeWorkout == null && current.activeWorkout != null,
            listener: (context, state) {
              if (!_hasScheduledInitialFocus) {
                _hasScheduledInitialFocus = true;
                if (widget.isExpandedNotifier.value) {
                  _scheduleFocus(delayMs: 400); 
                }
              }
              // Gọi hàm kiểm tra dùng chung
              _checkAndTriggerTour();
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          resizeToAvoidBottomInset: true, 
          appBar: _isReorderMode 
            ? GymTopBar(
                title: t.workout.title_routine_create_reorder,
                onBackClick: () {
                  setState(() => _isReorderMode = false);
                },
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() => _isReorderMode = false);
                    },
                    child: Text(t.common.done, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                  )
                ],
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(59.0), 
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GymTopBar(
                      title: t.workout.title_log_main,
                      navIcon: Symbols.keyboard_arrow_down,
                      onBackClick: () {
                        // ignore: deprecated_member_use
          _showcaseState?.dismiss(); 
                        widget.onMinimize(); 
                      },
                      navTourKey: TourKeys.logWorkoutMinimize,
                      navTourTitle: t.tour.log_minimize_title,
                      navTourDesc: t.tour.log_minimize_desc,
                      actions: [
                        TextButton(
                          onPressed: () => _handleDoneClick(currentSession),
                          child: Text(t.common.done, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                        )
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(3.0),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: workoutProgress),
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
                  ],
                ),
              ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
                
                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              // [FIX CỰC MẠNH 2]: Scroll Throttling chặn rebuild vô nghĩa
                              if (notification.metrics.axis == Axis.vertical) {
                                if (_scrollController.hasClients) {
                                  final offset = _scrollController.offset;
                                  if (offset > 100 && !_showFloatingStats.value) {
                                    _showFloatingStats.value = true;
                                  } else if (offset <= 100 && _showFloatingStats.value) {
                                    _showFloatingStats.value = false;
                                  }
                                }

                                if (notification is ScrollUpdateNotification) {
                                  if (notification.metrics.outOfRange && notification.dragDetails == null) {
                                    return false; 
                                  }
                                  
                                  if (notification.scrollDelta != null) {
                                    // Bỏ qua các rung động cuộn nhỏ hơn 1.5 pixels
                                    if (notification.scrollDelta!.abs() > 4.0) {
                                      _overlayAnimController.value += notification.scrollDelta! / 150.0;
                                    }
                                  }
                                }
                                else if (notification is OverscrollNotification) {
                                  if (notification.dragDetails != null) {
                                    _overlayAnimController.value += notification.overscroll / 150.0;
                                  }
                                } 
                                else if (notification is ScrollEndNotification) {
                                  if (_overlayAnimController.value > 0.0 && _overlayAnimController.value < 1.0) {
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
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1200),
                                child: isTablet 
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: ListView(
                                            physics: const AlwaysScrollableScrollPhysics(),
                                            padding: const EdgeInsets.all(24),
                                            children: [
                                              if (!_isReorderMode)
                                                buildStatsBoard(true).animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0),
                                            ],
                                          ),
                                        ),
                                        Container(width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                        Expanded(
                                          flex: 6,
                                          child: debugForceLoading 
                                            ? GymShimmer(
                                                child: ListView.builder(
                                                  padding: EdgeInsets.only(
                                                    top: 24, 
                                                    bottom: max(140.0, screenHeight * 0.6), 
                                                    left: 16, 
                                                    right: 16
                                                  ),
                                                  itemCount: 3,
                                                  itemBuilder: (context, index) => const _ExerciseCardShimmer(),
                                                ),
                                              )
                                            : currentSession.exercises.isEmpty 
                                              ? _buildEmptyExerciseState(colorScheme)
                                              : ReorderableListView.builder(
                                            physics: const AlwaysScrollableScrollPhysics(),
                                            scrollController: _scrollController,
                                            padding: EdgeInsets.only(
                                              top: 24, 
                                              bottom: max(140.0, screenHeight * 0.6), 
                                              left: 16, 
                                              right: 16
                                            ),
                                            itemCount: currentSession.exercises.length, 
                                            buildDefaultDragHandles: false, 
                                            proxyDecorator: (child, index, animation) {
                                              return AnimatedBuilder(
                                                animation: animation,
                                                builder: (context, _) {
                                                  final colorScheme = Theme.of(context).colorScheme;
                                                  final double animValue = Curves.easeOutCubic.transform(animation.value);
                                                  final double scale = 1.0 + (0.02 * animValue);
                                                  final double rotation = 0.01 * animValue; 
                                                  
                                                  return Transform(
                                                    alignment: Alignment.center,
                                                    // ignore: deprecated_member_use
                                                    transform: Matrix4.identity()..scale(scale)..rotateZ(rotation), 
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(16),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: colorScheme.primary.withValues(alpha: 0.15 * animValue),
                                                            blurRadius: 10 * animValue,
                                                            spreadRadius: 2 * animValue,
                                                            offset: Offset(0, 4 * animValue),
                                                          ),
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.1 * animValue), 
                                                            blurRadius: 8 * animValue,
                                                            offset: Offset(0, 2 * animValue),
                                                          )
                                                        ],
                                                      ),
                                                      child: Material(
                                                        color: Colors.transparent,
                                                        child: child,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              );
                                            },
                                            onReorderStart: (index) {
                                              FocusManager.instance.primaryFocus?.unfocus(); 
                                              HapticFeedback.heavyImpact(); 
                                            },
                                            onReorderEnd: (index) {
                                              HapticFeedback.lightImpact(); 
                                            },
                                            onReorder: (oldIndex, newIndex) {
                                              int clampedNewIndex = newIndex;
                                              if (clampedNewIndex > currentSession.exercises.length) clampedNewIndex = currentSession.exercises.length;
                                              if (clampedNewIndex > oldIndex) clampedNewIndex -= 1;
                                              
                                              final newList = List<WorkoutExercise>.from(currentSession.exercises);
                                              final item = newList.removeAt(oldIndex);
                                              newList.insert(clampedNewIndex, item);
                                              
                                              context.read<ActiveSessionCubit>().reorderExercises(newList);
                                            },
                                            itemBuilder: (context, index) {
                                              final exId = currentSession.exercises[index].id;
                                              _exerciseKeys[exId] ??= GlobalKey();
        
                                              final cardNode = Container(
                                                key: _exerciseKeys[exId],
                                                child: ActiveExerciseCard(
                                                  workoutExercise: currentSession.exercises[index],
                                                  exerciseIndex: index,
                                                  activeSessionCubit: context.read<ActiveSessionCubit>(),
                                                  isReorderMode: _isReorderMode,
                                                  ), // [FIX PERF]: Bỏ animate để tránh jank
                                              );

                                              return ReorderableDragStartListener(
                                                key: ValueKey('${exId}_drag'),
                                                index: index,
                                                enabled: _isReorderMode,
                                                child: ReorderableDelayedDragStartListener(
                                                  key: ValueKey('${exId}_delay_drag'),
                                                  index: index,
                                                  enabled: !_isReorderMode,
                                                  child: cardNode,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      ],
                                    )
                                  : debugForceLoading 
                                      ? Column(
                                          children: [
                                            if (!_isReorderMode)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 12.0),
                                                child: buildStatsBoard(false),
                                              ),
                                            Expanded(
                                              child: GymShimmer(
                                                child: ListView.builder(
                                                  padding: EdgeInsets.only(
                                                    top: 8, 
                                                    bottom: max(140.0, screenHeight * 0.2), 
                                                    left: 16, 
                                                    right: 16
                                                  ),
                                                  itemCount: 3,
                                                  itemBuilder: (context, index) => const _ExerciseCardShimmer(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : currentSession.exercises.isEmpty 
                                          ? Padding(
                                              padding: EdgeInsets.only(
                                              top: 8, 
                                              bottom: max(140.0, screenHeight * 0.2), 
                                              left: 16, 
                                              right: 16
                                            ),
                                            child: Column(
                                              children: [
                                                if (!_isReorderMode)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 12.0),
                                                    child: buildStatsBoard(false),
                                                  ),
                                                Expanded(child: _buildEmptyExerciseState(colorScheme)),
                                              ],
                                            ),
                                          )
                                        : ReorderableListView.builder(
                                            header: !isTablet ? Padding(
                                              padding: const EdgeInsets.only(bottom: 12.0),
                                              child: buildStatsBoard(false),
                                            ) : const SizedBox.shrink(),
                                            physics: const AlwaysScrollableScrollPhysics(),
                                            scrollController: _scrollController,
                                            padding: EdgeInsets.only(
                                              top: 8, 
                                              bottom: max(140.0, screenHeight * 0.2), 
                                              left: 16, 
                                              right: 16
                                            ),
                                            itemCount: currentSession.exercises.length,
                                            footer: _isReorderMode 
                                              ? const SizedBox.shrink() 
                                              : Padding(
                                                  key: const ValueKey('log_end_footer'),
                                                  padding: const EdgeInsets.only(top: 32.0, bottom: 32.0),
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Symbols.flag, 
                                                          size: 28, 
                                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          t.workout.msg_log_end_reached,
                                                          style: TextStyle(
                                                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                            buildDefaultDragHandles: false,
                                            proxyDecorator: (child, index, animation) {
                                              return AnimatedBuilder(
                                                animation: animation,
                                                builder: (context, _) {
                                                  final colorScheme = Theme.of(context).colorScheme;
                                                  final double animValue = Curves.easeOutCubic.transform(animation.value);
                                                  final double scale = 1.0 + (0.02 * animValue);
                                                  final double rotation = 0.01 * animValue; 
                                                  
                                                  return Transform(
                                                    alignment: Alignment.center,
                                                    // ignore: deprecated_member_use
                                              transform: Matrix4.identity()..scale(scale)..rotateZ(rotation), 
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(16),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: colorScheme.primary.withValues(alpha: 0.15 * animValue),
                                                            blurRadius: 10 * animValue,
                                                            spreadRadius: 2 * animValue,
                                                            offset: Offset(0, 4 * animValue),
                                                          ),
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.1 * animValue), 
                                                            blurRadius: 8 * animValue,
                                                            offset: Offset(0, 2 * animValue),
                                                          )
                                                        ],
                                                      ),
                                                      child: Material(
                                                        color: Colors.transparent,
                                                        child: child,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              );
                                            },
                                            
                                            onReorderStart: (index) {
                                              FocusManager.instance.primaryFocus?.unfocus(); 
                                              HapticFeedback.heavyImpact(); 
                                              Future.delayed(const Duration(milliseconds: 50), () => HapticFeedback.heavyImpact());
                                            },
                                            onReorderEnd: (index) {
                                              HapticFeedback.lightImpact(); 
                                            },
                                            onReorder: (oldIndex, newIndex) {
                                              if (oldIndex >= currentSession.exercises.length) return; 
                                              int clampedNewIndex = newIndex;
                                              if (clampedNewIndex > currentSession.exercises.length) clampedNewIndex = currentSession.exercises.length;
                                              if (clampedNewIndex > oldIndex) clampedNewIndex -= 1;
                                              
                                              final newList = List<WorkoutExercise>.from(currentSession.exercises);
                                              final item = newList.removeAt(oldIndex);
                                              newList.insert(clampedNewIndex, item);
                                              
                                              context.read<ActiveSessionCubit>().reorderExercises(newList);
                                            },
                                            itemBuilder: (context, index) {
                                              final exId = currentSession.exercises[index].id;
                                              _exerciseKeys[exId] ??= GlobalKey();
          
                                              final cardNode = Container(
                                                key: _exerciseKeys[exId],
                                                child: ActiveExerciseCard(
                                                  workoutExercise: currentSession.exercises[index],
                                                  exerciseIndex: index,
                                                  activeSessionCubit: context.read<ActiveSessionCubit>(),
                                                  isReorderMode: _isReorderMode,
                                                ), // [FIX PERF]: Bỏ animate để tránh jank
                                              );

                                              return ReorderableDragStartListener(
                                                key: ValueKey('${exId}_drag'),
                                                index: index,
                                                enabled: _isReorderMode,
                                                child: ReorderableDelayedDragStartListener(
                                                  key: ValueKey('${exId}_delay_drag'),
                                                  index: index,
                                                  enabled: !_isReorderMode,
                                                  child: cardNode,
                                                ),
                                              );
                                            },
                                          ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (!isTablet && !_isReorderMode)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _showFloatingStats,
                          builder: (context, isShowing, child) {
                            return AnimatedSlide(
                              offset: isShowing ? Offset.zero : const Offset(0, -1.5),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              child: AnimatedOpacity(
                                opacity: isShowing ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: _buildCompactFloatingBar(context, colorScheme, extraStats),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _overlayAnimController,
                        builder: (context, child) {
                          final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                          final fabAnimValue = (isKeyboardOpen || _isReorderMode) ? 1.0 : _overlayAnimController.value;
                          final timerAnimValue = (isKeyboardOpen || _isReorderMode) ? 1.0 : _overlayAnimController.value; 

                          final bottomSafeArea = MediaQuery.of(context).padding.bottom;
                          final timerVisibleOffset = (bottomSafeArea > 0 && !isKeyboardOpen) ? bottomSafeArea + 16.0 : 16.0;
                          final timerBottom = lerpDouble(timerVisibleOffset, -150.0, timerAnimValue);
                          
                          final fabBottomSafeArea = bottomSafeArea > 0 ? bottomSafeArea + 16.0 : 24.0;
                          final fabRight = lerpDouble(16.0, -100.0, fabAnimValue) ?? 16.0;

                          // [FIX CỰC MẠNH 3]: Đưa Timer vào BlocSelector, ngăn chặn re-render cả màn hình
                          return BlocSelector<ActiveSessionCubit, ActiveSessionState, int>(
                            selector: (state) => state.restTimerSeconds,
                            builder: (context, currentRestTimerSeconds) {
                              final hasTimer = currentRestTimerSeconds > 0;
                              final fabBottomOffset = (hasTimer && !isTablet) ? (fabBottomSafeArea + 72.0) : fabBottomSafeArea;
                              
                              return Stack(
                                children: [
                                  if (hasTimer)
                                    Positioned(
                                      bottom: timerBottom,
                                      left: 16,
                                      right: 16,
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 600),
                                          child: RestTimerOverlay(
                                            seconds: currentRestTimerSeconds, 
                                            activeSessionCubit: context.read<ActiveSessionCubit>()
                                          ),
                                        ),
                                      ),
                                    ),
                                  
                                  Positioned.fill(
                                    child: WorkoutExpandableActionFab(
                                      fabRightOffset: fabRight,
                                      fabBottomOffset: fabBottomOffset,
                                      isKeyboardOpen: isKeyboardOpen,
                                      fabTourKey: TourKeys.logWorkoutFabAdd,
                                      fabTourTitle: t.tour.log_fab_add_title,
                                      fabTourDesc: t.tour.log_fab_add_desc,
                                      onAdd: () => _navigateToAddExercise(currentSession),
                                      onReorder: () => setState(() => _isReorderMode = true),
                                      onCancel: () {
                                        HapticFeedback.heavyImpact();
                                        _showCancelDialog();
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                          );
                        }
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
      )
    );
  }
}



class _ExerciseCardShimmer extends StatelessWidget {
  const _ExerciseCardShimmer();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const GymShimmerCircle(radius: 20),
                const SizedBox(width: 12),
                const GymShimmerBlock(width: 150, height: 16),
                const Spacer(),
                Icon(Symbols.more_vert, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                GymShimmerBlock(width: 30, height: 12),
                GymShimmerBlock(width: 50, height: 12),
                GymShimmerBlock(width: 50, height: 12),
                GymShimmerBlock(width: 30, height: 12),
              ],
            ),
            const SizedBox(height: 12),
            const GymShimmerBlock(width: double.infinity, height: 32),
            const SizedBox(height: 8),
            const GymShimmerBlock(width: double.infinity, height: 32),
          ],
        ),
      ),
    );
  }
}











