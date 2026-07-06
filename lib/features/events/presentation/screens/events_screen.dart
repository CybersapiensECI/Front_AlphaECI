import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../domain/entities/event.dart';
import '../providers/event_provider.dart';

/// Eventos universitarios con filtro por categoría y RSVP de un toque.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  // TODO(backend): confirmar categorías reales sembradas en EventService.
  static const _categories = ['TECH', 'BIENESTAR', 'DEPORTE', 'CULTURA'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final agenda = ref.watch(myAgendaProvider).valueOrNull ?? const <String>{};
    final selectedCategory = ref.watch(eventCategoryProvider);

    return Column(
      children: [
        // Filtros por categoría.
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: selectedCategory == null,
                onSelected: (_) =>
                    ref.read(eventCategoryProvider.notifier).state = null,
              ),
              const SizedBox(width: 8),
              for (final category in _categories) ...[
                ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (_) => ref
                      .read(eventCategoryProvider.notifier)
                      .state = category,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: AsyncValueView<List<UniversityEvent>>(
            value: events,
            onRetry: () => ref.invalidate(eventsProvider),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_outlined,
                  message: 'No hay eventos en esta categoría.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(eventsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, index) => FadeSlideIn(
                    delay: Duration(milliseconds: 50 * index),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: Breakpoints.contentMaxWidth),
                        child: _EventCard(
                          event: items[index],
                          confirmed: agenda.contains(items[index].id),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EventCard extends ConsumerStatefulWidget {
  const _EventCard({required this.event, required this.confirmed});

  final UniversityEvent event;
  final bool confirmed;

  @override
  ConsumerState<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<_EventCard> {
  bool _loading = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    final result = await ref
        .read(eventActionsProvider)
        .toggleRsvp(widget.event, confirmed: widget.confirmed);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) => showAppSnackBar(
        context,
        widget.confirmed
            ? 'RSVP cancelado. Cupo liberado.'
            : '¡Asistencia confirmada! Quedó en tu agenda 📅',
      ),
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final soldOut = !event.hasCapacity && !widget.confirmed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.name, style: theme.textTheme.titleMedium),
                      Text(
                        [
                          if (event.category != null) event.category,
                          if (event.date != null) event.date,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (event.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                event.description!,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people_outline,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${event.availableCapacity} cupos disponibles',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: _loading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : widget.confirmed
                          ? FilledButton.tonalIcon(
                              key: const ValueKey('confirmed'),
                              onPressed: _toggle,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Asistiré'),
                            )
                          : OutlinedButton(
                              key: const ValueKey('rsvp'),
                              onPressed: soldOut ? null : _toggle,
                              child:
                                  Text(soldOut ? 'Sin cupos' : 'Confirmar'),
                            ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
