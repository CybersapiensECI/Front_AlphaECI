import '../../../../core/errors/result.dart';
import '../entities/profile.dart';

/// Contrato contra profile-service (/api/v1/users).
abstract interface class ProfileRepository {
  /// GET /{userId}.
  Future<Result<UserProfile>> getProfile(String userId);

  /// PATCH /{userId}/student — solo campos no nulos.
  Future<Result<UserProfile>> updateStudent(
    String userId, {
    String? name,
    String? gender,
    String? career,
    int? semester,
    String? biography,
    String? privacyLevel,
  });

  /// GET /tags — catálogo completo agrupado por categoría.
  Future<Result<List<TagCategory>>> getTagCatalog();

  /// POST /{userId}/tags {tagId}.
  Future<Result<void>> addTag(String userId, String tagId);

  /// DELETE /{userId}/tags/{tagId}.
  Future<Result<void>> removeTag(String userId, String tagId);

  /// POST /batch {ids} — perfiles resumidos para cards.
  Future<Result<List<ProfileSummary>>> getProfilesByIds(List<String> ids);
}
