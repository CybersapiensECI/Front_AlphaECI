import 'package:dio/dio.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/jwt_decoder.dart';
import '../../domain/entities/registration_data.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_models.dart';
import '../services/auth_api_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this._api,
    required this._tokens,
  });

  final AuthApiService _api;
  final TokenStorage _tokens;

  @override
  Future<Result<UserSession>> login({
    required String email,
    required String password,
  }) {
    return _sessionCall(() => _api.login(email, password));
  }

  @override
  Future<Result<UserSession>> verifyOtp({
    required String email,
    required String code,
  }) {
    return _sessionCall(() => _api.verifyOtp(email, code));
  }

  @override
  Future<Result<String>> initVerification({
    required String email,
    required String password,
  }) {
    return _messageCall(() => _api.initVerification(email, password));
  }

  @override
  Future<Result<String>> resendOtp({
    required String email,
    required String password,
  }) {
    return _messageCall(() => _api.resendOtp(email, password));
  }

  @override
  Future<Result<String>> completeRegistration(RegistrationData data) {
    return _messageCall(() => _api.completeRegistration(data));
  }

  @override
  Future<Result<String>> forgotPassword({required String email}) {
    return _messageCall(() => _api.forgotPassword(email));
  }

  @override
  Future<Result<String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _messageCall(() => _api.resetPassword(email, code, newPassword));
  }

  @override
  Future<Result<String>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) {
    return _messageCall(
      () => _api.changePassword(userId, currentPassword, newPassword),
    );
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refresh = await _tokens.refreshToken;
      if (refresh != null && refresh.isNotEmpty) {
        await _api.logout(refresh);
      }
      return const Success(null);
    } on DioException catch (e) {
      // El logout local procede aunque el backend falle.
      return Error(mapDioError(e));
    } finally {
      await _tokens.clear();
    }
  }

  @override
  Future<UserSession?> restoreSession() async {
    final access = await _tokens.accessToken;
    final refresh = await _tokens.refreshToken;
    if (access == null || refresh == null) return null;
    // Si el access token expiró, el AuthInterceptor lo renovará en la
    // primera petición; aquí solo se reconstruye la sesión visible.
    final session = _buildSession(access, refresh);
    if (session == null) await _tokens.clear();
    return session;
  }

  // ── helpers ─────────────────────────────────────────────────

  Future<Result<UserSession>> _sessionCall(
    Future<LoginResponseModel> Function() call,
  ) async {
    try {
      final model = await call();
      await _tokens.saveTokens(
        accessToken: model.accessToken,
        refreshToken: model.refreshToken,
      );
      final session = _buildSession(model.accessToken, model.refreshToken);
      if (session == null) {
        return const Error(UnknownFailure('Token inválido del servidor.'));
      }
      return Success(session);
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  Future<Result<String>> _messageCall(
    Future<MessageResponseModel> Function() call,
  ) async {
    try {
      final model = await call();
      return Success(model.message);
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  UserSession? _buildSession(String accessToken, String refreshToken) {
    final userId = JwtDecoder.userId(accessToken);
    if (userId == null) return null;
    return UserSession(
      userId: userId,
      email: JwtDecoder.email(accessToken) ?? '',
      role: JwtDecoder.role(accessToken) ?? 'STUDENT',
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
