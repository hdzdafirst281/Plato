import 'dart:math';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../screens/onboarding_screen.dart' show ChatMessage;

class ChatBubbleWidget extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme colorScheme;
  final String formattedText;
  final VoidCallback? onEdit;

  const ChatBubbleWidget({
    super.key,
    required this.message,
    required this.colorScheme,
    required this.formattedText,
    this.onEdit,
  });

  List<TextSpan> _buildHighlightedSpans(String text, ColorScheme colorScheme) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'<b>(.*?)</b>|<c_([a-fA-F0-9]{6})>(.*?)</c>');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      if (match.group(1) != null) { 
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w900), 
        ));
      } else if (match.group(2) != null && match.group(3) != null) { 
        final hexColor = match.group(2)!;
        final content = match.group(3)!;
        final color = Color(int.parse('FF$hexColor', radix: 16));
        spans.add(TextSpan(
          text: content,
          style: TextStyle(fontWeight: FontWeight.w900, color: color),
        ));
      }
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final bubbleRow = Padding(
      padding: EdgeInsets.only(bottom: message.customWidgetBuilder != null ? 0 : 16),
      child: Row(
        mainAxisAlignment: message.isApp ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isApp) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
              clipBehavior: Clip.hardEdge,
              child: Image.asset('assets/logo/logo_plato.png', fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Symbols.exercise, color: colorScheme.onPrimaryContainer, size: 14)
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          if (!message.isApp && message.isEditable && onEdit != null)
            IconButton(
              icon: Icon(Symbols.edit, size: 18, color: colorScheme.onSurfaceVariant),
              onPressed: onEdit,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(right: 8, bottom: 4),
            ),

          Flexible(
            child: Padding(
              padding: EdgeInsets.only(right: message.isApp ? 48.0 : 0.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: message.isApp ? colorScheme.surfaceContainerHighest : colorScheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: message.isApp ? const Radius.circular(4) : const Radius.circular(20),
                    bottomRight: !message.isApp ? const Radius.circular(4) : const Radius.circular(20),
                  )
                ),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(color: message.isApp ? colorScheme.onSurface : colorScheme.onPrimary, fontSize: 15, height: 1.4),
                    children: _buildHighlightedSpans(formattedText, colorScheme),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (message.customWidgetBuilder != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bubbleRow,
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.only(left: 40, right: 40), child: message.customWidgetBuilder!(context)), 
          ],
        )
      );
    }

    return bubbleRow;
  }
}

class TypingIndicatorWidget extends StatelessWidget {
  final ColorScheme colorScheme;
  const TypingIndicatorWidget({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
            clipBehavior: Clip.hardEdge,
            child: Image.asset('assets/logo/logo_plato.png', fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Symbols.exercise, color: colorScheme.onPrimaryContainer, size: 14)
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(20))
            ),
            child: SizedBox(
              width: 40, height: 10,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, val, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      return Opacity(
                        opacity: (sin((val * pi * 2) + (index * pi / 2)) + 1) / 2,
                        child: Container(width: 6, height: 6, decoration: BoxDecoration(color: colorScheme.onSurfaceVariant, shape: BoxShape.circle)),
                      );
                    }),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

class IconMiniCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const IconMiniCard({super.key, required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? colors.primary.withValues(alpha: 0.1) : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveValue<double>(context, defaultValue: 2.0, conditionalValues: [Condition.largerThan(name: MOBILE, value: 8.0)]).value, 
            vertical: 8
          ), 
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? colors.primary : Colors.transparent, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12)
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: ResponsiveValue<double>(context, defaultValue: 22.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 18.0)]).value, color: isSelected ? colors.primary : colors.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(
                title, 
                textAlign: TextAlign.center, 
                maxLines: 2, 
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                  fontSize: ResponsiveValue<double>(context, defaultValue: 11.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 10.0)]).value, 
                  height: 1.2, 
                  color: isSelected ? colors.primary : colors.onSurface
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VisualChoiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const VisualChoiceCard({super.key, required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? colors.primary.withValues(alpha: 0.1) : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveValue<double>(context, defaultValue: 2.0, conditionalValues: [Condition.largerThan(name: MOBILE, value: 12.0)]).value, 
            vertical: 8
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? colors.primary : Colors.transparent, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(16)
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: ResponsiveValue<double>(context, defaultValue: 28.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 24.0)]).value, color: isSelected ? colors.primary : colors.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                title, 
                textAlign: TextAlign.center,
                maxLines: 3, 
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                  fontSize: ResponsiveValue<double>(context, defaultValue: 12.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 11.0)]).value, 
                  height: 1.2, 
                  color: isSelected ? colors.primary : colors.onSurface
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaceCard extends StatelessWidget {
  final String? title;
  final IconData? topIcon;
  final String subtitle;
  final bool isSelected;
  final bool isSubtitlePrimary; 
  final VoidCallback onTap;

  const PaceCard({
    super.key,
    this.title, 
    this.topIcon, 
    required this.subtitle, 
    required this.isSelected, 
    required this.isSubtitlePrimary, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: isSelected ? 4 : 0, 
      shadowColor: Colors.black.withValues(alpha: 0.1),
      color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? colorScheme.primary : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (topIcon != null)
                Icon(topIcon, color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface, size: 22)
              else if (title != null)
                Text(
                  title!, 
                  textAlign: TextAlign.center, 
                  maxLines: 2,
                  softWrap: true,
                  style: TextStyle(
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 13
                  )
                ),
                
              const SizedBox(height: 6),
              
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle, 
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      color: isSelected 
                          ? colorScheme.onPrimary.withValues(alpha: 0.8) 
                          : (isSubtitlePrimary ? colorScheme.primary : colorScheme.onSurface), 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MacroItem({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Container(
              margin: const EdgeInsets.only(top: 5), 
              width: 8, height: 8, 
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label, 
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.2),
                maxLines: 2, 
                softWrap: true, 
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value, 
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, 
              fontWeight: FontWeight.w900, 
              fontSize: ResponsiveValue<double>(context, defaultValue: 18.0, conditionalValues: [Condition.smallerThan(name: MOBILE, value: 16.0)]).value
            )
          ),
        ),
      ],
    );
  }
}
