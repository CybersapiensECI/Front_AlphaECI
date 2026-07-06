import 'package:equatable/equatable.dart';

/// Recurso de bienestar — espejo del model Resource de BienestarService.
class WellbeingResource extends Equatable {
  const WellbeingResource({
    required this.id,
    required this.title,
    this.description,
    this.type,
    this.category,
  });

  final String id;
  final String title;
  final String? description;

  /// TIP / ARTICLE / CONTACT.
  final String? type;
  final String? category;

  @override
  List<Object?> get props => [id, title];
}

/// Contacto de emergencia — espejo de EmergencyContact.
class EmergencyContact extends Equatable {
  const EmergencyContact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;

  @override
  List<Object?> get props => [id, name];
}
