import '../config/env.dart';

/// Validadores de formularios reutilizables.
/// Devuelven null si el valor es válido (contrato de TextFormField).
abstract final class Validators {
  /// Mismo patrón que identity-service (@Pattern en LoginRequestDto):
  /// solo correo institucional.
  static final _emailRegex = RegExp(r'^[^@]+@mail\.escuelaing\.edu\.co$');

  /// Mismo patrón del backend: 8-100, una mayúscula, un símbolo !@#$,.
  static final _passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[!@#$,.]).{8,100}$');

  static String? required(String? value, [String field = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio.';
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, 'El correo');
    if (requiredError != null) return requiredError;
    if (Env.demoMode) return null; // demo: acepta cualquier correo
    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Usa tu correo @mail.escuelaing.edu.co';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, 'La contraseña');
    if (requiredError != null) return requiredError;
    if (Env.demoMode) return null; // demo: acepta cualquier contraseña
    if (!_passwordRegex.hasMatch(value!)) {
      return 'Mínimo 8 caracteres, una mayúscula y un símbolo (!@#\$,.)';
    }
    return null;
  }

  static String? otp(String? value) {
    final requiredError = required(value, 'El código');
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^\d{6}$').hasMatch(value!.trim())) {
      return 'Código de 6 dígitos.';
    }
    return null;
  }
}
