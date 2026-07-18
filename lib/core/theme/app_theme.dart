import 'package:flutter/material.dart';

import 'colors.dart';

/// Academic Precision Material 3 theme.
///
/// Built from the color and typography tokens in
/// `.planning/reference/ui-screens/academic_precision/DESIGN.md`.
///
/// Note: no Inter `.ttf` asset is bundled in Phase 1 (none provided in the
/// repo), so `fontFamily: 'Inter'` below falls back to the platform default
/// (Roboto on Android). This is acceptable per SKELETON.md's documented
/// scope, not a defect — bundling the real font is a later cosmetic pass.
class AppTheme {
  AppTheme._();

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.02,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.01,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 17,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.2,
    ),
  );

  // DESIGN.md Shapes: "All buttons must be fully pill-shaped (100px or
  // higher radius)".
  static final BorderRadius _pillRadius = BorderRadius.circular(999);

  // DESIGN.md Components > Cards / Product Tiles: "18px corner radius" for
  // utility cards — the concrete component spec overrides the abstract
  // `rounded.lg` (32px) token scale.
  static final BorderRadius _cardRadius = BorderRadius.circular(18);

  // DESIGN.md Shapes: "Search and text fields use a 12px corner radius".
  static final BorderRadius _inputRadius = BorderRadius.circular(12);

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      brightness: Brightness.light,
      primary: AppColors.kPrimaryContainer, // Action Blue #0066cc
      onPrimary: AppColors.kOnPrimary,
      primaryContainer: AppColors.kPrimaryContainer,
      onPrimaryContainer: AppColors.kOnPrimaryContainer,
      secondary: AppColors.kSecondary,
      onSecondary: AppColors.kOnSecondary,
      secondaryContainer: AppColors.kSecondaryContainer,
      onSecondaryContainer: AppColors.kOnSecondaryContainer,
      tertiary: AppColors.kTertiary,
      onTertiary: AppColors.kOnTertiary,
      tertiaryContainer: AppColors.kTertiaryContainer,
      onTertiaryContainer: AppColors.kOnTertiaryContainer,
      error: AppColors.kError,
      onError: AppColors.kOnError,
      errorContainer: AppColors.kErrorContainer,
      onErrorContainer: AppColors.kOnErrorContainer,
      surface: AppColors.kSurface,
      onSurface: AppColors.kOnSurface,
      surfaceContainerHighest: AppColors.kSurfaceContainerHighest,
      onSurfaceVariant: AppColors.kOnSurfaceVariant,
      outline: AppColors.kOutline,
      outlineVariant: AppColors.kOutlineVariant,
      inverseSurface: AppColors.kInverseSurface,
      onInverseSurface: AppColors.kInverseOnSurface,
      inversePrimary: AppColors.kInversePrimary,
      surfaceTint: AppColors.kSurfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.kBackground,
      textTheme: _textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: _pillRadius),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.kSurfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: _cardRadius,
          side: BorderSide(color: AppColors.kOutlineVariant, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kSurfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.kInversePrimary,
      onPrimary: AppColors.kOnPrimaryFixedVariant,
      primaryContainer: AppColors.kOnPrimaryFixedVariant,
      onPrimaryContainer: AppColors.kPrimaryFixed,
      secondary: AppColors.kSecondaryFixedDim,
      onSecondary: AppColors.kOnSecondaryFixed,
      secondaryContainer: AppColors.kOnSecondaryFixedVariant,
      onSecondaryContainer: AppColors.kSecondaryFixed,
      tertiary: AppColors.kTertiaryFixedDim,
      onTertiary: AppColors.kOnTertiaryFixed,
      tertiaryContainer: AppColors.kOnTertiaryFixedVariant,
      onTertiaryContainer: AppColors.kTertiaryFixed,
      error: AppColors.kError,
      onError: AppColors.kOnError,
      errorContainer: AppColors.kOnErrorContainer,
      onErrorContainer: AppColors.kErrorContainer,
      surface: AppColors.kInverseSurface,
      onSurface: AppColors.kInverseOnSurface,
      surfaceContainerHighest: AppColors.kOnSurfaceVariant,
      onSurfaceVariant: AppColors.kOutlineVariant,
      outline: AppColors.kOutline,
      outlineVariant: AppColors.kOnSurfaceVariant,
      inverseSurface: AppColors.kSurface,
      onInverseSurface: AppColors.kOnSurface,
      inversePrimary: AppColors.kPrimaryContainer,
      surfaceTint: AppColors.kInversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.kInverseSurface,
      textTheme: _textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: _pillRadius),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.kInverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: _cardRadius,
          side: BorderSide(color: AppColors.kOnSurfaceVariant, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kOnSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: _inputRadius,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
