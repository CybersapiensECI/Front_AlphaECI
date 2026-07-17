import 'package:equatable/equatable.dart';

/// Tag de interés (matching + perfil).
class Tag extends Equatable {
  const Tag({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Categoría del catálogo de tags (GET /api/v1/users/tags).
class TagCategory extends Equatable {
  const TagCategory({required this.id, required this.name, required this.tags});

  final String id;
  final String name;
  final List<Tag> tags;

  @override
  List<Object?> get props => [id, name, tags];
}

/// Perfil de usuario — espejo de la respuesta de profile-service
/// (UserResponseDto + StudentProfileResponseDto).
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    this.gender,
    this.userType,
    this.career,
    this.semester,
    this.biography,
    this.photoUrl,
    this.privacyLevel,
    this.tags = const [],
    this.xp = 0,
    this.level = 1,
    this.friendsId = const [],
    this.active = true,
  });

  final String id;
  final String name;
  final String? gender;
  final String? userType;
  final String? career;
  final int? semester;
  final String? biography;
  final String? photoUrl;
  final String? privacyLevel;
  final List<Tag> tags;
  final int xp;
  final int level;
  final List<String> friendsId;
  final bool active;

  /// Progreso hacia el siguiente nivel. TODO(backend): confirmar fórmula
  /// de XP por nivel; por ahora 100 XP por nivel.
  double get levelProgress => (xp % 100) / 100;

  @override
  List<Object?> get props =>
      [id, name, career, semester, biography, photoUrl, tags, xp, level];
}

/// Perfil resumido (POST /api/v1/users/batch) — para cards de discovery.
class ProfileSummary extends Equatable {
  const ProfileSummary({
    required this.id,
    required this.name,
    this.biography,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String? biography;
  final String? photoUrl;

  @override
  List<Object?> get props => [id, name, biography, photoUrl];
}
