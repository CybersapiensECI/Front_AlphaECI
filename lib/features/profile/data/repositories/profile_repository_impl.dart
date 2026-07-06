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
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (career != null) 'career': career,
      if (semester != null) 'semester': semester,
      if (biography != null) 'biography': biography,
      if (privacyLevel != null) 'privacyLevel': privacyLevel,
    };
    return _guard(() => _api.updateStudent(userId, fields));
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
