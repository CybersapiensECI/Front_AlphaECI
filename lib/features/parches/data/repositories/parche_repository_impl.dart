import 'package:dio/dio.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/parche.dart';
import '../../domain/repositories/parche_repository.dart';
import '../services/parche_api_service.dart';

class ParcheRepositoryImpl implements ParcheRepository {
  const ParcheRepositoryImpl({required this._api});

  final ParcheApiService _api;

  @override
  Future<Result<List<Parche>>> search({
    String? category,
    String? place,
    String? query,
    int page = 0,
    int size = 20,
  }) {
    return _guard(() => _api.search(
          category: category,
          place: place,
          query: query,
          page: page,
          size: size,
        ));
  }

  @override
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
  }) {
    // Espejo de CreateParcheCommand.
    return _guard(() => _api.create({
          'name': name,
          'description': description,
          'place': place,
          'category': category,
          'type': type,
          'date': ParcheApiService.formatDate(date),
          'hour': hour,
          'maximumQuota': maximumQuota,
          'creatorStudentId': creatorStudentId,
          if (eventId != null) 'eventId': eventId,
        }));
  }

  @override
  Future<Result<String>> join(String parcheId, String studentId) {
    return _guard(() => _api.join(parcheId, studentId));
  }

  @override
  Future<Result<List<ParcheMember>>> getMembers(String parcheId) {
    return _guard(() => _api.getMembers(parcheId));
  }

  @override
  Future<Result<List<ParchePost>>> getPosts(String parcheId) {
    return _guard(() => _api.getPosts(parcheId));
  }

  @override
  Future<Result<String>> createPost({
    required String parcheId,
    required String authorId,
    String? text,
    String? photoUrl,
  }) {
    return _guard(() => _api.createPost(
          parcheId: parcheId,
          authorId: authorId,
          text: text,
          photoUrl: photoUrl,
        ));
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
