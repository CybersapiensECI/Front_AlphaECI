import 'package:dio/dio.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';

/// Zona del usuario — espejo de ZoneResponse de GeoService.
class CampusZone {
  const CampusZone({this.currentZone, this.nearbyParches = const []});

  final String? currentZone;
  final List<String> nearbyParches;
}

/// Contrato contra GeoService (/api/zone). El JWT va en Authorization
/// (el backend extrae el userId de ahí).
abstract interface class ZoneRepository {
  /// GET /catalog — zonas válidas del campus.
  Future<Result<List<String>>> getCatalog();

  /// GET /me — 404 si aún no registra zona.
  Future<Result<CampusZone?>> getMyZone();

  /// POST / — {campusZone, geoLocationEnabled}.
  Future<Result<CampusZone>> saveZone(String zone, bool enabled);
}

class ZoneRepositoryImpl implements ZoneRepository {
  const ZoneRepositoryImpl(this._dio);

  final Dio _dio;

  static const _base = '/api/zone';

  @override
  Future<Result<List<String>>> getCatalog() async {
    try {
      final response = await _dio.get<List<dynamic>>('$_base/catalog');
      return Success(
          [for (final z in response.data ?? const []) z as String]);
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<Result<CampusZone?>> getMyZone() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_base/me');
      return Success(_fromJson(response.data ?? const {}));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const Success(null);
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<Result<CampusZone>> saveZone(String zone, bool enabled) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _base,
        data: {'campusZone': zone, 'geoLocationEnabled': enabled},
      );
      return Success(_fromJson(response.data ?? const {}));
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  static CampusZone _fromJson(Map<String, dynamic> json) => CampusZone(
        currentZone: json['currentZone'] as String?,
        nearbyParches: [
          for (final p in (json['nearbyParches'] as List? ?? const []))
            p as String,
        ],
      );
}

/// TODO(demo): zonas falsas. Eliminar en prod.
class MockZoneRepository implements ZoneRepository {
  MockZoneRepository();

  CampusZone? _zone = const CampusZone(
    currentZone: 'ZONA_NORTE',
    nearbyParches: ['Fútbol 5 en la cancha norte'],
  );

  Future<Result<T>> _ok<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 350), () => Success(value));

  @override
  Future<Result<List<String>>> getCatalog() => _ok(const [
        'ZONA_NORTE',
        'ZONA_SUR',
        'BIBLIOTECA',
        'CAFETERIA_CENTRAL',
        'EDIFICIO_D',
        'CANCHAS',
      ]);

  @override
  Future<Result<CampusZone?>> getMyZone() => _ok(_zone);

  @override
  Future<Result<CampusZone>> saveZone(String zone, bool enabled) {
    _zone = CampusZone(
      currentZone: enabled ? zone : null,
      nearbyParches:
          enabled ? const ['Fútbol 5 en la cancha norte'] : const [],
    );
    return _ok(_zone!);
  }
}
