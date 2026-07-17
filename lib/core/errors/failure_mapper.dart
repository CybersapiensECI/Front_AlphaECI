import 'package:dio/dio.dart';

import 'failures.dart';

/// Convierte DioException en Failure legible.
/// Todos los backends tienen GlobalExceptionHandler: intenta extraer
/// `message` (o `error`) del body JSON antes de usar mensajes genéricos.
Failure mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode ?? 0;
      final backendMessage = _extractMessage(e.response?.data);
      if (status == 401 || status == 403) {
        return AuthFailure(backendMessage ?? 'Sesión inválida o expirada.');
      }
      if (status == 404) {
        return NotFoundFailure(backendMessage ?? 'Recurso no encontrado.');
      }
      if (status >= 400 && status < 500) {
        return ValidationFailure(backendMessage ?? 'Datos inválidos.');
      }
      return ServerFailure(
        message: backendMessage ?? 'Error del servidor. Intenta luego.',
        statusCode: status,
      );
    case DioExceptionType.cancel:
      return const UnknownFailure('Operación cancelada.');
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return const UnknownFailure();
  }
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final m = data['message'] ?? data['error'] ?? data['detail'];
    if (m is String && m.isNotEmpty) return m;
  }
  return null;
}
