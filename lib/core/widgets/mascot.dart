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
    required this.stickerIndex,
    this.size = 72,
    this.fallbackIcon = Icons.pets,
  });

  final int stickerIndex;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    // Calcular fila y columna en la grilla 4x5
    final row = stickerIndex ~/ 4;
    final col = stickerIndex % 4;

    // Alignment va de -1.0 a 1.0
    // Columna 0 -> -1.0, Columna 1 -> -0.333, Columna 2 -> 0.333, Columna 3 -> 1.0
    // Fila 0 -> -1.0, Fila 1 -> -0.5, Fila 2 -> 0.0, Fila 3 -> 0.5, Fila 4 -> 1.0
    final x = -1.0 + (col * (2.0 / 3.0));
    final y = -1.0 + (row * 0.5);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: AppShadows.soft(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.none,
              alignment: Alignment(x, y),
              child: Image.asset(
                AppAssets.stickersSheet,
                width: size * 4,
                height: size * 5,
                fit: BoxFit.fill,
                errorBuilder: (_, _, _) =>
                    Icon(fallbackIcon, size: size * 0.5, color: scheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mascota grande para estados vacíos, con mensaje amistoso.
class MascotEmptyState extends StatelessWidget {
  const MascotEmptyState({
    super.key,
    required this.message,
    this.stickerIndex = AppAssets.stickerConfused,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final int stickerIndex;
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
            MascotSticker(stickerIndex: stickerIndex, size: 110),
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

/// Muestra un SnackBar flotante con el sticker de la mascota.
void showMascotSnackBar(BuildContext context, String message, int stickerIndex) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            MascotSticker(stickerIndex: stickerIndex, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
}
