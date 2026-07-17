import '../../../../core/errors/result.dart';
import '../entities/mona.dart';

/// Contrato contra GamificationService (/api/v1/gamification).
abstract interface class GamificationRepository {
  /// GET /users/{userId}/monas.
  Future<Result<UserMonas>> getUserMonas(String userId);
}
