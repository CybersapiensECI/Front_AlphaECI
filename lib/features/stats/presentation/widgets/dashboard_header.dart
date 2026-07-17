import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import 'stats_palette.dart';

/// AppBar compacta del Dashboard: volver, título, avatar del usuario,
/// notificaciones y configuración. Sin ocupar altura extra.
class DashboardHeader extends ConsumerWidget implements PreferredSizeWidget {
  const DashboardHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).valueOrNull;

    return AppBar(
      backgroundColor: StatsPalette.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 56,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: StatsPalette.textPrimary,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Dashboard',
        style: TextStyle(
          color: StatsPalette.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Notificaciones',
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: StatsPalette.textSecondary,
          ),
          onPressed: () => context.push(Routes.notifications),
        ),
        IconButton(
          tooltip: 'Configuración',
          icon: const Icon(
            Icons.settings_outlined,
            color: StatsPalette.textSecondary,
          ),
          // La configuración (tema, etc.) vive en Perfil; no hay ruta
          // directa aún, así que no navegamos a nada roto.
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Encuentra la configuración en tu perfil'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: ProfileAvatar(
            name: profile?.name ?? '',
            photoUrl: profile?.photoUrl,
            radius: 16,
          ),
        ),
      ],
    );
  }
}
