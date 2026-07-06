import 'package:dio/dio.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../domain/entities/personal_stats.dart';

/// Contrato contra Estadisticas_Eci (/api/v1/metrics).
abstract interface class StatsRepository {
  /// GET /user/{userId} — estadísticas personales agregadas.
  Future<Result<PersonalStats>> getPersonalStats(String userId);
}

class StatsRepositoryImpl implements StatsRepository {
  const StatsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<PersonalStats>> getPersonalStats(String userId) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/v1/metrics/user/$userId');
      return Success(_fromJson(response.data ?? const {}));
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  static PersonalStats _fromJson(Map<String, dynamic> json) {
    final gamification = json['gamification'] as Map<String, dynamic>?;
    final events = json['events'] as Map<String, dynamic>?;
    final parches = json['parches'] as Map<String, dynamic>?;
    final profile = json['profile'] as Map<String, dynamic>?;
    return PersonalStats(
      userId: json['userId'] as String? ?? '',
      gamification: gamification == null
          ? null
          : GamificationStats(
              totalXp: (gamification['totalXp'] as num?)?.toInt() ?? 0,
              totalMonasUnlocked:
                  (gamification['totalMonasUnlocked'] as num?)?.toInt() ?? 0,
              monasInProgress:
                  (gamification['monasInProgress'] as num?)?.toInt() ?? 0,
              monasLocked:
                  (gamification['monasLocked'] as num?)?.toInt() ?? 0,
              completionPercentage:
                  (gamification['completionPercentage'] as num?)
                          ?.toDouble() ??
                      0,
            ),
      events: events == null
          ? null
          : EventStats(
              totalAttended: (events['totalAttended'] as num?)?.toInt() ?? 0,
              upcomingEvents:
                  (events['upcomingEvents'] as num?)?.toInt() ?? 0,
              totalEvents: (events['totalEvents'] as num?)?.toInt() ?? 0,
            ),
      parches: parches == null
          ? null
          : ParcheStats(
              totalJoined: (parches['totalJoined'] as num?)?.toInt() ?? 0,
              activeParches:
                  (parches['activeParches'] as num?)?.toInt() ?? 0,
            ),
      profile: profile == null
          ? null
          : ProfileStats(
              xp: (profile['xp'] as num?)?.toInt() ?? 0,
              level: (profile['level'] as num?)?.toInt() ?? 1,
              isActive: profile['isActive'] as bool? ?? true,
              career: profile['career'] as String?,
              semester: (profile['semester'] as num?)?.toInt(),
            ),
    );
  }
}

/// TODO(demo): stats falsas. Eliminar en prod.
class MockStatsRepository implements StatsRepository {
  const MockStatsRepository();

  @override
  Future<Result<PersonalStats>> getPersonalStats(String userId) {
    return Future.delayed(
      const Duration(milliseconds: 450),
      () => Success(PersonalStats(
        userId: userId,
        gamification: const GamificationStats(
          totalXp: 340,
          totalMonasUnlocked: 3,
          monasInProgress: 2,
          monasLocked: 2,
          completionPercentage: 42.8,
        ),
        events: const EventStats(
            totalAttended: 5, upcomingEvents: 1, totalEvents: 6),
        parches: const ParcheStats(totalJoined: 4, activeParches: 1),
        profile: const ProfileStats(
          xp: 340,
          level: 4,
          isActive: true,
          career: 'SYSTEMS_ENGINEERING',
          semester: 4,
        ),
      )),
    );
  }
}
