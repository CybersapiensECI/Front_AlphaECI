/// Jerarquía de errores de la app. Los repositories capturan excepciones
/// (DioException, etc.) y las convierten en un Failure. La UI solo ve esto.
sealed class Failure {
  const Failure(this.message);

  /// Mensaje apto para mostrar al usuario.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Sin conexión, timeout, DNS.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión. Revisa tu red.']);
}

/// 401/403 — sesión inválida o sin permisos.
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sesión inválida o expirada.']);
}

/// 400/422 — datos rechazados por el backend.
final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Datos inválidos.']);
}

/// 404 — recurso no existe.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso no encontrado.']);
}

/// 5xx u otros errores del servidor.
final class ServerFailure extends Failure {
  const ServerFailure({
    String message = 'Error del servidor. Intenta luego.',
    this.statusCode,
  }) : super(message);

  final int? statusCode;
}

/// Cualquier cosa no anticipada.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Error inesperado.']);
}
