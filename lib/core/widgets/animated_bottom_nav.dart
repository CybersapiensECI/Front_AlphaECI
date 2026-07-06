import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'adaptive_scaffold.dart' show AdaptiveDestination;

/// Barra de navegación inferior FIJA (ancho completo, espacio propio,
/// nunca se superpone al contenido). Cada ítem: ícono con píldora de
/// selección + label centrado debajo, siempre visible. Sin expansión
/// horizontal: con 6 destinos no hay overflow en pantallas de 360dp.
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
              top: BorderSide(
                color: scheme.outline.withValues(alpha: 0.25),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
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
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Píldora solo detrás del ícono: nunca crece a lo ancho.
          AnimatedContainer(
            duration: AppDurations.base,
            curve: AppCurves.enter,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              gradient: selected ? AppGradients.buttonOf(context) : null,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Icon(
              selected ? destination.selectedIcon : destination.icon,
              size: 22,
              color: selected ? Colors.white : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          // Label centrado bajo el ícono, siempre visible y legible.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              destination.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
