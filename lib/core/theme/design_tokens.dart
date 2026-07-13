import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tokens del design system AlphaECI. La paleta oficial NO cambia:
/// aquí solo viven valores derivados (gradientes, alphas, radios, sombras).

abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
}

abstract final class AppCurves {
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const spring = Curves.easeOutBack;
}

abstract final class AppGradients {
  /// Gradiente héroe de marca: primario → interactivo → acento.
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryLight,
      AppColors.primaryVariantLight,
      AppColors.accentLight,
    ],
  );

  static const heroDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryDark,
      AppColors.primaryVariantDark,
      AppColors.accentDark,
    ],
  );

  /// Gradiente de botón principal.
  static const button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryLight, AppColors.primaryVariantLight],
  );

  static const buttonDark = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryDark, AppColors.primaryVariantDark],
  );

  static LinearGradient of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? heroDark : hero;

  static LinearGradient buttonOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? buttonDark : button;
}

abstract final class AppGlass {
  /// Relleno de tarjeta glass según brillo del tema.
  static Color fill(BuildContext context) => fillFor(
        Theme.of(context).colorScheme,
        Theme.of(context).brightness == Brightness.dark,
      );

  /// Igual que [fill] pero sin context — para usar dentro del ThemeData.
  static Color fillFor(ColorScheme scheme, bool isDark) => isDark
      ? scheme.surface.withValues(alpha: 0.52)
      : scheme.surface.withValues(alpha: 0.68);

  /// Relleno más opaco para superficies flotantes sobre scrim oscuro
  /// (diálogos, menús, bottom sheets): prioriza legibilidad.
  static Color sheetFillFor(ColorScheme scheme, bool isDark) => isDark
      ? scheme.surface.withValues(alpha: 0.82)
      : scheme.surface.withValues(alpha: 0.86);

  /// Borde sutil (sheen de vidrio).
  static Color border(BuildContext context) => borderFor(
        Theme.of(context).brightness == Brightness.dark,
      );

  static Color borderFor(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.white.withValues(alpha: 0.65);

  /// Gradiente de brillo superior (reflejo de vidrio) para tarjetas grandes.
  static LinearGradient sheen(bool isDark) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.06 : 0.22),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6],
      );

  static const blurSigma = 18.0;
  static const blurSigmaStrong = 26.0;
}

/// Acentos por categoría de parche/publicación.
/// Extensión funcional de la paleta (solo headers, banners y chips de
/// categoría): la paleta oficial base NO cambia. Colores mid-tone que
/// funcionan sobre claro y oscuro con texto blanco.
abstract final class AppCategoryStyles {
  static const _fallback = (Icons.celebration_outlined, Color(0xFF3E6FA5));

  static const Map<String, (IconData, Color)> _styles = {
    'DEPORTE': (Icons.sports_soccer, Color(0xFF2FA36F)),
    'ESTUDIO': (Icons.menu_book_outlined, Color(0xFF3E6FA5)),
    'JUEGOS': (Icons.sports_esports_outlined, Color(0xFF7C5CD6)),
    'CULTURA': (Icons.theater_comedy_outlined, Color(0xFFE08A3C)),
    'COMIDA': (Icons.restaurant_outlined, Color(0xFFD95E5E)),
    // Categorías de eventos universitarios.
    'TECH': (Icons.memory_outlined, Color(0xFF5D95D1)),
    'BIENESTAR': (Icons.spa_outlined, Color(0xFF2F9E9E)),
    // Categorías del catálogo de intereses (profile-service).
    'TECNOLOGÍA': (Icons.memory_outlined, Color(0xFF5D95D1)),
    'ENTRETENIMIENTO': (Icons.sports_esports_outlined, Color(0xFF7C5CD6)),
  };

  static (IconData, Color) of(String? category) =>
      _styles[category?.toUpperCase()] ?? _fallback;

  /// Etiqueta legible y uniforme para chips/filtros: la API usa MAYÚSCULAS
  /// (DEPORTE, TECH) pero en UI siempre va Title case (Deporte, Tech).
  static String labelOf(String? category) {
    final c = category?.trim();
    if (c == null || c.isEmpty) return '';
    final lower = c.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}

abstract final class AppShadows {
  /// Sombra suave para tarjetas flotantes.
  static List<BoxShadow> soft(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.35
                : 0.08,
          ),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Glow de acento (botones destacados, FAB).
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}
