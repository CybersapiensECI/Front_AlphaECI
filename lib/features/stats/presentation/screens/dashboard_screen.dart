import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
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
                  if (data.profile != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _AnimatedCounter(
                                value: data.profile!.level, label: 'Nivel'),
                            _AnimatedCounter(
                                value: data.profile!.xp, label: 'XP'),
                            if (data.profile!.semester != null)
                              _AnimatedCounter(
                                  value: data.profile!.semester!,
                                  label: 'Semestre'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (data.gamification != null)
                    _SectionCard(
                      icon: Icons.emoji_events_outlined,
                      title: 'Monas',
                      footer: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedProgressBar(
                              value:
                                  data.gamification!.completionPercentage /
                                      100),
                          const SizedBox(height: 4),
                          Text(
                            '${data.gamification!.completionPercentage.toStringAsFixed(0)}% de la colección',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      children: [
                        _AnimatedCounter(
                            value: data.gamification!.totalMonasUnlocked,
                            label: 'Desbloqueadas'),
                        _AnimatedCounter(
                            value: data.gamification!.monasInProgress,
                            label: 'En progreso'),
                        _AnimatedCounter(
                            value: data.gamification!.monasLocked,
                            label: 'Bloqueadas'),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (data.events != null)
                    _SectionCard(
                      icon: Icons.event_outlined,
                      title: 'Eventos',
                      children: [
                        _AnimatedCounter(
                            value: data.events!.totalAttended,
                            label: 'Asistidos'),
                        _AnimatedCounter(
                            value: data.events!.upcomingEvents,
                            label: 'Próximos'),
                        _AnimatedCounter(
                            value: data.events!.totalEvents, label: 'Total'),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (data.parches != null)
                    _SectionCard(
                      icon: Icons.groups_outlined,
                      title: 'Parches',
                      children: [
                        _AnimatedCounter(
                            value: data.parches!.totalJoined,
                            label: 'Unidos'),
                        _AnimatedCounter(
                            value: data.parches!.activeParches,
                            label: 'Activos'),
                      ],
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
    required this.children,
    this.footer,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? footer;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: children,
            ),
            if (footer != null) ...[const SizedBox(height: 16), footer!],
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
