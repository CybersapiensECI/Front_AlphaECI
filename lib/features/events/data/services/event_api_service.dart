import 'package:dio/dio.dart';

import '../../domain/entities/event.dart';

/// HTTP crudo contra EventService (vía gateway: /api/events/** con
/// StripPrefix=1 — el backend recibe /events/**).
class EventApiService {
  const EventApiService(this._dio);

  final Dio _dio;

  static const _base = '/api/events';

  Future<List<UniversityEvent>> getEvents({String? category}) async {
    final response = await _dio.get<List<dynamic>>(
      _base,
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    return [
      for (final e in response.data ?? const [])
        _eventFromJson(e as Map<String, dynamic>),
    ];
  }

  Future<String> confirmRsvp(String eventId, String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/$eventId/rsvp',
      data: {'userId': userId},
    );
    return response.data?['rsvpStatus'] as String? ?? 'CONFIRMED';
  }

  Future<String> cancelRsvp(String eventId, String userId) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_base/$eventId/rsvp',
      data: {'userId': userId},
    );
    return response.data?['rsvpStatus'] as String? ?? 'CANCELLED';
  }

  Future<List<String>> getAgenda(String userId) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/agenda',
      queryParameters: {'userId': userId},
    );
    return [for (final id in response.data ?? const []) id as String];
  }

  static UniversityEvent _eventFromJson(Map<String, dynamic> json) {
    return UniversityEvent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      date: json['date'] as String?,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      availableCapacity: (json['availableCapacity'] as num?)?.toInt() ?? 0,
      status: json['status'] as String?,
    );
  }
}
