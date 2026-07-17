import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/parche.dart';
import '../providers/parche_provider.dart';

/// Sheet de comentarios estilo Instagram: primero la lista de comentarios
/// de la publicación, con el campo para comentar fijo abajo. La lista viene
/// de parchePostsProvider (backend real) — nunca de estado local.
Future<void> showCommentsSheet(
  BuildContext context, {
  required String parcheId,
  required String postId,
}) {
  return showAppSheet<void>(
    context,
    child: _CommentsSheet(parcheId: parcheId, postId: postId),
  );
}

/// Nombres de los autores de los comentarios visibles, resueltos en batch.
final _commentAuthorsProvider =
    FutureProvider.family<Map<String, ProfileSummary>, List<String>>(
        (ref, authorIds) async {
  if (authorIds.isEmpty) return const {};
  final result =
      await ref.watch(profileRepositoryProvider).getProfilesByIds(authorIds);
  return result.when(
    success: (list) => {for (final p in list) p.id: p},
    error: (_) => const {},
  );
});

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.parcheId, required this.postId});

  final String parcheId;
  final String postId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await ref
        .read(parcheActionsProvider)
        .comment(widget.parcheId, widget.postId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    result.when(
      // parcheActionsProvider.comment ya invalida parchePostsProvider:
      // el comentario aparece solo cuando llegue el refetch.
      success: (_) => _input.clear(),
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final posts = ref.watch(parchePostsProvider(widget.parcheId));
    final post = (posts.valueOrNull ?? const <ParchePost>[])
        .where((p) => p.id == widget.postId)
        .firstOrNull;
    final comments = [...post?.comments ?? const <PostComment>[]]
      ..sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad == null || bd == null) return 0;
        return ad.compareTo(bd);
      });
    final authorIds = {for (final c in comments) c.authorId}.toList();
    final authors =
        ref.watch(_commentAuthorsProvider(authorIds)).valueOrNull ??
            const <String, ProfileSummary>{};

    // Contenedor/alto/handle: los pone AppSheet (estándar de la app).
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              comments.isEmpty
                  ? 'Comentarios'
                  : 'Comentarios (${comments.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // ── Lista de comentarios (llena los 2/3 de alto) ──
            Expanded(
              child: posts.isLoading && comments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : comments.isEmpty
                      ? const Center(
                          child: MascotEmptyState(
                            asset: AppAssets.stickerHello,
                            message:
                                'Aún no hay comentarios.\n¡Sé quien rompa el hielo!',
                          ),
                        )
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final authorName =
                                authors[comment.authorId]?.name ??
                                    'Estudiante ECI';
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 30 * index),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: scheme.tertiary
                                          .withValues(alpha: 0.25),
                                      child: Text(
                                        authorName.isNotEmpty
                                            ? authorName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  authorName,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.labelLarge,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _timeAgo(comment.createdAt),
                                                style: theme
                                                    .textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            comment.text,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const Divider(height: 20),
            // ── Escribir comentario ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Añade un comentario…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BouncyTap(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.buttonOf(context),
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
    );
  }
}

String _timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'hace ${diff.inHours} h';
  return 'hace ${diff.inDays} d';
}
