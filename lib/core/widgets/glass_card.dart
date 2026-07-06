import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'animations.dart';

/// Tarjeta glassmorphism: blur de fondo, relleno translúcido,
/// borde sutil y sombra suave. Con onTap gana microinteracción de press.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadii.lg,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.soft(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppGlass.fill(context),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppGlass.border(context)),
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
