import 'dart:typed_data';

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

  /// POST /{userId}/profile-image — sube la foto (multipart) y devuelve la
  /// URL final que asignó profile-service. Solo JPG/PNG, máx 5 MB.
  Future<Result<String>> updatePhoto(
    String userId,
    Uint8List bytes, {
    required String ext,
  });

  /// GET /tags — catálogo completo agrupado por categoría.
  Future<Result<List<TagCategory>>> getTagCatalog();

  /// POST /{userId}/tags {tagId}.
  Future<Result<void>> addTag(String userId, String tagId);

  /// DELETE /{userId}/tags/{tagId}.
  Future<Result<void>> removeTag(String userId, String tagId);

  /// POST /{userId}/schedules — agrega bloque de disponibilidad.
  Future<Result<UserProfile>> addSchedule(String userId, Schedule schedule);

  /// DELETE /{userId}/schedules — quita bloque de disponibilidad.
  Future<Result<UserProfile>> removeSchedule(String userId, Schedule schedule);

  /// POST /batch {ids} — perfiles resumidos para cards.
  Future<Result<List<ProfileSummary>>> getProfilesByIds(List<String> ids);
}
