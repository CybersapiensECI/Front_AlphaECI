import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/parche.dart';
import '../models/parche_models.dart';

/// HTTP crudo contra Parches-Service.
class ParcheApiService {
  const ParcheApiService(this._dio);

  final Dio _dio;

  static const _base = '/api/parches';

  Future<List<Parche>> search({
    String? category,
    String? place,
    String? query,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      _base,
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (place != null && place.isNotEmpty) 'place': place,
        if (query != null && query.isNotEmpty) 'query': query,
        'page': page,
        'size': size,
      },
    );
    return [
      for (final p in response.data ?? const [])
        parcheFromJson(p as Map<String, dynamic>),
    ];
  }

  Future<String> create(Map<String, dynamic> command) async {
    final response =
        await _dio.post<Map<String, dynamic>>(_base, data: command);
    return response.data?['parcheId'] as String? ?? '';
  }

  Future<String> join(String parcheId, String studentId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/$parcheId/join',
      data: {'studentId': studentId},
    );
    return response.data?['message'] as String? ?? 'Te uniste al parche.';
  }

  Future<List<ParcheMember>> getMembers(String parcheId) async {
    final response =
        await _dio.get<List<dynamic>>('$_base/$parcheId/members');
    return [
      for (final m in response.data ?? const [])
        parcheMemberFromJson(m as Map<String, dynamic>),
    ];
  }

  Future<List<ParchePost>> getPosts(String parcheId) async {
    final response = await _dio.get<List<dynamic>>('$_base/$parcheId/posts');
    return [
      for (final p in response.data ?? const [])
        parchePostFromJson(p as Map<String, dynamic>),
    ];
  }

  /// El backend recibe @RequestParam (query/form). Se envían como query.
  Future<String> createPost({
    required String parcheId,
    required String authorId,
    String? text,
    String? photoUrl,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/$parcheId/posts',
      queryParameters: {
        'authorId': authorId,
        if (text != null && text.isNotEmpty) 'text': text,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
      },
    );
    return response.data?['message'] as String? ?? 'Publicación creada.';
  }

  static String formatDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);
}
