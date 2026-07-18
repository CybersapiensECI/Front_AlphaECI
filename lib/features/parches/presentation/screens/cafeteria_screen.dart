import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../domain/entities/parche.dart';
import '../providers/parche_provider.dart';
import 'parches_screen.dart' show ParcheCard;

/// Apartado Cafetería: parches estrictamente relacionados a comer/tomar
/// algo en el campus (categoría GASTRONOMY o lugares Regio/Leyenda/Harvies).
/// Reutiliza por completo la búsqueda de Parches-Service (mismo GET
/// /api/parches ya usado por el feed de parches) — sin backend nuevo.
class CafeteriaScreen extends ConsumerWidget {
  const CafeteriaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parches = ref.watch(cafeteriaParchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cafetería')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create-cafeteria-parche',
        onPressed: () => context.push(Routes.createParche),
        icon: const Icon(Icons.add),
        label: const Text('Publicar mesa'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.15),
                          child: const Icon(Icons.coffee_outlined),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '¿No quieres almorzar solo/a? Busca un parche '
                            'o publica tu mesa.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueView<List<Parche>>(
              value: parches,
              onRetry: () => ref.invalidate(cafeteriaParchesProvider),
              loading: const SkeletonList(),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.coffee_outlined,
                    message: 'No hay parches de cafetería activos.\n'
                        '¡Publica tu mesa y que alguien te acompañe!',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(cafeteriaParchesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: items.length,
                    itemBuilder: (context, index) => FadeSlideIn(
                      delay: Duration(milliseconds: 50 * index),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: Breakpoints.contentMaxWidth),
                          child: ParcheCard(parche: items[index]),
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
