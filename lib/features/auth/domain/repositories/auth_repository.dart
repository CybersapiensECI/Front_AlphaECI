import '../../../../core/errors/result.dart';
import '../entities/registration_data.dart';
import '../entities/user_session.dart';

/// Contrato de autenticación. La implementación vive en data/.
/// Endpoints: identity-service /api/v1/auth/*.
abstract interface class AuthRepository {
  /// POST /login — {email, password} -> tokens.
  Future<Result<UserSession>> login({
    required String email,
    required String password,
  });

  /// POST /init-verification — inicia registro, envía OTP al correo.
  Future<Result<String>> initVerification({
    required String email,
    required String password,
  });

  /// POST /verify-otp — {email, code} -> tokens (queda autenticado).
  Future<Result<UserSession>> verifyOtp({
    required String email,
    required String code,
  });

  /// POST /resend-otp.
  Future<Result<String>> resendOtp({
    required String email,
    required String password,
  });

  /// POST /complete-registration — datos de perfil.
  Future<Result<String>> completeRegistration(RegistrationData data);

  /// POST /forgot-password — envía código de recuperación.
  Future<Result<String>> forgotPassword({required String email});

  /// POST /reset-password — {email, code, newPassword}.
  Future<Result<String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// POST /change-password — {userId, currentPassword, newPassword}.
  Future<Result<String>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });

  /// POST /logout + limpia tokens locales.
  Future<Result<void>> logout();

  /// Reconstruye sesión desde tokens guardados (arranque de la app).
  Future<UserSession?> restoreSession();
}
