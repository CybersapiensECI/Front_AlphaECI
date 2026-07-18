import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../services/profile_api_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this._api});

  final ProfileApiService _api;

  @override
  Future<Result<UserProfile>> getProfile(String userId) {
    return _guard(() => _api.getUser(userId));
  }

  @override
  Future<Result<UserProfile>> updateStudent(
    String userId, {
    String? name,
    String? gender,
    String? career,
    int? semester,
    String? biography,
    String? privacyLevel,
  }) {
    final fields = <String, dynamic>{
      'name': ?name,
      'gender': ?gender,
      'career': ?career,
      'semester': ?semester,
      'biography': ?biography,
      'privacyLevel': ?privacyLevel,
    };
    return _guard(() => _api.updateStudent(userId, fields));
  }

  @override
  Future<Result<String>> updatePhoto(
    String userId,
    Uint8List bytes, {
    required String ext,
  }) {
    return _guard(() => _api.uploadProfilePhoto(userId, bytes, ext: ext));
  }

  @override
  Future<Result<List<TagCategory>>> getTagCatalog() {
    return _guard(_api.getTagCatalog);
  }

  @override
  Future<Result<void>> addTag(String userId, String tagId) {
    return _guard(() => _api.addTag(userId, tagId));
  }

  @override
  Future<Result<void>> removeTag(String userId, String tagId) {
    return _guard(() => _api.removeTag(userId, tagId));
  }

  @override
  Future<Result<UserProfile>> addSchedule(String userId, Schedule schedule) {
    return _guard(() => _api.addSchedule(userId, schedule));
  }

  @override
  Future<Result<UserProfile>> removeSchedule(String userId, Schedule schedule) {
    return _guard(() => _api.removeSchedule(userId, schedule));
  }

  @override
  Future<Result<List<ProfileSummary>>> getProfilesByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(const Success([]));
    return _guard(() => _api.getBatch(ids));
  }

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Success(await call());
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }
}
