import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/interest_chip.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../domain/entities/parche.dart';
import '../providers/parche_provider.dart';

/// Categorías del feed. TODO(backend): confirmar valores del enum
/// ParcheCategory sembrados en Parches-Service.
const _feedCategories = ['DEPORTE', 'ESTUDIO', 'JUEGOS', 'CULTURA', 'COMIDA'];

/// Ícono y color por categoría (identidad visual del feed).
(IconData, Color) categoryStyle(String? category, ColorScheme scheme) {
  return switch (category?.toUpperCase()) {
    'DEPORTE' => (Icons.sports_soccer, scheme.tertiary),
    'ESTUDIO' => (Icons.menu_book_outlined, scheme.primary),
    'JUEGOS' => (Icons.sports_esports_outlined, scheme.secondary),
    'CULTURA' => (Icons.theater_comedy_outlined, scheme.tertiary),
    'COMIDA' => (Icons.restaurant_outlined, scheme.secondary),
    _ => (Icons.celebration_outlined, scheme.primary),
  };
}

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
    final filter = ref.watch(parcheFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Padding inferior: no chocar con la barra de navegación flotante.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          heroTag: 'create-parche',
          onPressed: () => context.push(Routes.createParche),
          icon: const Icon(Icons.add),
          label: const Text('Crear parche'),
        ),
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
          // Filtro por categoría (feed estilo red social).
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                InterestChip(
                  label: 'Todos',
                  selected: filter.category == null,
                  onTap: () => ref.read(parcheFilterProvider.notifier).state =
                      ParcheFilter(query: filter.query),
                ),
                const SizedBox(width: 8),
                for (final category in _feedCategories) ...[
                  InterestChip(
                    label: category,
                    selected: filter.category == category,
                    onTap: () =>
                        ref.read(parcheFilterProvider.notifier).state =
                            ParcheFilter(
                      query: filter.query,
                      category: category,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: AsyncValueView<List<Parche>>(
              value: feed,
              onRetry: () => ref.invalidate(parcheFeedProvider),
              loading: const SkeletonList(),
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

    final (categoryIcon, categoryColor) =
        categoryStyle(parche.category, scheme);

    return BouncyTap(
      onTap: () => context.push(
        Routes.parcheDetailPath(parche.id),
        extra: parche,
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de categoría con gradiente (feed visual).
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    categoryColor.withValues(alpha: 0.85),
                    scheme.primary.withValues(alpha: 0.75),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(categoryIcon, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  if (parche.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        parche.category!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (parche.type == 'PRIVATE')
                    const Icon(Icons.lock_outline,
                        size: 18, color: Colors.white),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(parche.name, style: theme.textTheme.titleMedium),
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
          ],
        ),
      ),
    );
  }
}
