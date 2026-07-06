import 'package:flutter/material.dart';

/// Tipografía centralizada. Cambiar aquí afecta toda la app.
abstract final class AppTypography {
  static TextTheme textTheme(Color textColor, Color secondaryColor) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textColor),
      bodyMedium: TextStyle(fontSize: 14, color: textColor),
      bodySmall: TextStyle(fontSize: 12, color: secondaryColor),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
