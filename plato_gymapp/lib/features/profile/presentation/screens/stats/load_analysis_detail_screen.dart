import 'package:flutter/material.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

import '../../../../../core/designsystem/theme/shapes.dart';
import '../../../../../core/designsystem/components/gym_top_bar.dart';

import '../../../../workout/data/models/workout_models.dart';
import '../../../../workout/domain/training_load_manager.dart'; 
import '../../../domain/profile_chart_utils.dart';

class LoadAnalysisDetailScreen extends StatefulWidget {
  final List<WorkoutSession> workouts;
  final VoidCallback onBack;

  const LoadAnalysisDetailScreen({super.key, required this.workouts, required this.onBack});

  @override
  State<LoadAnalysisDetailScreen> createState() => _LoadAnalysisDetailScreenState();
}

class _LoadAnalysisDetailScreenState extends State<LoadAnalysisDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _growthAnim;
  late Animation<double> _opacityAnim;
  
  int _highlightIndex = -1; 

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

  void _dismissTooltip() {
    if (_highlightIndex != -1) {
      setState(() => _highlightIndex = -1);
    }
  }

  void _handleTouch(double dx, double width, int dataLength) {
    if (dataLength == 0) return;
    const padLeft = 40.0;
    
    if (dx < padLeft) {
      if (_highlightIndex != -1) setState(() => _highlightIndex = -1);
      return;
    }

    final renderW = width - padLeft;
    final slotW = renderW / dataLength;
    
    if (dx >= padLeft && dx <= width) {
      int idx = ((dx - padLeft) / slotW).floor();
      idx = idx.clamp(0, dataLength - 1);
      
      if (_highlightIndex != idx) {
        setState(() => _highlightIndex = idx);
      }
    } else if (dx > width) {
      if (_highlightIndex != dataLength - 1) setState(() => _highlightIndex = dataLength - 1);
    }
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
            Text(t.stats.desc_load_info_acwr, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              color: Theme.of(context).gymColors.success.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.stats.label_load_info_acute_title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).gymColors.success, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(t.stats.desc_load_info_acute, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 0,
              color: Theme.of(context).gymColors.warning.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.stats.label_load_info_chronic_title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).gymColors.warning, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(t.stats.desc_load_info_chronic, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontSize: 13),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Symbols.lightbulb, fill: 1.0, color: Theme.of(context).gymColors.goldRank, size: 18),
                    ),
                  ),
                  TextSpan(text: t.stats.desc_load_info_recommendation),
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

    final historyLoad = ProfileChartUtils.calculateLoadHistory(widget.workouts, 12);
    final latestLoad = historyLoad.lastOrNull;

    final sortedWorkouts = List<WorkoutSession>.from(widget.workouts)..sort((a, b) => a.startTime.compareTo(b.startTime));
    final activeWeeks = sortedWorkouts.isNotEmpty 
        ? math.max(1, (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(sortedWorkouts.first.startTime)).inDays / 7).floor() + 1)
        : 1;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.stats.title_load_main,
        onBackClick: widget.onBack,
        actions: [
          IconButton(
            icon: Icon(Symbols.info, color: colorScheme.primary), 
            onPressed: () => _showInfoDialog(context)
          )
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: _dismissTooltip, 
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                children: [
                  if (latestLoad != null && historyLoad.isNotEmpty) ...[
                    AnimatedBuilder(
                      animation: _opacityAnim,
                      builder: (context, child) => Opacity(opacity: _opacityAnim.value, child: child),
                      child: _CurrentLoadCard(analysis: latestLoad)
                    ),
                    const SizedBox(height: 40),
                    
                    AnimatedBuilder(
                      animation: _opacityAnim,
                      builder: (context, child) => Opacity(opacity: _opacityAnim.value, child: child),
                      child: Text(t.stats.title_load_history_header, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 340, 
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) => _handleTouch(details.localPosition.dx, constraints.maxWidth, historyLoad.length),
                            onHorizontalDragUpdate: (details) => _handleTouch(details.localPosition.dx, constraints.maxWidth, historyLoad.length),
                            child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) => CustomPaint(
                                size: Size(constraints.maxWidth, 340),
                                painter: _LoadChartPainter(
                                  data: historyLoad, 
                                  activeWeeksTotal: activeWeeks,
                                  selectedIndex: _highlightIndex,
                                  progress: _growthAnim.value,
                                  opacity: _opacityAnim.value, 
                                  colorScheme: colorScheme,
                                  gymColors: Theme.of(context).gymColors,
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    AnimatedBuilder(
                      animation: _opacityAnim,
                      builder: (context, child) => Opacity(opacity: _opacityAnim.value, child: child),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: Theme.of(context).gymColors.success, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(width: 8),
                              Text(t.stats.label_load_legend_acute, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(width: 32),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: Theme.of(context).gymColors.warning, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(width: 8),
                              Text(t.stats.label_load_legend_chronic, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                      )
                    )
                  ] else ...[
                    SizedBox(
                      // Chiều cao 70% màn hình để icon thực sự nằm ở trung tâm tầm nhìn (trừ đi phần appBar)
                      height: MediaQuery.of(context).size.height * 0.7, 
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Symbols.unknown_med, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            t.stats.msg_load_insufficient_data, 
                            textAlign: TextAlign.center, 
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ).animate(delay: 300.ms).fade(duration: 600.ms),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentLoadCard extends StatelessWidget {
  final LoadAnalysis analysis;

  const _CurrentLoadCard({required this.analysis});

  String _getZoneName() {
    switch (analysis.zone) {
      case LoadZone.UNDERTRAINING: return t.workout.label_session_summary_zone_under;
      case LoadZone.OPTIMAL: return t.workout.label_session_summary_zone_optimal;
      case LoadZone.OVERREACHING: return t.workout.label_session_summary_zone_overreach;
      case LoadZone.OVERTRAINING: return t.workout.label_session_summary_zone_overtrain;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Color zoneColor;
    switch (analysis.zone) {
      case LoadZone.UNDERTRAINING: zoneColor = colorScheme.onSurfaceVariant; break;
      case LoadZone.OPTIMAL: zoneColor = Theme.of(context).gymColors.success; break;
      case LoadZone.OVERREACHING: zoneColor = Theme.of(context).gymColors.warning; break;
      case LoadZone.OVERTRAINING: zoneColor = colorScheme.error; break;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppShapes.large.borderRadius,
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.stats.title_load_current_acwr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: zoneColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getZoneName(), style: TextStyle(color: zoneColor, fontWeight: FontWeight.bold, fontSize: 13)),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(analysis.ratio.toStringAsFixed(2), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: zoneColor, height: 1.1)),
            const SizedBox(height: 4),
            Text(t.stats.desc_load_acwr_ratio, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.stats.label_load_acute, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(analysis.acuteLoad.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(t.stats.label_load_chronic, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(analysis.chronicLoad.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _LoadChartPainter extends CustomPainter {
  final List<LoadAnalysis> data;
  final int activeWeeksTotal;
  final int selectedIndex;
  final double progress;
  final double opacity;
  final ColorScheme colorScheme;
  final GymColors gymColors;

  _LoadChartPainter({
    required this.data, 
    required this.activeWeeksTotal, 
    required this.selectedIndex,
    required this.progress, 
    required this.opacity, 
    required this.colorScheme,
    required this.gymColors,
  });

  String _formatCompactNumber(double number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toInt().toString();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = math.max(
      data.map((e) => e.acuteLoad).reduce(math.max),
      data.map((e) => e.chronicLoad).reduce(math.max)
    ) * 1.2;
    final finalMaxVal = maxVal == 0 ? 1.0 : maxVal; 

    const paddingTop = 50.0;
    const padLeft = 40.0;
    const padBottom = 30.0;
    final w = size.width - padLeft;
    final h = size.height - padBottom;
    final chartHeight = h - paddingTop;
    
    final slotW = w / data.length;
    final barW = math.min(slotW * 0.4, 40.0); 

    final paintBar = Paint()..color = gymColors.success;
    final paintBarSel = Paint()..color = gymColors.success.withValues(alpha: 0.5); 
    
    final paintLine = Paint()..color = gymColors.warning..style = PaintingStyle.stroke..strokeWidth = 3..strokeJoin = StrokeJoin.round;
    final paintGrid = Paint()..color = colorScheme.outlineVariant.withValues(alpha: 0.5)..strokeWidth = 1;
    final paintAxis = Paint()..color = colorScheme.onSurfaceVariant..strokeWidth = 2.0;

    double getY(double val) => h - ((val / finalMaxVal) * chartHeight);

    for (int i = 0; i <= 4; i++) {
      final val = (finalMaxVal / 4) * i;
      final y = getY(val);
      canvas.drawLine(Offset(padLeft, y), Offset(size.width, y), paintGrid);
      
      if (opacity > 0) {
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.right))
          ..pushStyle(ui.TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: opacity), fontSize: 11, fontWeight: FontWeight.w600))
          ..addText(_formatCompactNumber(val)); 
        final p = builder.build()..layout(const ui.ParagraphConstraints(width: padLeft - 5));
        canvas.drawParagraph(p, Offset(0, y - 6));
      }
    }

    canvas.drawLine(Offset(padLeft, paddingTop), Offset(padLeft, h), paintAxis); 
    canvas.drawLine(Offset(padLeft, h), Offset(size.width, h), paintAxis); 

    for (int i = 0; i < data.length; i++) {
      final x = padLeft + (i * slotW) + (slotW / 2);
      final barH = (data[i].acuteLoad / finalMaxVal) * chartHeight * progress;
      
      canvas.drawRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(x - barW / 2, h - barH, barW, barH), 
        topLeft: const Radius.circular(4), topRight: const Radius.circular(4)
      ), i == selectedIndex ? paintBarSel : paintBar);
      
      if (opacity > 0) {
        final weekStr = "W${activeWeeksTotal - data.length + i + 1}";
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(ui.TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: opacity), fontSize: 10, fontWeight: FontWeight.bold))
          ..addText(weekStr);
        final p = builder.build()..layout(ui.ParagraphConstraints(width: slotW));
        canvas.drawParagraph(p, Offset(x - slotW / 2, h + 12));
      }
    }

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = padLeft + (i * slotW) + (slotW / 2);
      final y = getY(data[i].chronicLoad);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final extracted = metrics.first.extractPath(0, metrics.first.length * progress);
      canvas.drawPath(extracted, paintLine);

      for (int i = 0; i < data.length; i++) {
        if (progress < (i / data.length)) continue;

        final x = padLeft + (i * slotW) + (slotW / 2);
        final y = getY(data[i].chronicLoad);

        if (i == selectedIndex && progress > 0.99) {
          canvas.drawCircle(Offset(x, y), 10, Paint()
            ..color = gymColors.warning.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
          canvas.drawCircle(Offset(x, y), 6, Paint()..color = colorScheme.surface);
          canvas.drawCircle(Offset(x, y), 4, Paint()..color = gymColors.warning); // FIX
        } else {
          canvas.drawCircle(Offset(x, y), 4, Paint()..color = gymColors.warning); // FIX
        }
      }
    }

    if (selectedIndex >= 0 && selectedIndex < data.length && progress > 0.99) {
      final cx = padLeft + (selectedIndex * slotW) + (slotW / 2);
      final d = data[selectedIndex];
      
      final peakY = math.min(getY(d.acuteLoad), getY(d.chronicLoad)); 
      final weekStr = "W${activeWeeksTotal - data.length + selectedIndex + 1}";

      final textSpan = TextSpan(
        children: [
          TextSpan(text: "Tuần: $weekStr\n", style: TextStyle(color: colorScheme.surface.withValues(alpha: 0.8), fontSize: 11)),
          TextSpan(text: "${t.stats.label_load_acute}: ${d.acuteLoad.toInt()}\n", style: TextStyle(color: gymColors.success, fontSize: 13, fontWeight: FontWeight.w900, height: 1.5)),
          TextSpan(text: "${t.stats.label_load_chronic}: ${d.chronicLoad.toInt()}", style: TextStyle(color: gymColors.warning, fontSize: 13, fontWeight: FontWeight.w900)),
        ]
      );
      final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center)..layout();
      
      double boxCenter = cx;
      final tooltipW = textPainter.width + 24;
      if (boxCenter - (tooltipW / 2) < padLeft) {
        boxCenter = padLeft + (tooltipW / 2);
      }
      if (boxCenter + (tooltipW / 2) > size.width) {
        boxCenter = size.width - (tooltipW / 2);
      }

      final tooltipBottomY = peakY - 12; 
      
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxCenter - (textPainter.width / 2) - 12, tooltipBottomY - textPainter.height - 12, tooltipW, textPainter.height + 12),
        const Radius.circular(8)
      );
      canvas.drawShadow(Path()..addRRect(boxRect), Colors.black, 4, false);
      canvas.drawRRect(boxRect, Paint()..color = colorScheme.onSurface);
      
      textPainter.paint(canvas, Offset(boxCenter - (textPainter.width / 2), tooltipBottomY - textPainter.height - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _LoadChartPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.opacity != opacity || 
           oldDelegate.selectedIndex != selectedIndex;
  }
}