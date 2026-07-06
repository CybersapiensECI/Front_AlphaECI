import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'adaptive_scaffold.dart' show AdaptiveDestination;

/// Barra de navegación flotante glass con píldora de selección animada.
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
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: AppShadows.soft(context),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppGlass.blurSigma,
              sigmaY: AppGlass.blurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppGlass.fill(context),
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: AppGlass.border(context)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        accent: scheme,
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
    required this.accent,
    required this.onTap,
  });

  final AdaptiveDestination destination;
  final bool selected;
  final ColorScheme accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Center(
        child: AnimatedContainer(
          duration: AppDurations.base,
          curve: AppCurves.enter,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 16 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.buttonOf(context) : null,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 24,
                color: selected ? Colors.white : accent.onSurfaceVariant,
              ),
              AnimatedSize(
                duration: AppDurations.base,
                curve: AppCurves.enter,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          destination.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
