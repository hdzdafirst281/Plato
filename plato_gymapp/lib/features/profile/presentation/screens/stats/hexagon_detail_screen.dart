import 'package:flutter/material.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

import '../../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../workout/data/models/workout_models.dart';
import '../../../domain/profile_chart_utils.dart';

class HexagonDetailScreen extends StatefulWidget {
  final List<WorkoutSession> workouts;
  final VoidCallback onBack;

  const HexagonDetailScreen({super.key, required this.workouts, required this.onBack});

  @override
  State<HexagonDetailScreen> createState() => _HexagonDetailScreenState();
}

class _HexagonDetailScreenState extends State<HexagonDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _growthAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    
    _opacityAnim = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn));
    _growthAnim = CurvedAnimation(parent: _animController, curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack));
    
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    GymDialog.showCustom(
      context: context,
      titleWidget: Row(
        children: [
          Icon(Symbols.info, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(t.common.info, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                children: [
                  TextSpan(text: t.stats.desc_hexagon_info_rank_prefix),
                  TextSpan(
                    text: 'E',
                    style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8), fontWeight: FontWeight.w900),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Symbols.keyboard_double_arrow_right, size: 16, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  TextSpan(
                    text: 'S',
                    style: TextStyle(
                      color: Theme.of(context).gymColors.goldRank, 
                      fontSize: 18, 
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      shadows: [
                        Shadow(color: Theme.of(context).gymColors.goldRank.withValues(alpha: 0.6), blurRadius: 10), 
                        Shadow(color: Theme.of(context).gymColors.goldRank.withValues(alpha: 0.3), blurRadius: 20), 
                      ]
                    ),
                  ),
                  TextSpan(text: t.stats.desc_hexagon_info_rank_suffix),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(t.common.understood, style: const TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final t30 = now - (30 * 24 * 60 * 60 * 1000);
    final t60 = now - (60 * 24 * 60 * 60 * 1000);

    final currentMonth = widget.workouts.where((w) => w.startTime >= t30).toList();
    final prevMonth = widget.workouts.where((w) => w.startTime >= t60 && w.startTime < t30).toList();

    // REFACTOR: Sử dụng mốc Dynamic Scaling
    final rawCurrent = ProfileChartUtils.calculateRawMuscleScores(currentMonth);
    final rawPrev = ProfileChartUtils.calculateRawMuscleScores(prevMonth);

    final normCurrent = rawCurrent.map((k, v) {
      final dynamicLimit = ProfileChartUtils.getHexagonMaxVolume(k);
      return MapEntry(k, (v / dynamicLimit).clamp(0.0, 1.0));
    });
    
    final normPrev = rawPrev.map((k, v) {
      final dynamicLimit = ProfileChartUtils.getHexagonMaxVolume(k);
      return MapEntry(k, (v / dynamicLimit).clamp(0.0, 1.0));
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.stats.title_hexagon_main,
        onBackClick: widget.onBack,
        actions: [
          IconButton(
            icon: Icon(Symbols.info, color: colorScheme.primary), 
            onPressed: () => _showInfoDialog(context)
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), 
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (currentMonth.isNotEmpty || prevMonth.isNotEmpty) ...[
                    AnimatedBuilder(
                      animation: _opacityAnim,
                      builder: (context, child) => Opacity(opacity: _opacityAnim.value, child: child),
                      child: Text(
                        t.stats.title_hexagon_comparison_header, 
                        style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant), 
                        textAlign: TextAlign.center
                      ),
                    ),
                    const SizedBox(height: 80),
                    
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxSize = math.min(constraints.maxWidth, 400.0);
                        
                        return SizedBox(
                          width: maxSize,
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: AnimatedBuilder(
                              animation: _animController, 
                              builder: (context, _) => CustomPaint(
                                painter: _HexagonPainter(
                                  currentStats: normCurrent,
                                  prevStats: normPrev,
                                  progress: _growthAnim.value,
                                  opacity: _opacityAnim.value, 
                                  colorScheme: colorScheme,
                                  gymColors: Theme.of(context).gymColors,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                    
                    const SizedBox(height: 88),
                    
                    AnimatedBuilder(
                      animation: _opacityAnim,
                      builder: (context, child) => Opacity(
                        opacity: _opacityAnim.value,
                        child: child,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: Theme.of(context).gymColors.fireHexagon, borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 12),
                          Text(t.stats.label_hexagon_legend_current, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 32),
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 12),
                          Text(t.stats.label_hexagon_legend_previous, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    )
                  ] else ...[
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Symbols.show_chart, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(t.stats.msg_chart_no_data, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ).animate(delay: 300.ms).fade(duration: 600.ms)
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Map<String, double> currentStats;
  final Map<String, double> prevStats;
  final double progress;
  final double opacity; 
  final ColorScheme colorScheme;
  final GymColors gymColors;

  _HexagonPainter({
    required this.currentStats, 
    required this.prevStats, 
    required this.progress, 
    required this.opacity,
    required this.colorScheme,
    required this.gymColors,
  });

  String _getRank(double value) {
    // REFACTOR: Chia đều 6 khoảng (100% / 6) để Data khớp với Grid Lines của biểu đồ
    if (value >= 5 / 6) return 'S'; // >= 83.33%
    if (value >= 4 / 6) return 'A'; // >= 66.66%
    if (value >= 3 / 6) return 'B'; // >= 50.00%
    if (value >= 2 / 6) return 'C'; // >= 33.33%
    if (value >= 1 / 6) return 'D'; // >= 16.66%
    return 'E';                     // < 16.66%
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'S': return gymColors.goldRank;
      case 'A': return colorScheme.primary;
      case 'B': return gymColors.success;
      case 'C': return gymColors.warning;
      case 'D': return colorScheme.error;
      case 'E': return colorScheme.onSurfaceVariant;
      default: return colorScheme.onSurfaceVariant;
    }
  }

  void _paintElegantLabel(Canvas canvas, Offset center, String muscleName, String rank, Color rankColor, double opacity) {
    final nameSpan = TextSpan(
      text: muscleName.toUpperCase(), 
      style: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: opacity * 0.9),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0, 
      ),
    );
    final namePainter = TextPainter(text: nameSpan, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center);
    namePainter.layout();

    final isHighRank = rank == 'S' || rank == 'A' || rank == 'B'; 
    final rankSpan = TextSpan(
      text: rank,
      style: TextStyle(
        color: rankColor.withValues(alpha: opacity),
        fontSize: 22, 
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic, 
        shadows: isHighRank ? [
          Shadow(color: rankColor.withValues(alpha: 0.6 * opacity), blurRadius: 10), 
          Shadow(color: rankColor.withValues(alpha: 0.3 * opacity), blurRadius: 20), 
        ] : [],
      ),
    );
    final rankPainter = TextPainter(text: rankSpan, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center);
    rankPainter.layout();

    final spacing = 2.0; 
    final totalHeight = namePainter.height + spacing + rankPainter.height;
    final startY = center.dy - totalHeight / 2;

    namePainter.paint(canvas, Offset(center.dx - namePainter.width / 2, startY));
    rankPainter.paint(canvas, Offset(center.dx - rankPainter.width / 2, startY + namePainter.height + spacing));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    final maxRadius = math.min(size.width, size.height) / 2 * 0.75; 
    final stepAngle = 2 * math.pi / 6;

    final paintGrid = Paint()..color = colorScheme.onSurface.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final paintAxis = Paint()..color = colorScheme.onSurface.withValues(alpha: 0.45)..style = PaintingStyle.stroke..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final a1 = i * stepAngle - math.pi / 2;
      final a2 = (i + 3) * stepAngle - math.pi / 2;
      canvas.drawLine(
        Offset(cx + maxRadius * math.cos(a1), cy + maxRadius * math.sin(a1)),
        Offset(cx + maxRadius * math.cos(a2), cy + maxRadius * math.sin(a2)), 
        paintAxis
      );
    }

    for (int l = 1; l <= 6; l++) {
      final r = maxRadius * (l / 6);
      final p = Path();
      for (int v = 0; v < 6; v++) {
        final a = v * stepAngle - math.pi / 2;
        final x = cx + r * math.cos(a);
        final y = cy + r * math.sin(a);
        if (v == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      p.close();
      canvas.drawPath(p, paintGrid);
    }

    final labels = [
      MapEntry("Chest", t.muscles.chest),
      MapEntry("Abs", t.muscles.core),
      MapEntry("Back", t.muscles.back),
      MapEntry("Legs", t.muscles.legs),
      MapEntry("Arms", t.muscles.arms),
      MapEntry("Shoulders", t.muscles.shoulders),
    ];

    Path buildPath(Map<String, double> data) {
      final p = Path();
      for (int v = 0; v < 6; v++) {
        final val = (data[labels[v].key] ?? 0.0) * progress;
        final a = v * stepAngle - math.pi / 2;
        final x = cx + maxRadius * val * math.cos(a);
        final y = cy + maxRadius * val * math.sin(a);
        if (v == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      p.close();
      return p;
    }

    final pathPrev = buildPath(prevStats);
    canvas.drawPath(pathPrev, Paint()..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.15 * progress)..style = PaintingStyle.fill);
    canvas.drawPath(pathPrev, Paint()..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.4 * progress)..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round);

    final pathCurr = buildPath(currentStats);
    canvas.drawPath(pathCurr, Paint()..color = gymColors.fireHexagon.withValues(alpha: 0.35 * progress)..style = PaintingStyle.fill);
    canvas.drawPath(pathCurr, Paint()..color = gymColors.fireHexagon.withValues(alpha: progress)..style = PaintingStyle.stroke..strokeWidth = 3..strokeJoin = StrokeJoin.round);

    for (int v = 0; v < 6; v++) {
        final val = (currentStats[labels[v].key] ?? 0.0) * progress;
        final a = v * stepAngle - math.pi / 2;
        final x = cx + maxRadius * val * math.cos(a);
        final y = cy + maxRadius * val * math.sin(a);
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = gymColors.fireHexagon);
        canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = colorScheme.surface);
    }

    if (opacity > 0) {
      for (int v = 0; v < 6; v++) {
        final a = v * stepAngle - math.pi / 2;
        final r = maxRadius * 1.25; 
        final x = cx + r * math.cos(a);
        final y = cy + r * math.sin(a);

        final finalVal = currentStats[labels[v].key] ?? 0.0;
        final rank = _getRank(finalVal);
        final rankColor = _getRankColor(rank);

        _paintElegantLabel(canvas, Offset(x, y), labels[v].value, rank, rankColor, opacity);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}