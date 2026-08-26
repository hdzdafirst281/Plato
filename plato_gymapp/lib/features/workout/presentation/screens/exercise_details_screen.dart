import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/utils/search_utils.dart';
import 'package:plato_gymapp/features/workout/presentation/bloc/exercise_library_cubit.dart';

import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/database/entities.dart';

import '../../data/models/workout_models.dart';
import '../bloc/workout_cubit.dart';

import '../../domain/workout_extensions.dart';
import 'create_custom_exercise_screen.dart'; 
import 'package:intl/intl.dart';

class ExerciseDetailsScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailsScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailsScreen> createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Exercise _currentExercise; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentExercise = widget.exercise; 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmDialog() async {
    final confirmed = await GymDialog.showDestructive(
      context: context,
      title: t.common.title_delete_dialog_main,
      message: t.explore.msg_delete_custom_exercise_warning,
      cancelText: t.common.cancel,
      confirmText: t.common.delete,
    );

    if (confirmed == true && mounted) {
      context.read<ExerciseLibraryCubit>().deleteCustomExercise(_currentExercise.id);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final history = context.watch<WorkoutCubit>().state.historicalWorkoutSessionsList;
    final filteredHistory = history.where((s) => s.exercises.any((e) => e.exercise.name == _currentExercise.name)).toList();
    filteredHistory.sort((a, b) => b.startTime.compareTo(a.startTime)); 

    final exName = _currentExercise.isCustom ? _currentExercise.name : (t.translateDynamic(_currentExercise.name));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: exName, 
        onBackClick: () => context.pop(),
        actions: _currentExercise.isCustom 
          ? [
              PopupMenuButton<String>(
                icon: Icon(Symbols.more_vert, color: colorScheme.primary),
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                ),
                elevation: 4,
                onSelected: (val) async {
                  if (val == 'edit') {
                    final updatedExercise = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => CreateCustomExerciseScreen(exerciseToEdit: _currentExercise))
                    );
                    
                    if (updatedExercise != null && updatedExercise is Exercise) {
                      setState(() {
                        _currentExercise = updatedExercise;
                      });
                    }
                  } else if (val == 'delete') {
                    _showDeleteConfirmDialog();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(Symbols.edit, color: colorScheme.onSurface), const SizedBox(width: 8), Text(t.common.edit)])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Symbols.delete, color: colorScheme.error), const SizedBox(width: 8), Text(t.common.delete, style: TextStyle(color: colorScheme.error))])),
                ],
              )
            ]
          : [],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
            tabs: [
              Tab(text: t.explore.tab_exercise_detail_overview),
              Tab(text: t.explore.tab_exercise_detail_progress), 
              Tab(text: t.rank.tab_history),
            ],
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000), 
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(exercise: _currentExercise), 
                    _ProgressTab(key: ValueKey(_currentExercise), exercise: _currentExercise, history: filteredHistory), 
                    _HistoryTab(exercise: _currentExercise, history: filteredHistory), 
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ======================= TAB 1: TỔNG QUAN =======================
class _OverviewTab extends StatelessWidget {
  final Exercise exercise;

  const _OverviewTab({required this.exercise});

  // 🚀 FALLBACK 3: Hiển thị Text khi không có ảnh nào khả dụng
  Widget _buildNoImageFallback(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Symbols.image_not_supported, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 64),
        const SizedBox(height: 16), 
        Text(t.explore.msg_exercise_detail_no_image, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 🚀 FALLBACK 2: Ảnh tĩnh (Trường image)
  Widget _buildStaticImageFallback(ColorScheme colorScheme) {
    if (exercise.image != null && exercise.image!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          exercise.image!,
          fit: BoxFit.contain, // Giữ tỷ lệ, không làm méo hoặc cắt ảnh
          errorBuilder: (_, _, _) => _buildNoImageFallback(colorScheme), // Lỗi đọc file -> Về Fallback 3
        ),
      );
    }
    return _buildNoImageFallback(colorScheme);
  }

  // 🚀 FALLBACK 1: Video/GIF hướng dẫn (Trường url_instructions)
  Widget _buildInstructionFallback(ColorScheme colorScheme) {
    if (exercise.instructionVideoUrl != null && exercise.instructionVideoUrl!.trim().isNotEmpty) {
      final path = exercise.instructionVideoUrl!.startsWith('assets/') 
          ? exercise.instructionVideoUrl! 
          : 'assets/gifs/${exercise.instructionVideoUrl!}';
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          path,
          fit: BoxFit.contain, 
          errorBuilder: (_, _, _) => _buildStaticImageFallback(colorScheme) // Lỗi đọc file/GIF -> Về Fallback 2
        )
      );
    }
    return _buildStaticImageFallback(colorScheme);
  }

  // 🚀 LUỒNG CHÍNH ĐIỀU HƯỚNG ẢNH
  Widget _buildImageWidget(ColorScheme colorScheme) {
    // Ưu tiên cao nhất: Ảnh do người dùng tự upload (nếu là bài tập Custom)
    if (exercise.isCustom && exercise.localImagePath != null && exercise.localImagePath!.trim().isNotEmpty) {
      final file = File(exercise.localImagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            file, 
            fit: BoxFit.cover, // Ảnh custom thì dùng cover cho đẹp khung
            errorBuilder: (_, _, _) => _buildInstructionFallback(colorScheme) // Lỗi file -> Về luồng chuẩn
          )
        );
      }
    } 
    // Nếu không có custom image hoặc file không tồn tại -> bắt đầu luồng fallback chuẩn
    return _buildInstructionFallback(colorScheme);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String instructionText = t.explore.msg_exercise_detail_no_instructions;
    if (exercise.instructions?.isNotEmpty == true) {
      instructionText = exercise.isCustom ? exercise.instructions! : (t.translateDynamic(exercise.instructions!));
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24), 
      children: [
        Container(
          height: 240, width: double.infinity,
          decoration: BoxDecoration(
            color: const ui.Color(0xFFFFFFFF), 
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 3), blurRadius: 8)],
          ),
          alignment: Alignment.center,
          child: _buildImageWidget(colorScheme),
        ),
        
        const SizedBox(height: 24),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            if (exercise.primaryMuscle != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                child: Text(exercise.primaryMuscle!.getLocalizedName(), style: TextStyle(color: colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 8),
            if (exercise.secondaryMuscles != null && exercise.secondaryMuscles!.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: exercise.secondaryMuscles!.map((m) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                        child: Text(m.getLocalizedName(), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 32),

        Text(t.explore.title_exercise_detail_instructions, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        const SizedBox(height: 16),
        Text(instructionText, style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.6, fontSize: 15)),
        
        if (exercise.userNote != null && exercise.userNote!.trim().isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(
            t.workout.title_my_notes,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)
          ),
          const SizedBox(height: 16),
          Text(
            exercise.userNote!, 
            style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.6, fontSize: 15)
          ),
        ],

        const SizedBox(height: 48), 
      ],
    );
  }
}

// ======================= TAB 2: TIẾN ĐỘ =======================
class _LocalChartPoint {
  final int timestamp;
  final double value;
  _LocalChartPoint(this.timestamp, this.value);
}

class _ProgressTab extends StatefulWidget {
  final Exercise exercise;
  final List<WorkoutSession> history;

  const _ProgressTab({super.key, required this.exercise, required this.history});

  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  ChartTimeRange _timeRange = ChartTimeRange.THREE_MONTHS;
  late ExerciseMetric _selectedMetric;
  int _highlightIndex = -1;

  @override
  void initState() {
    super.initState();
    _selectedMetric = _getAvailableMetrics(widget.exercise.type).first;
  }

  List<ExerciseMetric> _getAvailableMetrics(ExerciseType type) {
    switch (type) {
      case ExerciseType.WEIGHT_REPS: 
        return [ExerciseMetric.BEST_WEIGHT, ExerciseMetric.ONE_RM, ExerciseMetric.BEST_SET_VOL, ExerciseMetric.SESSION_VOL];
      case ExerciseType.TIME_ONLY: 
        return [ExerciseMetric.BEST_TIME, ExerciseMetric.SESSION_TIME];
      case ExerciseType.CARDIO_DISTANCE: 
        return [ExerciseMetric.LONGEST_DISTANCE, ExerciseMetric.BEST_TIME, ExerciseMetric.PACE];
      case ExerciseType.CARDIO_STEPS: 
        return [ExerciseMetric.BEST_STEPS, ExerciseMetric.BEST_TIME];
      case ExerciseType.REPS_ONLY: 
        return [ExerciseMetric.BEST_REPS, ExerciseMetric.SESSION_REPS];
    }
  }

  String _getMetricLabel(ExerciseMetric metric) {
    switch (metric) {
      case ExerciseMetric.BEST_WEIGHT: return t.stats.label_model_metric_best_weight;
      case ExerciseMetric.BEST_TIME: return t.stats.label_model_metric_best_time;
      case ExerciseMetric.LONGEST_DISTANCE: return t.stats.label_model_metric_longest_distance;
      case ExerciseMetric.BEST_STEPS: return t.stats.label_model_metric_best_steps;
      case ExerciseMetric.BEST_REPS: return t.stats.label_model_metric_best_reps;
      case ExerciseMetric.ONE_RM: return t.stats.label_model_metric_one_rm;
      case ExerciseMetric.BEST_SET_VOL: return t.stats.label_model_metric_best_set_vol;
      case ExerciseMetric.SESSION_VOL: return t.stats.label_model_metric_session_vol;
      case ExerciseMetric.SESSION_REPS: return t.stats.label_model_metric_session_reps;
      case ExerciseMetric.SESSION_TIME: return t.stats.label_model_metric_session_time;
      case ExerciseMetric.PACE: return t.stats.label_model_metric_pace;
    }
  }

  String _getMetricUnit(ExerciseMetric metric) {
    switch (metric) {
      case ExerciseMetric.BEST_WEIGHT: 
      case ExerciseMetric.ONE_RM:
      case ExerciseMetric.BEST_SET_VOL:
      case ExerciseMetric.SESSION_VOL: return 'kg';
      case ExerciseMetric.LONGEST_DISTANCE: return 'km';
      case ExerciseMetric.BEST_STEPS: return 'steps';
      case ExerciseMetric.BEST_REPS:
      case ExerciseMetric.SESSION_REPS: return 'reps';
      case ExerciseMetric.PACE: return 'km/h';
      default: return '';
    }
  }

  String _getTimeRangeLabel(ChartTimeRange range) {
    if (range == ChartTimeRange.THREE_MONTHS) return t.stats.label_time_range_3_months;
    if (range == ChartTimeRange.YEAR) return t.stats.label_time_range_year; 
    return t.stats.label_time_range_all;
  }

  List<_LocalChartPoint> _getAggregatedData() {
    final limitMillis = _timeRange == ChartTimeRange.ALL_TIME 
        ? 0 
        : DateTime.now().subtract(Duration(days: _timeRange.days)).millisecondsSinceEpoch;
    
    final validSessions = widget.history.where((s) => s.startTime >= limitMillis).toList();
    final groupedData = <DateTime, double>{};

    bool isSumMetric = _selectedMetric == ExerciseMetric.SESSION_VOL || 
                       _selectedMetric == ExerciseMetric.SESSION_REPS || 
                       _selectedMetric == ExerciseMetric.SESSION_TIME;

    for (var s in validSessions) {
      final date = DateTime.fromMillisecondsSinceEpoch(s.startTime);
      DateTime key = _timeRange == ChartTimeRange.THREE_MONTHS 
          ? DateTime(date.year, date.month, date.day) 
          : DateTime(date.year, date.month);
      
      final ex = s.exercises.firstWhere((e) => e.exercise.name == widget.exercise.name);
      final val = ex.getMetricValue(_selectedMetric);

      if (val > 0) {
        if (!groupedData.containsKey(key)) {
          groupedData[key] = val; 
        } else {
          if (isSumMetric) {
             groupedData[key] = groupedData[key]! + val;
          } else {
             if (val > groupedData[key]!) groupedData[key] = val;
          }
        }
      }
    }

    final sortedKeys = groupedData.keys.toList()..sort();
    return sortedKeys.map((k) => _LocalChartPoint(k.millisecondsSinceEpoch, groupedData[k]!)).toList();
  }

  String _formatTime(double seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toInt();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dataPoints = _getAggregatedData();
    final availableMetrics = _getAvailableMetrics(widget.exercise.type);
    final allExercises = widget.history.expand((s) => s.exercises).where((e) => e.exercise.name == widget.exercise.name);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_highlightIndex != -1) {
          setState(() => _highlightIndex = -1);
        }
      },
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: availableMetrics.map((metric) {
                final isSelected = _selectedMetric == metric;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(_getMetricLabel(metric), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      _selectedMetric = metric;
                      _highlightIndex = -1;
                    }),
                    backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    selectedColor: colorScheme.primary,
                    labelStyle: TextStyle(color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text(_getMetricLabel(_selectedMetric), style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 20))),
                
                PopupMenuButton<ChartTimeRange>(
                  initialValue: _timeRange,
                  color: colorScheme.surface,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  onSelected: (val) => setState(() {
                    _timeRange = val;
                    _highlightIndex = -1; 
                  }),
                  itemBuilder: (context) => [ChartTimeRange.THREE_MONTHS, ChartTimeRange.YEAR, ChartTimeRange.ALL_TIME].map((val) {
                    return PopupMenuItem(
                      value: val,
                      child: Text(_getTimeRangeLabel(val), style: TextStyle(color: colorScheme.onSurface, fontSize: 13, fontWeight: _timeRange == val ? FontWeight.bold : FontWeight.normal)),
                    );
                  }).toList(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getTimeRangeLabel(_timeRange), style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Symbols.keyboard_arrow_down, size: 18, color: colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          SizedBox(
            height: 260, width: double.infinity,
            child: dataPoints.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.show_chart, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(t.stats.msg_chart_no_data, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                )
              : _ExerciseLineChart(
                  dataPoints: dataPoints, 
                  unitLabel: _getMetricUnit(_selectedMetric),
                  isTimeFormat: _selectedMetric == ExerciseMetric.BEST_TIME || _selectedMetric == ExerciseMetric.SESSION_TIME,
                  timeRange: _timeRange, 
                  metric: _selectedMetric,
                  selectedIndex: _highlightIndex,
                  onSelect: (idx) => setState(() => _highlightIndex = idx),
                ),
          ),
          
          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(t.explore.title_exercise_detail_personal_records, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ),
          
          const SizedBox(height: 16),
          
          ...availableMetrics.asMap().entries.map((entry) {
            final metric = entry.value;
            final bestVal = allExercises.isEmpty ? 0.0 : allExercises.map((e) => e.getMetricValue(metric)).reduce(math.max);
            final displayVal = (metric == ExerciseMetric.BEST_TIME || metric == ExerciseMetric.SESSION_TIME) 
                  ? _formatTime(bestVal) 
                  : "${bestVal.toStringAsFixed(bestVal % 1 == 0 ? 0 : 1)} ${_getMetricUnit(metric)}";
            
            return Container(
              margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Theme.of(context).gymColors.goldRank.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Icon(Symbols.trophy, color: Theme.of(context).gymColors.goldRank, size: 24, fill: 1.0),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getMetricLabel(metric), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(displayVal, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 20)),
                      ],
                    ),
                  )
                ],
              ),
            );
          }),
          
          Container(
            margin: const EdgeInsets.only(left: 24, right: 24, bottom: 48, top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(Symbols.history, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.explore.label_exercise_detail_total_sessions, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(t.explore.format_exercise_detail_session_count(arg1: widget.history.length.toString()), style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= TAB 3: LỊCH SỬ =======================
class _HistoryTab extends StatelessWidget {
  final Exercise exercise;
  final List<WorkoutSession> history;

  const _HistoryTab({required this.exercise, required this.history});

  String _formatSetTime(int seconds) {
    if (seconds <= 0) return "-";
    final m = seconds ~/ 60;
    final sec = seconds % 60;
    if (m > 0 && sec > 0) return '${m}m ${sec}s';
    if (m > 0) return '${m}m';
    return '${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.history_toggle_off, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(t.explore.msg_exercise_detail_no_history, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        )
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final session = history[index];
        final date = DateFormat("dd MMMM, yyyy", TranslationProvider.of(context).flutterLocale.languageCode).format(DateTime.fromMillisecondsSinceEpoch(session.startTime));
        final exData = session.exercises.firstWhere((e) => e.exercise.name == exercise.name);

        return InkWell(
          onTap: () => context.pushNamed('workout_detail', pathParameters: {'workoutId': session.id}),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2), width: 1))
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Symbols.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text(date, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Symbols.chevron_right, color: colorScheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 40, child: Text(t.explore.label_set, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant))),
                          
                          if (exercise.type == ExerciseType.TIME_ONLY) ...[
                            Expanded(child: Text(t.explore.label_time, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant))),
                          ] else ...[
                            if (exercise.type != ExerciseType.REPS_ONLY) ...[
                              Expanded(child: Text(
                                exercise.type == ExerciseType.CARDIO_DISTANCE ? t.explore.label_distance_short : 
                                exercise.type == ExerciseType.CARDIO_STEPS ? t.explore.label_steps_short : t.explore.label_weight_short,
                                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)
                              )),
                            ],
                            Expanded(child: Text(
                              (exercise.type == ExerciseType.CARDIO_DISTANCE || exercise.type == ExerciseType.CARDIO_STEPS) ? t.explore.label_time : t.explore.label_reps_short,
                              textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)
                            )),
                          ]
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      ...exData.sets.asMap().entries.map((entry) {
                        final setIdx = entry.key + 1;
                        final s = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 40, 
                                child: Text('$setIdx', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurfaceVariant))
                              ),
                              
                              if (exercise.type == ExerciseType.TIME_ONLY) ...[
                                Expanded(child: Text(_formatSetTime(s.durationTimeSeconds), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface))),
                              ] else ...[
                                if (exercise.type != ExerciseType.REPS_ONLY) ...[
                                  Expanded(child: Text(
                                    exercise.type == ExerciseType.CARDIO_DISTANCE ? "${s.distanceInKm} km" : 
                                    exercise.type == ExerciseType.CARDIO_STEPS ? "${s.steps}" : 
                                    "${s.weight} kg",
                                    textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface)
                                  )),
                                ],
                                Expanded(child: Text(
                                  (exercise.type == ExerciseType.CARDIO_DISTANCE || exercise.type == ExerciseType.CARDIO_STEPS) ? _formatSetTime(s.durationTimeSeconds) : "${s.reps}",
                                  textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface)
                                )),
                              ]
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// ======================= CUSTOM LINE CHART =======================
class _ExerciseLineChart extends StatefulWidget {
  final List<_LocalChartPoint> dataPoints;
  final String unitLabel;
  final bool isTimeFormat;
  final ChartTimeRange timeRange;
  final ExerciseMetric metric;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ExerciseLineChart({
    required this.dataPoints, 
    required this.unitLabel,
    required this.isTimeFormat,
    required this.timeRange,
    required this.metric,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<_ExerciseLineChart> createState() => _ExerciseLineChartState();
}

class _ExerciseLineChartState extends State<_ExerciseLineChart> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _growthAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _growthAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant _ExerciseLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metric != widget.metric || oldWidget.timeRange != widget.timeRange) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateSelection(Offset localPosition) {
    if (widget.dataPoints.isEmpty) return;
    const padLeft = 40.0; 
    const padRight = 16.0; 
    final w = context.size!.width - padLeft - padRight; 
    
    if (localPosition.dx >= padLeft - 20 && localPosition.dx <= context.size!.width) {
      double minDistance = double.infinity;
      int closestIndex = -1;
      
      for(int i=0; i<widget.dataPoints.length; i++) {
        double cx;
        if (widget.dataPoints.length == 1) {
          cx = padLeft + w / 2;
        } else {
          cx = padLeft + (i * w / (widget.dataPoints.length - 1));
        }
        final dist = (localPosition.dx - cx).abs();
        if (dist < minDistance) {
          minDistance = dist;
          closestIndex = i;
        }
      }
      
      if (minDistance < 60) { 
        if (widget.selectedIndex != closestIndex) widget.onSelect(closestIndex);
      } else {
        if (widget.selectedIndex != -1) widget.onSelect(-1);
      }
    } else {
      if (widget.selectedIndex != -1) widget.onSelect(-1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentLangCode = TranslationProvider.of(context).flutterLocale.languageCode;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) => _updateSelection(details.localPosition),
      onHorizontalDragUpdate: (details) => _updateSelection(details.localPosition),
      onTapDown: (details) => _updateSelection(details.localPosition),
      onTap: () {}, 
      child: AnimatedBuilder(
        animation: _growthAnim,
        builder: (context, _) => CustomPaint(
          painter: _ExerciseLinePainter(
            data: widget.dataPoints,
            unitLabel: widget.unitLabel,
            isTimeFormat: widget.isTimeFormat,
            timeRange: widget.timeRange,
            selectedIndex: widget.selectedIndex,
            progress: _growthAnim.value,
            colorScheme: colorScheme,
            langCode: currentLangCode,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ExerciseLinePainter extends CustomPainter {
  final List<_LocalChartPoint> data;
  final String unitLabel;
  final bool isTimeFormat;
  final ChartTimeRange timeRange;
  final int selectedIndex;
  final double progress;
  final ColorScheme colorScheme;
  final String langCode;

  _ExerciseLinePainter({
    required this.data, 
    required this.unitLabel,
    required this.isTimeFormat,
    required this.timeRange, 
    required this.selectedIndex, 
    required this.progress, 
    required this.colorScheme, 
    required this.langCode
  });

  double _getNiceStepFor5Intervals(double maxVal) {
    if (maxVal <= 0.0) return 1.0;
    final unrounded = maxVal / 4.5;
    final order = math.pow(10.0, (math.log(unrounded) / math.ln10).floorToDouble()).toDouble();
    final norm = unrounded / order;
    
    double mult;
    if (norm < 1.5) {
      mult = 1.0;
    } else if (norm < 2.5) mult = 2.0;
    else if (norm < 4.0) mult = 2.5; 
    else if (norm < 7.5) mult = 5.0;
    else mult = 10.0;
    
    double step = mult * order;
    if (step * 5 < maxVal) {
        if (mult == 1.0) {
          step = 2.0 * order;
        } else if (mult == 2.0) step = 2.5 * order;
        else if (mult == 2.5) step = 5.0 * order;
        else if (mult == 5.0) step = 10.0 * order;
    }
    return step;
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = start.dx;
    while (startX < end.dx) {
      canvas.drawLine(Offset(startX, start.dy), Offset(math.min(startX + dashWidth, end.dx), start.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  String _formatCompact(double val) {
     if (val >= 1000) return "${(val / 1000).toStringAsFixed(1).replaceAll('.0', '')}k";
     if (val == val.truncateToDouble()) return val.toInt().toString();
     return val.toStringAsFixed(1).replaceAll('.0', '');
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    double axisMax;
    double axisStep;

    if (data.length == 1) {
      final val = data[0].value;
      axisMax = val <= 0 ? 10.0 : val * 2.0;
      axisStep = axisMax / 5.0;
    } else {
      final maxVal = data.map((e) => e.value).reduce(math.max);
      axisStep = _getNiceStepFor5Intervals(maxVal);
      axisMax = axisStep * 5;
    }

    const padLeft = 40.0; 
    const padRight = 16.0;
    const paddingTop = 20.0; 
    const paddingBottom = 30.0; 
    
    final w = size.width - padLeft - padRight;
    final h = size.height - paddingBottom; 
    final chartHeight = h - paddingTop; 

    final paintGrid = Paint()..color = colorScheme.outlineVariant..strokeWidth = 1.5;
    final paintAxis = Paint()..color = colorScheme.onSurfaceVariant..strokeWidth = 2.0;

    for (int i = 1; i <= 4; i++) {
      final val = axisStep * i;
      final y = h - ((val / axisMax) * chartHeight);
      
      _drawDashedLine(canvas, Offset(padLeft, y), Offset(size.width - padRight, y), paintGrid);

      if (progress > 0) { 
        String text;
        if (isTimeFormat) {
           final m = val ~/ 60;
           text = m > 0 ? '${m}m' : '${val.toInt()}s'; 
        } else {
           text = _formatCompact(val);
        }
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.right))
          ..pushStyle(ui.TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: progress.clamp(0.0, 1.0)), fontSize: 11))
          ..addText(text);
        final p = builder.build()..layout(const ui.ParagraphConstraints(width: padLeft - 5));
        canvas.drawParagraph(p, Offset(0, y - 6));
      }
    }

    canvas.drawLine(Offset(padLeft, paddingTop), Offset(padLeft, h), paintAxis);
    canvas.drawLine(Offset(padLeft, h), Offset(size.width - padRight, h), paintAxis);

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
       double cx;
       if (data.length == 1) {
         cx = padLeft + w / 2; 
       } else {
         cx = padLeft + (i * w / (data.length - 1)); 
       }
       double cy = h - ((data[i].value / axisMax) * chartHeight) * progress; 
       points.add(Offset(cx, cy));
    }

    final skipRate = (data.length / 6).ceil().clamp(1, 999);
    for (int i = 0; i < data.length; i++) {
      if (i % skipRate == 0) {
        final cx = points[i].dx;
        final date = DateTime.fromMillisecondsSinceEpoch(data[i].timestamp);
        String text = timeRange == ChartTimeRange.THREE_MONTHS 
           ? DateFormat("dd/MM", langCode).format(date) 
           : DateFormat("MM/yyyy", langCode).format(date);

        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(ui.TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold))
          ..addText(text);
        final p = builder.build()..layout(const ui.ParagraphConstraints(width: 80));
        canvas.drawParagraph(p, Offset(cx - 40, h + 8));
      }
    }

    if (points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, h);
      for (var p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, h);
      fillPath.close();

      final paintGradient = Paint()..shader = ui.Gradient.linear(
        Offset(0, paddingTop), Offset(0, h),
        [colorScheme.primary.withValues(alpha: 0.4), colorScheme.primary.withValues(alpha: 0.05)]
      );
      canvas.drawPath(fillPath, paintGradient);

      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      
      final paintLine = Paint()
        ..color = colorScheme.primary
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, paintLine);
    }

    if (points.isNotEmpty) {
      final paintDotSolid = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.fill;
      
      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        if (i == selectedIndex) {
          canvas.drawCircle(p, 12.0, Paint()..color = colorScheme.primary.withValues(alpha: 0.25));
          canvas.drawCircle(p, 6.0, paintDotSolid);
        } else {
          canvas.drawCircle(p, 4.0, paintDotSolid);
        }
      }
    }

    if (selectedIndex >= 0 && selectedIndex < data.length && progress > 0.99) {
      final p = points[selectedIndex];
      final val = data[selectedIndex].value;
      final date = DateTime.fromMillisecondsSinceEpoch(data[selectedIndex].timestamp);
      
      String dateStr = DateFormat("dd MMM yyyy", langCode).format(date);
      String valStr;
      
      if (isTimeFormat) {
         final m = val ~/ 60;
         final s = (val % 60).toInt();
         valStr = m > 0 ? '${m}m ${s}s' : '${s}s';
      } else {
         if (val == val.truncateToDouble()) {
             valStr = "${val.toInt()} $unitLabel";
         } else {
             valStr = "${val.toStringAsFixed(1)} $unitLabel";
         }
      }

      final textSpan = TextSpan(
        children: [
          TextSpan(text: "$dateStr\n", style: TextStyle(color: colorScheme.surface.withValues(alpha: 0.8), fontSize: 11)),
          TextSpan(text: valStr, style: TextStyle(color: colorScheme.surface, fontSize: 14, fontWeight: FontWeight.w900)),
        ]
      );
      final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center)..layout();
      
      double tooltipX = p.dx;
      final boxWidth = textPainter.width + 24;
      if (tooltipX - boxWidth / 2 < padLeft) tooltipX = padLeft + boxWidth / 2;
      if (tooltipX + boxWidth / 2 > size.width - padRight) tooltipX = size.width - padRight - boxWidth / 2;

      final tooltipBottomY = p.dy - 16; 
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX - boxWidth / 2, tooltipBottomY - textPainter.height - 12, boxWidth, textPainter.height + 12),
        const Radius.circular(8)
      );
      
      canvas.drawShadow(Path()..addRRect(boxRect), Colors.black, 4, false);
      canvas.drawRRect(boxRect, Paint()..color = colorScheme.onSurface);
      
      textPainter.paint(canvas, Offset(tooltipX - (textPainter.width / 2), tooltipBottomY - textPainter.height - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _ExerciseLinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.selectedIndex != selectedIndex || oldDelegate.timeRange != timeRange || oldDelegate.unitLabel != unitLabel || oldDelegate.data != data;
  }
}