import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/mock_profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/services/profile_api_service.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  return ProfileApiService(ref.watch(apiClientProvider(Env.profileUrl)));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (Env.demoMode) return MockProfileRepository();
  return ProfileRepositoryImpl(api: ref.watch(profileApiServiceProvider));
});

/// Perfil del usuario autenticado. `ref.invalidate` tras editar.
final myProfileProvider = FutureProvider<UserProfile>((ref) async {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) throw const AuthFailure();
  final result =
      await ref.watch(profileRepositoryProvider).getProfile(session.userId);
  return result.when(
    success: (profile) => profile,
    error: (failure) => throw failure,
  );
});

/// Catálogo de tags agrupado por categoría (para el selector de intereses).
final tagCatalogProvider = FutureProvider<List<TagCategory>>((ref) async {
  final result = await ref.watch(profileRepositoryProvider).getTagCatalog();
  return result.when(
    success: (catalog) => catalog,
    error: (failure) => throw failure,
  );
});

/// Acciones de edición de perfil.
final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(ref);
});

class ProfileActions {
  const ProfileActions(this._ref);

  final Ref _ref;

  String? get _userId =>
      _ref.read(authControllerProvider).session?.userId;

  Future<Result<UserProfile>> update({
    String? name,
    String? gender,
    String? career,
    int? semester,
    String? biography,
    String? privacyLevel,
  }) async {
    final userId = _userId;
    if (userId == null) return const Error(AuthFailure());
    final result = await _ref.read(profileRepositoryProvider).updateStudent(
          userId,
          name: name,
          gender: gender,
          career: career,
          semester: semester,
          biography: biography,
          privacyLevel: privacyLevel,
        );
    if (result.isSuccess) _ref.invalidate(myProfileProvider);
    return result;
  }

  /// Sube la foto a profile-service (POST /profile-image) y refresca el
  /// perfil. [retries] > 0 reintenta con espera: tras el registro el perfil
  /// se crea de forma asíncrona (evento user-verified por RabbitMQ) y la
  /// primera subida puede llegar antes de que el usuario exista (404).
  Future<Result<String>> updatePhoto(
    Uint8List bytes, {
    required String ext,
    int retries = 0,
  }) async {
    final userId = _userId;
    if (userId == null) return const Error(AuthFailure());
    var result = await _ref
        .read(profileRepositoryProvider)
        .updatePhoto(userId, bytes, ext: ext);
    for (var attempt = 0; result.isSuccess == false && attempt < retries; attempt++) {
      await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      result = await _ref
          .read(profileRepositoryProvider)
          .updatePhoto(userId, bytes, ext: ext);
    }
    if (result.isSuccess) _ref.invalidate(myProfileProvider);
    return result;
  }

  Future<Result<void>> addTag(String tagId) async {
    final userId = _userId;
    if (userId == null) return const Error(AuthFailure());
    final result =
        await _ref.read(profileRepositoryProvider).addTag(userId, tagId);
    if (result.isSuccess) _ref.invalidate(myProfileProvider);
    return result;
  }

  Future<Result<void>> removeTag(String tagId) async {
    final userId = _userId;
    if (userId == null) return const Error(AuthFailure());
    final result =
        await _ref.read(profileRepositoryProvider).removeTag(userId, tagId);
    if (result.isSuccess) _ref.invalidate(myProfileProvider);
    return result;
  }

  Future<Result<UserProfile>> addSchedule(Schedule schedule) async {
    final userId = _userId;
    if (userId == null) return const Error(AuthFailure());
    final result = await _ref
        .read(profileRepositoryProvider)
        .addSchedule(userId, schedule);
    if (result.isSuccess) _ref.invalidate(myProfileProvider);
    return result;
  }

  Future<Result<UserProfile>> removeSchedule(Schedule schedule) async {
    final userId = _userId;
    if (userId == null) return const Error(AuthFailure());
    final result = await _ref
        .read(profileRepositoryProvider)
        .removeSchedule(userId, schedule);
    if (result.isSuccess) _ref.invalidate(myProfileProvider);
    return result;
  }
}
