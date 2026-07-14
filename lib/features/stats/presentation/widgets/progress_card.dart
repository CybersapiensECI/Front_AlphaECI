import 'package:flutter/material.dart';

import '../../../../core/theme/app_assets.dart';
import '../../../../core/widgets/charts.dart';
import '../../../../core/widgets/mascot.dart';
import '../../domain/entities/personal_stats.dart';
import 'stats_palette.dart';

/// Tarjeta de progreso: título, anillo de colección (protagonista) y
/// las métricas asociadas (XP total, monas desbloqueadas/total). No
/// repite nada del perfil — eso vive en [ProfileCard]. Misma identidad
/// visual (gradiente, esquinas 24, sombra) para que ambas tarjetas se
/// vean como parte del mismo sistema.
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.data});

  final PersonalStats data;

  @override
  Widget build(BuildContext context) {
    final profile = data.profile;
    final gamification = data.gamification;
    final progress = (gamification?.completionPercentage ?? 0) / 100;
    final totalMonas = gamification == null
        ? 0
        : gamification.totalMonasUnlocked +
              gamification.monasInProgress +
              gamification.monasLocked;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: StatsPalette.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StatsPalette.border),
        boxShadow: StatsPalette.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso del Estudiante',
            style: TextStyle(
              color: StatsPalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RingStat(
                value: progress,
                label: 'Colección',
                size: 120,
                color: StatsPalette.primaryBlue,
                gradientColors: const [StatsPalette.primaryBlue, Colors.white],
                labelColor: StatsPalette.textSecondary,
                valueColor: StatsPalette.textPrimary,
              ),
              const SizedBox(width: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatLine(
                    icon: Icons.bolt_rounded,
                    color: StatsPalette.orange,
                    value: profile?.xp ?? 0,
                    label: 'XP total',
                  ),
                  const SizedBox(height: 18),
                  _StatLine(
                    icon: Icons.emoji_events_rounded,
                    color: StatsPalette.purple,
                    value: gamification?.totalMonasUnlocked ?? 0,
                    suffix: totalMonas > 0 ? '/$totalMonas' : null,
                    label: 'Monas',
                  ),
                ],
              ),
              // Mascota grande cubriendo el espacio vacío restante — se
              // achica con FittedBox si la pantalla es angosta, nunca
              // desborda.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                    child: MascotSticker(
                      asset: AppAssets.stickerCool,
                      size: 118,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.suffix,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Text(
            '$v${suffix ?? ''}',
            style: const TextStyle(
              color: StatsPalette.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: StatsPalette.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
