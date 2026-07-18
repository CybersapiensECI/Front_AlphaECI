import 'package:dio/dio.dart';

import 'backend_message_translator.dart';
import 'failures.dart';

/// Convierte DioException en Failure legible.
/// Todos los backends tienen GlobalExceptionHandler: intenta extraer
/// `message` (o `error`) del body JSON antes de usar mensajes genéricos.
/// Los mensajes crudos vienen casi todos en inglés (salvo Parches-Service):
/// se traducen acá, único punto por el que pasan todos los repositorios,
/// antes de convertirse en un Failure que la UI muestra tal cual.
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
      final backendMessage = _translatedMessage(e.response?.data);
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

String? _translatedMessage(dynamic data) {
  final raw = _extractMessage(data);
  return raw == null ? null : translateBackendMessage(raw);
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final m = data['message'] ?? data['error'] ?? data['detail'];
    if (m is String && m.isNotEmpty) return m;
    // Spring @Valid en 400 a veces manda una LISTA de errores de campo
    // (ej. [{field, message}]) en vez de un solo `message` string —
    // sin esto, esos casos caían al genérico "Datos inválidos." y el
    // usuario nunca sabía cuál campo estaba mal.
    if (m is List && m.isNotEmpty) {
      final first = m.first;
      if (first is String) return first;
      if (first is Map) {
        final fieldMsg = first['message'] ?? first['defaultMessage'];
        if (fieldMsg is String && fieldMsg.isNotEmpty) return fieldMsg;
      }
    }
  }
  return null;
}
