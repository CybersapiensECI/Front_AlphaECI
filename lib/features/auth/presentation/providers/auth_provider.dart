import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/registration_data.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/services/auth_api_service.dart';

// ── Wiring de capas ───────────────────────────────────────────

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(apiClientProvider(Env.authUrl)));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Env.demoMode) return const MockAuthRepository();
  return AuthRepositoryImpl(
    api: ref.watch(authApiServiceProvider),
    tokens: ref.watch(tokenStorageProvider),
  );
});

// ── Estado de sesión ──────────────────────────────────────────

enum AuthStatus {
  /// Restaurando sesión al arrancar (mostrar splash).
  unknown,
  unauthenticated,
  authenticated,
}

class AuthState {
  const AuthState({required this.status, this.session});

  final AuthStatus status;
  final UserSession? session;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Sesión expirada (refresh falló en el interceptor): logout local.
    final bus = ref.watch(sessionExpiryBusProvider);
    void onExpired() =>
        state = const AuthState(status: AuthStatus.unauthenticated);
    bus.addListener(onExpired);
    ref.onDispose(() => bus.removeListener(onExpired));

    // Restaura sesión desde secure storage al arrancar.
    Future(() => _restore());

    return const AuthState(status: AuthStatus.unknown);
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _restore() async {
    final session = await _repo.restoreSession();
    state = session == null
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.authenticated, session: session);
  }

  Future<Result<UserSession>> login({
    required String email,
    required String password,
  }) async {
    final result = await _repo.login(email: email, password: password);
    _applySession(result);
    return result;
  }

  Future<Result<UserSession>> verifyOtp({
    required String email,
    required String code,
  }) async {
    final result = await _repo.verifyOtp(email: email, code: code);
    _applySession(result);
    return result;
  }

  Future<Result<String>> initVerification({
    required String email,
    required String password,
  }) {
    return _repo.initVerification(email: email, password: password);
  }

  Future<Result<String>> resendOtp({
    required String email,
    required String password,
  }) {
    return _repo.resendOtp(email: email, password: password);
  }

  Future<Result<String>> completeRegistration(RegistrationData data) {
    return _repo.completeRegistration(data);
  }

  Future<Result<String>> forgotPassword({required String email}) {
    return _repo.forgotPassword(email: email);
  }

  Future<Result<String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _repo.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  Future<Result<String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    final userId = state.session?.userId;
    if (userId == null) {
      return Future.value(
        const Error<String>(AuthFailure('No hay sesión activa.')),
      );
    }
    return _repo.changePassword(
      userId: userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _applySession(Result<UserSession> result) {
    final session = result.dataOrNull;
    if (session != null) {
      state = AuthState(status: AuthStatus.authenticated, session: session);
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
