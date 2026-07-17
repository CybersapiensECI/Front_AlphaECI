import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../parches/presentation/providers/parche_provider.dart';
import '../../../parches/presentation/widgets/comments_sheet.dart';
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
    // parcheActionsProvider.react ya invalida parchePostsProvider, que
    // publicationsProvider watchea: el corazón se actualiza solo al
    // llegar el refetch (ver feed_provider.dart).
    final result = await ref
        .read(parcheActionsProvider)
        .react(publication.parche.id, publication.post.id);
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) showAppSnackBar(context, failure.message);
  }

  /// Abre el sheet de comentarios (lista + campo para comentar).
  void _comments(BuildContext context) => showCommentsSheet(
        context,
        parcheId: publication.parche.id,
        postId: publication.post.id,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final post = publication.post;
    final parche = publication.parche;
    final author = publication.author;
    final (categoryIcon, categoryColor) =
        AppCategoryStyles.of(parche.category);
    final session = ref.watch(authControllerProvider).session;
    final liked = post.likedBy(session?.userId);
    final commentCount = post.comments.length;

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
                        AppCategoryStyles.labelOf(parche.category),
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
                  // Tap: abre la imagen completa con zoom.
                  GestureDetector(
                    onTap: () => showImageViewer(context, post.photoUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Image.network(
                        post.photoUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
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
                    // Burst al dar like: pop + sacudida (estilo Instagram).
                    child: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      size: 22,
                      color: liked
                          ? _likeColor
                          : theme.colorScheme.onSurfaceVariant,
                    )
                        .animate(target: liked ? 1 : 0)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.35, 1.35),
                          duration: 160.ms,
                          curve: Curves.easeOut,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1 / 1.35, 1 / 1.35),
                          duration: 220.ms,
                          curve: Curves.elasticOut,
                        )
                        .shake(hz: 5, rotation: 0.06, duration: 300.ms),
                  ),
                ),
                BouncyTap(
                  onTap: () => _comments(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mode_comment_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        // Contador de comentarios (sesión + demo).
                        if (commentCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$commentCount',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
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
