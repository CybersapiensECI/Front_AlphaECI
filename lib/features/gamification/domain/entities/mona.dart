import 'package:equatable/equatable.dart';

/// Mona (logro coleccionable) — espejo de MonaEntry/MonaProgressEntry
/// del UserMonasResult de GamificationService.
class Mona extends Equatable {
  const Mona({
    required this.code,
    required this.name,
    this.description,
    this.rarity,
    this.category,
    this.imageUrl,
    this.xpGranted = 0,
    this.progressPercentage,
    this.currentCount,
    this.requiredCount,
  });

  final String code;
  final String name;
  final String? description;

  /// COMMON / UNCOMMON / RARE / EPIC / LEGENDARY (MonaRarity).
  final String? rarity;

  /// NETWORKING / CAFETERIAS / EDIFICIOS / ESTILO_DE_VIDA / EVENTOS /
  /// LEGENDARIAS (MonaCategory). Ver LISTA_MONAS.md.
  final String? category;
  final String? imageUrl;
  final int xpGranted;

  /// Solo para monas en progreso.
  final int? progressPercentage;
  final int? currentCount;
  final int? requiredCount;

  @override
  List<Object?> get props => [code, name, progressPercentage];
}

/// Resultado de GET /api/v1/gamification/users/{userId}/monas.
class UserMonas extends Equatable {
  const UserMonas({
    required this.totalXp,
    required this.totalUnlocked,
    required this.unlocked,
    required this.inProgress,
    required this.locked,
  });

  final int totalXp;
  final int totalUnlocked;
  final List<Mona> unlocked;
  final List<Mona> inProgress;
  final List<Mona> locked;

  int get total => unlocked.length + inProgress.length + locked.length;

  @override
  List<Object?> get props => [totalXp, totalUnlocked, unlocked, inProgress];
}
