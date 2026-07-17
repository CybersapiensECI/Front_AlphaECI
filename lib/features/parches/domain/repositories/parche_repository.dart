import '../../../../core/errors/result.dart';
import '../entities/parche.dart';

/// Contrato contra Parches-Service (/api/parches).
abstract interface class ParcheRepository {
  /// GET / — filtros opcionales + paginación.
  Future<Result<List<Parche>>> search({
    String? category,
    String? place,
    String? query,
    int page,
    int size,
  });

  /// POST / — devuelve parcheId.
  Future<Result<String>> create({
    required String name,
    required String description,
    required String place,
    required String category,
    required String type,
    required DateTime date,
    required String hour,
    required int maximumQuota,
    required String creatorStudentId,
    String? eventId,
  });

  /// POST /{parcheId}/join — {studentId}.
  Future<Result<String>> join(String parcheId, String studentId);

  /// GET /{parcheId}/members.
  Future<Result<List<ParcheMember>>> getMembers(String parcheId);

  /// GET /{parcheId}/posts.
  Future<Result<List<ParchePost>>> getPosts(String parcheId);

  /// POST /{parcheId}/posts — form params authorId, text, photoUrl.
  Future<Result<String>> createPost({
    required String parcheId,
    required String authorId,
    String? text,
    String? photoUrl,
  });

  /// POST /api/invitations — SendInvitationCommand {parcheId, senderId,
  /// invitedId}.
  Future<Result<String>> sendInvitation({
    required String parcheId,
    required String senderId,
    required String invitedId,
  });

  /// POST /api/posts/{postId}/comments — {authorId, text}.
  Future<Result<String>> createComment({
    required String postId,
    required String authorId,
    required String text,
  });

  /// POST /api/posts/{postId}/reactions — {studentId} (toggle).
  Future<Result<String>> reactToPost({
    required String postId,
    required String studentId,
  });
}
