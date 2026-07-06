import 'package:flutter/material.dart';

import '../utils/breakpoints.dart';
import 'animated_bottom_nav.dart';
import 'gradient_scaffold.dart';

class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Shell de navegación adaptativo premium:
/// - ancho <  600: barra flotante glass (AnimatedBottomNav)
/// - ancho >= 600: NavigationRail (extendido en desktop >= 1024)
/// Fondo con blobs de marca en ambos casos.
/// Decisión por LayoutBuilder (ancho disponible), no por dispositivo.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.appBar,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < Breakpoints.tablet;
        final isDesktop = width >= Breakpoints.desktop;

        if (isMobile) {
          // extendBody false: la barra tiene su propio espacio,
          // no se superpone al contenido.
          return GradientScaffold(
            appBar: appBar,
            body: body,
            bottomNavigationBar: AnimatedBottomNav(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
          );
        }

        return GradientScaffold(
          appBar: appBar,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                extended: isDesktop,
                backgroundColor: Colors.transparent,
                labelType: isDesktop
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              // El contenido no se estira sin límite en pantallas anchas.
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Breakpoints.contentMaxWidth * 1.5,
                    ),
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
