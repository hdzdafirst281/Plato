import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';

class StreakIcon extends StatelessWidget {
  final int streak;
  final double size;

  const StreakIcon({
    super.key,
    required this.streak,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final gymColors = Theme.of(context).gymColors;

    final fire1Start = gymColors.streakGradientStart;
    final fire1End = gymColors.streakGradientEnd;

    final fire2Start = gymColors.fire2Start;
    final fire2End = gymColors.fire2End;
    
    final fire3Start = gymColors.fire3Start;
    final fire3End = gymColors.fire3End;
    
    final fireBreak = gymColors.fireBreakColor;

    String assetName;
    List<Color>? gradientColors;
    Color? solidColor;

    double iconScale = 1.0;
    if (streak == 0) {
      assetName = 'assets/svg/icons/fire_break.svg';
      solidColor = fireBreak;
      iconScale = 0.8;
    } else if (streak < 50) {
      assetName = 'assets/svg/icons/fire1.svg';
      gradientColors = [fire1Start, fire1End];
      iconScale = 0.75;
    } else if (streak < 100) {
      assetName = 'assets/svg/icons/fire2.svg';
      gradientColors = [fire2Start, fire2End];
      iconScale = 1.0;
    } else {
      assetName = 'assets/svg/icons/fire3.svg';
      gradientColors = [fire3Start, fire3End];
      iconScale = 1.3;
    }

    // Use SizedBox to force a strict, consistent size for all SVG assets
    Widget svg = SizedBox(
      width: size,
      height: size,
      child: Transform.scale(
        scale: iconScale,
        child: SvgPicture.asset(
          assetName,
          fit: BoxFit.contain,
          // Using Colors.white (or any solid color) so ShaderMask can tint the opaque parts (the drawing)
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );

    // Apply gradient to the SVG drawing itself
    // BlendMode.srcIn colors the opaque parts (the icon drawing) and keeps the transparent parts (background) transparent.
    if (gradientColors != null) {
      final colors = gradientColors;
      svg = ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcIn,
        child: svg,
      );
    } else {
      final color = solidColor ?? Colors.transparent;
      svg = ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            colors: [color, color],
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcIn,
        child: svg,
      );
    }

    return svg;
  }
}
