import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

import 'package:plato_gymapp/features/workout/data/models/workout_models.dart';
import 'package:plato_gymapp/features/workout/domain/workout_extensions.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/exercise_library_cubit.dart';

import '../../../../core/navigation/app_routes.dart';
import '../bloc/editor_cubit.dart';

import '../../../../core/designsystem/theme/app_theme.dart';
import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/database/enums.dart';

import '../../../../core/utils/search_utils.dart';

import '../bloc/workout_cubit.dart';

extension ExerciseMetricBadge on ExerciseMetric {
  String get shortBadgeString {
    switch (this) {
      case ExerciseMetric.ONE_RM: return t.workout.badge_1rm;
      case ExerciseMetric.BEST_WEIGHT: return t.common.weight;
      case ExerciseMetric.BEST_SET_VOL: return t.common.volume;
      case ExerciseMetric.LONGEST_DISTANCE: return t.common.distance;
      case ExerciseMetric.BEST_STEPS: return t.common.steps;
      case ExerciseMetric.BEST_TIME: return t.common.duration;
      case ExerciseMetric.BEST_REPS: return t.common.reps;
      default: return '';
    }
  }
}

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool _isExpandedMuscle = false;

  static const bool kShowCaloriesFeature = false;



  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;

    // Luôn format phút và giây cố định 2 chữ số (MM:SS)
    final formattedMS = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    // Nếu có giờ thì nối thêm giờ, nếu không thì giữ nguyên MM:SS
    return h > 0 ? '$h:$formattedMS' : formattedMS;
  }

  // Format chuyên biệt cho Rest Timer (Hiển thị m và s)
  String _formatRestTime(int seconds) {
    if (seconds <= 0) return "0s";
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return "${m}m ${s}s";
    if (m > 0) return "${m}m";
    return "${seconds}s";
  }

  String _formatDouble(double val) {
    if (val == val.toInt().toDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;

    final history = context.watch<WorkoutCubit>().state.historicalWorkoutSessionsList;
    final session = history.where((s) => s.id == widget.workoutId).firstOrNull;

    if (session == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: GymTopBar(title: t.workout.title_dtl_main, onBackClick: () => context.pop()),
        body: Center(child: Text(t.workout.msg_dtl_not_found, style: TextStyle(color: colorScheme.onSurfaceVariant))),
      );
    }
    final pureMuscleMap = session.exercises.calculateMuscleDistribution(onlyCompletedSets: true);
    final sortedMuscles = pureMuscleMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalVolume = session.totalVolume.toInt();

    final int sessionPRCount = session.calculateTotalPRs(history);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.workout.title_dtl_main,
        onBackClick: () => context.pop(),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Symbols.more_vert, color: colorScheme.onSurface),
            color: colorScheme.surface,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            elevation: 4, 
            onSelected: (v) async {
              if (v == 'delete') {
                final confirm = await GymDialog.showDestructive(
                  context: context,
                  title: t.workout.title_dtl_delete_dialog,
                  message: t.workout.msg_dtl_delete_dialog,
                );
                if (confirm == true && context.mounted) {
                  context.read<WorkoutCubit>().deleteWorkout(widget.workoutId);
                  context.pop();
                }
              } else if (v == 'save_as_routine') {
                context.read<EditorCubit>().initNewRoutineFromHistory(session);
                
                // CHỈ CẦN PUSH BÌNH THƯỜNG
                context.push('/workout/${AppRoutes.createRoutine}');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'save_as_routine', 
                child: Row(
                  children: [
                    Icon(Symbols.save_alt, color: colorScheme.onSurface, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      t.workout.menu_save_as_routine, 
                      style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600)
                    ),
                  ]
                )
              ),
              PopupMenuItem(
                value: 'delete', 
                child: Row(
                  children: [
                    Icon(Symbols.delete, color: colorScheme.error, size: 20),
                    const SizedBox(width: 12),
                    Text(t.common.delete, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600)),
                  ]
                )
              ),
            ],
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 600;

          // ===================================
          // PHẦN 1: HEADER
          // ===================================
          Widget headerSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center, 
                children: [
                  Expanded(
                    child: Text(
                      t.translateDynamic(session.name), 
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface, height: 1.2)
                    )
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: gymColors.goldRank.withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(t.workout.fmt_dtl_xp_earned(arg1: session.xpEarned.toString()), 
                          style: TextStyle(color: gymColors.goldRank, fontWeight: FontWeight.bold, fontSize: 16)), 
                        const SizedBox(width: 8),
                        Icon(Symbols.bolt, color: Theme.of(context).gymColors.goldRank, size: 18, fill: 1.0), // (Tuỳ chọn) Dùng Material Symbols với fill để icon nổi bật hơn
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _DetailSummaryItem(icon: Symbols.timer, label: t.common.duration, value: _formatDuration(session.totalDurationSeconds))),
                  const SizedBox(width: 16), 
                  Expanded(child: _DetailSummaryItem(icon: Symbols.exercise, label: t.stats.lbl_metric_volume, value: t.onboarding.fmt_kg(arg1: totalVolume.toString()))),
                  const SizedBox(width: 16),
                  Expanded(child: _DetailSummaryItem(icon: Symbols.repeat, label: t.workout.lbl_dtl_stat_sets, value: "${session.totalSets}")),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kShowCaloriesFeature) ...[
                    Expanded(child: _DetailSummaryItem(icon: Symbols.local_fire_department, label: t.workout.lbl_dtl_stat_calories, value: "${session.totalCaloriesBurned} kcal")),
                    const SizedBox(width: 16),
                  ],
                  Expanded(child: _DetailSummaryItem(icon: Symbols.speed, label: t.workout.lbl_dtl_stat_rpe, value: session.rpe != null ? t.workout.fmt_dtl_rpe_value(arg1: session.rpe.toString()) : t.workout.lbl_dtl_rpe_unrated)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: sessionPRCount > 0 
                      ? _DetailSummaryItem(icon: Symbols.trophy, label: t.gamification.title_main, value: t.workout.fmt_dtl_pr_count(arg1: sessionPRCount.toString()), highlightColor: gymColors.goldRank)
                      : const SizedBox.shrink()
                  ),
                  if (!kShowCaloriesFeature) const Spacer(), 
                ],
              ),
            ],
          ).animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);

          // ===================================
          // PHẦN 2: MUSCLE SPLIT
          // ===================================
          Widget muscleSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.workout.title_dtl_muscle_split, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)),
              const SizedBox(height: 24),
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    ...sortedMuscles.take(_isExpandedMuscle ? sortedMuscles.length : 3).toList().asMap().entries.map((entryMap) {
                      final index = entryMap.key;
                      final entry = entryMap.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(entry.key.getLocalizedName(), style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                                Text(t.workout.fmt_warn_recovery_percent(arg1: entry.value.toInt().toString()), style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)), 
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: entry.value / 100,
                                backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                color: (entry.value / 100) >= 0.02 ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                minHeight: 8,
                              ).animate().scaleX(duration: 800.ms, curve: Curves.easeOutCubic, alignment: Alignment.centerLeft),
                            )
                          ],
                        ),
                      ).animate(delay: (index * 100).ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0); 
                    }),
                    if (sortedMuscles.length > 3)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setState(() => _isExpandedMuscle = !_isExpandedMuscle),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(_isExpandedMuscle ? t.workout.btn_dtl_muscle_collapse : t.workout.btn_dtl_muscle_expand, 
                                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Icon(_isExpandedMuscle ? Symbols.expand_less : Symbols.expand_more, color: colorScheme.primary, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fade(duration: 400.ms),
                  ],
                ),
              )
            ],
          ).animate(delay: 100.ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);

          // ===================================
          // PHẦN 3: EXERCISES
          // ===================================
          Widget exercisesSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.workout.fmt_dtl_exercises_count(arg1: session.exercises.length.toString()), 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)),
              const SizedBox(height: 16),
              ...session.exercises.asMap().entries.map((exEntry) {
                final exIndex = exEntry.key;
                final ex = exEntry.value;
                final displayRestTime = ex.sets.firstOrNull?.restTimeSeconds ?? ex.restTimeSeconds;

                final pastHistory = history.where((s) => s.startTime < session.startTime).toList();
                List<ExerciseSet> pastSetsForThisEx = [];
                for (var pSession in pastHistory) {
                  final pastEx = pSession.exercises.where((e) => e.exercise.id == ex.exercise.id).firstOrNull;
                  if (pastEx != null) pastSetsForThisEx.addAll(pastEx.sets.where((s) => s.isCompleted));
                }

                final bool hasPastHistory = pastSetsForThisEx.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          // FIX DEBUG: Lấy bài tập Global mới nhất thay vì dùng bản sao lịch sử
                          final globalExercises = context.read<ExerciseLibraryCubit>().state.exercises;
                          final fullExercise = globalExercises.firstWhere(
                            (e) => e.id == ex.exercise.id, 
                            orElse: () => ex.exercise
                          );

                          context.pushNamed(
                            'exercise_details', 
                            extra: fullExercise, // Truyền fullExercise thay vì ex.exercise
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.translateDynamic(ex.exercise.name), 
                                      // REFACTOR: Đổi màu text thành onSurface
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colorScheme.onSurface)
                                    ),
                                  ),
                                  Icon(Symbols.chevron_right, size: 24, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                ],
                              ),
                              
                              // HIỂN THỊ BADGE REST TIMER & SUPERSET
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // REFACTOR: Luôn hiển thị Rest Timer, dùng primary color và handle case Off
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            displayRestTime > 0 ? Symbols.timer : Symbols.timer_off, 
                                            size: 12, 
                                            color: colorScheme.primary
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            displayRestTime > 0 ? _formatRestTime(displayRestTime) : t.workout.lbl_rest_off, 
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary)
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (ex.supersetId != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).gymColors.accentTeal.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Theme.of(context).gymColors.accentTeal.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Symbols.link, size: 12, color: Theme.of(context).gymColors.accentTeal),
                                            const SizedBox(width: 4),
                                            Text(t.workout.type_superset, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).gymColors.accentTeal)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...ex.sets.asMap().entries.map((setEntry) {
                        final setIdx = setEntry.key;
                        final s = setEntry.value;
                        
                        final List<ExerciseMetric> setPRs = ex.getAchievedPRsForSet(pastSetsForThisEx, s.id);
                        final bool isPR = hasPastHistory && s.isCompleted && setPRs.isNotEmpty;
                        
                        pastSetsForThisEx.add(s);
                        
                        String detailsString = "";
                        if (ex.exercise.type == ExerciseType.TIME_ONLY) {
                          detailsString = _formatDuration(s.durationTimeSeconds);
                        } else if (ex.exercise.type == ExerciseType.CARDIO_DISTANCE) {
                          detailsString = t.workout.fmt_dtl_set_dist_time(arg1: s.distanceInKm.toString(), arg2: _formatDuration(s.durationTimeSeconds));
                        } else if (ex.exercise.type == ExerciseType.CARDIO_STEPS) {
                          detailsString = t.workout.fmt_dtl_set_steps_time(arg1: s.steps.toString(), arg2: _formatDuration(s.durationTimeSeconds));
                        } else if (ex.exercise.type == ExerciseType.REPS_ONLY) {
                          detailsString = t.explore.fmt_ex_dtl_reps_only(arg1: s.reps.toString());
                        } else {
                          detailsString = t.explore.fmt_ex_dtl_wt_reps(arg1: _formatDouble(s.weight), arg2: s.reps.toString());
                        }

                        return Card(
                          elevation: isPR ? 4 : 0, 
                          shadowColor: Colors.black.withValues(alpha: 0.1),
                          color: isPR ? gymColors.goldRank.withValues(alpha: 0.1) : colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isPR ? gymColors.goldRank.withValues(alpha: 0.4) : colorScheme.outlineVariant.withValues(alpha: 0.15))
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center, 
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        String setTypeLabel = "${setIdx + 1}";
                                        Color setTypeTextColor = colorScheme.onSurfaceVariant;
                                        Color setTypeBgColor = Colors.transparent;

                                        switch (s.type) {
                                          case SetType.WARMUP:
                                            setTypeLabel = "W";
                                            setTypeTextColor = Theme.of(context).gymColors.warning;
                                            setTypeBgColor = Theme.of(context).gymColors.warning.withValues(alpha: 0.2);
                                            break;
                                          case SetType.DROPSET:
                                            setTypeLabel = "D";
                                            setTypeTextColor = Theme.of(context).gymColors.accentPurple;
                                            setTypeBgColor = Theme.of(context).gymColors.accentPurple.withValues(alpha: 0.2);
                                            break;
                                          case SetType.FAILURE:
                                            setTypeLabel = "F";
                                            setTypeTextColor = colorScheme.error;
                                            setTypeBgColor = colorScheme.error.withValues(alpha: 0.2);
                                            break;
                                          case SetType.SUPERSET:
                                          case SetType.NORMAL:
                                            setTypeLabel = "${setIdx + 1}";
                                            setTypeTextColor = colorScheme.onSurface;
                                            setTypeBgColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
                                            break;
                                        }

                                        return Container(
                                          width: 32,
                                          height: 32,
                                          margin: const EdgeInsets.only(right: 16),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: setTypeBgColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            setTypeLabel,
                                            style: TextStyle(
                                              color: setTypeTextColor, 
                                              fontSize: 14, 
                                              fontWeight: FontWeight.bold
                                            )
                                          ),
                                        );
                                      }
                                    ),
                                    Expanded(
                                      child: Text(detailsString, style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontSize: 16)) 
                                    ),
                                  ],
                                ),
                                if (isPR) ...[
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 48), 
                                    child: Wrap(
                                      spacing: 8, 
                                      runSpacing: 8, 
                                      children: setPRs.map((metric) => _buildBadge(metric, gymColors.goldRank)).toList(),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ).animate(delay: (setIdx * 100).ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0); 
                      })
                    ],
                  ),
                ).animate(delay: (200 + (exIndex * 100)).ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);
              })
            ],
          );

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1200, maxHeight: constraints.maxHeight), 
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SafeArea(
                    child: isDesktop 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 1, 
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(24, 24, 32, 60),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    headerSection,
                                    const SizedBox(height: 32),
                                    Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1),
                                    const SizedBox(height: 32),
                                    muscleSection,
                                  ],
                                ),
                              ),
                            ),
                            Container(width: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(vertical: 24)),
                            Expanded(
                              flex: 1,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(32, 24, 24, 60),
                                child: exercisesSection,
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 60),
                          children: [
                            headerSection,
                            const SizedBox(height: 32),
                            Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1),
                            const SizedBox(height: 32),
                            muscleSection,
                            const SizedBox(height: 32),
                            Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1),
                            const SizedBox(height: 32),
                            exercisesSection,
                          ],
                        ),
                  ),


                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildBadge(ExerciseMetric metric, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Symbols.trophy, color: color, size: 12, fill: 1.0),
          const SizedBox(width: 4),
          Text(
            metric.shortBadgeString, 
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w900, letterSpacing: 0.2) 
          ),
        ],
      ),
    );
  }
}

class _DetailSummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? highlightColor;

  const _DetailSummaryItem({
    required this.icon, 
    required this.label, 
    required this.value, 
    this.highlightColor
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Tách riêng logic màu cho Value và cho nhóm Label/Icon
    final valueColor = highlightColor ?? colorScheme.onSurface;
    final labelAndIconColor = highlightColor ?? colorScheme.onSurfaceVariant;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            // Áp dụng màu cho Icon
            Icon(
              icon, 
              size: 16, 
              color: labelAndIconColor,
              fill: highlightColor != null ? 1.0 : 0.0, // (Tuỳ chọn) Fill icon nếu đang dùng Material Symbols
            ),
            const SizedBox(width: 8),
            Expanded(
              // Áp dụng màu cho Label
              child: Text(
                label, 
                style: TextStyle(
                  fontSize: 12, 
                  color: labelAndIconColor, 
                  fontWeight: FontWeight.w500
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Màu Value giữ nguyên logic ban đầu
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 18, 
            color: valueColor
          ),
        ), 
      ],
    );
  }
}