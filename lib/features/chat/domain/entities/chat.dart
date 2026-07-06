import 'package:equatable/equatable.dart';

/// Conexión de chat — espejo de ConnectionResponse de chat-service.
class ChatConnection extends Equatable {
  const ChatConnection({
    required this.chatRoomId,
    required this.otherUserId,
    required this.status,
    this.createdAt,
  });

  final String chatRoomId;
  final String otherUserId;

  /// PENDING / ACTIVE / ... (ChatRoomStatus del backend).
  final String status;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [chatRoomId, otherUserId, status];
}

/// Mensaje — espejo de MessageResponse.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.content,
    this.type = 'TEXT',
    this.mediaUrl,
    this.sentAt,
  });

  final String id;
  final String chatRoomId;
  final String senderId;
  final String content;
  final String type;
  final String? mediaUrl;
  final DateTime? sentAt;

  @override
  List<Object?> get props => [id, chatRoomId, senderId, content];
}
