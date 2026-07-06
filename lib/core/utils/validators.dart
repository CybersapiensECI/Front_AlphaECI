/// Validadores de formularios reutilizables.
/// Devuelven null si el valor es válido (contrato de TextFormField).
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? value, [String field = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio.';
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, 'El correo');
    if (requiredError != null) return requiredError;
    if (!_emailRegex.hasMatch(value!.trim())) return 'Correo inválido.';
    // TODO(backend): confirmar si se exige dominio institucional
    // (@mail.escuelaing.edu.co) y validarlo aquí.
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, 'La contraseña');
    if (requiredError != null) return requiredError;
    if (value!.length < 8) return 'Mínimo 8 caracteres.';
    return null;
  }

  static String? otp(String? value) {
    final requiredError = required(value, 'El código');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 4) return 'Código incompleto.';
    return null;
  }
}
