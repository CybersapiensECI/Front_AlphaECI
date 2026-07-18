import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/entities/profile.dart';
import '../models/profile_models.dart';

/// HTTP crudo contra profile-service.
class ProfileApiService {
  const ProfileApiService(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/users';

  /// POST /{userId}/profile-image (multipart, campo `file`).
  /// El servicio guarda la imagen (Cloudinary), actualiza photoUrl del
  /// usuario y devuelve la URL final — el front nunca fabrica la URL.
  /// Solo PNG/JPEG: es lo único que acepta el use case del backend.
  Future<String> uploadProfilePhoto(
    String userId,
    Uint8List bytes, {
    required String ext,
  }) async {
    final normalized = ext.toLowerCase() == 'png' ? 'png' : 'jpeg';
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: 'profile.$normalized',
        contentType: DioMediaType('image', normalized),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/$userId/profile-image',
      data: form,
    );
    return response.data?['profileImageUrl'] as String? ?? '';
  }

  Future<UserProfile> getUser(String userId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_base/$userId');
    return userProfileFromJson(response.data!);
  }

  Future<UserProfile> updateStudent(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/$userId/student',
      data: fields,
    );
    return userProfileFromJson(response.data!);
  }

  Future<List<TagCategory>> getTagCatalog() async {
    final response = await _dio.get<List<dynamic>>('$_base/tags');
    return [
      for (final c in response.data ?? const [])
        tagCategoryFromJson(c as Map<String, dynamic>),
    ];
  }

  Future<void> addTag(String userId, String tagId) async {
    await _dio.post<void>('$_base/$userId/tags', data: {'tagId': tagId});
  }

  Future<void> removeTag(String userId, String tagId) async {
    await _dio.delete<void>('$_base/$userId/tags/$tagId');
  }

  Future<UserProfile> addSchedule(String userId, Schedule schedule) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/$userId/schedules',
      data: scheduleToJson(schedule),
    );
    return userProfileFromJson(response.data!);
  }

  Future<UserProfile> removeSchedule(String userId, Schedule schedule) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '$_base/$userId/schedules',
      data: scheduleToJson(schedule),
    );
    return userProfileFromJson(response.data!);
  }

  Future<List<ProfileSummary>> getBatch(List<String> ids) async {
    final response = await _dio.post<List<dynamic>>(
      '$_base/batch',
      data: {'ids': ids},
    );
    return [
      for (final p in response.data ?? const [])
        profileSummaryFromJson(p as Map<String, dynamic>),
    ];
  }
}
