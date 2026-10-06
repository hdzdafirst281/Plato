import 'package:flutter/material.dart';

/// Shared visual hierarchy for top-level sections on the Workout screen.
class WorkoutSectionHeader extends StatelessWidget {
  final String title;
  final Widget? titleSuffix;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const WorkoutSectionHeader({
    super.key,
    required this.title,
    this.titleSuffix,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.primary, colors.tertiary],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (titleSuffix != null) ...[
                  const SizedBox(width: 12),
                  titleSuffix!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
