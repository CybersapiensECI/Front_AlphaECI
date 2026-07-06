import 'package:intl/intl.dart';

import '../../domain/entities/registration_data.dart';

/// Modelos espejo de los DTOs reales de identity-service
/// (application/dto/request y /response). No inventar campos.

/// LoginResponseDto: {accessToken, refreshToken, tokenType}.
class LoginResponseModel {
  const LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String?,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String? tokenType;
}

/// RegisterResponseDto: {message}.
class MessageResponseModel {
  const MessageResponseModel({required this.message});

  factory MessageResponseModel.fromJson(Map<String, dynamic> json) {
    return MessageResponseModel(
      message: json['message'] as String? ?? 'Operación exitosa.',
    );
  }

  final String message;
}

/// CompleteRegistrationRequestDto — serialización del domain entity.
Map<String, dynamic> registrationDataToJson(RegistrationData data) {
  return {
    'email': data.email,
    'name': data.name,
    if (data.gender != null) 'gender': data.gender,
    if (data.career != null) 'career': data.career,
    if (data.semester != null) 'semester': data.semester,
    if (data.studentCarnet != null) 'studentCarnet': data.studentCarnet,
    if (data.photoUrl != null) 'photoUrl': data.photoUrl,
    if (data.biography != null) 'biography': data.biography,
    if (data.privacyLevel != null) 'privacyLevel': data.privacyLevel,
    if (data.dateOfBirth != null)
      // LocalDate en el backend: yyyy-MM-dd.
      'dateOfBirth': DateFormat('yyyy-MM-dd').format(data.dateOfBirth!),
    if (data.geolocationEnabled != null)
      'geolocationEnabled': data.geolocationEnabled,
  };
}
