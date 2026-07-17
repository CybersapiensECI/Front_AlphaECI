import 'package:equatable/equatable.dart';

/// Evento universitario — espejo del model Event de EventService.
class UniversityEvent extends Equatable {
  const UniversityEvent({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.date,
    this.capacity = 0,
    this.availableCapacity = 0,
    this.status,
  });

  final String id;
  final String name;
  final String? description;
  final String? category;

  /// YYYY-MM-DD (String en el backend).
  final String? date;
  final int capacity;
  final int availableCapacity;

  /// ACTIVE / CANCELLED.
  final String? status;

  bool get isActive => status == 'ACTIVE';
  bool get hasCapacity => availableCapacity > 0;

  @override
  List<Object?> get props => [id, name, status, availableCapacity];
}
