import 'package:dio/dio.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../services/event_api_service.dart';

class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl({required this._api});

  final EventApiService _api;

  @override
  Future<Result<List<UniversityEvent>>> getEvents({String? category}) {
    return _guard(() => _api.getEvents(category: category));
  }

  @override
  Future<Result<String>> confirmRsvp(String eventId, String userId) {
    return _guard(() => _api.confirmRsvp(eventId, userId));
  }

  @override
  Future<Result<String>> cancelRsvp(String eventId, String userId) {
    return _guard(() => _api.cancelRsvp(eventId, userId));
  }

  @override
  Future<Result<List<String>>> getAgenda(String userId) {
    return _guard(() => _api.getAgenda(userId));
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
