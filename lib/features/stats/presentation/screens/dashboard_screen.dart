import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/charts.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/stats_repository.dart';
import '../../domain/entities/personal_stats.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  if (Env.demoMode) return const MockStatsRepository();
  return StatsRepositoryImpl(ref.watch(apiClientProvider(Env.statsUrl)));
});

final personalStatsProvider = FutureProvider<PersonalStats>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) throw const AuthFailure();
  final result =
      await ref.watch(statsRepositoryProvider).getPersonalStats(session.userId);
  return result.when(
      success: (stats) => stats, error: (failure) => throw failure);
});

/// Dashboard personal: XP, monas, eventos y parches con contadores animados.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(personalStatsProvider);
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Mi Dashboard')),
      body: AsyncValueView<PersonalStats>(
        value: stats,
        onRetry: () => ref.invalidate(personalStatsProvider),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
              child: StaggeredColumn(
                children: [
                  // ── Héroe: nivel/XP + anillo de colección ────
                  GlassCard(
                    child: Row(
                      children: [
                        const MascotSticker(
                            stickerIndex: AppAssets.stickerCool, size: 64),
                        const SizedBox(width: 16),
                        if (data.profile != null) ...[
                          Expanded(
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _AnimatedCounter(
                                    value: data.profile!.level,
                                    label: 'Nivel'),
                                _AnimatedCounter(
                                    value: data.profile!.xp, label: 'XP'),
                                if (data.profile!.semester != null)
                                  _AnimatedCounter(
                                      value: data.profile!.semester!,
                                      label: 'Semestre'),
                              ],
                            ),
                          ),
                        ] else
                          const Spacer(),
                        if (data.gamification != null)
                          RingStat(
                            value: data.gamification!
                                    .completionPercentage /
                                100,
                            label: 'Colección',
                            size: 84,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Monas: barras por estado ─────────────────
                  if (data.gamification != null)
                    _SectionCard(
                      icon: Icons.emoji_events_outlined,
                      title: 'Monas',
                      child: MiniBarChart(
                        data: [
                          BarDatum(
                            label: 'Desbloq.',
                            value:
                                data.gamification!.totalMonasUnlocked,
                            color: Colors.amber,
                          ),
                          BarDatum(
                            label: 'En progreso',
                            value: data.gamification!.monasInProgress,
                            color: theme.colorScheme.tertiary,
                          ),
                          BarDatum(
                            label: 'Bloqueadas',
                            value: data.gamification!.monasLocked,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // ── Eventos ──────────────────────────────────
                  if (data.events != null)
                    _SectionCard(
                      icon: Icons.event_outlined,
                      title: 'Eventos',
                      child: MiniBarChart(
                        data: [
                          BarDatum(
                            label: 'Asistidos',
                            value: data.events!.totalAttended,
                            color: const Color(0xFF2FA36F),
                          ),
                          BarDatum(
                            label: 'Próximos',
                            value: data.events!.upcomingEvents,
                            color: theme.colorScheme.tertiary,
                          ),
                          BarDatum(
                            label: 'Total',
                            value: data.events!.totalEvents,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // ── Parches ──────────────────────────────────
                  if (data.parches != null)
                    _SectionCard(
                      icon: Icons.groups_outlined,
                      title: 'Parches',
                      child: MiniBarChart(
                        data: [
                          BarDatum(
                            label: 'Unidos',
                            value: data.parches!.totalJoined,
                            color: theme.colorScheme.secondary,
                          ),
                          BarDatum(
                            label: 'Activos',
                            value: data.parches!.activeParches,
                            color: const Color(0xFFE08A3C),
                          ),
                        ],
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Contador que anima de 0 al valor.
class _AnimatedCounter extends StatelessWidget {
  const _AnimatedCounter({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => Text(
            '$animated',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
