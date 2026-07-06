import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/parche.dart';
import '../providers/parche_provider.dart';

/// Feed de parches con búsqueda y FAB para crear.
class ParchesScreen extends ConsumerStatefulWidget {
  const ParchesScreen({super.key});

  @override
  ConsumerState<ParchesScreen> createState() => _ParchesScreenState();
}

class _ParchesScreenState extends ConsumerState<ParchesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(parcheFeedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create-parche',
        onPressed: () => context.push(Routes.createParche),
        icon: const Icon(Icons.add),
        label: const Text('Crear parche'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: Breakpoints.contentMaxWidth),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Buscar parches…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        ref.read(parcheFilterProvider.notifier).state =
                            const ParcheFilter();
                      },
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) =>
                      ref.read(parcheFilterProvider.notifier).state =
                          ParcheFilter(query: value.trim()),
                ),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueView<List<Parche>>(
              value: feed,
              onRetry: () => ref.invalidate(parcheFeedProvider),
              data: (parches) {
                if (parches.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_outlined,
                    message:
                        'No hay parches activos.\n¡Crea el primero y arma '
                        'el plan!',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(parcheFeedProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: parches.length,
                    itemBuilder: (context, index) => FadeSlideIn(
                      delay: Duration(milliseconds: 50 * index),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: Breakpoints.contentMaxWidth),
                          child: ParcheCard(parche: parches[index]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ParcheCard extends StatelessWidget {
  const ParcheCard({super.key, required this.parche});

  final Parche parche;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final slotsRatio = parche.maximumQuota == 0
        ? 0.0
        : parche.memberCount / parche.maximumQuota;

    return BouncyTap(
      onTap: () => context.push(
        Routes.parcheDetailPath(parche.id),
        extra: parche,
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.tertiary.withValues(alpha: 0.2),
                    child: Icon(Icons.celebration_outlined,
                        color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(parche.name, style: theme.textTheme.titleMedium),
                        if (parche.category != null)
                          Text(parche.category!,
                              style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (parche.type == 'PRIVATE')
                    Icon(Icons.lock_outline,
                        size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
              if (parche.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  parche.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (parche.date != null) ...[
                    Icon(Icons.calendar_today_outlined,
                        size: 15, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM').format(parche.date!) +
                          (parche.hour != null ? ' · ${parche.hour}' : ''),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (parche.place != null) ...[
                    Icon(Icons.place_outlined,
                        size: 15, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(parche.place!,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AnimatedProgressBar(
                      value: slotsRatio,
                      height: 6,
                      color: slotsRatio >= 1 ? Colors.redAccent : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${parche.memberCount}/${parche.maximumQuota}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
