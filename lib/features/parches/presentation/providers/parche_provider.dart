import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/parche_repository_impl.dart';
import '../../data/services/parche_api_service.dart';
import '../../domain/entities/parche.dart';
import '../../domain/repositories/parche_repository.dart';

final parcheApiServiceProvider = Provider<ParcheApiService>((ref) {
  return ParcheApiService(ref.watch(apiClientProvider(Env.parchesUrl)));
});

final parcheRepositoryProvider = Provider<ParcheRepository>((ref) {
  return ParcheRepositoryImpl(api: ref.watch(parcheApiServiceProvider));
});

/// Filtro del feed de parches.
class ParcheFilter {
  const ParcheFilter({this.query, this.category});

  final String? query;
  final String? category;

  ParcheFilter copyWith({String? query, String? category}) => ParcheFilter(
        query: query ?? this.query,
        category: category ?? this.category,
      );
}

final parcheFilterProvider =
    StateProvider<ParcheFilter>((_) => const ParcheFilter());

/// Feed de parches activos según filtro.
final parcheFeedProvider = FutureProvider<List<Parche>>((ref) async {
  final filter = ref.watch(parcheFilterProvider);
  final result = await ref.watch(parcheRepositoryProvider).search(
        query: filter.query,
        category: filter.category,
      );
  return result.when(
    success: (parches) => parches,
    error: (failure) => throw failure,
  );
});

/// Miembros de un parche.
final parcheMembersProvider =
    FutureProvider.family<List<ParcheMember>, String>((ref, parcheId) async {
  final result =
      await ref.watch(parcheRepositoryProvider).getMembers(parcheId);
  return result.when(
    success: (members) => members,
    error: (failure) => throw failure,
  );
});

/// Posts de un parche.
final parchePostsProvider =
    FutureProvider.family<List<ParchePost>, String>((ref, parcheId) async {
  final result = await ref.watch(parcheRepositoryProvider).getPosts(parcheId);
  return result.when(
    success: (posts) => posts,
    error: (failure) => throw failure,
  );
});

final parcheActionsProvider =
    Provider<ParcheActions>((ref) => ParcheActions(ref));

class ParcheActions {
  const ParcheActions(this._ref);

  final Ref _ref;

  String? get _userId => _ref.read(authControllerProvider).session?.userId;

  Future<Result<String>> join(String parcheId) async {
    final userId = _userId;
    if (userId == null) return const Error(AuthFailure());
    final result =
        await _ref.read(parcheRepositoryProvider).join(parcheId, userId);
    if (result.isSuccess) {
      _ref.invalidate(parcheFeedProvider);
      _ref.invalidate(parcheMembersProvider(parcheId));
    }
    return result;
  }

  Future<Result<String>> create({
    required String name,
    required String description,
    required String place,
    required String category,
    required String type,
    required DateTime date,
    required String hour,
    required int maximumQuota,
  }) async {
    final userId = _userId;
    if (userId == null) return const Error(AuthFailure());
    final result = await _ref.read(parcheRepositoryProvider).create(
          name: name,
          description: description,
          place: place,
          category: category,
          type: type,
          date: date,
          hour: hour,
          maximumQuota: maximumQuota,
          creatorStudentId: userId,
        );
    if (result.isSuccess) _ref.invalidate(parcheFeedProvider);
    return result;
  }

  Future<Result<String>> createPost(String parcheId, String text) async {
    final userId = _userId;
    if (userId == null) return const Error(AuthFailure());
    final result = await _ref.read(parcheRepositoryProvider).createPost(
          parcheId: parcheId,
          authorId: userId,
          text: text,
        );
    if (result.isSuccess) _ref.invalidate(parchePostsProvider(parcheId));
    return result;
  }
}
