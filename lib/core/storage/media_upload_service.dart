import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sube imágenes a Firebase Storage y devuelve la URL pública.
/// AlphaECI no tiene servicio de storage propio: esta es la única pieza
/// no-backend-propio del proyecto. Requiere `flutterfire configure`
/// (ver lib/firebase_options.dart) para funcionar de verdad.
class MediaUploadService {
  const MediaUploadService();

  Future<String> uploadPostImage(Uint8List bytes, {String ext = 'jpg'}) async {
    final path =
        'posts/${DateTime.now().microsecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref(path);
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/$ext'),
    );
    return task.ref.getDownloadURL();
  }
}

final mediaUploadServiceProvider =
    Provider<MediaUploadService>((ref) => const MediaUploadService());
