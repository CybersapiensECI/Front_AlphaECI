// TODO(demo): repositorio falso para ver la app sin backends.
// Se activa con --dart-define=DEMO=true. Eliminar en producción.
import '../../../../core/errors/result.dart';
import '../../domain/entities/registration_data.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';

const demoUserId = '11111111-1111-1111-1111-111111111111';

const _demoSession = UserSession(
  userId: demoUserId,
  email: 'demo@mail.escuelaing.edu.co',
  role: 'STUDENT',
  accessToken: 'demo-token',
  refreshToken: 'demo-refresh',
);

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  Future<T> _delay<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 600), () => value);

  @override
  Future<Result<UserSession>> login({
    required String email,
    required String password,
  }) =>
      _delay(const Success(_demoSession));

  @override
  Future<Result<UserSession>> verifyOtp({
    required String email,
    required String code,
  }) =>
      _delay(const Success(_demoSession));

  @override
  Future<Result<String>> initVerification({
    required String email,
    required String password,
  }) =>
      _delay(const Success('Código enviado (demo).'));

  @override
  Future<Result<String>> resendOtp({
    required String email,
    required String password,
  }) =>
      _delay(const Success('Código reenviado (demo).'));

  @override
  Future<Result<String>> completeRegistration(RegistrationData data) =>
      _delay(const Success('Registro completado (demo).'));

  @override
  Future<Result<String>> forgotPassword({required String email}) =>
      _delay(const Success('Código de recuperación enviado (demo).'));

  @override
  Future<Result<String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _delay(const Success('Contraseña restablecida (demo).'));

  @override
  Future<Result<String>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) =>
      _delay(const Success('Contraseña cambiada (demo).'));

  @override
  Future<Result<void>> logout() => _delay(const Success(null));

  @override
  Future<UserSession?> restoreSession() async => null;
}
