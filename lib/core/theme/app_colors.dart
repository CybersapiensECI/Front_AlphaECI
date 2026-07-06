import 'package:flutter/material.dart';

/// Paleta oficial AlphaECI — "Paleta de color, App Matching Social".
/// No usar colores hard-coded en widgets: siempre vía Theme.of(context).
abstract final class AppColors {
  // ── Modo claro ──────────────────────────────────────────────
  /// Botones principales, accesos, acciones importantes.
  static const primaryLight = Color(0xFF1A3F6D);

  /// Estados hover, enlaces, elementos interactivos.
  static const primaryVariantLight = Color(0xFF3E6FA5);

  /// Destacados sutiles, notificaciones, badges informativos.
  static const accentLight = Color(0xFF6FA8DC);

  /// Textos secundarios, íconos, bordes y divisores.
  static const secondaryGreyLight = Color(0xFFA6ADB6);

  /// Fondo principal de pantallas.
  static const backgroundLight = Color(0xFFF6F7F9);

  /// Tarjetas, modales, contenedores.
  static const surfaceLight = Color(0xFFFFFFFF);

  /// Textos principales, alta legibilidad.
  static const textPrimaryLight = Color(0xFF0F172A);

  // ── Modo oscuro ─────────────────────────────────────────────
  static const primaryDark = Color(0xFF1E4A7D);
  static const primaryVariantDark = Color(0xFF39639A);
  static const accentDark = Color(0xFF5D95D1);
  static const secondaryGreyDark = Color(0xFF7B828C);
  static const backgroundDark = Color(0xFF0E1117);
  static const surfaceDark = Color(0xFF161A22);
  static const textPrimaryDark = Color(0xFFF1F5F9);

  // ── Semánticos (no en paleta, necesarios para errores) ──────
  static const error = Color(0xFFB3261E);
  static const errorDark = Color(0xFFF2B8B5);
}
