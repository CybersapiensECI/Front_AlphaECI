import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'animations.dart';

/// Tarjeta glassmorphism: blur real de fondo, relleno translúcido,
/// borde sutil, reflejo (sheen) superior y sombra suave. Con onTap gana
/// microinteracción de press. Usar para superficies destacadas (héroes);
/// las tarjetas de lista usan el CardTheme frosted global (más barato).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadii.lg,
    this.onTap,
    this.margin,
    this.strongBlur = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  /// Blur más intenso para paneles grandes (login, overlays).
  final bool strongBlur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sigma = strongBlur ? AppGlass.blurSigmaStrong : AppGlass.blurSigma;
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.soft(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppGlass.fill(context),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppGlass.border(context)),
            ),
            // Reflejo de vidrio superior (no interfiere con el relleno).
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: AppGlass.sheen(isDark),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return BouncyTap(onTap: onTap, child: card);
  }
}
