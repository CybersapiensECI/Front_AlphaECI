import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../gamification/domain/entities/mona.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../gamification/presentation/widgets/mona_medal.dart';
import '../../../gamification/presentation/widgets/mona_styles.dart';
import 'stats_palette.dart';

/// "Colección": scroll horizontal de medallas realmente desbloqueadas —
/// reutiliza el provider y los widgets del módulo de gamificación
/// (myMonasProvider, MonaMedal) en vez de datos inventados.
class CollectionSection extends ConsumerWidget {
  const CollectionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monas = ref.watch(myMonasProvider);

    return monas.when(
      loading: () => const SizedBox(
        height: 96,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: StatsPalette.primaryBlue,
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final items = data.unlocked;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Colección',
                    style: TextStyle(
                      color: StatsPalette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(Routes.monas),
                  child: const Text(
                    'Ver todo',
                    style: TextStyle(
                      color: StatsPalette.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Aún no has desbloqueado ninguna mona.',
                  style: TextStyle(
                    color: StatsPalette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              )
            else
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _MonaCard(mona: items[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MonaCard extends StatelessWidget {
  const _MonaCard({required this.mona});

  final Mona mona;

  @override
  Widget build(BuildContext context) {
    final rarityColor = monaRarityColor(mona.rarity);
    final category = monaCategoryOf(mona);

    return Container(
      width: 84,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: StatsPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StatsPalette.border),
        boxShadow: StatsPalette.glow(rarityColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: MonaMedal(
              mona: mona,
              locked: false,
              fallbackIcon: monaCategoryIcon(category),
              iconSize: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mona.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StatsPalette.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
