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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    _NavItem(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () => onDestinationSelected(i),
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

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: onTap,
      // AnimatedSize hace que el ancho crezca/encoja con fluidez cuando
      // el label aparece o desaparece del ítem seleccionado.
      child: AnimatedSize(
        duration: AppDurations.base,
        curve: AppCurves.enter,
        child: AnimatedContainer(
          duration: AppDurations.base,
          curve: AppCurves.enter,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 16 : 12,
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
              if (selected) ...[
                const SizedBox(width: 8),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
