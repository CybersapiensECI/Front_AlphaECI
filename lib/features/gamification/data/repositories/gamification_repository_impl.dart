import 'package:dio/dio.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/mona.dart';
import '../../domain/repositories/gamification_repository.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  const GamificationRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<UserMonas>> getUserMonas(String userId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
          '/api/v1/gamification/users/$userId/monas');
      return Success(_userMonasFromJson(response.data ?? const {}));
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  static UserMonas _userMonasFromJson(Map<String, dynamic> json) {
    List<Mona> parse(String key) => [
          for (final m in (json[key] as List? ?? const []))
            _monaFromJson(m as Map<String, dynamic>),
        ];
    return UserMonas(
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      totalUnlocked: (json['totalUnlocked'] as num?)?.toInt() ?? 0,
      unlocked: parse('unlocked'),
      inProgress: parse('inProgress'),
      locked: parse('locked'),
    );
  }

  static Mona _monaFromJson(Map<String, dynamic> json) => Mona(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        rarity: json['rarity'] as String?,
        imageUrl: json['imageUrl'] as String?,
        xpGranted: (json['xpGranted'] as num?)?.toInt() ?? 0,
        progressPercentage: (json['progressPercentage'] as num?)?.toInt(),
        currentCount: (json['currentCount'] as num?)?.toInt(),
        requiredCount: (json['requiredCount'] as num?)?.toInt(),
      );
}
