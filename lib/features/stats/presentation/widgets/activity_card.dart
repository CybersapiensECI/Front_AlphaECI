import 'package:flutter/material.dart';

import '../../../../core/config/env.dart';
import 'section_card.dart';
import 'stats_palette.dart';

/// "Actividad reciente": el backend (Estadisticas_Eci) aún no expone un
/// feed cronológico por usuario — PersonalStats solo trae contadores
/// agregados, sin fechas por evento. En modo demo mostramos ejemplos
/// ilustrativos (mismo patrón que MockStatsRepository); en producción,
/// un estado vacío honesto en vez de inventar historial.
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final items = Env.demoMode ? _demoActivity : const <_ActivityEntry>[];

    return SectionCard(
      icon: Icons.history_rounded,
      iconColor: StatsPalette.primaryBlue,
      title: 'Actividad reciente',
      child: items.isEmpty
          ? const _EmptyActivity()
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 20, color: StatsPalette.border),
                  _ActivityTile(entry: items[i]),
                ],
              ],
            ),
    );
  }
}

// TODO(demo): actividad ilustrativa. Eliminar cuando el backend exponga
// un endpoint real de historial por usuario.
const _demoActivity = <_ActivityEntry>[
  _ActivityEntry(
    icon: Icons.emoji_events_rounded,
    color: StatsPalette.purple,
    title: 'Desbloqueaste "Regio Lover"',
    subtitle: 'Hace 2 días',
  ),
  _ActivityEntry(
    icon: Icons.local_cafe_rounded,
    color: StatsPalette.orange,
    title: 'Visitaste Cafetería Regio',
    subtitle: 'Hoy',
  ),
  _ActivityEntry(
    icon: Icons.bolt_rounded,
    color: StatsPalette.green,
    title: '+20 XP',
    subtitle: 'Hace 4 horas',
  ),
  _ActivityEntry(
    icon: Icons.celebration_rounded,
    color: StatsPalette.primaryBlue,
    title: 'Asististe al evento IA',
    subtitle: 'Ayer',
  ),
];

class _ActivityEntry {
  const _ActivityEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});

  final _ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: entry.color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(entry.icon, color: entry.color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: StatsPalette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                entry.subtitle,
                style: const TextStyle(
                  color: StatsPalette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.inbox_outlined,
            color: StatsPalette.textSecondary,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aún no hay actividad reciente para mostrar.',
              style: TextStyle(color: StatsPalette.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
