import 'package:flutter/material.dart';

/// Paleta fija del Dashboard de Estadísticas — identidad "gaming" oscura
/// definida explícitamente para este módulo. A diferencia del resto de la
/// app (que sigue el ColorScheme claro/oscuro vía [Theme.of]), estas
/// tarjetas usan siempre estos tonos exactos, sin importar el
/// light/dark mode global: es la identidad visual del Dashboard.
abstract final class StatsPalette {
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF181C23);
  static const primaryBlue = Color(0xFF5D93E8);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF2CC98A);
  static const orange = Color(0xFFFFB84D);
  static const border = Color(0xFF2A2F38);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB7BDC9);

  /// Gradiente sutil de la card principal (azul → azul apagado).
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A66), Color(0xFF16213A)],
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 16),
  ];
}
