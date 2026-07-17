import 'package:equatable/equatable.dart';

/// Datos de perfil para completar el registro.
/// Espejo del CompleteRegistrationRequestDto de identity-service.
class RegistrationData extends Equatable {
  const RegistrationData({
    required this.email,
    required this.name,
    this.gender,
    this.career,
    this.semester,
    this.studentCarnet,
    this.photoUrl,
    this.biography,
    this.privacyLevel,
    this.dateOfBirth,
    this.geolocationEnabled,
  });

  final String email;
  final String name;
  final String? gender;
  final String? career;
  final int? semester;
  final String? studentCarnet;
  final String? photoUrl;
  final String? biography;
  final String? privacyLevel;
  final DateTime? dateOfBirth;
  final bool? geolocationEnabled;

  @override
  List<Object?> get props => [
        email,
        name,
        gender,
        career,
        semester,
        studentCarnet,
        photoUrl,
        biography,
        privacyLevel,
        dateOfBirth,
        geolocationEnabled,
      ];
}
