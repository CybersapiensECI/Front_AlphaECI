// TODO(demo): datos falsos para ver la app sin backends. Eliminar en prod.
import '../../../../core/errors/result.dart';
import '../../domain/entities/parche.dart';
import '../../domain/repositories/parche_repository.dart';

class MockParcheRepository implements ParcheRepository {
  MockParcheRepository();

  static const _me = '11111111-1111-1111-1111-111111111111';

  final List<Parche> _parches = [
    Parche(
      id: 'p1',
      name: 'Fútbol 5 en la cancha norte',
      description: '¡Nos falta gente para el partido del viernes!',
      place: 'Cancha norte',
      category: 'SPORTS',
      type: 'PUBLIC',
      date: DateTime.now().add(const Duration(days: 2)),
      hour: '16:00',
      maximumQuota: 10,
      status: 'ACTIVE',
      creatorStudentId: 'u2',
      members: const [
        ParcheMember(studentId: 'u2', role: 'CREATOR'),
        ParcheMember(studentId: 'u3', role: 'STUDENT'),
        ParcheMember(studentId: 'u5', role: 'STUDENT'),
      ],
    ),
    Parche(
      id: 'p2',
      name: 'Estudio de Cálculo Vectorial',
      description: 'Parcial el lunes. Repaso grupal en biblioteca.',
      place: 'Biblioteca - Sala 3',
      category: 'STUDIES',
      type: 'PUBLIC',
      date: DateTime.now().add(const Duration(days: 4)),
      hour: '10:00',
      maximumQuota: 8,
      status: 'ACTIVE',
      creatorStudentId: 'u4',
      members: const [
        ParcheMember(studentId: 'u4', role: 'CREATOR'),
        ParcheMember(studentId: _me, role: 'STUDENT'),
      ],
    ),
    Parche(
      id: 'p4',
      name: 'Cine al parque ECI',
      description: 'Proyección al aire libre. Entrada libre, trae manta.',
      place: 'Plazoleta central',
      category: 'CINEMA',
      type: 'PUBLIC',
      // Hoy: habilita el composer del feed en demo.
      date: DateTime.now(),
      hour: '18:00',
      maximumQuota: 30,
      status: 'ACTIVE',
      creatorStudentId: _me,
      members: const [
        ParcheMember(studentId: _me, role: 'CREATOR'),
        ParcheMember(studentId: 'u2', role: 'STUDENT'),
        ParcheMember(studentId: 'u5', role: 'STUDENT'),
      ],
    ),
    Parche(
      id: 'p5',
      name: 'Almuerzo en el Regio',
      description: '¿Quién más almuerza solo hoy? Hay puestos libres.',
      place: 'REGIO',
      category: 'GASTRONOMY',
      type: 'PUBLIC',
      date: DateTime.now(),
      hour: '12:30',
      maximumQuota: 4,
      status: 'ACTIVE',
      creatorStudentId: 'u2',
      members: const [
        ParcheMember(studentId: 'u2', role: 'CREATOR'),
        ParcheMember(studentId: 'u3', role: 'STUDENT'),
      ],
    ),
    Parche(
      id: 'p3',
      name: 'Torneo de Smash Bros',
      description: 'Traigan sus controles. Hay premio 🏆',
      place: 'Sala de juegos',
      category: 'GAMING',
      type: 'PRIVATE',
      date: DateTime.now().add(const Duration(days: 7)),
      hour: '14:00',
      maximumQuota: 16,
      status: 'ACTIVE',
      creatorStudentId: 'u3',
      members: const [ParcheMember(studentId: 'u3', role: 'CREATOR')],
    ),
  ];

  final Map<String, List<ParchePost>> _posts = {
    'p1': [
      ParchePost(
        id: 'post2',
        authorId: 'u2',
        text: 'Ya reservé la cancha para el viernes 🔥 Nos vemos 4pm.',
        photoUrl: 'https://picsum.photos/seed/eci-cancha/900/540',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        reactions: [
          PostReaction(id: 'r1', studentId: 'u5'),
        ],
        comments: [
          PostComment(
            id: 'c1',
            authorId: 'u3',
            text: 'Cuenten conmigo para el arco 🧤',
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          ),
        ],
      ),
      ParchePost(
        id: 'post3',
        authorId: 'u5',
        text: 'Yo llevo los petos y el balón ⚽',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ],
    'p2': [
      ParchePost(
        id: 'post1',
        authorId: 'u4',
        text: 'Confirmen quiénes vienen para reservar la sala 👇',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        comments: [
          PostComment(
            id: 'c2',
            authorId: 'u2',
            text: 'Yo voy, aparto puesto 👋',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      ),
    ],
    'p3': [
      ParchePost(
        id: 'post4',
        authorId: 'u3',
        text: 'Cupos casi llenos, confirmen su control 🎮🏆',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ],
    'p4': [
      ParchePost(
        id: 'post5',
        authorId: 'u2',
        text: 'El plan de hoy pinta brutal 🎬🍿 ¿Quién más viene?',
        photoUrl: 'https://picsum.photos/seed/eci-cine/900/540',
        createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
        reactions: [
          PostReaction(id: 'r2', studentId: 'u5'),
        ],
        comments: [
          PostComment(
            id: 'c3',
            authorId: 'u2',
            text: '¡Confirmadísimo! 🙌',
            createdAt: DateTime.now().subtract(const Duration(minutes: 32)),
          ),
          PostComment(
            id: 'c4',
            authorId: 'u4',
            text: 'Llevo crispetas para todos 🍿',
            createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
          ),
        ],
      ),
    ],
  };

  var _nextId = 10;

  Future<Result<T>> _ok<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 400), () => Success(value));

  @override
  Future<Result<List<Parche>>> search({
    String? category,
    String? place,
    String? query,
    int page = 0,
    int size = 20,
  }) {
    final q = query?.toLowerCase() ?? '';
    final cat = category?.toUpperCase();
    final pl = place?.toUpperCase();
    return _ok([
      for (final p in _parches)
        // Igual que el backend real: filtra por categoría, lugar y texto.
        if ((cat == null || p.category?.toUpperCase() == cat) &&
            (pl == null || p.place?.toUpperCase() == pl) &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                (p.description?.toLowerCase().contains(q) ?? false)))
          p,
    ]);
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
    final id = 'p${_nextId++}';
    _parches.insert(
      0,
      Parche(
        id: id,
        name: name,
        description: description,
        place: place,
        category: category,
        type: type,
        date: date,
        hour: hour,
        maximumQuota: maximumQuota,
        status: 'ACTIVE',
        creatorStudentId: creatorStudentId,
        members: [
          ParcheMember(studentId: creatorStudentId, role: 'CREATOR'),
        ],
      ),
    );
    return _ok(id);
  }

  @override
  Future<Result<String>> join(String parcheId, String studentId) {
    final index = _parches.indexWhere((p) => p.id == parcheId);
    if (index >= 0 && !_parches[index].isMember(studentId)) {
      final p = _parches[index];
      _parches[index] = Parche(
        id: p.id,
        name: p.name,
        description: p.description,
        place: p.place,
        category: p.category,
        type: p.type,
        date: p.date,
        hour: p.hour,
        maximumQuota: p.maximumQuota,
        status: p.status,
        creatorStudentId: p.creatorStudentId,
        members: [
          ...p.members,
          ParcheMember(studentId: studentId, role: 'STUDENT'),
        ],
      );
    }
    return _ok('Te has unido exitosamente al parche.');
  }

  @override
  Future<Result<List<ParcheMember>>> getMembers(String parcheId) {
    final parche = _parches.where((p) => p.id == parcheId).firstOrNull;
    return _ok(parche?.members ?? const []);
  }

  @override
  Future<Result<List<ParchePost>>> getPosts(String parcheId) {
    return _ok(List.of(_posts[parcheId] ?? const []));
  }

  @override
  Future<Result<String>> sendInvitation({
    required String parcheId,
    required String senderId,
    required String invitedId,
  }) =>
      _ok('Invitación enviada (demo).');

  @override
  Future<Result<String>> createComment({
    required String postId,
    required String authorId,
    required String text,
  }) {
    _updatePost(postId, (post) => ParchePost(
          id: post.id,
          authorId: post.authorId,
          text: post.text,
          photoUrl: post.photoUrl,
          createdAt: post.createdAt,
          reactions: post.reactions,
          comments: [
            ...post.comments,
            PostComment(
              id: 'c${_nextId++}',
              authorId: authorId,
              text: text,
              createdAt: DateTime.now(),
            ),
          ],
        ));
    return _ok('Comentario creado (demo).');
  }

  @override
  Future<Result<String>> reactToPost({
    required String postId,
    required String studentId,
  }) {
    _updatePost(postId, (post) {
      final already = post.reactions.any((r) => r.studentId == studentId);
      return ParchePost(
        id: post.id,
        authorId: post.authorId,
        text: post.text,
        photoUrl: post.photoUrl,
        createdAt: post.createdAt,
        comments: post.comments,
        reactions: already
            ? [...post.reactions.where((r) => r.studentId != studentId)]
            : [
                ...post.reactions,
                PostReaction(
                  id: 'r${_nextId++}',
                  studentId: studentId,
                  createdAt: DateTime.now(),
                ),
              ],
      );
    });
    return _ok('Reacción procesada (demo).');
  }

  /// Reemplaza el post con [postId] (en el parche que sea) por el
  /// resultado de aplicarle [update], sin tocar el resto de la lista.
  void _updatePost(
    String postId,
    ParchePost Function(ParchePost post) update,
  ) {
    for (final entry in _posts.entries) {
      final index = entry.value.indexWhere((p) => p.id == postId);
      if (index >= 0) {
        entry.value[index] = update(entry.value[index]);
        return;
      }
    }
  }

  @override
  Future<Result<String>> reactToComment({
    required String commentId,
    required String studentId,
  }) {
    for (final posts in _posts.values) {
      for (var i = 0; i < posts.length; i++) {
        final post = posts[i];
        final commentIndex =
            post.comments.indexWhere((c) => c.id == commentId);
        if (commentIndex < 0) continue;
        final comment = post.comments[commentIndex];
        final already =
            comment.reactions.any((r) => r.studentId == studentId);
        final updatedComment = PostComment(
          id: comment.id,
          authorId: comment.authorId,
          text: comment.text,
          createdAt: comment.createdAt,
          reactions: already
              ? [...comment.reactions.where((r) => r.studentId != studentId)]
              : [
                  ...comment.reactions,
                  PostReaction(
                    id: 'r${_nextId++}',
                    studentId: studentId,
                    createdAt: DateTime.now(),
                  ),
                ],
        );
        posts[i] = ParchePost(
          id: post.id,
          authorId: post.authorId,
          text: post.text,
          photoUrl: post.photoUrl,
          createdAt: post.createdAt,
          reactions: post.reactions,
          comments: [
            for (final c in post.comments) c.id == commentId ? updatedComment : c,
          ],
        );
        return _ok('Reacción procesada (demo).');
      }
    }
    return _ok('Reacción procesada (demo).');
  }

  @override
  Future<Result<String>> createPost({
    required String parcheId,
    required String authorId,
    String? text,
    String? photoUrl,
  }) {
    (_posts[parcheId] ??= []).insert(
      0,
      ParchePost(
        id: 'post${_nextId++}',
        authorId: authorId,
        text: text,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      ),
    );
    return _ok('Publicación creada exitosamente.');
  }
}
