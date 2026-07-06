import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/interest_chip.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../domain/entities/parche.dart';
import '../providers/parche_provider.dart';
import '../widgets/friend_picker.dart';

/// Categorías del feed. TODO(backend): confirmar valores del enum
/// ParcheCategory sembrados en Parches-Service.
const kParcheCategories =
    ['DEPORTE', 'ESTUDIO', 'JUEGOS', 'CULTURA', 'COMIDA'];

/// Feed de parches con búsqueda y FAB para crear.
class ParchesScreen extends ConsumerStatefulWidget {
  const ParchesScreen({super.key});

  @override
  ConsumerState<ParchesScreen> createState() => _ParchesScreenState();
}

/// Alcance del listado: todos, creados por mí, o a los que pertenezco.
enum _ParcheScope { todos, mios, unidos }

class _ParchesScreenState extends ConsumerState<ParchesScreen> {
  final _search = TextEditingController();
  _ParcheScope _scope = _ParcheScope.todos;

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
                for (final category in kParcheCategories) ...[
                  InterestChip(
                    label: category,
                    selected: filter.category == category,
                    accent: AppCategoryStyles.of(category).$2,
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
          const SizedBox(height: 8),
          // Alcance: todos / creados por mí / a los que pertenezco.
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final (scope, label) in const [
                  (_ParcheScope.todos, 'Todos'),
                  (_ParcheScope.mios, 'Creados por mí'),
                  (_ParcheScope.unidos, 'Mis parches'),
                ]) ...[
                  InterestChip(
                    label: label,
                    selected: _scope == scope,
                    onTap: () => setState(() => _scope = scope),
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
              data: (allParches) {
                final userId =
                    ref.watch(authControllerProvider).session?.userId ?? '';
                final parches = switch (_scope) {
                  _ParcheScope.todos => allParches,
                  _ParcheScope.mios => [
                      for (final p in allParches)
                        if (p.isCreator(userId)) p,
                    ],
                  _ParcheScope.unidos => [
                      for (final p in allParches)
                        if (p.isMember(userId) && !p.isCreator(userId)) p,
                    ],
                };
                if (parches.isEmpty) {
                  return EmptyState(
                    icon: Icons.groups_outlined,
                    message: switch (_scope) {
                      _ParcheScope.todos =>
                        'No hay parches activos.\n¡Crea el primero y arma '
                            'el plan!',
                      _ParcheScope.mios =>
                        'Aún no has creado parches.\nUsa el botón '
                            '"Crear parche".',
                      _ParcheScope.unidos =>
                        'No perteneces a ningún parche.\nÚnete desde '
                            '"Todos".',
                    },
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(parcheFeedProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    // 88: espacio para el FAB extendido.
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

class ParcheCard extends ConsumerWidget {
  const ParcheCard({super.key, required this.parche});

  final Parche parche;

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final ids = await showFriendPicker(
      context,
      title: 'Invitar a «${parche.name}»',
    );
    if (ids == null || ids.isEmpty || !context.mounted) return;
    final actions = ref.read(parcheActionsProvider);
    var sent = 0;
    for (final id in ids) {
      final result = await actions.invite(parche.id, id);
      if (result.isSuccess) sent++;
    }
    if (!context.mounted) return;
    showAppSnackBar(context, 'Invitaciones enviadas: $sent/${ids.length} 💌');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final userId = ref.watch(authControllerProvider).session?.userId ?? '';
    final isCreator = parche.isCreator(userId);
    final slotsRatio = parche.maximumQuota == 0
        ? 0.0
        : parche.memberCount / parche.maximumQuota;

    final (categoryIcon, categoryColor) =
        AppCategoryStyles.of(parche.category);

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
                  // Creador: invitar amistades desde la card.
                  if (isCreator) ...[
                    const SizedBox(width: 8),
                    BouncyTap(
                      onTap: () => _invite(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_alt_1,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
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
