import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../domain/entities/mona.dart';
import '../providers/gamification_provider.dart';

/// Colección de monas: desbloqueadas, en progreso y bloqueadas.
class MonasScreen extends ConsumerWidget {
  const MonasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monas = ref.watch(myMonasProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Monas')),
      body: AsyncValueView<UserMonas>(
        value: monas,
        onRetry: () => ref.invalidate(myMonasProvider),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
              child: StaggeredColumn(
                children: [
                  // Resumen.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat(
                              value: '${data.totalUnlocked}/${data.total}',
                              label: 'Desbloqueadas'),
                          _Stat(value: '${data.totalXp}', label: 'XP total'),
                          _Stat(
                              value: '${data.inProgress.length}',
                              label: 'En progreso'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (data.inProgress.isNotEmpty) ...[
                    Text('En progreso', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    for (final mona in data.inProgress)
                      _MonaCard(mona: mona, state: _MonaState.inProgress),
                    const SizedBox(height: 20),
                  ],
                  if (data.unlocked.isNotEmpty) ...[
                    Text('Desbloqueadas', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    for (final mona in data.unlocked)
                      _MonaCard(mona: mona, state: _MonaState.unlocked),
                    const SizedBox(height: 20),
                  ],
                  if (data.locked.isNotEmpty) ...[
                    Text('Por descubrir', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    for (final mona in data.locked)
                      _MonaCard(mona: mona, state: _MonaState.locked),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _MonaState { unlocked, inProgress, locked }

class _MonaCard extends StatelessWidget {
  const _MonaCard({required this.mona, required this.state});

  final Mona mona;
  final _MonaState state;

  Color _rarityColor(BuildContext context) => switch (mona.rarity) {
        'LEGENDARY' => Colors.amber,
        'EPIC' => Colors.purpleAccent,
        'RARE' => Theme.of(context).colorScheme.tertiary,
        _ => Theme.of(context).colorScheme.outline,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locked = state == _MonaState.locked;
    final rarityColor = _rarityColor(context);

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: locked
                      ? null
                      : LinearGradient(colors: [
                          rarityColor.withValues(alpha: 0.7),
                          rarityColor.withValues(alpha: 0.3),
                        ]),
                  color: locked ? scheme.outline.withValues(alpha: 0.2) : null,
                ),
                child: Icon(
                  locked
                      ? Icons.lock_outline
                      : state == _MonaState.inProgress
                          ? Icons.hourglass_bottom
                          : Icons.emoji_events,
                  color: locked ? scheme.onSurfaceVariant : Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(mona.name,
                              style: theme.textTheme.titleMedium),
                        ),
                        const SizedBox(width: 8),
                        if (mona.rarity != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: rarityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              mona.rarity!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: rarityColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (mona.description != null)
                      Text(mona.description!,
                          style: theme.textTheme.bodySmall),
                    if (state == _MonaState.inProgress &&
                        mona.progressPercentage != null) ...[
                      const SizedBox(height: 8),
                      AnimatedProgressBar(
                        value: mona.progressPercentage! / 100,
                        height: 7,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mona.currentCount ?? 0}/${mona.requiredCount ?? 0}'
                        ' · ${mona.progressPercentage}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('+${mona.xpGranted} XP',
                  style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineSmall),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
