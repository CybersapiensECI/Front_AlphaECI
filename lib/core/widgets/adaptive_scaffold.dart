import 'package:flutter/material.dart';

import '../utils/breakpoints.dart';

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

/// Shell de navegación adaptativo:
/// - ancho <  600: NavigationBar inferior (móvil)
/// - ancho >= 600: NavigationRail lateral (compacto en tablet,
///   extendido en desktop >= 1024)
///
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
          return Scaffold(
            appBar: appBar,
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                extended: isDesktop,
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
