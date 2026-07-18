import '../../domain/entities/profile.dart';

/// Parsers de las respuestas de profile-service (NestJS).
/// Campos verificados contra los DTOs reales del repositorio.

Tag tagFromJson(Map<String, dynamic> json) => Tag(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
    );

TagCategory tagCategoryFromJson(Map<String, dynamic> json) => TagCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      tags: [
        for (final t in (json['tags'] as List? ?? const []))
          tagFromJson(t as Map<String, dynamic>),
      ],
    );

Schedule scheduleFromJson(Map<String, dynamic> json) => Schedule(
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      name: json['name'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
    );

Map<String, dynamic> scheduleToJson(Schedule s) => {
      'dayOfWeek': s.dayOfWeek,
      'name': s.name,
      'startTime': s.startTime,
      'endTime': s.endTime,
    };

UserProfile userProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String?,
      userType: json['userType'] as String?,
      career: json['career'] as String?,
      semester: (json['semester'] as num?)?.toInt(),
      biography: json['biography'] as String?,
      photoUrl: json['photoUrl'] as String?,
      privacyLevel: json['privacyLevel'] as String?,
      tags: [
        for (final t in (json['tags'] as List? ?? const []))
          tagFromJson(t as Map<String, dynamic>),
      ],
      schedules: [
        for (final s in (json['schedules'] as List? ?? const []))
          scheduleFromJson(s as Map<String, dynamic>),
      ],
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      friendsId: [
        for (final f in (json['friendsId'] as List? ?? const [])) f as String,
      ],
      active: json['active'] as bool? ?? true,
      geolocationEnabled: json['geolocationEnabled'] as bool? ?? false,
    );

ProfileSummary profileSummaryFromJson(Map<String, dynamic> json) =>
    ProfileSummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      biography: json['biography'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
