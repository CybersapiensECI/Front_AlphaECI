import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Dato de una barra del gráfico.
class BarDatum {
  const BarDatum({required this.label, required this.value, this.color});

  final String label;
  final int value;
  final Color? color;
}

/// Gráfico de barras animado, nativo (sin librerías): las barras crecen
/// desde la base con curva suave. Para dashboards y estadísticas.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.data,
    this.height = 140,
  });

  final List<BarDatum> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxValue = data.fold<int>(1, (m, d) => d.value > m ? d.value : m);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final datum in data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${datum.value}',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: datum.value / maxValue),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => Container(
                        height: (height - 58) * t,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              (datum.color ?? scheme.primary),
                              (datum.color ?? scheme.primary)
                                  .withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      datum.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Anillo de progreso con valor central. Para porcentajes destacados.
class RingStat extends StatelessWidget {
  const RingStat({
    super.key,
    required this.value,
    required this.label,
    this.size = 96,
    this.color,
  });

  /// 0.0 – 1.0
  final double value;
  final String label;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ringColor = color ?? scheme.tertiary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: t,
                    strokeWidth: size * 0.09,
                    strokeCap: StrokeCap.round,
                    backgroundColor: scheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  ),
                ),
                Text(
                  '${(t * 100).round()}%',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
