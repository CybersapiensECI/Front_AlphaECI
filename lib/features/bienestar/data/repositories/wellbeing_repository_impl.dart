import 'package:dio/dio.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../events/domain/entities/event.dart';
import '../../domain/entities/wellbeing.dart';
import '../../domain/repositories/wellbeing_repository.dart';

class WellbeingRepositoryImpl implements WellbeingRepository {
  const WellbeingRepositoryImpl(this._dio);

  final Dio _dio;

  static const _base = '/bienestar';

  @override
  Future<Result<List<WellbeingResource>>> getResources({String? category}) {
    return _guard(() async {
      final response = await _dio.get<List<dynamic>>(
        '$_base/resources',
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      return [
        for (final r in response.data ?? const [])
          _resourceFromJson(r as Map<String, dynamic>),
      ];
    });
  }

  @override
  Future<Result<List<EmergencyContact>>> getContacts() {
    return _guard(() async {
      final response = await _dio.get<List<dynamic>>('$_base/contacts');
      return [
        for (final c in response.data ?? const [])
          _contactFromJson(c as Map<String, dynamic>),
      ];
    });
  }

  @override
  Future<Result<List<UniversityEvent>>> getWellbeingEvents() {
    return _guard(() async {
      final response = await _dio.get<List<dynamic>>('$_base/events');
      return [
        for (final e in response.data ?? const [])
          _eventFromJson(e as Map<String, dynamic>),
      ];
    });
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

  static WellbeingResource _resourceFromJson(Map<String, dynamic> json) =>
      WellbeingResource(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        type: json['type'] as String?,
        category: json['category'] as String?,
      );

  static EmergencyContact _contactFromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );

  // EventDTO de bienestar: {id, name, description, category, date,
  // availableCapacity}.
  static UniversityEvent _eventFromJson(Map<String, dynamic> json) =>
      UniversityEvent(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        category: json['category'] as String?,
        date: json['date'] as String?,
        availableCapacity:
            (json['availableCapacity'] as num?)?.toInt() ?? 0,
        status: 'ACTIVE',
      );
}
