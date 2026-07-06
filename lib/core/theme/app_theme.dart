import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Temas Material 3 con la paleta oficial AlphaECI.
/// ColorScheme explícito (la marca fija cada rol; fromSeed alteraría los tonos).
abstract final class AppTheme {
  static ThemeData get light => _build(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primaryLight,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryVariantLight,
          onPrimaryContainer: Colors.white,
          secondary: AppColors.primaryVariantLight,
          onSecondary: Colors.white,
          tertiary: AppColors.accentLight,
          onTertiary: AppColors.textPrimaryLight,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.textPrimaryLight,
          onSurfaceVariant: AppColors.secondaryGreyLight,
          outline: AppColors.secondaryGreyLight,
        ),
        background: AppColors.backgroundLight,
        textPrimary: AppColors.textPrimaryLight,
        secondaryGrey: AppColors.secondaryGreyLight,
      );

  static ThemeData get dark => _build(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.primaryDark,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryVariantDark,
          onPrimaryContainer: Colors.white,
          secondary: AppColors.primaryVariantDark,
          onSecondary: Colors.white,
          tertiary: AppColors.accentDark,
          onTertiary: AppColors.backgroundDark,
          error: AppColors.errorDark,
          onError: AppColors.backgroundDark,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
          onSurfaceVariant: AppColors.secondaryGreyDark,
          outline: AppColors.secondaryGreyDark,
        ),
        background: AppColors.backgroundDark,
        textPrimary: AppColors.textPrimaryDark,
        secondaryGrey: AppColors.secondaryGreyDark,
      );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Color background,
    required Color textPrimary,
    required Color secondaryGrey,
  }) {
    final textTheme = AppTypography.textTheme(textPrimary, secondaryGrey);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.secondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.tertiary.withValues(alpha: 0.25),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.tertiary.withValues(alpha: 0.25),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: TextStyle(color: background),
      ),
    );
  }
}
