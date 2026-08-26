import 'dart:ui';
import 'package:flutter/material.dart';

class GymSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? accentColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Default accent color if not provided
    final resolvedAccent = accentColor ?? colorScheme.primary;

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: resolvedAccent.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: resolvedAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: resolvedAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
