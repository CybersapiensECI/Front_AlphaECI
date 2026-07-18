import '../../../../core/errors/result.dart';
import '../entities/match.dart';

/// Contrato contra matching-service (/api/v1/matches).
abstract interface class MatchingRepository {
  /// GET /recommendations/{userId}/scores.
  Future<Result<List<ScoredCandidate>>> getRecommendations(String userId);

  /// POST /recommendations/{userId}/filtered — ids que pasan los filtros
  /// (carrera, semestre, tag, cercanía). 404 del backend = nadie pasa el
  /// filtro = Success con lista vacía.
  Future<Result<List<String>>> getFilteredRecommendationIds(
    String userId,
    DiscoveryFilters filters,
  );

  /// POST / — {requesterId, targetId}.
  Future<Result<Match>> createMatch({
    required String requesterId,
    required String targetId,
  });

  /// GET /user/{userId}/received.
  Future<Result<List<Match>>> getReceived(String userId);

  /// GET /user/{userId}/sent.
  Future<Result<List<Match>>> getSent(String userId);

  /// PATCH /{id}/status?userId= — {status}.
  Future<Result<Match>> respond({
    required String matchId,
    required String userId,
    required MatchStatus status,
  });

  /// GET /relationship?userId=&otherUserId= — fuente única de verdad para
  /// el botón del perfil público.
  Future<Result<Relationship>> getRelationship({
    required String userId,
    required String otherUserId,
  });

  /// DELETE /friends/{friendId}?userId=.
  Future<Result<void>> removeFriend({
    required String userId,
    required String friendId,
  });
}
