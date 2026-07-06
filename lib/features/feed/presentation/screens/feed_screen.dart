import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../../core/widgets/interest_chip.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/text_input_sheet.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../parches/domain/entities/parche.dart';
import '../../../parches/presentation/providers/parche_provider.dart';
import '../../../parches/presentation/screens/parches_screen.dart'
    show kParcheCategories;
import '../providers/feed_provider.dart';
import '../widgets/publication_card.dart';

/// Feed principal (Inicio): publicaciones hechas por estudiantes DESDE
/// sus parches. Regla: solo se publica siendo miembro y mientras ocurre
/// el parche — el composer solo aparece en ese caso.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  Future<void> _publish(
    BuildContext context,
    WidgetRef ref,
    Parche parche,
  ) async {
    final text = await showTextInputSheet(
      context,
      title: 'Publicar en ${parche.name}',
      hint: '¿Cómo va el parche? Comparte el momento…',
      maxLines: 5,
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    final result =
        await ref.read(parcheActionsProvider).createPost(parche.id, text);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(publicationsProvider);
        showAppSnackBar(context, '¡Publicado! 🎉');
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publications = ref.watch(publicationsProvider);
    final category = ref.watch(feedCategoryProvider);
    final publishable = ref.watch(publishableParcheProvider).valueOrNull;
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Filtro por categoría ────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              InterestChip(
                label: 'Todos',
                selected: category == null,
                onTap: () =>
                    ref.read(feedCategoryProvider.notifier).state = null,
              ),
              const SizedBox(width: 8),
              for (final c in kParcheCategories) ...[
                InterestChip(
                  label: c,
                  selected: category == c,
                  accent: AppCategoryStyles.of(c).$2,
                  onTap: () =>
                      ref.read(feedCategoryProvider.notifier).state = c,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        // ── Composer: solo con parche activo hoy ────────────────
        if (publishable != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: Breakpoints.contentMaxWidth),
                child: FadeSlideIn(
                  child: GlassCard(
                    onTap: () => _publish(context, ref, publishable),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Estás en «${publishable.name}» — '
                            'comparte el momento',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Icon(
                          Icons.add_circle,
                          color: theme.colorScheme.tertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        // ── Publicaciones ───────────────────────────────────────
        Expanded(
          child: AsyncValueView(
            value: publications,
            onRetry: () => ref.invalidate(publicationsProvider),
            loading: const SkeletonList(),
            data: (items) {
              if (items.isEmpty) {
                return MascotEmptyState(
                  asset: AppAssets.stickerConfused,
                  message: category == null
                      ? 'Aún no hay publicaciones.\nÚnete a un parche y '
                          'comparte el momento cuando esté ocurriendo.'
                      : 'Sin publicaciones de $category por ahora.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(publicationsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) => FadeSlideIn(
                    delay: Duration(milliseconds: 50 * index),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: Breakpoints.contentMaxWidth),
                        child: PublicationCard(publication: items[index]),
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
