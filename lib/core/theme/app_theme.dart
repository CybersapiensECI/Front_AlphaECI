import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'design_tokens.dart';

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
    final isDark = colorScheme.brightness == Brightness.dark;
    // Superficies glass derivadas (translúcidas): los blobs del fondo se
    // filtran a través y dan el efecto frosted, sin blur por-widget (barato).
    final glassFill = AppGlass.fillFor(colorScheme, isDark);
    final sheetFill = AppGlass.sheetFillFor(colorScheme, isDark);
    final glassBorder = AppGlass.borderFor(isDark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      // Tarjetas frosted: relleno translúcido + sheen de borde claro.
      cardTheme: CardThemeData(
        color: glassFill,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: glassBorder),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: glassBorder),
        ),
        backgroundColor: glassFill,
        selectedColor: colorScheme.tertiary.withValues(alpha: 0.28),
        labelStyle: textTheme.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          // OJO: nunca Size.fromHeight aquí — su ancho mínimo INFINITO
          // revienta el layout de cualquier FilledButton dentro de un Row
          // ("BoxConstraints forces an infinite width").
          minimumSize: const Size(64, 48),
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
      // Inputs frosted: relleno translúcido + bordes suaves de vidrio.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colorScheme.tertiary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: colorScheme.outline.withValues(alpha: 0.25),
        indicator: UnderlineTabIndicator(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(width: 3, color: colorScheme.tertiary),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        extendedTextStyle: textTheme.labelLarge,
      ),
      // Superficies flotantes frosted (más opacas para legibilidad).
      dialogTheme: DialogThemeData(
        backgroundColor: sheetFill,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: glassBorder),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: sheetFill,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: glassBorder),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheetFill,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: sheetFill,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(sheetFill),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.tertiary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: glassFill,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.tertiary.withValues(alpha: 0.28),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: glassFill,
        indicatorColor: colorScheme.tertiary.withValues(alpha: 0.28),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: TextStyle(color: background),
      ),
    );
  }
}
