import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import '../utils/jwt_decoder.dart';
import 'session_expiry_bus.dart';

/// Agrega credenciales a cada petición y maneja expiración:
///
/// 1. Header `Authorization: Bearer <accessToken>`.
/// 2. Header `X-User-Id` (los servicios lo leen; en producción lo inyecta
///    el gateway — TODO(gateway): quitar cuando el gateway lo maneje).
/// 3. En 401: intenta POST /api/v1/auth/refresh una vez y reintenta la
///    petición original. Si falla, limpia tokens y notifica al bus.
///
/// QueuedInterceptor serializa los errores concurrentes: evita N refresh
/// simultáneos cuando varias peticiones reciben 401 a la vez.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required SessionExpiryBus expiryBus,
  })  : _tokens = tokenStorage,
        _expiryBus = expiryBus;

  final TokenStorage _tokens;
  final SessionExpiryBus _expiryBus;

  /// Dio "desnudo" solo para refresh (sin este interceptor: sin recursión).
  final Dio _refreshDio = Dio(BaseOptions(baseUrl: Env.authUrl));

  static const _refreshPath = '/api/v1/auth/refresh';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final access = await _tokens.accessToken;
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
      final userId = JwtDecoder.userId(access);
      if (userId != null) options.headers['X-User-Id'] = userId;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final isAuthCall = err.requestOptions.path.contains('/api/v1/auth/');

    if (status != 401 || isAuthCall) {
      handler.next(err);
      return;
    }

    final refreshed = await _tryRefresh();
    if (!refreshed) {
      await _tokens.clear();
      _expiryBus.expire();
      handler.next(err);
      return;
    }

    // Reintenta la petición original con el token nuevo.
    try {
      final access = await _tokens.accessToken;
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $access';
      final userId = access == null ? null : JwtDecoder.userId(access);
      if (userId != null) opts.headers['X-User-Id'] = userId;
      final response = await Dio().fetch(opts);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refreshToken': refresh},
      );
      final data = response.data;
      final newAccess = data?['accessToken'] as String?;
      final newRefresh = data?['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) return false;
      await _tokens.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
