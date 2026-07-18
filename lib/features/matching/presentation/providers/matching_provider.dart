import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/repositories/matching_repository_impl.dart';
import '../../data/repositories/mock_matching_repository.dart';
import '../../data/services/matching_api_service.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/matching_repository.dart';

final matchingApiServiceProvider = Provider<MatchingApiService>((ref) {
  return MatchingApiService(ref.watch(apiClientProvider(Env.matchingUrl)));
});

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  if (Env.demoMode) return MockMatchingRepository();
  return MatchingRepositoryImpl(api: ref.watch(matchingApiServiceProvider));
});

/// Candidato listo para pintar: score + perfil resumido.
class DiscoveryCandidate {
  const DiscoveryCandidate({required this.scored, required this.profile});

  final ScoredCandidate scored;
  final ProfileSummary profile;
}

/// Filtros activos del descubrimiento (carrera/semestre/interés/cercanía).
final discoveryFiltersProvider =
    StateProvider<DiscoveryFilters>((ref) => const DiscoveryFilters());

/// Mazo de descubrimiento: recomendaciones con score + perfiles (batch),
/// siempre ordenado de mayor a menor % de afinidad. Con filtros activos se
/// cruza con POST /filtered conservando ese orden.
class DiscoveryController extends AsyncNotifier<List<DiscoveryCandidate>> {
  @override
  Future<List<DiscoveryCandidate>> build() async {
    final session = ref.watch(authControllerProvider).session;
    if (session == null) throw const AuthFailure();
    final filters = ref.watch(discoveryFiltersProvider);
    final repo = ref.read(matchingRepositoryProvider);

    final recommendations = await repo.getRecommendations(session.userId);

    return recommendations.when(
      error: (failure) => throw failure,
      success: (scored) async {
        // Orden garantizado en el cliente: de mayor a menor afinidad,
        // sin depender del orden que devuelva el backend.
        var ranked = List.of(scored)
          ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

        if (filters.hasAny) {
          final filtered = await repo.getFilteredRecommendationIds(
            session.userId,
            filters,
          );
          final allowed = (filtered.dataOrNull ?? const <String>[]).toSet();
          ranked = [
            for (final s in ranked)
              if (allowed.contains(s.targetUserId)) s,
          ];
        }

        if (ranked.isEmpty) return const <DiscoveryCandidate>[];
        final profiles = await ref
            .read(profileRepositoryProvider)
            .getProfilesByIds([for (final s in ranked) s.targetUserId]);
        final byId = {
          for (final p in profiles.dataOrNull ?? const <ProfileSummary>[])
            p.id: p,
        };
        return [
          for (final s in ranked)
            DiscoveryCandidate(
              scored: s,
              profile: byId[s.targetUserId] ??
                  ProfileSummary(id: s.targetUserId, name: 'Estudiante ECI'),
            ),
        ];
      },
    );
  }

  void _removeFromDeck(String targetUserId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final c in current)
        if (c.scored.targetUserId != targetUserId) c,
    ]);
  }

  /// Swipe derecha: crea solicitud de match. Devuelve el Match creado
  /// (status ACCEPTED significa match mutuo instantáneo).
  Future<Result<Match>> like(DiscoveryCandidate candidate) async {
    final session = ref.read(authControllerProvider).session;
    if (session == null) return const Error(AuthFailure());
    _removeFromDeck(candidate.scored.targetUserId);
    return ref.read(matchingRepositoryProvider).createMatch(
          requesterId: session.userId,
          targetId: candidate.scored.targetUserId,
        );
  }

  /// Swipe izquierda: solo lo saca del mazo local.
  void skip(DiscoveryCandidate candidate) {
    _removeFromDeck(candidate.scored.targetUserId);
  }
}

final discoveryProvider =
    AsyncNotifierProvider<DiscoveryController, List<DiscoveryCandidate>>(
        DiscoveryController.new);

/// Match + perfil de la otra persona (para listas de solicitudes).
class MatchWithProfile {
  const MatchWithProfile({required this.match, required this.profile});

  final Match match;
  final ProfileSummary profile;
}

Future<List<MatchWithProfile>> _withProfiles(
  Ref ref,
  List<Match> matches,
  String Function(Match) otherId,
) async {
  if (matches.isEmpty) return const [];
  final profiles = await ref
      .read(profileRepositoryProvider)
      .getProfilesByIds([for (final m in matches) otherId(m)]);
  final byId = {
    for (final p in profiles.dataOrNull ?? const <ProfileSummary>[]) p.id: p,
  };
  return [
    for (final m in matches)
      MatchWithProfile(
        match: m,
        profile: byId[otherId(m)] ??
            ProfileSummary(id: otherId(m), name: 'Estudiante ECI'),
      ),
  ];
}

/// IDs de amigos reales (perfil propio, friendsId) — única fuente de verdad,
/// la misma que matching-service consulta primero en /relationship. No se
/// deriva de documentos de match: matching-service permitía (antes del fix
/// de hoy) que existieran dos Match independientes para el mismo par —uno
/// por dirección— con estados que podían divergir (uno REJECTED viejo y
/// otro ACCEPTED más reciente), lo que hacía aparecer a un amigo real como
/// "Rechazada" en Enviadas. Enviadas/Recibidas se filtran contra esto.
final friendIdsProvider = FutureProvider<Set<String>>((ref) async {
  final profile = await ref.watch(myProfileProvider.future);
  return profile.friendsId.toSet();
});

/// Solicitudes recibidas (yo soy target → la otra persona es requester).
/// Excluye a quien ya es amigo real: un match viejo (aceptado o rechazado
/// en el otro sentido) no debe seguir apareciendo como solicitud.
final receivedMatchesProvider =
    FutureProvider<List<MatchWithProfile>>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) throw const AuthFailure();
  final friendIds = await ref.watch(friendIdsProvider.future);
  final result =
      await ref.read(matchingRepositoryProvider).getReceived(session.userId);
  return result.when(
    error: (failure) => throw failure,
    success: (matches) => _withProfiles(
      ref,
      [for (final m in matches) if (!friendIds.contains(m.requesterId)) m],
      (m) => m.requesterId,
    ),
  );
});

/// Solicitudes enviadas (yo soy requester → la otra persona es target).
final sentMatchesProvider =
    FutureProvider<List<MatchWithProfile>>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) throw const AuthFailure();
  final friendIds = await ref.watch(friendIdsProvider.future);
  final result =
      await ref.read(matchingRepositoryProvider).getSent(session.userId);
  return result.when(
    error: (failure) => throw failure,
    success: (matches) => _withProfiles(
      ref,
      [for (final m in matches) if (!friendIds.contains(m.targetId)) m],
      (m) => m.targetId,
    ),
  );
});

/// Amistades: perfiles resueltos directo de friendsId (ver friendIdsProvider).
final friendsProvider = FutureProvider<List<MatchWithProfile>>((ref) async {
  final friendIds = await ref.watch(friendIdsProvider.future);
  if (friendIds.isEmpty) return const [];
  final result = await ref
      .read(profileRepositoryProvider)
      .getProfilesByIds(friendIds.toList());
  return result.when(
    success: (profiles) => [
      for (final p in profiles)
        MatchWithProfile(
          match: Match(
            id: '',
            requesterId: '',
            targetId: p.id,
            status: MatchStatus.accepted,
          ),
          profile: p,
        ),
    ],
    error: (_) => const [],
  );
});

/// Relación con otro usuario (fuente única para el botón del perfil
/// público): FRIEND, PENDING_SENT, PENDING_RECEIVED o NONE.
final relationshipProvider =
    FutureProvider.family<Relationship, String>((ref, otherUserId) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) throw const AuthFailure();
  final result = await ref.read(matchingRepositoryProvider).getRelationship(
        userId: session.userId,
        otherUserId: otherUserId,
      );
  return result.when(
    success: (relationship) => relationship,
    error: (failure) => throw failure,
  );
});

/// Aceptar/rechazar una solicitud recibida.
final matchActionsProvider = Provider<MatchActions>((ref) => MatchActions(ref));

class MatchActions {
  const MatchActions(this._ref);

  final Ref _ref;

  Future<Result<Match>> respond(String matchId, MatchStatus status) async {
    final session = _ref.read(authControllerProvider).session;
    if (session == null) return const Error(AuthFailure());
    final result = await _ref.read(matchingRepositoryProvider).respond(
          matchId: matchId,
          userId: session.userId,
          status: status,
        );
    if (result.isSuccess) {
      _ref.invalidate(friendIdsProvider);
      _ref.invalidate(receivedMatchesProvider);
      _ref.invalidate(sentMatchesProvider);
    }
    return result;
  }

  Future<Result<void>> removeFriend(String friendId) async {
    final session = _ref.read(authControllerProvider).session;
    if (session == null) return const Error(AuthFailure());
    final result = await _ref.read(matchingRepositoryProvider).removeFriend(
          userId: session.userId,
          friendId: friendId,
        );
    if (result.isSuccess) {
      _ref.invalidate(friendIdsProvider);
      _ref.invalidate(receivedMatchesProvider);
      _ref.invalidate(sentMatchesProvider);
    }
    return result;
  }
}
