import 'package:equatable/equatable.dart';

/// Espejo de NotificationResponse de notification-service.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    this.type,
    this.referenceId,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool read;
  final String? type;
  final String? referenceId;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, read];
}
