import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografía centralizada. Cambiar aquí afecta toda la app.
/// Montserrat: titulares (geometría del logo AlphaECI).
/// Inter: cuerpo (alta legibilidad en tamaños pequeños).
abstract final class AppTypography {
  static TextTheme textTheme(Color textColor, Color secondaryColor) {
    TextStyle display(double size, FontWeight weight,
            {double? spacing, Color? color}) =>
        GoogleFonts.montserrat(
          fontSize: size,
          fontWeight: weight,
          color: color ?? textColor,
          letterSpacing: spacing,
        );

    TextStyle body(double size,
            {FontWeight weight = FontWeight.w400, Color? color}) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: color ?? textColor,
        );

    return TextTheme(
      displaySmall: display(36, FontWeight.w800, spacing: -0.5),
      headlineMedium: display(28, FontWeight.w700),
      headlineSmall: display(24, FontWeight.w700),
      titleLarge: display(20, FontWeight.w600),
      titleMedium: display(16, FontWeight.w600),
      bodyLarge: body(16),
      bodyMedium: body(14),
      bodySmall: body(12, color: secondaryColor),
      labelLarge: body(14, weight: FontWeight.w600),
    );
  }
}
