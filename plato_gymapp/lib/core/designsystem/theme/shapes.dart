import 'package:flutter/material.dart';

// =====================================================
// APP SHAPES SYSTEM
// Senior-Level Shape Tokens
// =====================================================

class AppShapes {
  AppShapes._();

  // =====================================================
  // RADIUS TOKENS
  // =====================================================

  // Micro radius
  // badges, tiny chips
  static const double xsRadius = 6;

  // Small components
  // buttons, inputs
  static const double smRadius = 10;

  // Standard cards
  // most surfaces
  static const double mdRadius = 16;

  // Large surfaces
  // dialogs, sheets
  static const double lgRadius = 22;

  // Hero containers
  // special widgets
  static const double xlRadius = 28;

  // Full rounded
  static const double pillRadius = 999;

  // =====================================================
  // BORDER RADIUS
  // =====================================================

  static const xs = BorderRadius.all(
    Radius.circular(xsRadius),
  );

  static const sm = BorderRadius.all(
    Radius.circular(smRadius),
  );

  static const md = BorderRadius.all(
    Radius.circular(mdRadius),
  );

  static const lg = BorderRadius.all(
    Radius.circular(lgRadius),
  );

  static const xl = BorderRadius.all(
    Radius.circular(xlRadius),
  );

  static const pill = BorderRadius.all(
    Radius.circular(pillRadius),
  );

  // =====================================================
  // SHAPES
  // =====================================================

  // Small components
  // chips / tags / compact buttons
  static final small = RoundedRectangleBorder(
    borderRadius: sm,
  );

  // Default cards
  static final medium = RoundedRectangleBorder(
    borderRadius: md,
  );

  // Dialogs / sheets
  static final large = RoundedRectangleBorder(
    borderRadius: lg,
  );

  // Hero sections / modals
  static final extraLarge = RoundedRectangleBorder(
    borderRadius: xl,
  );

  // Fully rounded
  static final pillShape = RoundedRectangleBorder(
    borderRadius: pill,
  );

  // =====================================================
  // SPECIALIZED COMPONENT SHAPES
  // =====================================================

  // Navigation bar
  static final navigationBar = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  );

  // Bottom sheet top radius only
  static const bottomSheetRadius = BorderRadius.vertical(
    top: Radius.circular(28),
  );

  // Modal radius
  static const modalRadius = BorderRadius.all(
    Radius.circular(24),
  );

  // Input radius
  static const inputRadius = BorderRadius.all(
    Radius.circular(14),
  );

  // Button radius
  static const buttonRadius = BorderRadius.all(
    Radius.circular(16),
  );

  // Card radius
  static const cardRadius = BorderRadius.all(
    Radius.circular(20),
  );

  // =====================================================
  // SHADOW PRESETS
  // Match new premium theme system
  // =====================================================

  // Soft shadow for light mode
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Elevated card shadow
  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Floating modal shadow
  static List<BoxShadow> largeShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  // =====================================================
  // DARK MODE SHADOWS
  // =====================================================

  // Dark mode needs subtler shadows
  static List<BoxShadow> darkSoftShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.22),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> darkMediumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.32),
      blurRadius: 32,
      offset: const Offset(0, 10),
    ),
  ];

  // =====================================================
  // BORDER HELPERS
  // =====================================================

  static Border subtleBorder(Color color) {
    return Border.all(
      color: color,
      width: 1,
    );
  }

  static Border strongBorder(Color color) {
    return Border.all(
      color: color,
      width: 1.4,
    );
  }

  // =====================================================
  // GLASS EFFECT HELPERS
  // =====================================================

  static BoxDecoration glass({
    required Color backgroundColor,
    required Color borderColor,
    BorderRadius borderRadius = lg,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius,
      border: Border.all(
        color: borderColor,
        width: 1,
      ),
    );
  }

  // =====================================================
  // CARD DECORATION HELPERS
  // =====================================================

  static BoxDecoration cardDecoration({
    required Color backgroundColor,
    required Color borderColor,
    required List<BoxShadow> shadows,
    BorderRadius borderRadius = cardRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius,
      border: Border.all(
        color: borderColor,
        width: 1,
      ),
      boxShadow: shadows,
    );
  }
}