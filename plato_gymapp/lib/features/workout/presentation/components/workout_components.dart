import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/i18n/translation_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/features/profile/presentation/components/body_path_data.dart';
import 'package:plato_gymapp/features/workout/domain/muscle_recovery_calculator.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../core/designsystem/components/gym_animated_progress_bar.dart';
import '../../../../core/database/enums.dart';
import '../../data/models/workout_models.dart';
import '../bloc/active_session_cubit.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/workout_permission_helper.dart';

// ==========================================
// 1. GENERIC & BASE COMPONENTS
// ==========================================
class GymMuscleIcon extends StatelessWidget {
  final MajorMuscleGroup group;
  final Color color;
  final double size;
  
  // Vẫn giữ lại cờ hiệu flip như cũ
  final bool isFlipped; 

  const GymMuscleIcon({
    super.key,
    required this.group,
    required this.color,
    this.size = 20.0,
    this.isFlipped = false, 
  });

  @override
  Widget build(BuildContext context) {
    String assetPath = _getPathForGroup(group);

    // Fallback nếu không tìm thấy file tương ứng
    if (assetPath.isEmpty) {
      return Icon(Icons.fitness_center, color: color, size: size);
    }

    // Widget SVG hiển thị icon
    Widget svgIcon = SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      // ColorFilter với srcIn sẽ tô màu toàn bộ phần tử fill của SVG (y chang Paint cũ)
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      fit: BoxFit.contain, // Đảm bảo icon nằm gọn trong size (giống behavior cũ của scale bounds)
    );

    // Lật ngược trục Y nếu có yêu cầu
    if (isFlipped) {
      return Transform.flip(
        flipY: true,
        child: svgIcon,
      );
    }

    return svgIcon;
  }

  String _getPathForGroup(MajorMuscleGroup group) {
    switch (group) {
      case MajorMuscleGroup.CHEST: return BodyPathData.chestIcon;
      case MajorMuscleGroup.BACK: return BodyPathData.backIcon;
      case MajorMuscleGroup.LEGS: return BodyPathData.legsIcon;
      case MajorMuscleGroup.SHOULDERS: return BodyPathData.shouldersIcon;
      case MajorMuscleGroup.CORE: return BodyPathData.coreIcon;
      case MajorMuscleGroup.ARMS: return BodyPathData.armsIcon;
      default: return '';
    }
  }
}

Future<void> handleStartWorkoutConflict({
  required BuildContext context,
  required ActiveSessionCubit activeSessionCubit,
  required VoidCallback onConfirmStart,
}) async {
  if (activeSessionCubit.state.activeWorkout != null) {
    final shouldStart = await GymDialog.showConfirm(
      context: context,
      title: t.workout.title_active_ssn_conflict,
      message: t.workout.msg_active_ssn_conflict,
      cancelText: t.workout.btn_keep_ssn,
      confirmText: t.workout.btn_start_new_ssn,
      icon: Symbols.warning_amber_rounded,
      iconColor: Theme.of(context).colorScheme.error,
    );

    if (shouldStart == true) {
      activeSessionCubit.cancelWorkout();
      if (!context.mounted) return;
      WorkoutPermissionHelper.checkAndStartWorkout(context, onConfirmStart);
    }
  } else {
    WorkoutPermissionHelper.checkAndStartWorkout(context, onConfirmStart);
  }
}

class GymExcelCell extends StatefulWidget {
  final String initialValue;
  final String placeholder;
  final Function(String) onChanged;
  final Function(String)? onLiveChanged; 
  final bool isInteger;

  const GymExcelCell({
    super.key,
    required this.initialValue,
    required this.placeholder,
    required this.onChanged,
    this.onLiveChanged,
    this.isInteger = false,
  });

  @override
  State<GymExcelCell> createState() => _GymExcelCellState();
}

class _GymExcelCellState extends State<GymExcelCell> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String _lastKnownValue = "";

  @override
  void initState() {
    super.initState();
    _lastKnownValue = widget.initialValue;
    _controller = TextEditingController(text: _lastKnownValue);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (_controller.text != _lastKnownValue) {
          _lastKnownValue = _controller.text;
          widget.onChanged(_controller.text);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant GymExcelCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _controller.text) {
      _lastKnownValue = widget.initialValue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.text = _lastKnownValue;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTablet = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
    
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      alignment: Alignment.center, 
      decoration: const BoxDecoration(color: Colors.transparent),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        scrollPhysics: const NeverScrollableScrollPhysics(),
        scrollPadding: isTablet ? const EdgeInsets.all(20.0) : const EdgeInsets.only(bottom: 160.0), 
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center, 
        keyboardType: TextInputType.numberWithOptions(decimal: !widget.isInteger),
        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 16),
        onChanged: (val) {
          if (widget.onLiveChanged != null) widget.onLiveChanged!(val);
        },
        onFieldSubmitted: (val) {
          _lastKnownValue = val;
          widget.onChanged(val);
        },
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), fontWeight: FontWeight.w600),
          border: InputBorder.none,
          isDense: true, 
          contentPadding: EdgeInsets.zero, 
        ),
      ),
    );
  }
}

class ThemedTagChip extends StatelessWidget {
  final String text;
  final Color? color;
  const ThemedTagChip({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: baseColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: baseColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class WorkoutStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const WorkoutStatItem({super.key, required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color ?? colorScheme.primary, fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500), maxLines: 2, softWrap: true, textAlign: TextAlign.center),
            )
          ],
        )
      ],
    );
  }
}


class GymReorderDialog<T> extends StatefulWidget {
  final String title;
  final String description;
  final List<T> initialItems;
  final String Function(T) itemNameSelector;
  final String Function(T) idSelector; 
  final Function(List<T>) onSave;

  const GymReorderDialog({
    super.key, required this.title, required this.description, required this.initialItems, required this.itemNameSelector, required this.idSelector, required this.onSave,
  });

  @override
  State<GymReorderDialog<T>> createState() => _GymReorderDialogState<T>();
}

class _GymReorderDialogState<T> extends State<GymReorderDialog<T>> {
  late List<T> _currentList;

  @override
  void initState() {
    super.initState();
    _currentList = List.from(widget.initialItems);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double maxDialogHeight = ResponsiveValue<double>(context, defaultValue: 600.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 450.0)]).value;
    final double dialogPadding = ResponsiveValue<double>(context, defaultValue: 24.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 16.0)]).value;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2))),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        padding: EdgeInsets.all(dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text(widget.description, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false, 
                  itemCount: _currentList.length,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) {
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
                                BoxShadow(color: colorScheme.primary.withValues(alpha: 0.15 * animValue), blurRadius: 10 * animValue, spreadRadius: 2 * animValue, offset: Offset(0, 4 * animValue)),
                                BoxShadow(color: Colors.black.withValues(alpha: 0.1 * animValue), blurRadius: 8 * animValue, offset: Offset(0, 2 * animValue))
                              ],
                            ),
                            child: child,
                          ),
                        );
                      }
                    );
                  },
                  onReorderStart: (_) => HapticFeedback.heavyImpact(),
                  onReorderEnd: (_) => HapticFeedback.lightImpact(),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _currentList.removeAt(oldIndex);
                      _currentList.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _currentList[index];
                    return ReorderableDragStartListener(
                      key: ValueKey(widget.idSelector(item)),
                      index: index,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16), 
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6))
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                child: Text(widget.itemNameSelector(item), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 3, softWrap: true),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Icon(Symbols.drag_handle, color: colorScheme.primary, size: 22),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel, style: TextStyle(color: colorScheme.onSurfaceVariant))),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () { widget.onSave(_currentList); Navigator.pop(context); }, 
                  child: Text(t.common.save, style: const TextStyle(fontWeight: FontWeight.bold))
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ExerciseChartDataPoint {
  final int timestampMillis;
  final double recordedValue;
  ExerciseChartDataPoint(this.timestampMillis, this.recordedValue);
}

class GymAdvancedLineChart extends StatefulWidget {
  final List<ExerciseChartDataPoint> dataPoints;
  final String unitLabel;
  final bool isTimeFormat;
  final ChartTimeRange timeRange; 

  const GymAdvancedLineChart({super.key, required this.dataPoints, required this.unitLabel, this.isTimeFormat = false, required this.timeRange});

  @override
  State<GymAdvancedLineChart> createState() => _GymAdvancedLineChartState();
}

class _GymAdvancedLineChartState extends State<GymAdvancedLineChart> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _growthAnim;
  int _highlightIndex = -1; 

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _growthAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant GymAdvancedLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataPoints != widget.dataPoints) {
      _animController.forward(from: 0.0);
      setState(() => _highlightIndex = -1);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateHighlight(Offset localPosition, double width) {
    if (widget.dataPoints.isEmpty) return;
    const paddingLeft = 50.0;
    const paddingRight = 24.0; 
    final w = width - paddingLeft - paddingRight; 
    final spacing = w / (widget.dataPoints.length - 1).clamp(1, 999);
    
    int index = ((localPosition.dx - paddingLeft) / spacing).round();
    index = index.clamp(0, widget.dataPoints.length - 1);
    
    if (_highlightIndex != index) setState(() => _highlightIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.show_chart, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(t.explore.msg_ex_dtl_no_data_range, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
          ],
        )
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) => _updateHighlight(details.localPosition, constraints.maxWidth),
          onTapDown: (details) => _updateHighlight(details.localPosition, constraints.maxWidth),
          onTapUp: (_) => setState(() => _highlightIndex = -1),
          onHorizontalDragEnd: (_) => setState(() => _highlightIndex = -1),
          child: AnimatedBuilder(
            animation: _growthAnim,
            builder: (context, _) => CustomPaint(
              painter: _AdvancedChartPainter(
                dataPoints: widget.dataPoints, progress: _growthAnim.value, colorScheme: Theme.of(context).colorScheme, highlightIndex: _highlightIndex, unitLabel: widget.unitLabel, isTimeFormat: widget.isTimeFormat, timeRange: widget.timeRange, localeCode: TranslationProvider.of(context).flutterLocale.languageCode,
              ),
              size: Size.infinite,
            ),
          ),
        );
      }
    );
  }
}

class _AdvancedChartPainter extends CustomPainter {
  final List<ExerciseChartDataPoint> dataPoints;
  final double progress;
  final ColorScheme colorScheme;
  final int highlightIndex;
  final String unitLabel;
  final bool isTimeFormat;
  final ChartTimeRange timeRange;
  final String localeCode;

  _AdvancedChartPainter({
    required this.dataPoints, required this.progress, required this.colorScheme, 
    required this.highlightIndex, required this.unitLabel, required this.isTimeFormat,
    required this.timeRange, required this.localeCode,
  });

  double _getNiceStep(double range, int numSteps) {
    if (range <= 0) return 1.0;
    double roughStep = range / (numSteps - 1);
    double stepPower = math.pow(10, (math.log(roughStep) / math.ln10).floor()).toDouble();
    double normalizedStep = roughStep / stepPower;
    double niceNormalizedStep;
    if (normalizedStep < 1.5) {
      niceNormalizedStep = 1.0;
    } else if (normalizedStep < 3) niceNormalizedStep = 2.0;
    else if (normalizedStep < 7) niceNormalizedStep = 5.0;
    else niceNormalizedStep = 10.0;
    return niceNormalizedStep * stepPower;
  }

  String _formatNumber(double num) {
    if (num >= 1000) return "${(num / 1000).toStringAsFixed(1)}k";
    return num % 1 == 0 ? num.toInt().toString() : num.toStringAsFixed(1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paintLine = Paint()..color = colorScheme.primary..strokeWidth = 3..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    final paintGrid = Paint()..color = colorScheme.outlineVariant.withValues(alpha: 0.5)..strokeWidth = 1;
    final paintAxis = Paint()..color = colorScheme.onSurfaceVariant..strokeWidth = 1.0;
    final paintCircleOut = Paint()..color = colorScheme.primary..style = PaintingStyle.fill;
    final paintCircleIn = Paint()..color = colorScheme.surface..style = PaintingStyle.fill;

    const paddingLeft = 50.0;
    const paddingBottom = 40.0;
    const paddingRight = 24.0;
    final w = size.width - paddingLeft - paddingRight; 
    final h = size.height - paddingBottom;

    final minDataValue = dataPoints.map((p) => p.recordedValue).reduce(math.min);
    final maxDataValue = dataPoints.map((p) => p.recordedValue).reduce(math.max);
    
    double rangeDelta = maxDataValue - minDataValue;
    if (rangeDelta == 0.0) rangeDelta = maxDataValue == 0.0 ? 3.0 : maxDataValue * 0.2;

    double stepSize = _getNiceStep(rangeDelta, 4);
    double renderMinY = (minDataValue / stepSize).floor() * stepSize;

    while (renderMinY + stepSize * 3 < maxDataValue) {
      rangeDelta *= 1.2;
      stepSize = _getNiceStep(rangeDelta, 4);
      renderMinY = (minDataValue / stepSize).floor() * stepSize;
    }
    if (renderMinY < 0 && minDataValue >= 0) renderMinY = 0.0;

    final renderMaxY = renderMinY + stepSize * 3;
    final renderRangeY = renderMaxY - renderMinY;

    double getX(int index) => paddingLeft + (index * (w / (dataPoints.length - 1).clamp(1, 999)));
    double getY(double val) => h - (((val - renderMinY) / renderRangeY).clamp(0.0, 1.0) * h);

    for (int i = 0; i <= 3; i++) {
      final val = renderMinY + (stepSize * i);
      final yPos = getY(val);
      
      if (i > 0 && i < 3) {
        double currentX = paddingLeft;
        while (currentX < size.width - paddingRight) {
          canvas.drawLine(Offset(currentX, yPos), Offset(currentX + 5, yPos), paintGrid);
          currentX += 10;
        }
      }
      
      final textSpan = TextSpan(text: _formatNumber(val), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12));
      final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 12, yPos - (textPainter.height / 2)));
    }

    canvas.drawLine(Offset(paddingLeft, 0), Offset(paddingLeft, h), paintAxis);
    canvas.drawLine(Offset(paddingLeft, h), Offset(size.width - paddingRight, h), paintAxis);

    final path = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final x = getX(i);
      final y = getY(dataPoints[i].recordedValue);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final extractedPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractedPath, paintLine);

      final drawPointLimit = (dataPoints.length * progress).floor() + 1;
      final maxLabels = 12;
      final dynamicSkipLabel = (dataPoints.length / maxLabels).ceil().clamp(1, 999);

      for (int i = 0; i < drawPointLimit; i++) {
        if (i >= dataPoints.length) break;
        final pointOffset = Offset(getX(i), getY(dataPoints[i].recordedValue));
        
        canvas.drawCircle(pointOffset, 4, paintCircleOut); 
        canvas.drawCircle(pointOffset, 2, paintCircleIn);

        if (i % dynamicSkipLabel == 0 || i == dataPoints.length - 1) {
          final date = DateTime.fromMillisecondsSinceEpoch(dataPoints[i].timestampMillis);
          String dateStr;
          
          if (timeRange == ChartTimeRange.YEAR) {
            dateStr = DateFormat("MMM", localeCode).format(date);
          } else {
            dateStr = DateFormat("dd/MM").format(date);
          }

          final textSpan = TextSpan(text: dateStr, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold));
          final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr)..layout();
          textPainter.paint(canvas, Offset(pointOffset.dx - (textPainter.width / 2), h + 12));
        }
      }
    }

    if (highlightIndex >= 0 && highlightIndex < dataPoints.length && progress > 0.99) {
      final x = getX(highlightIndex);
      final y = getY(dataPoints[highlightIndex].recordedValue);
      
      double currentY = 0;
      final dashPaint = Paint()..color = colorScheme.onSurface.withValues(alpha: 0.6)..strokeWidth = 1.5;
      while (currentY < h) {
        canvas.drawLine(Offset(x, currentY), Offset(x, currentY + 5), dashPaint);
        currentY += 10;
      }

      final date = DateTime.fromMillisecondsSinceEpoch(dataPoints[highlightIndex].timestampMillis);
      
      final dateStr = timeRange == ChartTimeRange.YEAR 
          ? DateFormat("MMMM yyyy", localeCode).format(date) 
          : DateFormat("dd MMM yyyy", localeCode).format(date);

      final valNum = dataPoints[highlightIndex].recordedValue;
      final valStr = isTimeFormat ? "${valNum~/60}m ${(valNum%60).toInt().toString().padLeft(2,'0')}s" : valNum.toStringAsFixed(1);
      
      final textSpan = TextSpan(
        children: [
          TextSpan(text: "$dateStr\n", style: TextStyle(color: colorScheme.surface.withValues(alpha: 0.8), fontSize: 11)),
          TextSpan(text: "$valStr $unitLabel", style: TextStyle(color: colorScheme.surface, fontSize: 14, fontWeight: FontWeight.w900)),
        ]
      );
      
      final textPainter = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center)..layout();
      
      double boxCenter = x;
      if (boxCenter - (textPainter.width / 2) < paddingLeft) boxCenter = paddingLeft + (textPainter.width / 2);
      if (boxCenter + (textPainter.width / 2) > size.width - paddingRight) boxCenter = size.width - paddingRight - (textPainter.width / 2);

      final boxRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxCenter - (textPainter.width / 2) - 12, y - textPainter.height - 24, textPainter.width + 24, textPainter.height + 12),
        const Radius.circular(8)
      );
      
      canvas.drawShadow(Path()..addRRect(boxRect), Colors.black, 4, false);
      canvas.drawRRect(boxRect, Paint()..color = colorScheme.onSurface);
      
      final arrowPath = Path()..moveTo(boxCenter - 6, y - 12)..lineTo(boxCenter + 6, y - 12)..lineTo(boxCenter, y - 6)..close();
      canvas.drawPath(arrowPath, Paint()..color = colorScheme.onSurface);

      textPainter.paint(canvas, Offset(boxCenter - (textPainter.width / 2), y - textPainter.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _AdvancedChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.highlightIndex != highlightIndex || oldDelegate.dataPoints != dataPoints;
  }
}

// ========================================================================================
// => GÓC CHUYỂN DỜI CỦA BẠN (CÓ THỂ CẮT VÀ ĐEM ĐI NƠI KHÁC VỀ SAU)
// ========================================================================================

class RecoveryUIData {
  final String label;
  final MuscleRecoveryStatus status;
  RecoveryUIData(this.label, this.status);
}

class RecoveryBarChart extends StatelessWidget {
  final List<RecoveryUIData> recoveryDataList;

  const RecoveryBarChart({super.key, required this.recoveryDataList});

  void _showInfoDialog(BuildContext context, ColorScheme colorScheme) {
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
            Text(t.workout.desc_warn_muscle_info_general, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 16),
            _buildInfoZone(Theme.of(context).gymColors.success, t.workout.title_warn_muscle_zone_green, t.workout.desc_warn_muscle_zone_green, context),
            const SizedBox(height: 12),
            _buildInfoZone(Theme.of(context).gymColors.warning, t.workout.title_warn_muscle_zone_yellow, t.workout.desc_warn_muscle_zone_yellow, context),
            const SizedBox(height: 12),
            _buildInfoZone(Theme.of(context).colorScheme.error, t.workout.title_warn_muscle_zone_red, t.workout.desc_warn_muscle_zone_red, context),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(), 
          child: Text(t.common.understood, style: const TextStyle(fontWeight: FontWeight.bold))
        )
      ],
    );
  }

  Widget _buildInfoZone(Color color, String title, String desc, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.of(context).textScaler;

    double maxLabelWidth = 0;
    const labelStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    
    for (var data in recoveryDataList) {
      final textPainter = TextPainter(
        text: TextSpan(text: t.translateDynamic(data.label), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      
      final widthWithBuffer = textPainter.width + 4.0;
      
      if (widthWithBuffer > maxLabelWidth) {
        maxLabelWidth = widthWithBuffer;
      }
    }

    // Giới hạn max width lên 40% để có không gian thở cho text
    final double maxAllowedWidth = screenWidth * 0.40;
    final double finalLabelWidth = maxLabelWidth > maxAllowedWidth ? maxAllowedWidth : maxLabelWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  t.workout.title_recovery_status.trim(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                )
              ),
              IconButton(
                icon: Icon(Symbols.info, color: colorScheme.primary),
                onPressed: () => _showInfoDialog(context, colorScheme),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32), 
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        
        Card(
          elevation: 4, 
          color: colorScheme.surface, 
          margin: EdgeInsets.zero, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 14.0),
            child: Column(
              children: recoveryDataList.map((data) => SegmentedRecoveryBar(
                recoveryUIDataItem: data,
                labelWidth: finalLabelWidth,
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class SegmentedRecoveryBar extends StatefulWidget {
  final RecoveryUIData recoveryUIDataItem;
  final double labelWidth;

  const SegmentedRecoveryBar({
    super.key, 
    required this.recoveryUIDataItem,
    required this.labelWidth,
  });

  @override
  State<SegmentedRecoveryBar> createState() => _SegmentedRecoveryBarState();
}

class _SegmentedRecoveryBarState extends State<SegmentedRecoveryBar> {
  Timer? _timer;
  int _currentSystemTimeMillis = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _currentSystemTimeMillis = DateTime.now().millisecondsSinceEpoch);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = widget.recoveryUIDataItem.status;
    
    int dynamicPercent = 100;
    double remainingHours = 0.0;

    if (status.initialFatigue > 0 && status.recoveryRate > 0 && status.lastTrainedDate > 0) {
      final exactHoursPassed = (_currentSystemTimeMillis - status.lastTrainedDate) / 3600000.0;
      final safeHours = exactHoursPassed < 0 ? 0.0 : exactHoursPassed;
      
      final currentFatigue = status.initialFatigue * math.exp(-status.recoveryRate * safeHours);
      final trueRecovery = 100.0 - currentFatigue;
      
      dynamicPercent = ((trueRecovery / 95.0) * 100.0).toInt().clamp(0, 100);

      const targetFatigue = 5.0;
      if (currentFatigue > targetFatigue) {
        final totalHoursReq = -math.log(targetFatigue / status.initialFatigue) / status.recoveryRate;
        remainingHours = totalHoursReq - safeHours;
      }
    }

    final percent = dynamicPercent;
    final progressColor = percent >= 80 
        ? Theme.of(context).gymColors.success 
        : (percent >= 40 ? Theme.of(context).gymColors.warning : colorScheme.error);
    
    String timeString;
    if (remainingHours <= 0) {
      timeString = ""; 
    } else {
      final int totalSeconds = (remainingHours * 3600).toInt();
      final h = totalSeconds ~/ 3600;
      final m = (totalSeconds % 3600) ~/ 60;
      final s = totalSeconds % 60;
      timeString = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bọc FittedBox, giới hạn 1 dòng để tự động thu nhỏ text thay vì rớt dòng
          SizedBox(
            width: widget.labelWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                t.translateDynamic(widget.recoveryUIDataItem.label), 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1, 
              ),
            ),
          ),
          const SizedBox(width: 10),
          
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GymAnimatedProgressBar(
                  progress: percent / 100.0, 
                  color: progressColor,
                  trackColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  height: 14.0, 
                ),
                if (timeString.isNotEmpty) 
                  Text(
                    timeString,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w900,
                      fontSize: 11, 
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          
          // Bọc FittedBox cho % chống text scaling gây overflow
          SizedBox(
            width: 44, 
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '$percent%', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: progressColor),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutMiniPlayer extends StatelessWidget {
  final WorkoutSession currentActiveSession;
  final ActiveSessionCubit activeSessionCubit;
  final VoidCallback onResumeSessionClick;

  const WorkoutMiniPlayer({super.key, required this.currentActiveSession, required this.activeSessionCubit, required this.onResumeSessionClick});

  void _showCancelDialog(BuildContext context) async {
    final confirmed = await GymDialog.showDestructive(
      context: context,
      title: t.workout.title_mini_player_cancel_dialog,
      message: t.workout.msg_mini_player_cancel_warn,
      cancelText: t.common.back,
      confirmText: t.workout.btn_mini_player_confirm_delete,
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      activeSessionCubit.cancelWorkout();
    }
  }

  String _formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final formattedMS = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return h > 0 ? '$h:$formattedMS' : formattedMS;
  }

  @override
  Widget build(BuildContext context) {  
    final colorScheme = Theme.of(context).colorScheme;
    final isTablet = ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);

    return BlocBuilder<ActiveSessionCubit, ActiveSessionState>(
      bloc: activeSessionCubit,
      builder: (context, state) {
        final session = state.activeWorkout ?? currentActiveSession;
        
        final workoutTime = state.workoutTimerSeconds;
        final restTime = state.restTimerSeconds;
        final bool isResting = restTime > 0;
        final activeTimerColor = workoutTime > 240 * 60 ? colorScheme.error : (workoutTime > 120 * 60 ? Theme.of(context).gymColors.warning : colorScheme.primary);

        final targetData = activeSessionCubit.getNextTarget();
        final isAllDone = targetData == null && session.exercises.isNotEmpty;

        String statusText = '';
        
        if (isResting) {
          statusText = '${t.workout.status_resting} ${_formatTime(restTime)}';
        } else {
          if (session.exercises.isEmpty) {
            statusText = t.workout.status_working;
          } else if (isAllDone) {
            statusText = t.workout.status_workout_done;
          } else if (targetData != null) {
            String rawName = targetData.exercise.exercise.name;
            String exName = t.translateDynamic(rawName);
            String setLabel = t.common.set;
            statusText = '$exName • $setLabel ${targetData.setIndex}/${targetData.exercise.sets.length}';
          }
        }

        Widget playerUI = Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest, 
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onResumeSessionClick, 
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center, 
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(t.translateDynamic(session.name), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (statusText.isNotEmpty) ...[
                                const SizedBox(height: 2), 
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8, height: 8, 
                                      decoration: BoxDecoration(color: isResting ? Theme.of(context).gymColors.warning : colorScheme.primary, shape: BoxShape.circle)
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        statusText, 
                                        style: TextStyle(fontSize: 13, color: isResting ? Theme.of(context).gymColors.warning : colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                                        maxLines: 1, overflow: TextOverflow.ellipsis
                                      ),
                                    ),
                                  ]
                                )
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        FittedBox(
                          fit: BoxFit.scaleDown, alignment: Alignment.centerRight,
                          child: Text(_formatTime(workoutTime), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: activeTimerColor, fontFeatures: const [FontFeature.tabularFigures()])),
                        ),

                        IconButton(
                          icon: Icon(Icons.close, color: colorScheme.error, size: 25), padding: const EdgeInsets.all(6), constraints: const BoxConstraints(),
                          onPressed: () { HapticFeedback.heavyImpact(); _showCancelDialog(context); } 
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              Positioned(
                top: 6, left: 0, right: 0, 
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                  ),
                ),
              ),
            ],
          ),
        );

        if (isTablet) {
          return Align(alignment: Alignment.bottomRight, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: playerUI));
        }

        return playerUI;
      }
    );
  }
}