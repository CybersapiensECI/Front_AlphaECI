import '../../domain/entities/parche.dart';

/// Parsers del JSON de Parches-Service (domain Parche serializado).

ParcheMember parcheMemberFromJson(Map<String, dynamic> json) => ParcheMember(
      studentId: json['studentId'] as String? ?? '',
      role: json['role'] as String?,
      unionDate: _tryDate(json['unionDate']),
    );

PostComment postCommentFromJson(Map<String, dynamic> json) => PostComment(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: _tryDate(json['createdAt']),
      reactions: [
        for (final r in (json['reactions'] as List? ?? const []))
          postReactionFromJson(r as Map<String, dynamic>),
      ],
    );

PostReaction postReactionFromJson(Map<String, dynamic> json) => PostReaction(
      id: json['id'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      createdAt: _tryDate(json['createdAt']),
    );

ParchePost parchePostFromJson(Map<String, dynamic> json) => ParchePost(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      text: json['text'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: _tryDate(json['createdAt']),
      comments: [
        for (final c in (json['comments'] as List? ?? const []))
          postCommentFromJson(c as Map<String, dynamic>),
      ],
      reactions: [
        for (final r in (json['reactions'] as List? ?? const []))
          postReactionFromJson(r as Map<String, dynamic>),
      ],
    );

Parche parcheFromJson(Map<String, dynamic> json) => Parche(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      place: json['place'] as String?,
      category: json['category'] as String?,
      type: json['type'] as String?,
      date: _tryDate(json['date']),
      hour: _hourToString(json['hour']),
      maximumQuota: (json['maximumQuota'] as num?)?.toInt() ?? 0,
      status: json['status'] as String?,
      creatorStudentId: json['creatorStudentId'] as String?,
      eventId: json['eventId'] as String?,
      members: [
        for (final m in (json['members'] as List? ?? const []))
          parcheMemberFromJson(m as Map<String, dynamic>),
      ],
    );

DateTime? _tryDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  // LocalDate puede llegar como [yyyy, MM, dd] según configuración Jackson.
  if (value is List && value.length >= 3) {
    return DateTime(
      (value[0] as num).toInt(),
      (value[1] as num).toInt(),
      (value[2] as num).toInt(),
    );
  }
  return null;
}

String? _hourToString(dynamic value) {
  if (value is String) {
    // "14:30" o "14:30:00" — recortar a HH:mm.
    final parts = value.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return value;
  }
  // LocalTime como [HH, mm] según configuración Jackson.
  if (value is List && value.length >= 2) {
    final h = (value[0] as num).toInt().toString().padLeft(2, '0');
    final m = (value[1] as num).toInt().toString().padLeft(2, '0');
    return '$h:$m';
  }
  return null;
}
