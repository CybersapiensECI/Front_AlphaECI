import '../../../../core/errors/result.dart';
import '../entities/event.dart';

/// Contrato contra EventService (/events).
abstract interface class EventRepository {
  /// GET /events?category&startDate&endDate.
  Future<Result<List<UniversityEvent>>> getEvents({String? category});

  /// POST /events/{id}/rsvp — {userId}.
  Future<Result<String>> confirmRsvp(String eventId, String userId);

  /// PUT /events/{id}/rsvp — {userId} (cancela).
  Future<Result<String>> cancelRsvp(String eventId, String userId);

  /// GET /events/agenda?userId — ids de eventos confirmados.
  Future<Result<List<String>>> getAgenda(String userId);
}
