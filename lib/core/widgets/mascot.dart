import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_assets.dart';
import '../theme/design_tokens.dart';

/// Logo oficial (lobo + escudo). No recorta en círculo porque el logo
/// tiene forma de escudo con coronita — se muestra completo.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size * 1.35, // proporción real del escudo (522x706)
      child: Image.asset(
        AppAssets.logo,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.of(context),
            boxShadow: AppShadows.glow(scheme.primary),
          ),
          child:
              Icon(Icons.hub_outlined, size: size * 0.5, color: Colors.white),
        ),
      ),
    );
  }
}

/// Sticker de la mascota. Muestra la imagen sin fondo adicional.
/// Fallback a ícono si falta el asset.
class MascotSticker extends StatelessWidget {
  const MascotSticker({
    super.key,
    required this.asset,
    this.size = 72,
    this.fallbackIcon = Icons.pets,
    this.rounded = false,
  });

  final String asset;
  final double size;
  final IconData fallbackIcon;

  /// El PNG del sticker es un recorte irregular que llega casi hasta los
  /// bordes de su lienzo cuadrado: junto a tarjetas y avatares circulares
  /// se ve "cuadrado". Con [rounded] se enmarca en una insignia circular
  /// (sin recortar el arte, solo con relleno) para que combine con el
  /// resto de la UI.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Center(
        child: Icon(fallbackIcon, size: size * 0.5, color: scheme.primary),
      ),
    );

    if (!rounded) {
      return SizedBox(width: size, height: size, child: image);
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHigh,
      ),
      child: image,
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
            // Balanceo suave en loop (interno) + entrada elástica única
            // (externo): dos controllers separados, el vacío se siente
            // vivo sin re-disparar la entrada.
            MascotSticker(asset: asset, size: 110)
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .rotate(
                  begin: -0.015,
                  end: 0.015,
                  duration: 1800.ms,
                  curve: Curves.easeInOut,
                )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 200.ms),
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
void showMascotSnackBar(BuildContext context, String message, String asset) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Pop del sticker al aparecer el aviso.
            MascotSticker(asset: asset, size: 40)
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(width: 12),
            Flexible(
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
