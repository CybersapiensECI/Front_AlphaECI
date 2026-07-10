import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';

/// Comentario de una publicación, visible en la UI.
/// TODO(backend): Parches-Service solo expone POST de comentarios
/// (sin GET). Mientras tanto la lista vive en memoria de sesión
/// (+ semilla demo). Al existir el GET, cambiar por FutureProvider.family.
class PostComment {
  const PostComment({
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String author;
  final String text;
  final DateTime createdAt;
}

/// Comentarios por postId (estado de sesión, optimista).
final postCommentsProvider =
    StateProvider<Map<String, List<PostComment>>>((ref) {
  if (!Env.demoMode) return const {};
  final now = DateTime.now();
  return {
    // Cine al parque ECI.
    'post5': [
      PostComment(
        author: 'Diego Torres',
        text: '¡Confirmadísimo! 🙌',
        createdAt: now.subtract(const Duration(minutes: 32)),
      ),
      PostComment(
        author: 'Ana García',
        text: 'Llevo crispetas para todos 🍿',
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
    ],
    // Fútbol 5 (reserva de cancha).
    'post2': [
      PostComment(
        author: 'Carlos López',
        text: 'Cuenten conmigo para el arco 🧤',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    ],
    // Estudio de cálculo.
    'post1': [
      PostComment(
        author: 'Diego Torres',
        text: 'Yo voy, aparto puesto 👋',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ],
  };
});
