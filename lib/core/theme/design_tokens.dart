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
  static Color fill(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? scheme.surface.withValues(alpha: 0.55)
        : scheme.surface.withValues(alpha: 0.70);
  }

  /// Borde sutil.
  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.60);
  }

  static const blurSigma = 16.0;
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
