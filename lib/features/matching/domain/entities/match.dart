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
