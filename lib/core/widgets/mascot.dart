import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/design_tokens.dart';

/// Logo oficial (lobo + escudo) en círculo con glow de marca.
/// Fallback al ícono anterior si el asset no está disponible.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadows.glow(scheme.primary),
      ),
      child: ClipOval(
        child: Image.asset(
          AppAssets.logo,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.of(context),
            ),
            child: Icon(Icons.hub_outlined,
                size: size * 0.5, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Sticker de la mascota en contenedor estilo pegatina (fondo blanco,
/// borde redondeado, sombra suave). Fallback a ícono si falta el asset.
class MascotSticker extends StatelessWidget {
  const MascotSticker({
    super.key,
    required this.asset,
    this.size = 72,
    this.fallbackIcon = Icons.pets,
  });

  final String asset;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: AppShadows.soft(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(fallbackIcon, size: size * 0.5, color: scheme.primary),
      ),
    );
  }
}

/// Mascota grande para estados vacíos, con mensaje amistoso.
class MascotEmptyState extends StatelessWidget {
  const MascotEmptyState({
    super.key,
    required this.message,
    this.asset = AppAssets.stickerConfused,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String asset;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotSticker(asset: asset, size: 110),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
