import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../domain/entities/profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';

/// Mi perfil: avatar, nivel/XP animado, intereses, biografía.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    return AsyncValueView<UserProfile>(
      value: profile,
      onRetry: () => ref.invalidate(myProfileProvider),
      data: (p) => _ProfileBody(profile: p),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
          child: StaggeredColumn(
            children: [
              // ── Header con cover de marca ─────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppGradients.of(context),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow: AppShadows.soft(context),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'my-avatar',
                      child: ProfileAvatar(
                        name: profile.name,
                        photoUrl: profile.photoUrl,
                        radius: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(color: Colors.white),
                          ),
                          if (profile.career != null)
                            Text(
                              '${profile.career}'
                              '${profile.semester != null ? ' · Semestre ${profile.semester}' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar perfil',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push(Routes.editProfile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Nivel / XP ────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                scheme.primary,
                                scheme.tertiary,
                              ]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Nivel ${profile.level}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text('${profile.xp} XP',
                              style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedProgressBar(value: profile.levelProgress),
                      const SizedBox(height: 6),
                      Text(
                        'Sigue participando para subir de nivel',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── Intereses ─────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mis intereses',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (profile.tags.isEmpty)
                        Text(
                          'Aún no tienes intereses. Agrégalos para mejorar '
                          'tus recomendaciones.',
                          style: theme.textTheme.bodySmall,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in profile.tags)
                              Chip(
                                label: Text(tag.name),
                                backgroundColor:
                                    scheme.tertiary.withValues(alpha: 0.15),
                                side: BorderSide(
                                    color:
                                        scheme.tertiary.withValues(alpha: 0.4)),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── Biografía ─────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sobre mí', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        profile.biography?.isNotEmpty == true
                            ? profile.biography!
                            : 'Cuéntale a la ECI quién eres ✍️',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── Amigos ────────────────────────────────────
              Card(
                child: ListTile(
                  leading: Icon(Icons.people_outline, color: scheme.primary),
                  title: Text('${profile.friendsId.length} conexiones'),
                  subtitle: const Text('Personas con las que has conectado'),
                ),
              ),
              const SizedBox(height: 16),
              // ── Accesos ───────────────────────────────────
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          Icon(Icons.emoji_events_outlined, color: scheme.primary),
                      title: const Text('Mis Monas'),
                      subtitle: const Text('Logros y recompensas'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.monas),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.insights_outlined,
                          color: scheme.primary),
                      title: const Text('Mi Dashboard'),
                      subtitle: const Text('Tu actividad en números'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.dashboard),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.spa_outlined, color: scheme.primary),
                      title: const Text('Bienestar'),
                      subtitle: const Text('Recursos y contactos de apoyo'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.bienestar),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          Icon(Icons.place_outlined, color: scheme.primary),
                      title: const Text('Mi zona del campus'),
                      subtitle: const Text('Parches cerca de ti'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.zone),
                    ),
                    const Divider(height: 1),
                    // Selector de tema (Sistema/Claro/Oscuro), persistido.
                    ListTile(
                      leading: Icon(Icons.dark_mode_outlined,
                          color: scheme.primary),
                      title: const Text('Apariencia'),
                      trailing: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto, size: 18),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode, size: 18),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode, size: 18),
                          ),
                        ],
                        selected: {ref.watch(themeModeProvider)},
                        onSelectionChanged: (selection) => ref
                            .read(themeModeProvider.notifier)
                            .set(selection.first),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
