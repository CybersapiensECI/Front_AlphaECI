import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Error de validación de imagen, con mensaje listo para mostrar.
class MediaValidationException implements Exception {
  const MediaValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sube imágenes de posts a Firebase Storage y devuelve la URL pública.
///
/// AlphaECI no tiene servicio de storage propio: esta es la única pieza
/// no-backend-propio del proyecto. Ruta usada:
///   posts/{parcheId}/{userId}/{timestamp}.{ext}
/// (ids saneados; nunca rutas planas compartidas entre usuarios).
///
/// Reglas de Storage recomendadas: ver storage.rules en la raíz del repo.
///
/// TODO(seguridad-producción): sin Firebase Auth cualquier cliente con la
/// API key pública puede escribir en /posts (las reglas solo acotan tamaño,
/// tipo y prefijo). Para producción, elegir UNA:
///  1. Firebase Auth con custom tokens emitidos por el backend tras el
///     login email/OTP (reglas pasan a request.auth.uid == userId).
///  2. Endpoint backend que genere signed upload URLs.
///  3. Endpoint backend que reciba la imagen y la suba él mismo.
///  4. Validación backend de pertenencia al parche antes de aceptar la
///     photoUrl del post.
class MediaUploadService {
  const MediaUploadService();

  /// Tamaño máximo aceptado (alineado con storage.rules).
  static const maxBytes = 5 * 1024 * 1024; // 5 MB

  /// Extensiones de imagen permitidas.
  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  static const _contentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// Deja solo [a-zA-Z0-9_-] para segmentos de ruta seguros.
  static String _sanitize(String id) {
    final safe = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    return safe.isEmpty ? 'x' : safe;
  }

  /// Valida bytes + extensión. Lanza [MediaValidationException] legible.
  static void validate(Uint8List bytes, String ext) {
    if (bytes.isEmpty) {
      throw const MediaValidationException('La imagen está vacía.');
    }
    if (bytes.length > maxBytes) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      throw MediaValidationException(
        'La imagen pesa $mb MB. El máximo es 5 MB.',
      );
    }
    if (!allowedExtensions.contains(ext.toLowerCase())) {
      throw const MediaValidationException(
        'Formato no soportado. Usa JPG, PNG o WEBP.',
      );
    }
  }

  /// Sube la imagen y devuelve la downloadURL pública (https).
  Future<String> uploadPostImage(
    Uint8List bytes, {
    required String parcheId,
    required String userId,
    String ext = 'jpg',
  }) async {
    final extension = ext.toLowerCase();
    validate(bytes, extension);

    final path = 'posts/${_sanitize(parcheId)}/${_sanitize(userId)}/'
        '${DateTime.now().microsecondsSinceEpoch}.$extension';
    final ref = FirebaseStorage.instance.ref(path);
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: _contentTypes[extension]!),
    );
    return task.ref.getDownloadURL();
  }

  /// Foto de perfil. Vive bajo posts/profile/{userId}/... a propósito: las
  /// storage.rules actuales solo permiten escribir bajo /posts/**, y pedir
  /// que se agregue un prefijo nuevo (con su propio despliegue manual de
  /// reglas en la consola de Firebase) es fricción evitable para algo que
  /// ya cabe en el patrón existente.
  Future<String> uploadProfilePhoto(
    Uint8List bytes, {
    required String userId,
    String ext = 'jpg',
  }) async {
    final extension = ext.toLowerCase();
    validate(bytes, extension);

    final path = 'posts/profile/${_sanitize(userId)}/'
        '${DateTime.now().microsecondsSinceEpoch}.$extension';
    final ref = FirebaseStorage.instance.ref(path);
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: _contentTypes[extension]!),
    );
    return task.ref.getDownloadURL();
  }
}

final mediaUploadServiceProvider =
    Provider<MediaUploadService>((ref) => const MediaUploadService());
