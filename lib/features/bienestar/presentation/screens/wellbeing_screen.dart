import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/wellbeing.dart';
import '../providers/wellbeing_provider.dart';

/// Centro de bienestar: recursos, contactos de emergencia y eventos.
class WellbeingScreen extends ConsumerWidget {
  const WellbeingScreen({super.key});

  // TODO(backend): confirmar categorías sembradas en BienestarService.
  static const _categories = ['PSICOLOGÍA', 'NUTRICIÓN', 'ACADÉMICO'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resources = ref.watch(wellbeingResourcesProvider);
    final contacts = ref.watch(emergencyContactsProvider);
    final selected = ref.watch(wellbeingCategoryProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bienestar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Contactos de emergencia ────────────────
                FadeSlideIn(
                  child: Card(
                    color: scheme.tertiary.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.health_and_safety_outlined,
                                  color: scheme.primary),
                              const SizedBox(width: 8),
                              Text('Contactos de apoyo',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          contacts.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text(
                                'No se pudieron cargar los contactos.',
                                style: theme.textTheme.bodySmall),
                            data: (items) => Column(
                              children: [
                                for (final contact in items)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    leading: Icon(Icons.support_agent,
                                        color: scheme.primary),
                                    title: Text(contact.name),
                                    subtitle: Text([
                                      if (contact.phone != null) contact.phone,
                                      if (contact.email != null) contact.email,
                                    ].join(' · ')),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // ── Recursos ───────────────────────────────
                Text('Recursos', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: selected == null,
                      onSelected: (_) => ref
                          .read(wellbeingCategoryProvider.notifier)
                          .state = null,
                    ),
                    for (final category in _categories)
                      ChoiceChip(
                        label: Text(category),
                        selected: selected == category,
                        onSelected: (_) => ref
                            .read(wellbeingCategoryProvider.notifier)
                            .state = category,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AsyncValueView<List<WellbeingResource>>(
                  value: resources,
                  onRetry: () => ref.invalidate(wellbeingResourcesProvider),
                  data: (items) {
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.spa_outlined,
                        message: 'Sin recursos en esta categoría.',
                      );
                    }
                    return StaggeredColumn(
                      children: [
                        for (final resource in items)
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Icon(
                                switch (resource.type) {
                                  'TIP' => Icons.lightbulb_outline,
                                  'CONTACT' => Icons.call_outlined,
                                  _ => Icons.article_outlined,
                                },
                                color: scheme.primary,
                              ),
                              title: Text(resource.title),
                              subtitle: Text(resource.description ?? ''),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
