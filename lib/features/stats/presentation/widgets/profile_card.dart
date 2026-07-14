import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../domain/entities/personal_stats.dart';
import 'stats_palette.dart';

/// Tarjeta de presentación del estudiante: avatar, nombre, nivel,
/// semestre y programa. Sin XP, porcentajes ni indicadores de progreso
/// — eso vive en [ProgressCard]. Gradiente azul oscuro, esquinas 24,
/// sombra suave, ancho completo.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key, required this.data});

  final PersonalStats data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(myProfileProvider).valueOrNull;
    final profile = data.profile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: StatsPalette.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StatsPalette.border),
        boxShadow: StatsPalette.softShadow,
      ),
      // Tarjeta de presentación: todo centrado (avatar arriba, nombre y
      // tags debajo), en vez de la fila avatar-izquierda/texto-derecha.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProfileAvatar(
            name: userProfile?.name ?? '',
            photoUrl: userProfile?.photoUrl,
            radius: 36,
          ),
          const SizedBox(height: 14),
          Text(
            userProfile?.name ?? 'Estudiante ECI',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: StatsPalette.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              if (profile != null) _Tag('Nivel ${profile.level}'),
              if (profile?.semester != null)
                _Tag('Semestre ${profile!.semester}'),
              if (profile?.career != null) _Tag(profile!.career!),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: StatsPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
