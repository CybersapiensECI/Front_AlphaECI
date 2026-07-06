import 'package:flutter/material.dart';

import 'animations.dart';

/// Chip de interés con tinte de acento, selección animada y rebote
/// al tocar/hover. [accent] tiñe la selección (p. ej. color de categoría).
class InterestChip extends StatelessWidget {
  const InterestChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BouncyTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected && accent == null
              ? LinearGradient(colors: [scheme.primary, scheme.secondary])
              : null,
          color: selected ? accent : scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (accent ?? scheme.outline).withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
