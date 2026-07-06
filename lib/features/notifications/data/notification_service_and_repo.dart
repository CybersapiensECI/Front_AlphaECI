import 'package:dio/dio.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/result.dart';
import '../domain/entities/app_notification.dart';

/// notification-service usa el header X-User-Id, que ya inyecta el
/// AuthInterceptor — no hay que pasarlo manualmente.
class NotificationApiService {
  const NotificationApiService(this._dio);

  final Dio _dio;

  static const _base = '/api/notifications';

  /// GET / — Page<NotificationResponse>: el contenido viene en `content`.
  Future<List<AppNotification>> getNotifications({int page = 0}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _base,
      queryParameters: {'page': page, 'size': 20},
    );
    final content = response.data?['content'] as List? ?? const [];
    return [
      for (final n in content) _fromJson(n as Map<String, dynamic>),
    ];
  }

  Future<int> getUnreadCount() async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_base/unread/count');
    return (response.data?['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch<void>('$_base/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch<void>('$_base/read-all');
  }

  static AppNotification _fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      type: json['type'] as String?,
      referenceId: json['referenceId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

/// Repository delgado (el servicio ya devuelve entidades).
class NotificationRepository {
  const NotificationRepository(this._api);

  final NotificationApiService _api;

  Future<Result<List<AppNotification>>> getNotifications() =>
      _guard(_api.getNotifications);

  Future<Result<int>> getUnreadCount() => _guard(_api.getUnreadCount);

  Future<Result<void>> markAsRead(String id) =>
      _guard(() => _api.markAsRead(id));

  Future<Result<void>> markAllAsRead() => _guard(_api.markAllAsRead);

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
