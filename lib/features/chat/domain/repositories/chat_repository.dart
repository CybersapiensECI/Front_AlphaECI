import '../../../../core/errors/result.dart';
import '../entities/chat.dart';

/// Contrato contra chat-service (REST /api/chat + STOMP /ws-chat).
abstract interface class ChatRepository {
  /// GET /api/chat/connections.
  Future<Result<List<ChatConnection>>> getConnections();

  /// GET /api/chat/{chatRoomId}/messages (paginado, page 0 = recientes).
  Future<Result<List<ChatMessage>>> getHistory(String chatRoomId);

  /// Mensajes entrantes en tiempo real de una sala
  /// (suscripción a /topic/parche/{chatRoomId}/messages).
  Stream<ChatMessage> subscribe(String chatRoomId);

  /// Envío por STOMP a /app/chat/{chatRoomId}/send.
  Future<Result<void>> sendMessage(String chatRoomId, String content);

  /// Cierra la conexión WebSocket.
  void disconnect();
}
