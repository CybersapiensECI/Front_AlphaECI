import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../parches/domain/entities/parche.dart';
import '../../../parches/presentation/providers/parche_provider.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Publicación del feed principal: post de un parche + contexto
/// (parche de origen para el color de categoría, autor para avatar/nombre).
class FeedPublication {
  const FeedPublication({
    required this.post,
    required this.parche,
    this.author,
  });

  final ParchePost post;
  final Parche parche;
  final ProfileSummary? author;
}

/// Filtro de categoría del feed principal (null = todas).
final feedCategoryProvider = StateProvider<String?>((_) => null);

/// Likes dados en esta sesión (optimista).
/// TODO(backend): GET de posts no expone contadores de reacciones ni
/// comentarios; cuando existan, reemplazar este estado local.
final likedPostsProvider = StateProvider<Set<String>>((_) => <String>{});

/// Feed principal: agrega las publicaciones de todos los parches visibles,
/// resuelve autores en batch y ordena por fecha descendente.
final publicationsProvider =
    FutureProvider<List<FeedPublication>>((ref) async {
  final repo = ref.watch(parcheRepositoryProvider);
  final category = ref.watch(feedCategoryProvider);

  final parchesResult = await repo.search();
  final parches = parchesResult.when(
    success: (p) => p,
    error: (failure) => throw failure,
  );

  final visible = [
    for (final p in parches)
      if (category == null || p.category?.toUpperCase() == category) p,
  ];

  // Posts de cada parche en paralelo. Un parche que falle no tumba el feed.
  final postsResults =
      await Future.wait([for (final p in visible) repo.getPosts(p.id)]);

  final items = <FeedPublication>[];
  final authorIds = <String>{};
  for (var i = 0; i < visible.length; i++) {
    postsResults[i].when(
      success: (posts) {
        for (final post in posts) {
          items.add(FeedPublication(post: post, parche: visible[i]));
          authorIds.add(post.authorId);
        }
      },
      error: (_) {},
    );
  }

  // Autores en batch (foto + nombre). Si falla, el feed sale sin autor.
  var authors = const <String, ProfileSummary>{};
  if (authorIds.isNotEmpty) {
    final profilesResult = await ref
        .watch(profileRepositoryProvider)
        .getProfilesByIds(authorIds.toList());
    profilesResult.when(
      success: (list) => authors = {for (final s in list) s.id: s},
      error: (_) {},
    );
  }

  final enriched = [
    for (final item in items)
      FeedPublication(
        post: item.post,
        parche: item.parche,
        author: authors[item.post.authorId],
      ),
  ];

  enriched.sort((a, b) {
    final ad = a.post.createdAt;
    final bd = b.post.createdAt;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return bd.compareTo(ad);
  });
  return enriched;
});

/// Parche donde el usuario puede publicar AHORA: es miembro, está ACTIVE
/// y ocurre hoy. Regla de negocio: solo se publica durante el parche.
/// TODO(backend): el Parche no expone hora de fin; la ventana usada es
/// el día completo del parche. Afinar cuando exista endTime.
final publishableParcheProvider = FutureProvider<Parche?>((ref) async {
  final userId = ref.watch(authControllerProvider).session?.userId;
  if (userId == null) return null;

  final result = await ref.watch(parcheRepositoryProvider).search();
  final parches = result.when(
    success: (p) => p,
    error: (failure) => throw failure,
  );

  final now = DateTime.now();
  for (final p in parches) {
    if (p.status != 'ACTIVE' || !p.isMember(userId)) continue;
    final date = p.date;
    if (date == null) continue;
    final sameDay = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    if (sameDay) return p;
  }
  return null;
});
