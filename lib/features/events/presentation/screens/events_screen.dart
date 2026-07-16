import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/interest_chip.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../domain/entities/event.dart';
import '../providers/event_provider.dart';

/// Eventos universitarios con filtro por categoría y RSVP de un toque.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final agenda = ref.watch(myAgendaProvider).valueOrNull ?? const <String>{};
    final selectedCategory = ref.watch(eventCategoryProvider);
    // Chips derivados de los datos reales (sin catálogo en el back).
    final categories =
        ref.watch(eventCategoriesProvider).valueOrNull ?? const <String>[];

    return Column(
      children: [
        // Filtros por categoría con colores de marca (mismos del feed).
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              InterestChip(
                label: 'Todos',
                selected: selectedCategory == null,
                onTap: () =>
                    ref.read(eventCategoryProvider.notifier).state = null,
              ),
              const SizedBox(width: 8),
              for (final category in categories) ...[
                InterestChip(
                  label: AppCategoryStyles.labelOf(category),
                  selected: selectedCategory == category,
                  accent: AppCategoryStyles.of(category).$2,
                  onTap: () => ref
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
                return MascotEmptyState(
                  asset: AppAssets.stickerSleepy,
                  message: selectedCategory == null
                      ? 'Nada por aquí todavía.\nLos eventos del campus '
                          'aparecerán en este espacio.'
                      : 'No hay eventos de $selectedCategory por ahora.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(eventsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
    final (categoryIcon, categoryColor) =
        AppCategoryStyles.of(event.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // Tap en el cuerpo (no en los botones): detalle expandido.
      child: InkWell(
        onTap: () => showEventDetailsSheet(context, event),
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
                    color: categoryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: categoryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.name, style: theme.textTheme.titleMedium),
                      Text(
                        [
                          if (event.category != null)
                            AppCategoryStyles.labelOf(event.category),
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
      ),
    );
  }
}

/// Detalle expandido del evento en bottom sheet (identidad glass de la app).
/// TODO(backend): EventService no expone hora, ubicación ni lista de
/// asistentes — cuando existan, agregarlos aquí.
void showEventDetailsSheet(BuildContext context, UniversityEvent event) {
  showAppSheet<void>(context, child: _EventDetailsSheet(event: event));
}

class _EventDetailsSheet extends ConsumerStatefulWidget {
  const _EventDetailsSheet({required this.event});

  final UniversityEvent event;

  @override
  ConsumerState<_EventDetailsSheet> createState() =>
      _EventDetailsSheetState();
}

class _EventDetailsSheetState extends ConsumerState<_EventDetailsSheet> {
  bool _loading = false;

  Future<void> _toggle(bool confirmed) async {
    setState(() => _loading = true);
    final result = await ref
        .read(eventActionsProvider)
        .toggleRsvp(widget.event, confirmed: confirmed);
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      success: (_) => showAppSnackBar(
        context,
        confirmed
            ? 'RSVP cancelado. Cupo liberado.'
            : '¡Asistencia confirmada! Quedó en tu agenda 📅',
      ),
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final event = widget.event;
    final (categoryIcon, categoryColor) =
        AppCategoryStyles.of(event.category);
    final confirmed =
        (ref.watch(myAgendaProvider).valueOrNull ?? const <String>{})
            .contains(event.id);
    final taken = (event.capacity - event.availableCapacity)
        .clamp(0, event.capacity);
    final occupancy =
        event.capacity == 0 ? 0.0 : taken / event.capacity;
    final soldOut = !event.hasCapacity && !confirmed;

    // Contenedor/alto/handle: AppSheet (estándar 2/3 de pantalla).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              // ── Cabecera ────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        Icon(categoryIcon, color: categoryColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.name, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (event.category != null)
                              _Tag(
                                label:
                                    AppCategoryStyles.labelOf(event.category),
                                color: categoryColor,
                              ),
                            if (!event.isActive)
                              _Tag(label: 'Cancelado', color: scheme.error),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Fecha ───────────────────────────────────
              if (event.date != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(event.date!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              const SizedBox(height: 14),
              // ── Cupos ───────────────────────────────────
              Row(
                children: [
                  Icon(Icons.people_outline,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    '$taken asistirán · ${event.availableCapacity} cupos '
                    'libres de ${event.capacity}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedProgressBar(
                value: occupancy,
                height: 8,
                color: soldOut ? scheme.error : null,
              ),
              // ── Descripción ─────────────────────────────
              if (event.description?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Text('Descripción', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(event.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              // ── Gamificación: enlace con el álbum de Monas ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.tertiary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const MascotSticker(
                        asset: AppAssets.stickerApproved, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Asistir a eventos suma XP y desbloquea monas de '
                        'tu álbum 🏆',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
        const SizedBox(height: 12),
        // ── RSVP fijo al pie del sheet ──────────────────
        _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            : confirmed
                ? FilledButton.tonalIcon(
                    onPressed: () => _toggle(true),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Asistiré — tocar para cancelar'),
                  )
                : FilledButton.icon(
                    onPressed: soldOut || !event.isActive
                        ? null
                        : () => _toggle(false),
                    icon: const Icon(Icons.event_available),
                    label:
                        Text(soldOut ? 'Sin cupos' : 'Confirmar asistencia'),
                  ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
