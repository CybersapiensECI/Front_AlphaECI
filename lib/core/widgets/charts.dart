import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'animations.dart';

/// Dato de una barra del gráfico.
class BarDatum {
  const BarDatum({required this.label, required this.value, this.color});

  final String label;
  final int value;
  final Color? color;
}

/// Gráfico de barras animado, nativo (sin librerías): las barras crecen
/// desde la base con curva suave y entrada escalonada. Para dashboards
/// y estadísticas.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({super.key, required this.data, this.height = 150});

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
          for (var i = 0; i < data.length; i++)
            Expanded(
              child: FadeSlideIn(
                delay: Duration(milliseconds: 90 * i),
                offset: const Offset(0, 0.25),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${data[i].value}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: data[i].value / maxValue),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, _) {
                          final color = data[i].color ?? scheme.primary;
                          return Container(
                            height: (height - 64) * t,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.lerp(color, Colors.white, 0.35)!,
                                  color,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Anillo de progreso con valor central y trazo en degradado. Para
/// porcentajes destacados (colección, completitud).
class RingStat extends StatelessWidget {
  const RingStat({
    super.key,
    required this.value,
    required this.label,
    this.size = 96,
    this.color,
    this.gradientColors,
    this.labelColor,
    this.valueColor,
  });

  /// 0.0 – 1.0
  final double value;
  final String label;
  final double size;
  final Color? color;
  final List<Color>? gradientColors;
  final Color? labelColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ringColor = color ?? scheme.tertiary;
    final gradient =
        gradientColors ??
        [Color.lerp(ringColor, Colors.white, 0.5)!, ringColor];

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
                    value: 1,
                    strokeWidth: size * 0.09,
                    backgroundColor: (labelColor ?? scheme.outline).withValues(
                      alpha: 0.15,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.transparent,
                    ),
                  ),
                ),
                ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => SweepGradient(
                    startAngle: -1.5708,
                    endAngle: 6.2832 - 1.5708,
                    colors: [...gradient, gradient.first],
                  ).createShader(bounds),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: t,
                      strokeWidth: size * 0.09,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${(t * 100).round()}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: labelColor),
        ),
      ],
    );
  }
}
