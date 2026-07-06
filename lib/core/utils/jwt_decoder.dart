import 'dart:convert';

/// Decodifica el payload de un JWT sin validar firma (la firma la valida
/// el backend; aquí solo se leen claims para la UI).
///
/// identity-service emite: subject = userId, claims `email` y `role`.
abstract final class JwtDecoder {
  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return const {};
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload);
      return map is Map<String, dynamic> ? map : const {};
    } catch (_) {
      return const {};
    }
  }

  static String? userId(String token) => decode(token)['sub'] as String?;

  static String? email(String token) => decode(token)['email'] as String?;

  static String? role(String token) => decode(token)['role'] as String?;

  static bool isExpired(String token) {
    final exp = decode(token)['exp'];
    if (exp is! int) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
  }
}
