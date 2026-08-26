import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'colors.dart';
import 'shapes.dart';

// ==========================================
// 1. MỞ RỘNG MÀU SẮC (ThemeExtension)
// Tương đương với class CustomColors bên Kotlin
// ==========================================
class GymColors extends ThemeExtension<GymColors> {
  final Color goldRank;
  final Color chartLine;
  final Color success;
  final Color warning;
  
  // Màu nền Heatmap
  final Color heatmapBase;
  final Color heatmapUnused;
  final Color heatmapBorder;

  // Màu cường độ Heatmap (Bổ sung đầy đủ không trượt phát nào)
  final Color heatmapLow;
  final Color heatmapMed;
  final Color heatmapHigh;
  final Color heatmapExtreme;
  
  // ĐÃ FIX: Bổ sung 2 màu còn thiếu để UI gọi được
  final Color heatmapFreqDone;
  final Color heatmapSelected;
  
  final Color accentTeal;
  final Color accentPurple;

  final Color fireHexagon;
  final Color rankBronze;
  final Color rankSilver;
  final Color rankGold;
  final Color rankDiamond;

  final Color waterBgStart;
  final Color waterBgEnd;
  final Color waterEmptyDrop;
  final Color waterAccent;

  final Color podiumGoldStart;
  final Color podiumGoldEnd;
  final Color podiumSilverStart;
  final Color podiumSilverEnd;
  final Color podiumBronzeStart;
  final Color podiumBronzeEnd;
  
  final Color chestBannerStart;
  final Color chestBannerEnd;

  final Color streakGradientStart;
  final Color streakGradientEnd;
  final Color restGradientStart;
  final Color restGradientEnd;

  final Color xpGradientStart;
  final Color xpGradientEnd;

  final Color nutritionBgStart;
  final Color nutritionBgEnd;
  final Color nutritionEmpty;

  const GymColors({
    required this.goldRank,
    required this.chartLine,
    required this.success,
    required this.warning,
    required this.heatmapBase,
    required this.heatmapUnused,
    required this.heatmapBorder,
    required this.heatmapLow,
    required this.heatmapMed,
    required this.heatmapHigh,
    required this.heatmapExtreme,
    required this.heatmapFreqDone,
    required this.heatmapSelected,
    required this.accentTeal,
    required this.accentPurple,
    required this.fireHexagon,
    required this.rankBronze,
    required this.rankSilver,
    required this.rankGold,
    required this.rankDiamond,
    required this.waterBgStart,
    required this.waterBgEnd,
    required this.waterEmptyDrop,
    required this.waterAccent,
    required this.podiumGoldStart,
    required this.podiumGoldEnd,
    required this.podiumSilverStart,
    required this.podiumSilverEnd,
    required this.podiumBronzeStart,
    required this.podiumBronzeEnd,
    required this.chestBannerStart,
    required this.chestBannerEnd,
    required this.streakGradientStart,
    required this.streakGradientEnd,
    required this.restGradientStart,
    required this.restGradientEnd,
    required this.xpGradientStart,
    required this.xpGradientEnd,
    required this.nutritionBgStart,
    required this.nutritionBgEnd,
    required this.nutritionEmpty,
  });

  @override
  ThemeExtension<GymColors> copyWith({
    Color? goldRank, Color? chartLine, Color? success, Color? warning,
    Color? heatmapBase, Color? heatmapUnused, Color? heatmapBorder,
    Color? heatmapLow, Color? heatmapMed, Color? heatmapHigh, Color? heatmapExtreme,
    Color? heatmapFreqDone, Color? heatmapSelected,
    Color? accentTeal, Color? accentPurple,
    Color? fireHexagon, Color? rankBronze,
    Color? rankSilver, Color? rankGold, Color? rankDiamond,
    Color? waterBgStart, Color? waterBgEnd, Color? waterEmptyDrop, Color? waterAccent,
    Color? podiumGoldStart, Color? podiumGoldEnd, Color? podiumSilverStart, Color? podiumSilverEnd, Color? podiumBronzeStart, Color? podiumBronzeEnd,
    Color? chestBannerStart, Color? chestBannerEnd,
    Color? streakGradientStart, Color? streakGradientEnd, Color? restGradientStart, Color? restGradientEnd,
    Color? xpGradientStart, Color? xpGradientEnd,
    Color? nutritionBgStart, Color? nutritionBgEnd, Color? nutritionEmpty,
  }) {
    return GymColors(
      goldRank: goldRank ?? this.goldRank,
      chartLine: chartLine ?? this.chartLine,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      heatmapBase: heatmapBase ?? this.heatmapBase,
      heatmapUnused: heatmapUnused ?? this.heatmapUnused,
      heatmapBorder: heatmapBorder ?? this.heatmapBorder,
      heatmapLow: heatmapLow ?? this.heatmapLow,
      heatmapMed: heatmapMed ?? this.heatmapMed,
      heatmapHigh: heatmapHigh ?? this.heatmapHigh,
      heatmapExtreme: heatmapExtreme ?? this.heatmapExtreme,
      heatmapFreqDone: heatmapFreqDone ?? this.heatmapFreqDone,
      heatmapSelected: heatmapSelected ?? this.heatmapSelected,
      accentTeal: accentTeal ?? this.accentTeal,
      accentPurple: accentPurple ?? this.accentPurple,
      fireHexagon: fireHexagon ?? this.fireHexagon,
      rankBronze: rankBronze ?? this.rankBronze,
      rankSilver: rankSilver ?? this.rankSilver,
      rankGold: rankGold ?? this.rankGold,
      rankDiamond: rankDiamond ?? this.rankDiamond,
      waterBgStart: waterBgStart ?? this.waterBgStart,
      waterBgEnd: waterBgEnd ?? this.waterBgEnd,
      waterEmptyDrop: waterEmptyDrop ?? this.waterEmptyDrop,
      waterAccent: waterAccent ?? this.waterAccent,
      podiumGoldStart: podiumGoldStart ?? this.podiumGoldStart,
      podiumGoldEnd: podiumGoldEnd ?? this.podiumGoldEnd,
      podiumSilverStart: podiumSilverStart ?? this.podiumSilverStart,
      podiumSilverEnd: podiumSilverEnd ?? this.podiumSilverEnd,
      podiumBronzeStart: podiumBronzeStart ?? this.podiumBronzeStart,
      podiumBronzeEnd: podiumBronzeEnd ?? this.podiumBronzeEnd,
      chestBannerStart: chestBannerStart ?? this.chestBannerStart,
      chestBannerEnd: chestBannerEnd ?? this.chestBannerEnd,
      streakGradientStart: streakGradientStart ?? this.streakGradientStart,
      streakGradientEnd: streakGradientEnd ?? this.streakGradientEnd,
      restGradientStart: restGradientStart ?? this.restGradientStart,
      restGradientEnd: restGradientEnd ?? this.restGradientEnd,
      xpGradientStart: xpGradientStart ?? this.xpGradientStart,
      xpGradientEnd: xpGradientEnd ?? this.xpGradientEnd,
      nutritionBgStart: nutritionBgStart ?? this.nutritionBgStart,
      nutritionBgEnd: nutritionBgEnd ?? this.nutritionBgEnd,
      nutritionEmpty: nutritionEmpty ?? this.nutritionEmpty,
    );
  }

  @override
  ThemeExtension<GymColors> lerp(ThemeExtension<GymColors>? other, double t) {
    if (other is! GymColors) return this;
    return GymColors(
      goldRank: Color.lerp(goldRank, other.goldRank, t)!,
      chartLine: Color.lerp(chartLine, other.chartLine, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      heatmapBase: Color.lerp(heatmapBase, other.heatmapBase, t)!,
      heatmapUnused: Color.lerp(heatmapUnused, other.heatmapUnused, t)!,
      heatmapBorder: Color.lerp(heatmapBorder, other.heatmapBorder, t)!,
      heatmapLow: Color.lerp(heatmapLow, other.heatmapLow, t)!,
      heatmapMed: Color.lerp(heatmapMed, other.heatmapMed, t)!,
      heatmapHigh: Color.lerp(heatmapHigh, other.heatmapHigh, t)!,
      heatmapExtreme: Color.lerp(heatmapExtreme, other.heatmapExtreme, t)!,
      heatmapFreqDone: Color.lerp(heatmapFreqDone, other.heatmapFreqDone, t)!,
      heatmapSelected: Color.lerp(heatmapSelected, other.heatmapSelected, t)!,
      accentTeal: Color.lerp(accentTeal, other.accentTeal, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      fireHexagon: Color.lerp(fireHexagon, other.fireHexagon, t)!,
      rankBronze: Color.lerp(rankBronze, other.rankBronze, t)!,
      rankSilver: Color.lerp(rankSilver, other.rankSilver, t)!,
      rankGold: Color.lerp(rankGold, other.rankGold, t)!,
      rankDiamond: Color.lerp(rankDiamond, other.rankDiamond, t)!,
      waterBgStart: Color.lerp(waterBgStart, other.waterBgStart, t)!,
      waterBgEnd: Color.lerp(waterBgEnd, other.waterBgEnd, t)!,
      waterEmptyDrop: Color.lerp(waterEmptyDrop, other.waterEmptyDrop, t)!,
      waterAccent: Color.lerp(waterAccent, other.waterAccent, t)!,
      podiumGoldStart: Color.lerp(podiumGoldStart, other.podiumGoldStart, t)!,
      podiumGoldEnd: Color.lerp(podiumGoldEnd, other.podiumGoldEnd, t)!,
      podiumSilverStart: Color.lerp(podiumSilverStart, other.podiumSilverStart, t)!,
      podiumSilverEnd: Color.lerp(podiumSilverEnd, other.podiumSilverEnd, t)!,
      podiumBronzeStart: Color.lerp(podiumBronzeStart, other.podiumBronzeStart, t)!,
      podiumBronzeEnd: Color.lerp(podiumBronzeEnd, other.podiumBronzeEnd, t)!,
      chestBannerStart: Color.lerp(chestBannerStart, other.chestBannerStart, t)!,
      chestBannerEnd: Color.lerp(chestBannerEnd, other.chestBannerEnd, t)!,
      streakGradientStart: Color.lerp(streakGradientStart, other.streakGradientStart, t)!,
      streakGradientEnd: Color.lerp(streakGradientEnd, other.streakGradientEnd, t)!,
      restGradientStart: Color.lerp(restGradientStart, other.restGradientStart, t)!,
      restGradientEnd: Color.lerp(restGradientEnd, other.restGradientEnd, t)!,
      xpGradientStart: Color.lerp(xpGradientStart, other.xpGradientStart, t)!,
      xpGradientEnd: Color.lerp(xpGradientEnd, other.xpGradientEnd, t)!,
      nutritionBgStart: Color.lerp(nutritionBgStart, other.nutritionBgStart, t)!,
      nutritionBgEnd: Color.lerp(nutritionBgEnd, other.nutritionBgEnd, t)!,
      nutritionEmpty: Color.lerp(nutritionEmpty, other.nutritionEmpty, t)!,
    );
  }
}

// Khai báo cho Dark Mode
const gymColorsDark = GymColors(
  goldRank: xpGoldDark,
  chartLine: chartPurpleDark,
  success: successGreenDark,
  warning: warningOrangeDark,
  heatmapBase: heatmapBaseDark,
  heatmapUnused: heatmapUnusedDark,
  heatmapBorder: heatmapBorderDark,
  heatmapLow: heatmapLowDark,
  heatmapMed: heatmapMedDark,
  heatmapHigh: heatmapHighDark,
  heatmapExtreme: heatmapExtremeDark,
  heatmapFreqDone: heatmapFreqDoneDark,
  heatmapSelected: heatmapSelectedDark,
  accentTeal: accentTealDark,
  accentPurple: accentPurpleDark,
  fireHexagon: fireHexagonDark,
  rankBronze: rankBronzeDark,
  rankSilver: rankSilverDark,
  rankGold: rankGoldDark,
  rankDiamond: rankDiamondDark,
  waterBgStart: waterBgStartDark,
  waterBgEnd: waterBgEndDark,
  waterEmptyDrop: waterEmptyDropDark,
  waterAccent: waterAccentDark,
  podiumGoldStart: podiumGoldStartDark,
  podiumGoldEnd: podiumGoldEndDark,
  podiumSilverStart: podiumSilverStartDark,
  podiumSilverEnd: podiumSilverEndDark,
  podiumBronzeStart: podiumBronzeStartDark,
  podiumBronzeEnd: podiumBronzeEndDark,
  chestBannerStart: chestBannerStartDark,
  chestBannerEnd: chestBannerEndDark,
  streakGradientStart: streakGradientStartDark,
  streakGradientEnd: streakGradientEndDark,
  restGradientStart: restGradientStartDark,
  restGradientEnd: restGradientEndDark,
  xpGradientStart: xpGradientStartDark,
  xpGradientEnd: xpGradientEndDark,
  nutritionBgStart: nutritionBgStartDark,
  nutritionBgEnd: nutritionBgEndDark,
  nutritionEmpty: nutritionEmptyDark,
);

// Khai báo cho Light Mode
const gymColorsLight = GymColors(
  goldRank: xpGoldLight,
  chartLine: chartPurpleLight,
  success: successGreenLight,
  warning: warningOrangeLight,
  heatmapBase: heatmapBaseLight,
  heatmapUnused: heatmapUnusedLight,
  heatmapBorder: heatmapBorderLight,
  heatmapLow: heatmapLowLight,
  heatmapMed: heatmapMedLight,
  heatmapHigh: heatmapHighLight,
  heatmapExtreme: heatmapExtremeLight,
  heatmapFreqDone: heatmapFreqDoneLight,
  heatmapSelected: heatmapSelectedLight,
  accentTeal: accentTealLight,
  accentPurple: accentPurpleLight,
  fireHexagon: fireHexagonLight,
  rankBronze: rankBronzeLight,
  rankSilver: rankSilverLight,
  rankGold: rankGoldLight,
  rankDiamond: rankDiamondLight,
  waterBgStart: waterBgStartLight,
  waterBgEnd: waterBgEndLight,
  waterEmptyDrop: waterEmptyDropLight,
  waterAccent: waterAccentLight,
  podiumGoldStart: podiumGoldStartLight,
  podiumGoldEnd: podiumGoldEndLight,
  podiumSilverStart: podiumSilverStartLight,
  podiumSilverEnd: podiumSilverEndLight,
  podiumBronzeStart: podiumBronzeStartLight,
  podiumBronzeEnd: podiumBronzeEndLight,
  chestBannerStart: chestBannerStartLight,
  chestBannerEnd: chestBannerEndLight,
  streakGradientStart: streakGradientStartLight,
  streakGradientEnd: streakGradientEndLight,
  restGradientStart: restGradientStartLight,
  restGradientEnd: restGradientEndLight,
  xpGradientStart: xpGradientStartLight,
  xpGradientEnd: xpGradientEndLight,
  nutritionBgStart: nutritionBgStartLight,
  nutritionBgEnd: nutritionBgEndLight,
  nutritionEmpty: nutritionEmptyLight,
);

// ==========================================
// 2. KHỞI TẠO THEMEDATA CHÍNH
// ==========================================
class AppTheme {
  // -- Cấu hình Typography (Font Roboto) --
  static TextTheme get _textTheme => GoogleFonts.robotoTextTheme().copyWith(
    displayLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 57),
    headlineMedium: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
    titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
    titleMedium: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16), 
    bodyLarge: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16, height: 1.5),
    bodyMedium: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
    bodySmall: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
    labelLarge: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), 
    labelMedium: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    labelSmall: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5),
  );

  // -- THEME TỐI --
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryBlueDark, // Dùng màu xanh dịu
        surface: bgDark,
        surfaceContainer: surfaceDark,
        surfaceContainerHighest: const Color(0xFF2C2C2C),
        onPrimary: textWhite,
        onSurface: textWhite,
        onSurfaceVariant: textGrayDark,
        outline: const Color(0xFF8E9296),
        outlineVariant: Colors.grey.withValues(alpha: 0.2), 
        error: errorRedDark,
        onError: textWhite,
        errorContainer: errorRedDark.withValues(alpha: 0.15), 
        onErrorContainer: errorRedDark,
      ),
      textTheme: _textTheme.apply(bodyColor: textWhite, displayColor: textWhite),
      extensions: const [gymColorsDark],
      cardTheme: CardThemeData(shape: AppShapes.medium, color: surfaceDark),
      dialogTheme: DialogThemeData(shape: AppShapes.large, backgroundColor: surfaceDark),
    );
  }

  // -- THEME SÁNG --
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryBlueLight, // Dùng màu xanh bão hòa cao
        surface: bgLight,
        surfaceContainer: surfaceLight,
        surfaceContainerHighest: const Color(0xFFEEEEEE),
        onPrimary: textWhite,
        onSurface: textBlack,
        onSurfaceVariant: textGrayLight, 
        outline: const Color(0xFF72777A),
        outlineVariant: Colors.grey.shade300, 
        error: errorRedLight,
        onError: textWhite,
        errorContainer: errorRedLight.withValues(alpha: 0.1), 
        onErrorContainer: errorRedLight,
      ),
      textTheme: _textTheme.apply(bodyColor: textBlack, displayColor: textBlack),
      extensions: const [gymColorsLight],
      cardTheme: CardThemeData(shape: AppShapes.medium, color: surfaceLight),
      dialogTheme: DialogThemeData(shape: AppShapes.large, backgroundColor: surfaceLight),
    );
  }
}

// ==========================================
// 3. EXTENSION ĐỂ GỌI MÀU NHANH TRONG UI
// ==========================================
extension ThemeDataX on ThemeData {
  GymColors get gymColors => extension<GymColors>()!;
}