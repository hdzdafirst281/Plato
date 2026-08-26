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
import '../../data/models/workout_models.dart';
import '../bloc/workout_cubit.dart';
import '../../domain/training_load_manager.dart'; 

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
      case LoadZone.UNDERTRAINING: return (colorScheme.onSurfaceVariant, t.workout.label_session_summary_zone_under);
      case LoadZone.OPTIMAL: return (Theme.of(context).gymColors.success, t.workout.label_session_summary_zone_optimal);
      case LoadZone.OVERREACHING: return (Theme.of(context).gymColors.warning, t.workout.label_session_summary_zone_overreach);
      case LoadZone.OVERTRAINING: return (colorScheme.error, t.workout.label_session_summary_zone_overtrain);
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
                  child: ElevatedButton.icon(
                    icon: const Icon(Symbols.home, fill: 1.0),
                    label: Text(t.workout.btn_session_summary_home, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary, 
                      foregroundColor: colorScheme.onPrimary, 
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _targetSession == null ? null : _handleGoHome,
                  ),
                ),
              ],
            ),
          ),
        );

        if (_targetSession == null || debugForceLoading) {
          return Scaffold(
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
            ? t.workout.label_session_summary_default_name 
            : t.translateDynamic(rawName); 
            
        final currentRpe = _rpeValue ?? 5.0;

        return PopScope(
          canPop: _allowPop, 
          onPopInvokedWithResult: (didPop, result) {
            // Nếu đã pop thành công (nhờ lệnh router.pop() ở trên), thoát ngay để tránh vòng lặp
            if (didPop) return; 
            
            // Nếu người dùng bấm Back vật lý, ép chạy luồng an toàn
            _handleGoHome();
          },
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            bottomNavigationBar: bottomNav,
            body: Stack(
              children: [
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                        children: [
                          _buildTrophyIcon(),
                          const SizedBox(height: 24),
                          
                          Text(t.workout.title_session_summary_complete, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 28)),
                          const SizedBox(height: 4),
                          Text(sessionName, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
                          const SizedBox(height: 40),

                          AnimatedOpacity(
                            opacity: _isRouteTransitionCompleted ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _SummaryStatCard(label: t.workout.label_session_summary_stat_time, value: _formatDuration(safeDuration))),
                                    const SizedBox(width: 12),
                                    Expanded(child: _SummaryStatCard(label: t.stats.label_metric_volume, value: t.workout.format_summary_kg(arg1: safeVolume.toInt().toString()))),
                                    const SizedBox(width: 12),
                                    Expanded(child: _SummaryStatCard(label: t.workout.label_session_summary_stat_xp, value: "+$safeXp", highlight: true, colorScheme: colorScheme)),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                _buildRpeCard(colorScheme, currentRpe),
                                const SizedBox(height: 24),

                                FutureBuilder<LoadAnalysis>(
                                  future: _loadAnalysisFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                      return _buildAcwrCard(colorScheme, snapshot.data!);
                                    }
                                    return const SizedBox.shrink(); 
                                  },
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
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

  Widget _buildTrophyIcon() {
    return Center(
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(color: Theme.of(context).gymColors.success.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: Theme.of(context).gymColors.success.withValues(alpha: 0.5), width: 4)),
        child: Icon(Symbols.trophy, color: Theme.of(context).gymColors.success, size: 56, fill: 1.0),
      ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.workout.title_session_summary_rpe_card, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(t.workout.desc_session_summary_rpe_slider, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _getRpeColor(context, currentRpe.toInt()).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text("${currentRpe.toInt()}/10", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _getRpeColor(context, currentRpe.toInt()))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              ),
              child: Slider(
                value: currentRpe.clamp(1.0, 10.0),
                min: 1, max: 10, divisions: 9,
                activeColor: _getRpeColor(context, currentRpe.toInt()),
                inactiveColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                onChanged: (v) => setState(() => _rpeValue = v),
                onChangeEnd: (v) {
                  if (_targetSession != null) {
                    context.read<WorkoutCubit>().updateSessionRpe(_targetSession!.id, v.toInt());
                  }
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.workout.label_session_summary_rpe_min, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
                Text(t.workout.label_session_summary_rpe_max, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
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
            Text(t.workout.title_session_summary_acwr_card, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                      Text(t.workout.format_session_summary_acwr_ratio(arg1: safeRatio.toStringAsFixed(2)), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(t.workout.format_session_summary_acwr_stats(arg1: safeAcute.toString(), arg2: safeChronic.toString()), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
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
                      Text(t.workout.label_session_summary_advice_title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.primary)),
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
}

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final ColorScheme? colorScheme;

  const _SummaryStatCard({required this.label, required this.value, this.highlight = false, this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final cScheme = colorScheme ?? Theme.of(context).colorScheme;
    final color = highlight ? Theme.of(context).gymColors.goldRank : cScheme.onSurface;
    final bgColor = highlight ? Theme.of(context).gymColors.goldRank.withValues(alpha: 0.15) : cScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: highlight ? Theme.of(context).gymColors.goldRank.withValues(alpha: 0.5) : cScheme.outlineVariant.withValues(alpha: 0.5))
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: highlight ? Theme.of(context).gymColors.goldRank : cScheme.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SessionSummaryShimmer extends StatelessWidget {
  const _SessionSummaryShimmer();

  @override
  Widget build(BuildContext context) {
    return GymShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        children: [
          const Center(child: GymShimmerCircle(radius: 50)),
          const SizedBox(height: 24),
          const Center(child: GymShimmerBlock(width: 250, height: 32, borderRadius: 8)),
          const SizedBox(height: 8),
          const Center(child: GymShimmerBlock(width: 150, height: 16, borderRadius: 4)),
          const SizedBox(height: 40),
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