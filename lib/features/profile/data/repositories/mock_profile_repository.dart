// TODO(demo): datos falsos para ver la app sin backends. Eliminar en prod.
import '../../../../core/errors/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

const _tags = [
  Tag(id: 't1', name: 'Fútbol'),
  Tag(id: 't2', name: 'Videojuegos'),
  Tag(id: 't3', name: 'Programación'),
  Tag(id: 't4', name: 'Música'),
  Tag(id: 't5', name: 'Ajedrez'),
  Tag(id: 't6', name: 'Anime'),
  Tag(id: 't7', name: 'Senderismo'),
  Tag(id: 't8', name: 'Robótica'),
];

const demoProfiles = [
  ProfileSummary(
    id: 'u2',
    name: 'Ana García',
    biography: 'Ing. de Sistemas · Semestre 5 · Amante del café y el código',
  ),
  ProfileSummary(
    id: 'u3',
    name: 'Carlos López',
    biography: 'Ing. Electrónica · Semestre 3 · Torneos de robótica 🤖',
  ),
  ProfileSummary(
    id: 'u4',
    name: 'Juana Rosa',
    biography: 'Ing. Industrial · Semestre 7 · Capitana del parche de ajedrez',
  ),
  ProfileSummary(
    id: 'u5',
    name: 'Diego Torres',
    biography: 'Ing. Civil · Semestre 2 · Buscando equipo para la hackathon',
  ),
];

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository();

  UserProfile _me = UserProfile(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Estudiante Demo',
    gender: 'PREFER_NOT_TO_SAY',
    userType: 'STUDENT',
    career: 'SYSTEMS_ENGINEERING',
    semester: 4,
    biography: 'Explorando AlphaECI en modo demo 🚀',
    privacyLevel: 'PUBLIC',
    tags: [_tags[2], _tags[1], _tags[4]],
    schedules: const [
      Schedule(
        dayOfWeek: 'MONDAY',
        name: 'Cálculo diferencial',
        startTime: '08:00',
        endTime: '10:00',
      ),
    ],
    xp: 340,
    level: 4,
    friendsId: ['u2', 'u4'],
  );

  Future<Result<T>> _ok<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 400), () => Success(value));

  @override
  Future<Result<UserProfile>> getProfile(String userId) => _ok(_me);

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
    _me = UserProfile(
      id: _me.id,
      name: name ?? _me.name,
      gender: gender ?? _me.gender,
      userType: _me.userType,
      career: career ?? _me.career,
      semester: semester ?? _me.semester,
      biography: biography ?? _me.biography,
      privacyLevel: privacyLevel ?? _me.privacyLevel,
      tags: _me.tags,
      schedules: _me.schedules,
      xp: _me.xp,
      level: _me.level,
      friendsId: _me.friendsId,
    );
    return _ok(_me);
  }

  @override
  Future<Result<List<TagCategory>>> getTagCatalog() => _ok([
        TagCategory(
            id: 'c1',
            name: 'Deporte',
            tags: [_tags[0], _tags[4], _tags[6]]),
        TagCategory(id: 'c2', name: 'Tecnología', tags: [_tags[2], _tags[7]]),
        TagCategory(
            id: 'c3',
            name: 'Entretenimiento',
            tags: [_tags[1], _tags[3], _tags[5]]),
      ]);

  @override
  Future<Result<void>> addTag(String userId, String tagId) {
    final tag = _tags.where((t) => t.id == tagId).firstOrNull;
    if (tag != null && !_me.tags.any((t) => t.id == tagId)) {
      _me = UserProfile(
        id: _me.id,
        name: _me.name,
        gender: _me.gender,
        userType: _me.userType,
        career: _me.career,
        semester: _me.semester,
        biography: _me.biography,
        privacyLevel: _me.privacyLevel,
        tags: [..._me.tags, tag],
        schedules: _me.schedules,
        xp: _me.xp,
        level: _me.level,
        friendsId: _me.friendsId,
      );
    }
    return _ok(null);
  }

  @override
  Future<Result<void>> removeTag(String userId, String tagId) {
    _me = UserProfile(
      id: _me.id,
      name: _me.name,
      gender: _me.gender,
      userType: _me.userType,
      career: _me.career,
      semester: _me.semester,
      biography: _me.biography,
      privacyLevel: _me.privacyLevel,
      tags: [..._me.tags.where((t) => t.id != tagId)],
      schedules: _me.schedules,
      xp: _me.xp,
      level: _me.level,
      friendsId: _me.friendsId,
    );
    return _ok(null);
  }

  @override
  Future<Result<UserProfile>> addSchedule(String userId, Schedule schedule) {
    _me = UserProfile(
      id: _me.id,
      name: _me.name,
      gender: _me.gender,
      userType: _me.userType,
      career: _me.career,
      semester: _me.semester,
      biography: _me.biography,
      privacyLevel: _me.privacyLevel,
      tags: _me.tags,
      schedules: [..._me.schedules, schedule],
      xp: _me.xp,
      level: _me.level,
      friendsId: _me.friendsId,
    );
    return _ok(_me);
  }

  @override
  Future<Result<UserProfile>> removeSchedule(String userId, Schedule schedule) {
    _me = UserProfile(
      id: _me.id,
      name: _me.name,
      gender: _me.gender,
      userType: _me.userType,
      career: _me.career,
      semester: _me.semester,
      biography: _me.biography,
      privacyLevel: _me.privacyLevel,
      tags: _me.tags,
      schedules: [..._me.schedules.where((s) => s != schedule)],
      xp: _me.xp,
      level: _me.level,
      friendsId: _me.friendsId,
    );
    return _ok(_me);
  }

  @override
  Future<Result<List<ProfileSummary>>> getProfilesByIds(List<String> ids) {
    return _ok([
      for (final p in demoProfiles)
        if (ids.contains(p.id)) p,
    ]);
  }
}
