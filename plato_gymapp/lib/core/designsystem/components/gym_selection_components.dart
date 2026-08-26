import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:responsive_framework/responsive_framework.dart';

class GymSelectableCard extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const GymSelectableCard({super.key, required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    // Tối ưu Padding ngang cho màn hình nhỏ
    final double hPadding = ResponsiveValue<double>(context, 
      defaultValue: 12.0, 
      conditionalValues: [Condition.smallerThan(name: MOBILE, value: 8.0)]
    ).value;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56), 
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.2) : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: colors.primary, width: 2) : Border.all(color: colors.outlineVariant),
        ),
        child: Text(
          text, 
          textAlign: TextAlign.center, 
          maxLines: 3, 
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? colors.primary : colors.onSurface, 
            fontWeight: FontWeight.bold, 
            // Scale Down font size
            fontSize: ResponsiveValue<double>(context, 
              defaultValue: 13.0, 
              conditionalValues: [Condition.smallerThan(name: MOBILE, value: 11.0)]
            ).value
          )
        ),
      ),
    );
  }
}

class GymSelectableRow extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const GymSelectableRow({super.key, required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    final double hPadding = ResponsiveValue<double>(context, 
      defaultValue: 16.0, 
      conditionalValues: [Condition.smallerThan(name: MOBILE, value: 12.0)]
    ).value;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.2) : colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Symbols.radio_button_checked : Symbols.radio_button_unchecked,
              color: selected ? colors.primary : colors.onSurfaceVariant,
              size: ResponsiveValue<double>(context, defaultValue: 24.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 20.0)]).value,
            ),
            SizedBox(width: ResponsiveValue<double>(context, defaultValue: 12.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 8.0)]).value),
            Expanded(
              child: Text(
                text, 
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface, 
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: ResponsiveValue<double>(context, defaultValue: 14.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 13.0)]).value
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GymSingleSelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GymSingleSelectChip({super.key, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Ép giảm padding nội bộ của Chip trên màn hình nhỏ để đỡ tốn diện tích
    final double chipPadding = ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      padding: EdgeInsets.all(chipPadding),
      label: Text(
        label, 
        textAlign: TextAlign.center,
        maxLines: 3, 
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: ResponsiveValue<double>(context, defaultValue: 13.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 11.0)]).value, 
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant
        )
      ),
      selectedColor: colorScheme.primary.withValues(alpha: 0.2),
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: isSelected ? colorScheme.primary : Colors.transparent),
    );
  }
}

class GymMultiSelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GymMultiSelectChip({super.key, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final double chipPadding = ResponsiveValue<double>(context, defaultValue: 8.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 4.0)]).value;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      padding: EdgeInsets.all(chipPadding),
      label: Text(
        label, 
        textAlign: TextAlign.center,
        maxLines: 3, 
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: ResponsiveValue<double>(context, defaultValue: 13.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 11.0)]).value, 
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant
        )
      ),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: const BorderSide(color: Colors.transparent),
    );
  }
}