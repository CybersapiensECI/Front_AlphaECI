import 'package:dio/dio.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/matching_repository.dart';
import '../services/matching_api_service.dart';

class MatchingRepositoryImpl implements MatchingRepository {
  const MatchingRepositoryImpl({required this._api});

  final MatchingApiService _api;

  @override
  Future<Result<List<ScoredCandidate>>> getRecommendations(String userId) {
    return _guard(() => _api.getRecommendationsWithScores(userId));
  }

  @override
  Future<Result<Match>> createMatch({
    required String requesterId,
    required String targetId,
  }) {
    return _guard(() => _api.createMatch(requesterId, targetId));
  }

  @override
  Future<Result<List<Match>>> getReceived(String userId) {
    return _guard(() => _api.getReceived(userId));
  }

  @override
  Future<Result<List<Match>>> getSent(String userId) {
    return _guard(() => _api.getSent(userId));
  }

  @override
  Future<Result<Match>> respond({
    required String matchId,
    required String userId,
    required MatchStatus status,
  }) {
    return _guard(() => _api.respond(matchId, userId, status));
  }

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Success(await call());
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }
}
