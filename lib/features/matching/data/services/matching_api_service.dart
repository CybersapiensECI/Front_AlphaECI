import 'package:dio/dio.dart';

import '../../domain/entities/match.dart';

/// HTTP crudo contra matching-service.
class MatchingApiService {
  const MatchingApiService(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/matches';

  Future<List<ScoredCandidate>> getRecommendationsWithScores(
    String userId,
  ) async {
    final response =
        await _dio.get<List<dynamic>>('$_base/recommendations/$userId/scores');
    return [
      for (final r in response.data ?? const [])
        _scoredCandidateFromJson(r as Map<String, dynamic>),
    ];
  }

  Future<Match> createMatch(String requesterId, String targetId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _base,
      data: {'requesterId': requesterId, 'targetId': targetId},
    );
    return _matchFromJson(response.data!);
  }

  Future<List<Match>> getReceived(String userId) async {
    final response =
        await _dio.get<List<dynamic>>('$_base/user/$userId/received');
    return [
      for (final m in response.data ?? const [])
        _matchFromJson(m as Map<String, dynamic>),
    ];
  }

  Future<List<Match>> getSent(String userId) async {
    final response = await _dio.get<List<dynamic>>('$_base/user/$userId/sent');
    return [
      for (final m in response.data ?? const [])
        _matchFromJson(m as Map<String, dynamic>),
    ];
  }

  Future<Match> respond(
    String matchId,
    String userId,
    MatchStatus status,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/$matchId/status',
      queryParameters: {'userId': userId},
      data: {'status': status.api},
    );
    return _matchFromJson(response.data!);
  }

  // ── parsers (espejo de MatchResponse / RecommendationWithScoreResponse) ──

  static Match _matchFromJson(Map<String, dynamic> json) {
    final affinity = json['affinityScore'] as Map<String, dynamic>?;
    return Match(
      id: json['idMatch'] as String,
      requesterId: json['requesterId'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      status: MatchStatus.fromApi(json['status'] as String?),
      score: (affinity?['score'] as num?)?.toDouble(),
    );
  }

  static ScoredCandidate _scoredCandidateFromJson(Map<String, dynamic> json) {
    return ScoredCandidate(
      targetUserId: json['targetUserId'] as String,
      totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0,
      interestScore: (json['interestScore'] as num?)?.toDouble() ?? 0,
      academicScore: (json['academicScore'] as num?)?.toDouble() ?? 0,
      scheduleScore: (json['scheduleScore'] as num?)?.toDouble() ?? 0,
    );
  }
}
