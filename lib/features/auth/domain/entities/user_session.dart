import 'package:equatable/equatable.dart';

/// Sesión activa del usuario. Se construye a partir de los claims del JWT
/// emitido por identity-service (subject = userId, claims email y role).
class UserSession extends Equatable {
  const UserSession({
    required this.userId,
    required this.email,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });

  final String userId;
  final String email;
  final String role;
  final String accessToken;
  final String refreshToken;

  @override
  List<Object?> get props => [userId, email, role, accessToken, refreshToken];
}
