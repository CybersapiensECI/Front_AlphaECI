import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/repositories/matching_repository_impl.dart';
import '../../data/services/matching_api_service.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/matching_repository.dart';

final matchingApiServiceProvider = Provider<MatchingApiService>((ref) {
  return MatchingApiService(ref.watch(apiClientProvider(Env.matchingUrl)));
});

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  return MatchingRepositoryImpl(api: ref.watch(matchingApiServiceProvider));
});

/// Candidato listo para pintar: score + perfil resumido.
class DiscoveryCandidate {
  const DiscoveryCandidate({required this.scored, required this.profile});

  final ScoredCandidate scored;
  final ProfileSummary profile;
}

/// Mazo de descubrimiento: recomendaciones con score + perfiles (batch).
class DiscoveryController extends AsyncNotifier<List<DiscoveryCandidate>> {
  @override
  Future<List<DiscoveryCandidate>> build() async {
    final session = ref.watch(authControllerProvider).session;
    if (session == null) throw const AuthFailure();

    final recommendations = await ref
        .read(matchingRepositoryProvider)
        .getRecommendations(session.userId);

    return recommendations.when(
      error: (failure) => throw failure,
      success: (scored) async {
        if (scored.isEmpty) return const <DiscoveryCandidate>[];
        final profiles = await ref
            .read(profileRepositoryProvider)
            .getProfilesByIds([for (final s in scored) s.targetUserId]);
        final byId = {
          for (final p in profiles.dataOrNull ?? const <ProfileSummary>[])
            p.id: p,
        };
        return [
          for (final s in scored)
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

/// Solicitudes recibidas (yo soy target → la otra persona es requester).
final receivedMatchesProvider =
    FutureProvider<List<MatchWithProfile>>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) throw const AuthFailure();
  final result =
      await ref.read(matchingRepositoryProvider).getReceived(session.userId);
  return result.when(
    error: (failure) => throw failure,
    success: (matches) => _withProfiles(ref, matches, (m) => m.requesterId),
  );
});

/// Solicitudes enviadas (yo soy requester → la otra persona es target).
final sentMatchesProvider =
    FutureProvider<List<MatchWithProfile>>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) throw const AuthFailure();
  final result =
      await ref.read(matchingRepositoryProvider).getSent(session.userId);
  return result.when(
    error: (failure) => throw failure,
    success: (matches) => _withProfiles(ref, matches, (m) => m.targetId),
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
      _ref.invalidate(receivedMatchesProvider);
      _ref.invalidate(sentMatchesProvider);
    }
    return result;
  }
}
