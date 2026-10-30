import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

const _buttonRadius = 12.0;
const _progressStrokeWidth = 2.5;
const _progressEdgeInset = 2.0;

double gymScrollProgress(double pixels, double maxScrollExtent) {
  if (maxScrollExtent <= 0) return 0;
  return (pixels / maxScrollExtent).clamp(0.0, 1.0);
}

@visibleForTesting
Path gymScrollProgressPath(Size size) {
  const pathInset = _progressEdgeInset + _progressStrokeWidth / 2;
  final rect = (Offset.zero & size).deflate(pathInset);
  final radius = (_buttonRadius - pathInset)
      .clamp(0.0, rect.shortestSide / 2)
      .toDouble();
  final corner = Radius.circular(radius);

  return Path()
    ..moveTo(rect.left, rect.center.dy)
    ..lineTo(rect.left, rect.top + radius)
    ..arcToPoint(
      Offset(rect.left + radius, rect.top),
      radius: corner,
      clockwise: true,
    )
    ..lineTo(rect.right - radius, rect.top)
    ..arcToPoint(
      Offset(rect.right, rect.top + radius),
      radius: corner,
      clockwise: true,
    )
    ..lineTo(rect.right, rect.bottom - radius)
    ..arcToPoint(
      Offset(rect.right - radius, rect.bottom),
      radius: corner,
      clockwise: true,
    )
    ..lineTo(rect.left + radius, rect.bottom)
    ..arcToPoint(
      Offset(rect.left, rect.bottom - radius),
      radius: corner,
      clockwise: true,
    )
    ..lineTo(rect.left, rect.center.dy)
    ..close();
}

class GymScrollToTopButton extends StatelessWidget {
  final ScrollController controller;

  const GymScrollToTopButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = GymMotion.reduceMotion(context);
    final showAfter = MediaQuery.sizeOf(context).height * 0.5;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final position = _readyScrollPosition(controller);
        final pixels = position?.pixels ?? 0.0;
        final progress = gymScrollProgress(
          pixels,
          position?.maxScrollExtent ?? 0.0,
        );
        final show = pixels > showAfter;
        const buttonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_buttonRadius)),
        );

        return IgnorePointer(
          ignoring: !show,
          child: ExcludeSemantics(
            excluding: !show,
            child: AnimatedScale(
              scale: show ? 1 : 0,
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Tooltip(
                message: t.common.scroll_to_top,
                excludeFromSemantics: true,
                child: Semantics(
                  button: true,
                  label: t.common.scroll_to_top,
                  excludeSemantics: true,
                  child: SizedBox.square(
                    dimension: 48,
                    child: Material(
                      color: colorScheme.primary,
                      elevation: 4,
                      shape: buttonShape,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        customBorder: buttonShape,
                        onTap: () {
                          final activePosition = _readyScrollPosition(
                            controller,
                          );
                          if (activePosition == null) return;
                          if (reduceMotion) {
                            activePosition.jumpTo(0);
                          } else {
                            activePosition.animateTo(
                              0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: CustomPaint(
                          key: const ValueKey('gym-scroll-progress'),
                          foregroundPainter: _ShapeProgressPainter(
                            progress: progress,
                            color: colorScheme.onPrimary,
                            backgroundColor: colorScheme.onPrimary.withValues(
                              alpha: 0.24,
                            ),
                          ),
                          child: Icon(
                            Symbols.keyboard_double_arrow_up,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

ScrollPosition? _readyScrollPosition(ScrollController controller) {
  ScrollPosition? readyPosition;
  for (final position in controller.positions) {
    if (position.hasPixels && position.hasContentDimensions) {
      readyPosition = position;
    }
  }
  return readyPosition;
}

class _ShapeProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  const _ShapeProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final insetPath = gymScrollProgressPath(size);
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _progressStrokeWidth;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _progressStrokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(insetPath, backgroundPaint);
    if (progress <= 0) return;
    for (final metric in insetPath.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeProgressPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      backgroundColor != oldDelegate.backgroundColor;
}
