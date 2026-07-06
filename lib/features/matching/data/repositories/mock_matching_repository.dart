// TODO(demo): datos falsos para ver la app sin backends. Eliminar en prod.
import '../../../../core/errors/result.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/matching_repository.dart';

class MockMatchingRepository implements MatchingRepository {
  MockMatchingRepository();

  final List<Match> _sent = [
    const Match(
      id: 'm1',
      requesterId: '11111111-1111-1111-1111-111111111111',
      targetId: 'u4',
      status: MatchStatus.accepted,
      score: 0.87,
    ),
  ];

  final List<Match> _received = [
    const Match(
      id: 'm2',
      requesterId: 'u3',
      targetId: '11111111-1111-1111-1111-111111111111',
      status: MatchStatus.pending,
      score: 0.72,
    ),
    const Match(
      id: 'm3',
      requesterId: 'u5',
      targetId: '11111111-1111-1111-1111-111111111111',
      status: MatchStatus.pending,
      score: 0.64,
    ),
  ];

  var _nextId = 10;

  Future<Result<T>> _ok<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 400), () => Success(value));

  @override
  Future<Result<List<ScoredCandidate>>> getRecommendations(String userId) {
    return _ok(const [
      ScoredCandidate(
        targetUserId: 'u2',
        totalScore: 0.91,
        interestScore: 0.95,
        academicScore: 0.88,
        scheduleScore: 0.85,
      ),
      ScoredCandidate(
        targetUserId: 'u3',
        totalScore: 0.76,
        interestScore: 0.70,
        academicScore: 0.82,
        scheduleScore: 0.75,
      ),
      ScoredCandidate(
        targetUserId: 'u4',
        totalScore: 0.68,
        interestScore: 0.72,
        academicScore: 0.55,
        scheduleScore: 0.80,
      ),
      ScoredCandidate(
        targetUserId: 'u5',
        totalScore: 0.54,
        interestScore: 0.40,
        academicScore: 0.66,
        scheduleScore: 0.58,
      ),
    ]);
  }

  @override
  Future<Result<Match>> createMatch({
    required String requesterId,
    required String targetId,
  }) {
    final match = Match(
      id: 'm${_nextId++}',
      requesterId: requesterId,
      targetId: targetId,
      // Ana (u2) acepta al instante para mostrar el overlay de match.
      status: targetId == 'u2' ? MatchStatus.accepted : MatchStatus.pending,
      score: 0.9,
    );
    _sent.add(match);
    return _ok(match);
  }

  @override
  Future<Result<List<Match>>> getReceived(String userId) =>
      _ok(List.of(_received));

  @override
  Future<Result<List<Match>>> getSent(String userId) => _ok(List.of(_sent));

  @override
  Future<Result<Match>> respond({
    required String matchId,
    required String userId,
    required MatchStatus status,
  }) {
    final index = _received.indexWhere((m) => m.id == matchId);
    if (index >= 0) {
      final old = _received[index];
      _received[index] = Match(
        id: old.id,
        requesterId: old.requesterId,
        targetId: old.targetId,
        status: status,
        score: old.score,
      );
      return _ok(_received[index]);
    }
    return _ok(_received.first);
  }
}
