import 'package:flutter/material.dart';

import '../../domain/entities/mona.dart';
import 'locked_overlay.dart';
import 'mona_styles.dart';

/// Medalla de una mona: el arte real en assets/monas si existe en el
/// catálogo, o un ícono de respaldo. Bloqueada: imagen oscurecida y,
/// opcionalmente, cadenas + candado de esquina.
class MonaMedal extends StatelessWidget {
  const MonaMedal({
    super.key,
    required this.mona,
    required this.locked,
    required this.fallbackIcon,
    this.iconSize = 48,
    this.lockBadgeSize,
    this.chains = true,
  });

  final Mona mona;
  final bool locked;
  final IconData fallbackIcon;
  final double iconSize;

  /// Tamaño del candado de esquina; `null` = no dibujarlo.
  final double? lockBadgeSize;

  /// Cadenas cruzadas sobre la medalla. Desactivar cuando el contenedor
  /// que la envuelve ya dibuja sus propias cadenas a nivel de tarjeta.
  final bool chains;

  @override
  Widget build(BuildContext context) {
    final imageAsset = monaImageAsset(mona);
    final art = imageAsset == null
        ? Icon(
            locked ? Icons.lock_rounded : fallbackIcon,
            size: iconSize,
            color: Colors.white,
          )
        : Image.asset(
            imageAsset,
            fit: BoxFit.contain,
            color: locked ? Colors.black.withValues(alpha: 0.55) : null,
            colorBlendMode: locked ? BlendMode.darken : null,
            errorBuilder: (context, error, stack) => Icon(
              locked ? Icons.lock_rounded : fallbackIcon,
              size: iconSize,
              color: Colors.white,
            ),
          );

    if (!locked || (!chains && lockBadgeSize == null)) return art;

    return Stack(
      alignment: Alignment.center,
      children: [
        art,
        if (chains) const Positioned.fill(child: ChainsOverlay(opacity: 0.55)),
        if (lockBadgeSize != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: lockBadgeSize,
              height: lockBadgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: kChainSteel),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_rounded,
                size: lockBadgeSize! * 0.55,
                color: const Color(0xFF2B2F36),
              ),
            ),
          ),
      ],
    );
  }
}
