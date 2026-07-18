import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/design_tokens.dart';
import 'adaptive_scaffold.dart' show AdaptiveDestination;

/// Barra de navegación inferior FIJA (ancho completo, espacio propio,
/// nunca se superpone al contenido). Solo íconos por defecto: el
/// seleccionado se expande en una píldora que revela su nombre, para no
/// saturar la vista con seis labels a la vez.
class AnimatedBottomNav extends StatelessWidget {
  const AnimatedBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            // Más opaco que las cards glass: legibilidad ante todo.
            color: scheme.surface.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              // Cada ítem en un Expanded: con 7 tabs en pantallas angostas
              // un Row suelto se desbordaba y los últimos quedaban fuera
              // de la pantalla (intocables). Así todos comparten el ancho
              // disponible y siempre son alcanzables.
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AdaptiveDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      // Si el slot es angosto (7 tabs en un teléfono pequeño) la píldora
      // con texto no cabe: se muestra solo el ícono resaltado.
      final showLabel = selected && constraints.maxWidth >= 86;

      return InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Center(
          // AnimatedSize hace que el ancho crezca/encoja con fluidez cuando
          // el label aparece o desaparece del ítem seleccionado.
          child: AnimatedSize(
            duration: AppDurations.base,
            curve: AppCurves.enter,
            child: AnimatedContainer(
              duration: AppDurations.base,
              curve: AppCurves.enter,
              padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 16 : 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: selected ? AppGradients.buttonOf(context) : null,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Pop del ícono al quedar seleccionado.
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 22,
                color: selected ? Colors.white : scheme.onSurfaceVariant,
              )
                  .animate(target: selected ? 1 : 0)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.18, 1.18),
                    duration: 140.ms,
                    curve: Curves.easeOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1 / 1.18, 1 / 1.18),
                    duration: 220.ms,
                    curve: Curves.elasticOut,
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
