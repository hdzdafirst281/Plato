import 'package:flutter/material.dart';

class GymMarqueeText extends StatelessWidget {
  static const cycleDuration = Duration(seconds: 16);
  static const _pauseFraction = 1 / 16;
  static const _moveFraction = 7 / 16;

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Animation<double> animation;

  const GymMarqueeText(
    this.text, {
    super.key,
    required this.animation,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: effectiveStyle),
          maxLines: 1,
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout();

        if (!constraints.hasBoundedWidth ||
            painter.width <= constraints.maxWidth) {
          return Text(
            text,
            style: style,
            maxLines: 1,
            softWrap: false,
            textAlign: textAlign,
          );
        }

        final travel = painter.width - constraints.maxWidth;
        return Semantics(
          label: text,
          child: ExcludeSemantics(
            child: SizedBox(
              height: painter.height,
              child: RepaintBoundary(
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: animation,
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: painter.width,
                      maxWidth: painter.width,
                      minHeight: painter.height,
                      maxHeight: painter.height,
                      child: Text(
                        text,
                        style: style,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    builder: (context, child) => Transform.translate(
                      offset: Offset(-travel * _position(animation.value), 0),
                      transformHitTests: false,
                      child: child,
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

  double _position(double value) {
    if (value < _pauseFraction) return 0;
    if (value < _pauseFraction + _moveFraction) {
      final progress = ((value - _pauseFraction) / _moveFraction).clamp(
        0.0,
        1.0,
      );
      return Curves.easeInOut.transform(progress);
    }
    if (value < _pauseFraction * 2 + _moveFraction) return 1;
    final progress =
        ((value - (_pauseFraction * 2 + _moveFraction)) / _moveFraction).clamp(
          0.0,
          1.0,
        );
    return 1 - Curves.easeInOut.transform(progress);
  }
}
