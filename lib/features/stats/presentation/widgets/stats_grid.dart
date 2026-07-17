import 'package:flutter/material.dart';

import '../../../../core/widgets/animations.dart';
import '../../domain/entities/personal_stats.dart';
import 'stat_card.dart';
import 'stats_palette.dart';

/// Grid de resumen: XP, Monas, Eventos y Parches. 2 columnas en móvil,
/// 4 en pantallas anchas (tablet/web) — sin tamaños fijos.
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.data});

  final PersonalStats data;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      StatCard(
        icon: Icons.bolt_rounded,
        label: 'XP',
        value: data.gamification?.totalXp ?? data.profile?.xp ?? 0,
        color: StatsPalette.orange,
      ),
      StatCard(
        icon: Icons.emoji_events_rounded,
        label: 'Monas',
        value: data.gamification?.totalMonasUnlocked ?? 0,
        color: StatsPalette.purple,
      ),
      StatCard(
        icon: Icons.event_rounded,
        label: 'Eventos',
        value: data.events?.totalAttended ?? 0,
        color: StatsPalette.green,
      ),
      StatCard(
        icon: Icons.groups_rounded,
        label: 'Parches',
        value: data.parches?.totalJoined ?? 0,
        color: StatsPalette.primaryBlue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 560 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, i) => FadeSlideIn(
            delay: Duration(milliseconds: 60 * i),
            child: tiles[i],
          ),
        );
      },
    );
  }
}
