import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Core Shimmer wrapper that automatically applies the correct color scheme.
class GymShimmer extends StatelessWidget {
  final Widget child;
  final ShimmerDirection direction;

  const GymShimmer({
    super.key,
    required this.child,
    this.direction = ShimmerDirection.ltr,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      direction: direction,
      child: child,
    );
  }
}

/// A basic rectangular shimmer block with border radius.
class GymShimmerBlock extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const GymShimmerBlock({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Shimmer will override this color
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A basic circular shimmer block.
class GymShimmerCircle extends StatelessWidget {
  final double radius;

  const GymShimmerCircle({
    super.key,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A generic text line shimmer.
class GymTextShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const GymTextShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return GymShimmerBlock(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// A skeleton loader mimicking a list tile (Avatar/Icon + 2 lines of text).
class GymListTileShimmer extends StatelessWidget {
  final bool hasAvatar;
  final bool hasTrailing;
  final double avatarRadius;

  const GymListTileShimmer({
    super.key,
    this.hasAvatar = true,
    this.hasTrailing = false,
    this.avatarRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return GymShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasAvatar) ...[
              GymShimmerCircle(radius: avatarRadius),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GymTextShimmer(width: 150),
                  const SizedBox(height: 8),
                  const GymTextShimmer(width: 100, height: 12),
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: 16),
              const GymShimmerBlock(width: 24, height: 24, borderRadius: 4),
            ],
          ],
        ),
      ),
    );
  }
}

/// A skeleton loader mimicking a card (Image placeholder + Text).
class GymCardShimmer extends StatelessWidget {
  final double? width;
  final double height;
  final bool isList;

  const GymCardShimmer({
    super.key,
    this.width,
    this.height = 120,
    this.isList = false,
  });

  @override
  Widget build(BuildContext context) {
    return GymShimmer(
      child: Container(
        width: width,
        height: height,
        margin: isList ? const EdgeInsets.only(bottom: 16.0) : null,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.transparent, // Background should be transparent so we only shimmer the blocks
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2), // Outer border shimmer
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GymShimmerCircle(radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GymTextShimmer(width: 120),
                      const SizedBox(height: 6),
                      const GymTextShimmer(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            const GymTextShimmer(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            const GymTextShimmer(width: 200, height: 16),
          ],
        ),
      ),
    );
  }
}

/// Legacy wrapper for backwards compatibility, refactored to use the new core.
class GymBentoShimmer extends StatelessWidget {
  final double? fixedHeight;
  final ShimmerDirection direction;

  const GymBentoShimmer({
    super.key,
    this.fixedHeight = 220,
    this.direction = ShimmerDirection.ltr,
  });

  @override
  Widget build(BuildContext context) {
    Widget shimmerContent = GymShimmer(
      direction: direction,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: GymShimmerBlock(borderRadius: 10)),
                const SizedBox(height: 4),
                const Expanded(child: GymShimmerBlock(borderRadius: 10)),
                const SizedBox(height: 4),
                const Expanded(child: GymShimmerBlock(borderRadius: 10)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: GymShimmerBlock(borderRadius: 10)),
                const SizedBox(height: 4),
                const Expanded(child: GymShimmerBlock(borderRadius: 10)),
                const SizedBox(height: 4),
                const Expanded(child: GymShimmerBlock(borderRadius: 10)),
              ],
            ),
          ),
        ],
      ),
    );

    if (fixedHeight != null) {
      return SizedBox(height: fixedHeight, child: shimmerContent);
    }
    return shimmerContent;
  }
}