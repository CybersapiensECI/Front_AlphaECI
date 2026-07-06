import 'package:equatable/equatable.dart';

/// Espejo de UserPersonalStatsResponse de Estadisticas_Eci (BFF).
/// Secciones nullables: el BFF devuelve null si un microservicio no responde.
class PersonalStats extends Equatable {
  const PersonalStats({
    required this.userId,
    this.gamification,
    this.events,
    this.parches,
    this.profile,
  });

  final String userId;
  final GamificationStats? gamification;
  final EventStats? events;
  final ParcheStats? parches;
  final ProfileStats? profile;

  @override
  List<Object?> get props => [userId, gamification, events, parches, profile];
}

class GamificationStats extends Equatable {
  const GamificationStats({
    required this.totalXp,
    required this.totalMonasUnlocked,
    required this.monasInProgress,
    required this.monasLocked,
    required this.completionPercentage,
  });

  final int totalXp;
  final int totalMonasUnlocked;
  final int monasInProgress;
  final int monasLocked;
  final double completionPercentage;

  @override
  List<Object?> get props => [totalXp, totalMonasUnlocked];
}

class EventStats extends Equatable {
  const EventStats({
    required this.totalAttended,
    required this.upcomingEvents,
    required this.totalEvents,
  });

  final int totalAttended;
  final int upcomingEvents;
  final int totalEvents;

  @override
  List<Object?> get props => [totalAttended, upcomingEvents, totalEvents];
}

class ParcheStats extends Equatable {
  const ParcheStats({required this.totalJoined, required this.activeParches});

  final int totalJoined;
  final int activeParches;

  @override
  List<Object?> get props => [totalJoined, activeParches];
}

class ProfileStats extends Equatable {
  const ProfileStats({
    required this.xp,
    required this.level,
    required this.isActive,
    this.career,
    this.semester,
  });

  final int xp;
  final int level;
  final bool isActive;
  final String? career;
  final int? semester;

  @override
  List<Object?> get props => [xp, level];
}
