import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/text_input_sheet.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../parches/presentation/providers/parche_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../providers/feed_provider.dart';

/// Tarjeta de publicación del feed principal.
/// Header con el color de la categoría del parche de origen,
/// autor con avatar + nombre, y acciones de like/comentario.
class PublicationCard extends ConsumerWidget {
  const PublicationCard({super.key, required this.publication});

  final FeedPublication publication;

  /// Color del corazón activo (coral de la escala de categorías).
  static const _likeColor = Color(0xFFD95E5E);

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    final postId = publication.post.id;
    final liked = ref.read(likedPostsProvider);
    final wasLiked = liked.contains(postId);
    // Optimista: pinta ya, revierte si el backend falla.
    ref.read(likedPostsProvider.notifier).state = wasLiked
        ? ({...liked}..remove(postId))
        : {...liked, postId};

    final result = await ref
        .read(parcheActionsProvider)
        .react(publication.parche.id, postId);
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      ref.read(likedPostsProvider.notifier).state =
          wasLiked ? {...liked, postId} : ({...liked}..remove(postId));
      showAppSnackBar(context, failure.message);
    }
  }

  Future<void> _comment(BuildContext context, WidgetRef ref) async {
    final text = await showTextInputSheet(
      context,
      title: 'Comentar',
      hint: 'Tu comentario…',
      submitLabel: 'Comentar',
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    final result = await ref
        .read(parcheActionsProvider)
        .comment(publication.parche.id, publication.post.id, text);
    if (!context.mounted) return;
    result.when(
      success: (message) => showAppSnackBar(context, message),
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final post = publication.post;
    final parche = publication.parche;
    final author = publication.author;
    final (categoryIcon, categoryColor) =
        AppCategoryStyles.of(parche.category);
    final liked = ref.watch(likedPostsProvider).contains(post.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header con color de categoría ────────────────────
          BouncyTap(
            onTap: () => context.push(
              Routes.parcheDetailPath(parche.id),
              extra: parche,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    categoryColor.withValues(alpha: 0.92),
                    categoryColor.withValues(alpha: 0.62),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ProfileAvatar(
                      name: author?.name ?? '?',
                      photoUrl: author?.photoUrl,
                      radius: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author?.name ?? 'Estudiante ECI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(categoryIcon,
                                size: 12,
                                color:
                                    Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                parche.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (parche.category != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        parche.category!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // ── Contenido ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.text?.isNotEmpty == true)
                  Text(post.text!, style: theme.textTheme.bodyMedium),
                if (post.photoUrl?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: Image.network(
                      post.photoUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ── Acciones ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
            child: Row(
              children: [
                BouncyTap(
                  onTap: () => _toggleLike(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedSwitcher(
                      duration: AppDurations.fast,
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(liked),
                        size: 22,
                        color: liked
                            ? _likeColor
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                BouncyTap(
                  onTap: () => _comment(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.mode_comment_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(post.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'hace ${diff.inDays} d';
  return 'hace ${(diff.inDays / 7).floor()} sem';
}
