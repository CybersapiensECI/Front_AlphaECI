import 'package:equatable/equatable.dart';

/// Estados reales del enum MatchStatus de matching-service.
enum MatchStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED');

  const MatchStatus(this.api);
  final String api;

  static MatchStatus fromApi(String? value) => MatchStatus.values.firstWhere(
        (s) => s.api == value,
        orElse: () => MatchStatus.pending,
      );
}

/// Espejo de MatchResponse.
class Match extends Equatable {
  const Match({
    required this.id,
    required this.requesterId,
    required this.targetId,
    required this.status,
    this.score,
  });

  final String id;
  final String requesterId;
  final String targetId;
  final MatchStatus status;
  final double? score;

  @override
  List<Object?> get props => [id, requesterId, targetId, status, score];
}

/// Estado real de la relación entre dos usuarios (espejo de
/// RelationshipResponse) — fuente única de verdad para el botón del perfil
/// público: FRIEND/PENDING_SENT/PENDING_RECEIVED/NONE.
enum RelationshipStatus {
  friend('FRIEND'),
  pendingSent('PENDING_SENT'),
  pendingReceived('PENDING_RECEIVED'),
  none('NONE');

  const RelationshipStatus(this.api);
  final String api;

  static RelationshipStatus fromApi(String? value) =>
      RelationshipStatus.values.firstWhere(
        (s) => s.api == value,
        orElse: () => RelationshipStatus.none,
      );
}

class Relationship extends Equatable {
  const Relationship({required this.status, this.matchId});

  final RelationshipStatus status;
  final String? matchId;

  @override
  List<Object?> get props => [status, matchId];
}

/// Espejo de RecommendationWithScoreResponse.
class ScoredCandidate extends Equatable {
  const ScoredCandidate({
    required this.targetUserId,
    required this.totalScore,
    required this.interestScore,
    required this.academicScore,
    required this.scheduleScore,
  });

  final String targetUserId;
  final double totalScore;
  final double interestScore;
  final double academicScore;
  final double scheduleScore;

  @override
  List<Object?> get props => [targetUserId, totalScore];
}
