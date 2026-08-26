import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:material_symbols_icons/symbols.dart';

class GymDialog {
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    IconData? icon,
    Color? iconColor,
    Color? buttonColor,
    VoidCallback? onConfirm,
    bool useRootNavigator = true,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (ctx) => _buildStandardDialog(
        context: ctx,
        title: title,
        message: message,
        icon: icon ?? Symbols.info,
        iconColor: iconColor ?? Theme.of(ctx).colorScheme.primary,
        actions: [
          FilledButton(
            style: buttonColor != null 
                ? FilledButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                  ) 
                : null,
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            child: Text(buttonText ?? t.common.close, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
    bool useRootNavigator = true,
  }) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final primaryColor = isDestructive ? colorScheme.error : colorScheme.primary;
        final onPrimaryColor = isDestructive ? Colors.white : colorScheme.onPrimary;

        return _buildStandardDialog(
          context: ctx,
          title: title,
          message: message,
          icon: icon ?? (isDestructive ? Symbols.warning : Symbols.help),
          iconColor: iconColor ?? primaryColor,
          actions: [
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelText ?? t.common.cancel, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: onPrimaryColor,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText ?? t.common.confirm, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> showDestructive({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    IconData? icon,
    bool useRootNavigator = true,
  }) {
    return showConfirm(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon ?? Symbols.warning,
      iconColor: Theme.of(context).colorScheme.error,
      isDestructive: true,
      useRootNavigator: useRootNavigator,
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onConfirm,
    bool useRootNavigator = true,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => _buildStandardDialog(
        context: ctx,
        title: title,
        message: message,
        icon: Symbols.check_circle,
        iconColor: Theme.of(ctx).gymColors.success,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).gymColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            child: Text(buttonText ?? t.common.confirm, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Future<T?> showCustom<T>({
    required BuildContext context,
    Widget? titleWidget,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    EdgeInsetsGeometry? contentPadding,
    bool useRootNavigator = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        
        final screenWidth = MediaQuery.of(ctx).size.width;
        final isTablet = screenWidth > 600;
        final maxWidth = isTablet ? 450.0 : double.infinity;
        
        return StatefulBuilder(
          builder: (context, setState) {
            final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
            
            return Dialog(
              backgroundColor: colorScheme.surface,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              insetPadding: isTablet 
                  ? EdgeInsets.only(left: 40.0, right: 40.0, top: isKeyboardOpen ? 0.0 : 24.0, bottom: 0.0) 
                  : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: contentPadding ?? const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (titleWidget != null) ...[
                        titleWidget,
                        const SizedBox(height: 16),
                      ],
                      content,
                      if (actions != null && actions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        OverflowBar(
                          alignment: MainAxisAlignment.end,
                          spacing: 8,
                          overflowSpacing: 8,
                          children: actions,
                        )
                      ]
                    ],
                  ),
                ),
              ),
            );
          },
        ).animate().fade(duration: 300.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);
      },
    );
  }

  static Widget _buildStandardDialog({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required List<Widget> actions,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Đảm bảo responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 450.0 : double.infinity;
    
    return Dialog(
      backgroundColor: colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: iconColor),
              ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(height: 12),
              
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                ),
              ),
              
              const SizedBox(height: 12),
              Row(
                children: actions.map((a) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: a))).toList(),
              )
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 300.ms, curve: Curves.easeOutCubic).slideY(begin: 0.1, end: 0);
  }
}
