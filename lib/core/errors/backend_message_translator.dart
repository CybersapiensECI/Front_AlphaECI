/// Traduce mensajes crudos de los backends (todos en inglés salvo
/// Parches-Service) a español, para que nunca lleguen tal cual a un
/// SnackBar. Recopilado leyendo los throw/@NotBlank/@IsNotEmpty de cada
/// servicio (identity-service, matching-service, profile-service,
/// chat-service) — si aparece un mensaje nuevo que no está acá, se
/// devuelve tal cual (mejor mostrar inglés que romper) en vez de fallar.
String translateBackendMessage(String message) {
  final exact = _exactTranslations[message];
  if (exact != null) return exact;

  for (final entry in _prefixTranslations.entries) {
    if (message.startsWith(entry.key)) {
      return entry.value + message.substring(entry.key.length);
    }
  }

  return message;
}

const _exactTranslations = <String, String>{
  // ── identity-service: validación de DTOs ──────────────────────────
  'Email is required': 'El correo es obligatorio.',
  'Email must be a valid @mail.escuelaing.edu.co address':
      'El correo debe ser una dirección válida @mail.escuelaing.edu.co.',
  'Invalid email format': 'Formato de correo inválido.',
  'Password is required': 'La contraseña es obligatoria.',
  'Password must be at least 8 characters, contain at least one uppercase letter and one of: !@#\$,.':
      'La contraseña debe tener mínimo 8 caracteres, una mayúscula y uno de: !@#\$,.',
  'Name is required': 'El nombre es obligatorio.',
  'Name must be between 2 and 50 characters':
      'El nombre debe tener entre 2 y 50 caracteres.',
  'Gender is required': 'El género es obligatorio.',
  'Career is required': 'La carrera es obligatoria.',
  'Semester is required': 'El semestre es obligatorio.',
  'Minimum semester is 1': 'El semestre mínimo es 1.',
  'Maximum semester is 10': 'El semestre máximo es 10.',
  'Student carnet is required': 'El carnet es obligatorio.',
  'Carnet must have exactly 10 digits':
      'El carnet debe tener exactamente 10 dígitos.',
  'Photo URL is required': 'La foto de perfil es obligatoria.',
  'Biography cannot exceed 200 characters':
      'La biografía no puede superar los 200 caracteres.',
  'Privacy level is required': 'El nivel de privacidad es obligatorio.',
  'Date of birth is required': 'La fecha de nacimiento es obligatoria.',
  'Date of birth must be in the past':
      'La fecha de nacimiento debe ser anterior a hoy.',
  'Geolocation enabled is required':
      'Falta indicar si compartís tu ubicación.',
  'Current password must not be blank':
      'La contraseña actual es obligatoria.',
  'New password must not be blank': 'La contraseña nueva es obligatoria.',
  'Refresh token must not be blank': 'Sesión inválida, inicia sesión de nuevo.',
  'OTP code must be a 6-digit number': 'El código debe tener 6 dígitos.',
  'OTP code must not be blank': 'Ingresa el código de verificación.',

  // ── identity-service: reglas de negocio ───────────────────────────
  'An account with this email already exists':
      'Ya existe una cuenta con este correo.',
  'Current password is incorrect': 'La contraseña actual es incorrecta.',
  'Email is already verified': 'Este correo ya está verificado.',
  'Email must be verified before completing registration':
      'Verifica tu correo antes de completar el registro.',
  'Email not verified. Check your inbox for the OTP.':
      'Correo no verificado. Revisa tu bandeja de entrada por el código.',
  'Invalid OTP': 'Código incorrecto.',
  'Invalid email or password': 'Correo o contraseña incorrectos.',
  'Invalid or expired token': 'Sesión inválida o expirada.',
  'Maximum OTP attempts reached. Please request a new code':
      'Superaste el máximo de intentos. Pide un código nuevo.',
  'Maximum attempts reached, please request a new code':
      'Superaste el máximo de intentos. Pide un código nuevo.',
  'OTP code has expired or was already used':
      'El código expiró o ya fue usado.',
  'OTP code is incorrect': 'El código es incorrecto.',
  'OTP has expired or was already used': 'El código expiró o ya fue usado.',
  'OTP must be a 6-digit number': 'El código debe tener 6 dígitos.',
  'Refresh token has expired or been revoked':
      'Tu sesión expiró, inicia sesión de nuevo.',

  // ── matching-service ───────────────────────────────────────────────
  'Cannot send a match request to yourself':
      'No puedes conectar contigo mismo.',
  "You can't match without any tags!":
      'Agrega al menos un interés a tu perfil para poder conectar.',
  "You can't match without any available schedules!":
      'Agrega tu horario de disponibilidad para poder conectar.',
  'Cannot send a match request to someone who is already your friend':
      'Ya están conectados.',
  'Already exists a match request between requester and target':
      'Ya existe una solicitud entre ustedes.',
  'Only the recipient of a match request can accept or reject it':
      'Solo quien recibió la solicitud puede aceptarla o rechazarla.',
  'Only pending requests can be responded to':
      'Solo se puede responder solicitudes pendientes.',
  'Only the sender of a match request can cancel it':
      'Solo quien envió la solicitud puede cancelarla.',
  'Only pending match requests can be cancelled':
      'Solo se pueden cancelar solicitudes pendientes.',
  'Cannot accept match right now, please try again later':
      'No se pudo aceptar la solicitud. Intenta de nuevo.',
  'Cannot remove friend right now, please try again later':
      'No se pudo eliminar la amistad. Intenta de nuevo.',
  'The category name cannot be blank':
      'El nombre de la categoría es obligatorio.',
  'The category name must be between 1 and 50 characters':
      'El nombre de la categoría debe tener entre 1 y 50 caracteres.',
  'The tag category ID cannot be null': 'Falta la categoría del interés.',
  'The tag name cannot be blank': 'El nombre del interés es obligatorio.',
  'The tag name must be between 1 and 50 characters':
      'El nombre del interés debe tener entre 1 y 50 caracteres.',

  // ── profile-service ─────────────────────────────────────────────────
  'This user is already a friend': 'Ya son amigos.',
  'The file is empty': 'El archivo está vacío.',
  'Image exceeds 5MB limit': 'La imagen supera el límite de 5MB.',
  'Schedule not found for removal': 'No se encontró ese horario.',
  'Only STUDENT users can have schedules':
      'Solo los estudiantes pueden tener horario.',
  'Day of week is required': 'El día de la semana es obligatorio.',
  'Start and end time are required': 'La hora de inicio y fin son obligatorias.',
  'Name must be less than 100 characters':
      'El nombre debe tener menos de 100 caracteres.',
  'Start time must be before end time':
      'La hora de inicio debe ser antes que la de fin.',
  'Career must not be null': 'La carrera es obligatoria.',
  'Semester must be between 1 and 10': 'El semestre debe estar entre 1 y 10.',
  'Photo URL must not be blank': 'La foto de perfil es obligatoria.',
  'Privacy level must not be null': 'El nivel de privacidad es obligatorio.',
  'Gender must not be null': 'El género es obligatorio.',
  'Date of birth must be a past date':
      'La fecha de nacimiento debe ser anterior a hoy.',
  'The carnet cannot be null or empty': 'El carnet es obligatorio.',
  'The carnet must have exactly 10 digits':
      'El carnet debe tener exactamente 10 dígitos.',
  'Access restricted to internal services.': 'Acceso restringido.',
  'Authentication required.': 'Debes iniciar sesión.',
  'You can only modify your own profile.':
      'Solo puedes modificar tu propio perfil.',
  'Unsupported user type.': 'Tipo de usuario no soportado.',
  'Active status must not be null': 'Falta el estado activo.',
  'Contact information is required': 'La información de contacto es obligatoria.',
  'Date of birth must be in the past (ISO 8601)':
      'La fecha de nacimiento debe ser anterior a hoy.',
  'End time must be in HH:mm format': 'La hora de fin debe tener formato HH:mm.',
  'Geolocation enabled field must not be null':
      'Falta indicar si compartís tu ubicación.',
  'Level must be at least 1': 'El nivel mínimo es 1.',
  'Level value must not be null': 'Falta el nivel.',
  'Start time must be in HH:mm format':
      'La hora de inicio debe tener formato HH:mm.',
  'The biography cannot exceed 200 characters':
      'La biografía no puede superar los 200 caracteres.',
  'The friend ID cannot be null': 'Falta el id del amigo.',
  'The list of IDs must not be empty': 'La lista de ids no puede estar vacía.',
  'The tag ID cannot be null': 'Falta el id del interés.',
  'XP must be zero or positive': 'El XP debe ser cero o positivo.',
  'XP value must not be null': 'Falta el valor de XP.',
  'userId is required': 'Falta el id de usuario.',

  // ── chat-service ─────────────────────────────────────────────────────
  'Image message must have a media URL':
      'Un mensaje de imagen necesita una URL.',
  'Text message must have content': 'El mensaje no puede estar vacío.',
};

/// Prefijos para mensajes con un id/valor dinámico pegado al final
/// (ej. "Match not found with ID: 3f2a..." -> mantiene el id, traduce
/// el prefijo).
const _prefixTranslations = <String, String>{
  'Match not found with ID: ': 'No se encontró el match: ',
  'Profile not found with ID: ': 'No se encontró el perfil: ',
  'Tag not found with ID: ': 'No se encontró el interés: ',
  'Category not found with ID: ': 'No se encontró la categoría: ',
  'Category already exists with name: ': 'Ya existe una categoría llamada: ',
  'Tag already exists with name: ': 'Ya existe un interés llamado: ',
  'Chat room not found: ': 'No se encontró el chat: ',
  'Message not found: ': 'No se encontró el mensaje: ',
  'Message report not found: ': 'No se encontró el reporte: ',
  'User not found: ': 'No se encontró el usuario: ',
  'Tag not found in the catalog: ': 'No se encontró el interés en el catálogo: ',
  'Profile service unavailable while adding friend: ':
      'Servicio de perfiles no disponible: ',
  'Profile service unavailable while removing friend: ':
      'Servicio de perfiles no disponible: ',
  'Profile service unavailable: ': 'Servicio de perfiles no disponible: ',
  'Geolocation service unavailable: ':
      'Servicio de geolocalización no disponible: ',
};
