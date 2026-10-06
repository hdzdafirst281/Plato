import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_shimmer.dart';

import '../../../../core/database/enums.dart';
import 'dart:math' as math;
import '../../data/models/workout_models.dart';
import '../bloc/workout_cubit.dart';
import '../../domain/training_load_manager.dart'; 
import '../../../profile/presentation/bloc/profile_cubit.dart';
import '../../../profile/presentation/components/bodymap/body_map_geometry.dart';
import '../../../profile/presentation/components/bodymap/body_map_repository.dart';
import '../../../profile/presentation/components/bodymap/body_map_painter.dart';

class SessionSummaryScreen extends StatefulWidget {
  final String? workoutId; 

  const SessionSummaryScreen({super.key, this.workoutId});

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> with TickerProviderStateMixin {
  final bool debugForceLoading = false; // TODO(Debug): Đổi thành false khi build Production
  
  double? _rpeValue;
  WorkoutSession? _targetSession;
  
  // Biến cờ để khóa animation nặng cho đến khi trang chuyển xong
  bool _isRouteTransitionCompleted = false;
  bool _allowPop = false;
  
  // FIX DEBUG: Đổi thành nullable Future thay vì `late final` để tránh lỗi LateInitializationError
  // khi FutureBuilder cố truy cập trước lúc Route Animation hoàn tất.
  Future<LoadAnalysis>? _loadAnalysisFuture;
  late final AnimationController _lottieController;

  LottieComposition? _confettiComposition;
  bool _isLottieReady = false;

  @override
  void initState() {
    super.initState();
    
    _preloadLottieComposition();
    _lottieController = AnimationController(vsync: this);

    // 1. FAST-PATH: Cố gắng chộp lấy Session ngay lập tức từ State hiện tại (Nếu DB chạy đủ nhanh)
    _findSession(context.read<WorkoutCubit>().state);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ModalRoute.of(context)?.animation?.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _isRouteTransitionCompleted = true;
          });

          if (_isLottieReady && _targetSession != null) {
            _lottieController.forward(from: 0.0);
          }
        }
      });
    });
  }

  // [THÊM MỚI]: Tách logic tìm Session để tái sử dụng
  void _findSession(WorkoutState state) {
    if (_targetSession != null) return; // Đã tìm thấy thì bỏ qua để không setState vô ích

    WorkoutSession? foundSession;
    if (widget.workoutId != null) {
      foundSession = state.historicalWorkoutSessionsList.where((s) => s.id == widget.workoutId).firstOrNull;
    }
    
    if (foundSession == null && state.historicalWorkoutSessionsList.isNotEmpty) {
      foundSession = state.historicalWorkoutSessionsList.reduce((a, b) => a.startTime > b.startTime ? a : b);
    }

    if (foundSession != null && mounted) {
      setState(() {
        _targetSession = foundSession;
        final dbRpe = foundSession!.rpe?.toDouble() ?? 5.0;
        _rpeValue = (dbRpe < 1.0 || dbRpe > 10.0) ? 5.0 : dbRpe;
        
        // Chỉ kích hoạt phân tích Background khi chắc chắn đã có Session
        _loadAnalysisFuture = context.read<WorkoutCubit>().getWeeklyLoadAnalysis();
      });
    }
  }

  // Hàm giải nén file Lottie ra khỏi Main Thread Rendering
  Future<void> _preloadLottieComposition() async {
    try {
      final assetData = await rootBundle.load('assets/lottie/confetti.json');
      final composition = await LottieComposition.fromByteData(assetData);
      
      if (mounted) {
        setState(() {
          _confettiComposition = composition;
          _isLottieReady = true;
        });
        
        // Đồng bộ thời lượng ngay khi parse xong
        _lottieController.duration = composition.duration;
        
        // Nếu màn hình đã chuyển xong trước khi Lottie kịp load xong, chạy luôn
        if (_isRouteTransitionCompleted) {
          _lottieController.forward(from: 0.0);
        }
      }
    } catch (e) {
      debugPrint("Lỗi load Lottie: $e");
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  } 

  void _handleGoHome() {
    if (_targetSession != null && _targetSession!.id.isNotEmpty) {
      context.read<WorkoutCubit>().updateSessionRpe(
        _targetSession!.id, 
        (_rpeValue ?? 5.0).clamp(1.0, 10.0).toInt()
      );
    }
    
    // Lưu lại router trước khi các widget có thể bị unmount
    final router = GoRouter.of(context);
    
    // [FIX 1]: Mở khóa PopScope để tránh lỗi khóa cứng (Locked)
    setState(() => _allowPop = true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // [FIX 2]: Chủ động gỡ màn hình này khỏi nhánh Profile (Calendar)
      if (router.canPop()) {
        router.pop();
      }
      
      // [FIX 3]: Trì hoãn luồng chuyển Tab để tránh xung đột "Future already completed"
      // Thời gian 150ms đủ để hệ thống ổn định trạng thái trước khi nhảy sang Tab Workout
      Future.delayed(const Duration(milliseconds: 150), () {
        router.go('/workout');
      });
    });
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    // Luôn format phút và giây cố định 2 chữ số (MM:SS)
    final formattedMS = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    // Nếu có giờ thì nối thêm giờ, nếu không thì giữ nguyên định dạng MM:SS
    return h > 0 ? '$h:$formattedMS' : formattedMS;
  }

  Color _getRpeColor(BuildContext context, int? rpe) {
    final colorScheme = Theme.of(context).colorScheme;
    final gymColors = Theme.of(context).gymColors;

    if (rpe == null) return colorScheme.primary; 
    if (rpe <= 4) return gymColors.success; 
    if (rpe <= 7) return gymColors.warning; 
    
    return colorScheme.error; 
  }

  (Color, String) _getZoneInfo(LoadZone zone, ColorScheme colorScheme) {
    switch (zone) {
      case LoadZone.UNDERTRAINING: return (colorScheme.onSurfaceVariant, t.workout.lbl_ssn_sum_zone_under);
      case LoadZone.OPTIMAL: return (Theme.of(context).gymColors.success, t.workout.lbl_ssn_sum_zone_optimal);
      case LoadZone.OVERREACHING: return (Theme.of(context).gymColors.warning, t.workout.lbl_ssn_sum_zone_overreach);
      case LoadZone.OVERTRAINING: return (colorScheme.error, t.workout.lbl_ssn_sum_zone_overtrain);
    }
  }

  String _getAdvice(LoadZone zone) {
    switch (zone) {
      case LoadZone.UNDERTRAINING: return t.workout.msg_load_manager_undertraining(arg1: '');
      case LoadZone.OPTIMAL: return t.workout.msg_load_manager_optimal;
      case LoadZone.OVERREACHING: return t.workout.msg_load_manager_overreaching;
      case LoadZone.OVERTRAINING: return t.workout.msg_load_manager_overtraining;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 2. SLOW-PATH: Lắng nghe Stream của SQLite. Nếu DB lưu chậm, BlocConsumer sẽ tự động cập nhật UI ngay khi xong.
    return BlocConsumer<WorkoutCubit, WorkoutState>(
      listener: (context, state) {
        _findSession(state);
      },
      builder: (context, state) {
        final bottomNav = SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Symbols.home, fill: 1.0),
                          label: Text(t.workout.btn_ssn_sum_home, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary, 
                            foregroundColor: colorScheme.onPrimary, 
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _targetSession == null ? null : _handleGoHome,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: const Icon(Symbols.share, fill: 1.0),
                          color: colorScheme.onSurface,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        if (_targetSession == null || debugForceLoading) {
          return Scaffold(
            extendBody: true,
            backgroundColor: colorScheme.surface,
            bottomNavigationBar: bottomNav,
            body: const _SessionSummaryShimmer(),
          );
        }

        final safeDuration = _targetSession!.totalDurationSeconds;
        final safeVolume = (_targetSession!.totalVolume.isNaN) ? 0.0 : _targetSession!.totalVolume;
        final safeXp = _targetSession!.xpEarned;
        
        final rawName = _targetSession!.name;
        final sessionName = rawName.isEmpty 
            ? t.workout.title_new_workout 
            : t.translateDynamic(rawName); 
            
        final currentRpe = _rpeValue ?? 5.0;

        final isTablet = MediaQuery.of(context).size.width >= 800;

        return PopScope(
          canPop: _allowPop, 
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return; 
            _handleGoHome();
          },
          child: Scaffold(
            extendBody: true,
            backgroundColor: colorScheme.surface,
            bottomNavigationBar: isTablet ? null : bottomNav,
            body: Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet = constraints.maxWidth >= 800;
                        
                        final headerRow = Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(t.workout.title_ssn_sum_complete, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 24)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                sessionName, 
                                textAlign: TextAlign.right, 
                                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                        
                        final heatmapCard = _buildHeatmapAndStatsCard(
                          context,
                          colorScheme,
                          safeDuration: safeDuration,
                          safeVolume: safeVolume,
                          safeXp: safeXp,
                          session: _targetSession!,
                        );
                        
                        final rpeCard = _buildRpeCard(colorScheme, currentRpe);
                        
                        final acwrCard = FutureBuilder<LoadAnalysis>(
                          future: _loadAnalysisFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                              return _buildAcwrCard(colorScheme, snapshot.data!);
                            }
                            return const SizedBox.shrink(); 
                          },
                        );

                        if (isTablet) {
                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: ListView(
                                    padding: const EdgeInsets.only(left: 24, right: 12, top: 32, bottom: 32),
                                    children: [
                                      headerRow,
                                      const SizedBox(height: 24),
                                      AnimatedOpacity(
                                        opacity: _isRouteTransitionCompleted ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: heatmapCard,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Stack(
                                    children: [
                                      ListView(
                                        padding: const EdgeInsets.only(left: 12, right: 24, top: 32, bottom: 120),
                                        children: [
                                          AnimatedOpacity(
                                            opacity: _isRouteTransitionCompleted ? 1.0 : 0.0,
                                            duration: const Duration(milliseconds: 300),
                                            child: Column(
                                              children: [
                                                rpeCard,
                                                const SizedBox(height: 24),
                                                acwrCard,
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: bottomNav,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: ListView(
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 120),
                            children: [
                              headerRow,
                              const SizedBox(height: 24),
                              AnimatedOpacity(
                                opacity: _isRouteTransitionCompleted ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: Column(
                                  children: [
                                    heatmapCard,
                                    const SizedBox(height: 32),
                                    rpeCard,
                                    const SizedBox(height: 24),
                                    acwrCard,
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }
                    ),
                  ),
                ),
                
                if (_isRouteTransitionCompleted && _isLottieReady && _confettiComposition != null)
                  IgnorePointer(
                    child: SizedBox.expand(
                      child: Lottie(
                        composition: _confettiComposition,
                        controller: _lottieController,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildRpeCard(ColorScheme colorScheme, double currentRpe) {
    return Card(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(t.workout.title_ssn_sum_rpe_card, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: _getRpeColor(context, currentRpe.toInt()).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text("${currentRpe.toInt()}/10", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _getRpeColor(context, currentRpe.toInt()))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    final dx = details.localPosition.dx;
                    final width = constraints.maxWidth;
                    int newValue = ((dx / width) * 10).ceil().clamp(1, 10);
                    setState(() => _rpeValue = newValue.toDouble());
                  },
                  onPanEnd: (details) {
                    if (_targetSession != null) {
                      context.read<WorkoutCubit>().updateSessionRpe(_targetSession!.id, _rpeValue!.toInt());
                    }
                  },
                  onTapDown: (details) {
                    final dx = details.localPosition.dx;
                    final width = constraints.maxWidth;
                    int newValue = ((dx / width) * 10).ceil().clamp(1, 10);
                    setState(() => _rpeValue = newValue.toDouble());
                    if (_targetSession != null) {
                      context.read<WorkoutCubit>().updateSessionRpe(_targetSession!.id, newValue);
                    }
                  },
                  child: Row(
                    children: List.generate(10, (index) {
                      final value = index + 1;
                      final isActive = value <= currentRpe;
                      return Expanded(
                        child: Container(
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isActive ? _getRpeColor(context, value) : colorScheme.outlineVariant.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.workout.lbl_ssn_sum_rpe_min, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
                Text(t.workout.lbl_ssn_sum_rpe_max, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAcwrCard(ColorScheme colorScheme, LoadAnalysis analysis) {
    double safeRatio = analysis.ratio.isNaN || analysis.ratio.isInfinite ? 0.0 : analysis.ratio;
    int safeAcute = analysis.acuteLoad.isNaN ? 0 : analysis.acuteLoad.toInt();
    int safeChronic = analysis.chronicLoad.isNaN ? 0 : analysis.chronicLoad.toInt();
    
    final zoneInfo = _getZoneInfo(analysis.zone, colorScheme);

    return Card(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.workout.title_ssn_sum_acwr_card, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            
            RepaintBoundary(
              child: Container(
                width: double.infinity, height: 16,
                decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: safeRatio),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, ratioValue, child) {
                    double validWidth = ratioValue.isNaN ? 0.0 : (ratioValue / 2.0).clamp(0.0, 1.0);
                    return FractionallySizedBox(
                      widthFactor: validWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(colors: [Colors.lightBlue, Theme.of(context).gymColors.success, Theme.of(context).gymColors.warning, Colors.red]),
                        ),
                      ),
                    );
                  }
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.workout.fmt_ssn_sum_acwr_ratio(arg1: safeRatio.toStringAsFixed(2)), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(t.workout.fmt_ssn_sum_acwr_stats(arg1: safeAcute.toString(), arg2: safeChronic.toString()), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: zoneInfo.$1.withValues(alpha: 0.15), 
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: zoneInfo.$1)
                  ),
                  child: Text(zoneInfo.$2, style: TextStyle(color: zoneInfo.$1, fontWeight: FontWeight.w900, fontSize: 13)),
                )
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Symbols.tips_and_updates, color: colorScheme.primary, size: 20, fill: 1.0),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.workout.lbl_ssn_sum_advice_title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.primary)),
                      const SizedBox(height: 4),
                      Text(_getAdvice(analysis.zone), style: TextStyle(fontSize: 14, height: 1.5, color: colorScheme.onSurface)),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
  Widget _buildHeatmapAndStatsCard(
    BuildContext context, 
    ColorScheme colorScheme, {
    required int safeDuration,
    required double safeVolume,
    required int safeXp,
    required WorkoutSession session,
  }) {
    final gender = context.read<ProfileCubit>().state.userProfile.gender;
    
    final Map<MuscleGroup, double> muscleScores = {};
    for (var workoutEx in session.exercises) {
      int completedSets = workoutEx.sets.where((s) => s.isCompleted).length;
      if (completedSets == 0) continue;

      final primary = workoutEx.exercise.primaryMuscle;
      if (primary != null) {
        muscleScores[primary] = (muscleScores[primary] ?? 0) + completedSets;
      }

      final secondaries = workoutEx.exercise.secondaryMuscles ?? [];
      for (var secondary in secondaries) {
        muscleScores[secondary] = (muscleScores[secondary] ?? 0) + (completedSets * 0.5);
      }
    }

    final Map<MuscleGroup, double> intensityStats = {};
    for (var entry in muscleScores.entries) {
      final score = entry.value;
      if (score >= 6) {
        intensityStats[entry.key] = 0.7; // High
      } else if (score >= 3) {
        intensityStats[entry.key] = 0.4; // Medium
      } else {
        intensityStats[entry.key] = 0.2; // Low
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.stats.title_card_body_heatmap, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 130,
                height: 240,
                child: _StaticBodymap(gender: gender, front: true, muscleIntensities: intensityStats),
              ),
              SizedBox(
                width: 130,
                height: 240,
                child: _StaticBodymap(gender: gender, front: false, muscleIntensities: intensityStats),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildLegendItem(context, Theme.of(context).gymColors.heatmapUnused, t.stats.lbl_heatmap_legend_unused),
                _buildLegendItem(context, Theme.of(context).gymColors.heatmapLow, t.stats.lbl_heatmap_legend_low),
                _buildLegendItem(context, Theme.of(context).gymColors.heatmapMed, t.stats.lbl_heatmap_legend_medium),
                _buildLegendItem(context, Theme.of(context).gymColors.heatmapHigh, t.stats.lbl_heatmap_legend_high),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildStatItem(label: t.profile.btn_menu_exercises, value: session.exercises.length.toString(), colorScheme: colorScheme)),
                VerticalDivider(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1, thickness: 1),
                Expanded(child: _buildStatItem(label: t.common.time, value: _formatDuration(safeDuration), colorScheme: colorScheme)),
                VerticalDivider(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1, thickness: 1),
                Expanded(child: _buildStatItem(label: t.workout.lbl_ssn_sum_stat_xp, value: "+$safeXp", highlight: true, colorScheme: colorScheme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({required String label, required String value, required ColorScheme colorScheme, bool highlight = false}) {
    final color = highlight ? Theme.of(context).gymColors.goldRank : colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: highlight ? Theme.of(context).gymColors.goldRank : colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
      ],
    );
  }
}

class _StaticBodymap extends StatefulWidget {
  final Gender gender;
  final bool front;
  final Map<MuscleGroup, double> muscleIntensities;

  const _StaticBodymap({
    required this.gender,
    required this.front,
    required this.muscleIntensities,
  });

  @override
  State<_StaticBodymap> createState() => _StaticBodymapState();
}

class _StaticBodymapState extends State<_StaticBodymap> {
  late BodyMapGeometry _geometry;
  late List<MuscleRenderData> _muscles;

  @override
  void initState() {
    super.initState();
    _loadGeometry();
  }

  void _loadGeometry() {
    _geometry = BodyMapRepository.resolve(widget.gender, front: widget.front);
    _muscles = _geometry.muscles.entries
        .map((e) => MuscleRenderData(e.key, e.value, e.value.getBounds()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints.maxWidth;
        final canvasHeight = constraints.maxHeight;

        final scaleX = canvasWidth / BodyMapGeometry.viewport.width;
        final scaleY = canvasHeight / BodyMapGeometry.viewport.height;
        final finalDrawScale = math.min(scaleX, scaleY);

        const targetBounds = BodyMapGeometry.viewport;
        final canvasTranslateX = (canvasWidth / 2) - (targetBounds.center.dx * finalDrawScale);
        final canvasTranslateY = (canvasHeight / 2) - (targetBounds.center.dy * finalDrawScale);

        return CustomPaint(
          painter: BodyMapPainter(
            borderPath: _geometry.border,
            hairBack: _geometry.hairBack,
            hairFront: _geometry.hairFront,
            skinPath: _geometry.skin,
            muscles: _muscles,
            intensities: widget.muscleIntensities,
            mode: HeatmapMode.INTENSITY,
            selected: null,
            colorScheme: Theme.of(context).colorScheme,
            gymColors: Theme.of(context).gymColors,
            scale: finalDrawScale,
            dx: canvasTranslateX,
            dy: canvasTranslateY,
            animationProgress: 1.0,
          ),
          size: Size.infinite,
        );
      }
    );
  }
}

class _SessionSummaryShimmer extends StatelessWidget {
  const _SessionSummaryShimmer();

  @override
  Widget build(BuildContext context) {
    return GymShimmer(
      child: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 120),
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               GymShimmerBlock(width: 150, height: 32, borderRadius: 8),
               GymShimmerBlock(width: 100, height: 20, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: GymShimmerBlock(height: 80, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: GymShimmerBlock(height: 80, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: GymShimmerBlock(height: 80, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 32),
          const GymShimmerBlock(height: 180, borderRadius: 20),
          const SizedBox(height: 24),
          const GymShimmerBlock(height: 220, borderRadius: 20),
        ],
      ),
    );
  }
}