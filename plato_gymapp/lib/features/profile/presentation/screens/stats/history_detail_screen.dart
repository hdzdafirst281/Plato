import 'package:flutter/material.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';

import '../../../../../core/designsystem/components/gym_top_bar.dart';
import '../../../../../core/designsystem/theme/shapes.dart';

import '../../../../workout/data/models/workout_models.dart';
import '../../../domain/profile_chart_utils.dart';
import '../../components/profile_components.dart';
import 'package:intl/intl.dart';

extension BarChartMetricExt on BarChartMetric {
  String getLocalizedLabel() {
    switch (this) {
      case BarChartMetric.VOLUME: return t.common.volume;
      case BarChartMetric.DURATION: return t.common.duration;
      case BarChartMetric.REPS: return t.common.reps;
    }
  }

  String getLocalizedUnit() {
    switch (this) {
      case BarChartMetric.VOLUME: return t.common.unit_kg;
      case BarChartMetric.DURATION: return ''; 
      case BarChartMetric.REPS: return t.common.reps.toLowerCase();
    }
  }
}

class HistoryDetailScreen extends StatefulWidget {
  final List<WorkoutSession> workouts;
  final void Function() onBack;

  const HistoryDetailScreen({super.key, required this.workouts, required this.onBack});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  ChartTimeRange _timeRange = ChartTimeRange.THREE_MONTHS;
  BarChartMetric _activeMetric = BarChartMetric.VOLUME;
  int _highlightIndex = -1;

  void _showInfoDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget buildMetricRow(IconData icon, String label, String desc) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  children: [
                    TextSpan(text: t.translateDynamic(label), style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: t.translateDynamic(desc)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

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
            Text(t.stats.desc_history_info_general, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.stats.lbl_history_info_metrics_title, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 14)),
                    const SizedBox(height: 8),
                    buildMetricRow(Symbols.weight, 'stats.label_history_info_metrics_volume', 'stats.desc_history_info_metrics_volume'),
                    buildMetricRow(Symbols.timer, 'stats.label_history_info_metrics_duration', 'stats.desc_history_info_metrics_duration'),
                    buildMetricRow(Symbols.autorenew, 'stats.label_history_info_metrics_reps', 'stats.desc_history_info_metrics_reps'),
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
                  TextSpan(text: '${t.stats.lbl_history_info_tip_title} '),
                  TextSpan(text: t.stats.desc_history_info_tip, style: const TextStyle(fontWeight: FontWeight.normal)),
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

  void _dismissTooltip() {
    if (_highlightIndex != -1) {
      setState(() => _highlightIndex = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final limitMillis = _timeRange == ChartTimeRange.ALL_TIME ? 0 : nowMillis - (_timeRange.days * 86400000);
    final filteredWorkouts = widget.workouts.where((w) => w.startTime >= limitMillis).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    final dataPoints = ProfileChartUtils.aggregateStatsByTimeRange(filteredWorkouts, _timeRange, TranslationProvider.of(context).flutterLocale.languageCode);

    double totalMetricVal = 0.0;
    for (var d in dataPoints) {
      if (_activeMetric == BarChartMetric.VOLUME) {
        totalMetricVal += d.volume;
      } else if (_activeMetric == BarChartMetric.DURATION) totalMetricVal += d.durationHours;
      else totalMetricVal += d.reps;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: GymTopBar(
        title: t.stats.title_history_main,
        onBackClick: widget.onBack,
        actions: [
          IconButton(
            icon: Icon(Symbols.info, color: colorScheme.primary), 
            onPressed: () => _showInfoDialog(context),
          )
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: _dismissTooltip,
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000), 
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: BarChartMetric.values.map((m) {
                        final isSel = _activeMetric == m;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: isSel ? colorScheme.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: isSel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                                child: InkWell(
                                  onTap: () => setState(() { _activeMetric = m; _highlightIndex = -1; }),
                                  borderRadius: BorderRadius.circular(50),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        m.getLocalizedLabel(), 
                                        style: TextStyle(
                                          color: isSel ? colorScheme.primary : colorScheme.onSurfaceVariant, 
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.w600, 
                                          fontSize: 13 
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(t.stats.lbl_history_filter_by, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 16)),
                      TimeRangeSelectorButton(
                        selected: _timeRange,
                        onSelect: (v) => setState(() { _timeRange = v; _highlightIndex = -1; }),
                      )
                    ],
                  ).animate(delay: 100.ms).fade(duration: 400.ms),
                  
                  const SizedBox(height: 24),

                  if (totalMetricVal > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5), 
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)), 
                        borderRadius: AppShapes.large.borderRadius,
                        boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.2), 
                              shape: BoxShape.circle
                            ),
                            child: Icon(
                              Symbols.tips_and_updates,
                              size: 24, // Cân chỉnh size nhỉnh hơn 20 một chút để Icon nhìn rõ nét
                              color: Theme.of(context).gymColors.goldRank, // Lấy màu primary để tone-sur-tone với background
                              fill: 1.0, // (Tuỳ chọn) Fill icon để tạo cảm giác sáng đèn
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              getFunComparisonText(_activeMetric, totalMetricVal, _timeRange), 
                              style: TextStyle(
                                height: 1.5, 
                                color: colorScheme.onPrimaryContainer, 
                                fontWeight: FontWeight.w600
                              )
                            )
                          ),
                        ],
                      ),
                    ).animate(delay: 200.ms).fade(duration: 400.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),
                  
                  if (dataPoints.isNotEmpty)
                    SizedBox(
                      height: 340, 
                      child: _ImprovedBarChart(
                        dataPoints: dataPoints,
                        metric: _activeMetric,
                        timeRange: _timeRange, 
                        selectedIndex: _highlightIndex,
                        onSelect: (i) => setState(() => _highlightIndex = i),
                      ),
                    ).animate(delay: 300.ms).fade(duration: 600.ms)
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 64, bottom: 64),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Symbols.show_chart, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(t.stats.msg_chart_no_data, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ).animate(delay: 300.ms).fade(duration: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImprovedBarChart extends StatefulWidget {
  final List<StatPoint> dataPoints;
  final BarChartMetric metric;
  final ChartTimeRange timeRange;
  final int selectedIndex;
  final Function(int) onSelect;

  const _ImprovedBarChart({
    required this.dataPoints, 
    required this.metric, 
    required this.timeRange,
    required this.selectedIndex, 
    required this.onSelect,
  });

  @override
  State<_ImprovedBarChart> createState() => _ImprovedBarChartState();
}

class _ImprovedBarChartState extends State<_ImprovedBarChart> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant _ImprovedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metric != widget.metric || oldWidget.dataPoints.length != widget.dataPoints.length) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _getVal(StatPoint p) {
    if (widget.metric == BarChartMetric.VOLUME) return p.volume;
    if (widget.metric == BarChartMetric.DURATION) return p.durationHours;
    return p.reps.toDouble();
  }

  void _handleTouch(Offset localPosition, double availableWidth) {
    const padLeft = 30.0;
    final renderW = availableWidth - padLeft;
    
    if (localPosition.dx >= padLeft && renderW > 0) {
      final slotW = renderW / widget.dataPoints.length;
      final idx = ((localPosition.dx - padLeft) / slotW).floor();
      if (idx >= 0 && idx < widget.dataPoints.length) {
        widget.onSelect(idx);
      } else {
        widget.onSelect(-1);
      }
    } else {
      widget.onSelect(-1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentLangCode = TranslationProvider.of(context).flutterLocale.languageCode; 

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handleTouch(details.localPosition, constraints.maxWidth),
          onPanUpdate: (details) => _handleTouch(details.localPosition, constraints.maxWidth),
          child: AnimatedBuilder(
            animation: _growthAnim,
            builder: (context, _) => CustomPaint(
              painter: _HistoryBarPainter(
                data: widget.dataPoints,
                getVal: _getVal,
                metric: widget.metric,
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
    );
  }
}

class _HistoryBarPainter extends CustomPainter {
  final List<StatPoint> data;
  final double Function(StatPoint) getVal;
  final BarChartMetric metric;
  final ChartTimeRange timeRange;
  final int selectedIndex;
  final double progress;
  final ColorScheme colorScheme;
  final String langCode;

  _HistoryBarPainter({
    required this.data, 
    required this.getVal, 
    required this.metric,
    required this.timeRange, 
    required this.selectedIndex, 
    required this.progress, 
    required this.colorScheme, 
    required this.langCode
  });

  // HÀM CUSTOM FORMAT SỐ LIỆU CHO TRỤC Y - ĐÃ ĐƯỢC TỐI ƯU HÓA LÀM TRÒN
  String _formatCompactNumber(double number) {
    if (number >= 1000) {
      String formatted = (number / 1000).toStringAsFixed(1);
      if (formatted.endsWith('.0')) {
        return '${formatted.substring(0, formatted.length - 2)}k';
      }
      return '${formatted}k';
    }
    return number.toInt().toString();
  }

  double _getTightStep(double maxVal) {
    if (maxVal <= 0.0) return 1.0;
    
    double rawStep = maxVal / 5.0; 
    double mag = math.pow(10.0, (math.log(rawStep) / math.ln10).floorToDouble()).toDouble();
    double norm = rawStep / mag; 
    
    double step;
    if (norm <= 1.0) {
      step = 1.0;
    } else if (norm <= 1.2) step = 1.2;
    else if (norm <= 1.5) step = 1.5;
    else if (norm <= 2.0) step = 2.0;
    else if (norm <= 2.5) step = 2.5;
    else if (norm <= 3.0) step = 3.0;
    else if (norm <= 4.0) step = 4.0;
    else if (norm <= 5.0) step = 5.0;
    else if (norm <= 6.0) step = 6.0;
    else if (norm <= 8.0) step = 8.0;
    else step = 10.0;
    
    return step * mag;
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

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.map(getVal).reduce(math.max);
    final axisStep = _getTightStep(maxVal);
    final axisMax = axisStep * 5;

    const paddingTop = 15.0; 
    const padLeft = 36.0; 
    final w = size.width - padLeft;
    final h = size.height - 40.0; 
    final chartHeight = h - paddingTop; 

    final slotW = w / data.length;
    final barW = slotW * 0.5;

    final paintGrid = Paint()..color = colorScheme.outlineVariant..strokeWidth = 1.5;
    final paintAxis = Paint()..color = colorScheme.onSurfaceVariant..strokeWidth = 2.0;
    final paintBar = Paint()..color = colorScheme.primary;
    final paintBarSel = Paint()..color = colorScheme.primary.withValues(alpha: 0.5);

    double getY(double val) => h - ((val / axisMax) * chartHeight);

    for (int i = 1; i <= 4; i++) { 
      final val = axisStep * i;
      final y = getY(val);
      
      _drawDashedLine(canvas, Offset(padLeft, y), Offset(size.width, y), paintGrid);

      if (progress > 0) { 
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.right))
          ..pushStyle(ui.TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: progress.clamp(0.0, 1.0)), fontSize: 11))
          ..addText(_formatCompactNumber(val)); // SỬ DỤNG HÀM CUSTOM Ở ĐÂY
        final p = builder.build()..layout(const ui.ParagraphConstraints(width: padLeft - 5));
        canvas.drawParagraph(p, Offset(0, y - 6));
      }
    }

    canvas.drawLine(Offset(padLeft, paddingTop), Offset(padLeft, h), paintAxis);
    canvas.drawLine(Offset(padLeft, h), Offset(size.width, h), paintAxis);

    final skipRate = (data.length / 6).ceil().clamp(1, 999);

    for (int i = 0; i < data.length; i++) {
      final val = getVal(data[i]);
      final barH = (val / axisMax) * chartHeight * progress;
      final cx = padLeft + (i * slotW) + (slotW / 2);

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, h - barH, barW, barH),
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
      );
      canvas.drawRRect(rrect, i == selectedIndex ? paintBarSel : paintBar);

      if (i % skipRate == 0) {
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
          ..pushStyle(ui.TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold))
          ..addText(data[i].label);
        final p = builder.build()..layout(const ui.ParagraphConstraints(width: 80)); 
        canvas.drawParagraph(p, Offset(cx - 40, h + 8));
      }
    }

    if (selectedIndex >= 0 && selectedIndex < data.length && progress > 0.99) {
      final cx = padLeft + (selectedIndex * slotW) + (slotW / 2);
      final val = getVal(data[selectedIndex]);
      final y = getY(val);

      final startDate = DateTime.fromMillisecondsSinceEpoch(data[selectedIndex].timestamp);
      String dateStr;
      if (timeRange == ChartTimeRange.THREE_MONTHS) {
        final endDate = startDate.add(const Duration(days: 6));
        dateStr = "${DateFormat("dd/MM", langCode).format(startDate)} - ${DateFormat("dd/MM", langCode).format(endDate)}";
      } else {
        dateStr = DateFormat("MM/yyyy", langCode).format(startDate);
      }

      String valStr;
      if (metric == BarChartMetric.DURATION) {
        final hours = val.toInt();
        final mins = ((val % 1) * 60).toInt();
        valStr = t.common.time_h_m(
          h: hours.toString(),
          m: mins.toString().padLeft(2, '0') 
        );
      } else if (metric == BarChartMetric.REPS) {
        valStr = "${val.toInt()} ${metric.getLocalizedUnit()}";
      } else {
        valStr = "${val.toStringAsFixed(1)} ${metric.getLocalizedUnit()}";
      }

      final textSpan = TextSpan(
        children: [
          TextSpan(text: "$dateStr\n", style: TextStyle(color: colorScheme.surface.withValues(alpha: 0.8), fontSize: 11)),
          TextSpan(text: valStr, style: TextStyle(color: colorScheme.surface, fontSize: 14, fontWeight: FontWeight.w900)),
        ]
      );
      final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center)..layout();
      
      double boxCenter = cx;
      if (boxCenter - (textPainter.width / 2) - 12 < padLeft) boxCenter = padLeft + (textPainter.width / 2) + 12;
      if (boxCenter + (textPainter.width / 2) + 12 > size.width) boxCenter = size.width - (textPainter.width / 2) - 12;

      final tooltipBottomY = y - 18; 
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxCenter - (textPainter.width / 2) - 12, tooltipBottomY - textPainter.height - 12, textPainter.width + 24, textPainter.height + 12),
        const Radius.circular(8)
      );
      
      canvas.drawShadow(Path()..addRRect(boxRect), Colors.black, 4, false);
      canvas.drawRRect(boxRect, Paint()..color = colorScheme.onSurface);
      
      double arrowBaseLeft = math.max(cx - 6, boxRect.left + 4);
      double arrowBaseRight = math.min(cx + 6, boxRect.right - 4);
      
      final arrowPath = Path()
        ..moveTo(arrowBaseLeft, tooltipBottomY)
        ..lineTo(arrowBaseRight, tooltipBottomY)
        ..lineTo(cx, tooltipBottomY + 6)
        ..close();
      canvas.drawPath(arrowPath, Paint()..color = colorScheme.onSurface);

      textPainter.paint(canvas, Offset(boxCenter - (textPainter.width / 2), tooltipBottomY - textPainter.height - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryBarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.selectedIndex != selectedIndex || oldDelegate.metric != metric || oldDelegate.timeRange != timeRange;
  }
}