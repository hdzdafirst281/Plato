import 'package:flutter/material.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../../../core/database/enums.dart';

// =========================================================================
// HELPER MAP ENUM SANG CHUỖI ĐA NGÔN NGỮ
// =========================================================================

extension ChartTimeRangeExt on ChartTimeRange {
  String getLocalizedLabel() {
    switch (this) {
      case ChartTimeRange.WEEK: return t.stats.label_time_range_week;
      case ChartTimeRange.MONTH: return t.stats.label_time_range_month;
      case ChartTimeRange.THREE_MONTHS: return t.stats.label_time_range_3_months;
      case ChartTimeRange.YEAR: return t.stats.label_time_range_year;
      case ChartTimeRange.ALL_TIME: return t.stats.label_time_range_all;
    }
  }
}

// =========================================================================
// COMPONENTS DÙNG CHUNG CHO PROFILE & STATS
// =========================================================================

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onClick;

  const DashboardCard({super.key, required this.title, required this.subtitle, required this.icon, required this.color, required this.onClick});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // [REFACTOR] Tối ưu kích thước icon box theo breakpoint
    final double iconBoxSize = ResponsiveValue<double>(
      context,
      defaultValue: 56.0,
      conditionalValues: [
        Condition.equals(name: 'NARROW_MOBILE', value: 48.0),
      ],
    ).value;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      color: colorScheme.surface,
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(16),
        // [REFACTOR] CẤP ĐỘ 1: Dùng minHeight thay vì height fix cứng để Card tự giãn khi Text rớt dòng
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: iconBoxSize, 
                height: iconBoxSize,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                alignment: Alignment.center,
                // Kích thước icon bằng 1/2 box
                child: Icon(icon, color: color, size: iconBoxSize / 2),
              ),
              const SizedBox(width: 16),
              // [REFACTOR] CẤP ĐỘ 1: Expanded ép Text lấp đầy không gian còn lại
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // [REFACTOR] CẤP ĐỘ 2: Cho phép text rớt dòng tự nhiên
                    Text(
                      title, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle, 
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                      maxLines: 3,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Symbols.keyboard_arrow_right, color: colorScheme.onSurfaceVariant)
            ],
          ),
        ),
      ),
    );
  }
}

class BetterSegmentedControl extends StatelessWidget {
  final HeatmapMode currentMode; 
  final Function(HeatmapMode) onModeChanged;

  const BetterSegmentedControl({super.key, required this.currentMode, required this.onModeChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // [REFACTOR] Thu gọn width của tab trên màn hình hẹp
    final double tabWidth = ResponsiveValue<double>(
      context,
      defaultValue: 100.0,
      conditionalValues: [
        Condition.equals(name: 'NARROW_MOBILE', value: 85.0),
      ],
    ).value;

    return Container(
      height: 40,
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(50)),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: HeatmapMode.values.map((mode) {
          final isSelected = currentMode == mode;
          final label = mode == HeatmapMode.INTENSITY 
              ? t.stats.label_heatmap_mode_intensity 
              : t.stats.label_heatmap_mode_frequency;

          return InkWell(
            onTap: () => onModeChanged(mode),
            borderRadius: BorderRadius.circular(50),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: tabWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(50),
              ),
              // [REFACTOR] CẤP ĐỘ 3: Dùng FittedBox scaleDown cho label từ đơn
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label, 
                    style: TextStyle(
                      color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                      fontSize: 13,
                    )
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TimeRangeSelectorButton extends StatefulWidget {
  final ChartTimeRange selected;
  final Function(ChartTimeRange) onSelect;

  const TimeRangeSelectorButton({super.key, required this.selected, required this.onSelect});

  @override
  State<TimeRangeSelectorButton> createState() => _TimeRangeSelectorButtonState();
}

class _TimeRangeSelectorButtonState extends State<TimeRangeSelectorButton> {
  final LayerLink _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final allowedRanges = [
      ChartTimeRange.THREE_MONTHS, 
      ChartTimeRange.YEAR, 
      ChartTimeRange.ALL_TIME
    ];

    return CompositedTransformTarget(
      link: _link,
      child: PopupMenuButton<ChartTimeRange>(
        color: colorScheme.surface,
        onSelected: widget.onSelect,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        elevation: 4,
        itemBuilder: (context) => allowedRanges.map((range) => 
          PopupMenuItem(
            value: range, 
            child: Text(range.getLocalizedLabel())
          )
        ).toList(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          // [REFACTOR] CẤP ĐỘ 1: Giới hạn chiều rộng tối đa, tránh tràn do multi-language
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [REFACTOR] CẤP ĐỘ 3: Bọc Flexible + FittedBox
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.selected.getLocalizedLabel(), 
                      style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.primary)
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Symbols.keyboard_arrow_down, color: colorScheme.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// UTILS FORMATS & MATH
// =========================================================================

String getFunComparisonText(BarChartMetric metricType, double totalVal, ChartTimeRange range) {
  final timeLabel = range.getLocalizedLabel().toLowerCase();
  final fmtVal = formatCompactNumber(totalVal);

  switch (metricType) {
    case BarChartMetric.VOLUME:
      String equiv = "";
      if (totalVal < 5000) {
        equiv = t.stats.msg_equivalent_rhinos;
      } else if (totalVal < 20000) {
        equiv = t.stats.msg_equivalent_bus;
      } else if (totalVal < 50000) {
        equiv = t.stats.msg_equivalent_tank;
      } else if (totalVal < 100000) {
        equiv = t.stats.msg_equivalent_boeing;
      } else if (totalVal < 200000) {
        equiv = t.stats.msg_equivalent_whale;
      } else if (totalVal < 500000) {
        equiv = t.stats.msg_equivalent_iss;
      } else if (totalVal < 1000000) {
        equiv = t.stats.msg_equivalent_submarine;
      }
      else equiv = t.stats.msg_equivalent_fleet;
      return t.stats.format_fun_fact_volume(arg1: timeLabel, arg2: fmtVal, arg3: equiv);
      
    case BarChartMetric.DURATION:
      String equiv = "";
      if (totalVal < 20) {
        equiv = t.stats.msg_equivalent_movie;
      } else if (totalVal < 80) {
        equiv = t.stats.msg_equivalent_flight;
      }
      else if (totalVal < 150) {
        equiv = t.stats.msg_equivalent_bootcamp;
      } else if (totalVal < 350) {
        equiv = t.stats.msg_equivalent_language;
      } else if (totalVal < 600) {
        equiv = t.stats.msg_equivalent_vacation;
      } else if (totalVal < 1000) {
        equiv = t.stats.msg_equivalent_walk;
      } else {
        equiv = t.stats.msg_equivalent_gym_home;
      }
      return t.stats.format_fun_fact_duration(arg1: fmtVal, arg2: timeLabel, arg3: equiv);
      
    case BarChartMetric.REPS:
      String equiv = "";
      if (totalVal < 2000) {
        equiv = t.stats.msg_equivalent_blacksmith;
      } else if (totalVal < 12000) equiv = t.stats.msg_equivalent_marathon;
      else if (totalVal < 30000) equiv = t.stats.msg_equivalent_building;
      else if (totalVal < 60000) equiv = t.stats.msg_equivalent_machine;
      else if (totalVal < 120000) equiv = t.stats.msg_equivalent_eagle;
      else equiv = t.stats.msg_equivalent_diamond;
      return t.stats.format_fun_fact_reps(arg1: fmtVal, arg2: timeLabel, arg3: equiv);
  }
}

double getNiceStep(double delta, {int steps = 3}) {
  if (delta <= 0.0) return 1.0;
  final unrounded = delta / steps;
  final order = math.pow(10.0, (math.log(unrounded) / math.ln10).floorToDouble());
  final norm = unrounded / order;
  double mult;
  if (norm < 1.5) {
    mult = 1.0;
  } else if (norm < 3.5) mult = 2.0;
  else mult = 5.0;
  return mult * order;
}

String formatCompactNumber(double val) {
  if (val >= 1000) {
    final k = val / 1000;
    return (k % 1 == 0) ? "${k.toInt()}k" : "${k.toStringAsFixed(1)}k";
  }
  return (val % 1 == 0) ? val.toInt().toString() : val.toStringAsFixed(1);
}

// Bổ sung thêm tham số ColorScheme colorScheme
void drawTooltip(Canvas canvas, Size size, Offset offset, String text, ColorScheme colorScheme) {
  // Thay thế màu cứng bằng màu trên nền (onSurface)
  final paint = Paint()..color = colorScheme.onSurface.withValues(alpha: 0.9);
  
  // Chữ sẽ lấy màu nền (surface) để tạo sự tương phản (vd: nền đen chữ trắng, nền trắng chữ đen)
  final textStyle = ui.TextStyle(color: colorScheme.surface, fontSize: 16, fontWeight: FontWeight.bold);
  final paragraphStyle = ui.ParagraphStyle(textAlign: TextAlign.center);
  final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
    ..pushStyle(textStyle)
    ..addText(text);
  final paragraph = paragraphBuilder.build();
  paragraph.layout(const ui.ParagraphConstraints(width: 200));

  final textWidth = paragraph.maxIntrinsicWidth;
  const padding = 20.0;
  final boxWidth = textWidth + padding * 2;
  const boxHeight = 40.0;

  double left = offset.dx - boxWidth / 2;
  if (left < 10) left = 10;
  if (left + boxWidth > size.width - 10) left = size.width - boxWidth - 10;

  final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(left, offset.dy - boxHeight - 10, boxWidth, boxHeight), const Radius.circular(8));
  canvas.drawRRect(rrect, paint);
  
  canvas.drawParagraph(paragraph, Offset(left + padding, offset.dy - boxHeight - 10 + (boxHeight - paragraph.height) / 2));
}