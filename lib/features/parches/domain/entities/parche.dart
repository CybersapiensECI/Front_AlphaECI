import 'package:equatable/equatable.dart';

/// Miembro de un parche (espejo del domain Member).
class ParcheMember extends Equatable {
  const ParcheMember({
    required this.studentId,
    this.role,
    this.unionDate,
  });

  final String studentId;

  /// STUDENT / CREATOR.
  final String? role;
  final DateTime? unionDate;

  @override
  List<Object?> get props => [studentId, role];
}

/// Publicación dentro de un parche.
class ParchePost extends Equatable {
  const ParchePost({
    required this.id,
    required this.authorId,
    this.text,
    this.photoUrl,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String? text;
  final String? photoUrl;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, authorId, text, photoUrl];
}

/// Plan grupal (espejo del domain Parche de Parches-Service).
class Parche extends Equatable {
  const Parche({
    required this.id,
    required this.name,
    this.description,
    this.place,
    this.category,
    this.type,
    this.date,
    this.hour,
    this.maximumQuota = 0,
    this.status,
    this.creatorStudentId,
    this.eventId,
    this.members = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? place;
  final String? category;

  /// PUBLIC / PRIVATE.
  final String? type;
  final DateTime? date;

  /// HH:mm (LocalTime del backend).
  final String? hour;
  final int maximumQuota;

  /// ACTIVE / FILED.
  final String? status;
  final String? creatorStudentId;
  final String? eventId;
  final List<ParcheMember> members;

  int get memberCount => members.length;

  int get availableSlots =>
      (maximumQuota - memberCount).clamp(0, maximumQuota);

  bool isMember(String userId) =>
      members.any((m) => m.studentId == userId);

  bool isCreator(String userId) => creatorStudentId == userId;

  @override
  List<Object?> get props => [id, name, status, members];
}
