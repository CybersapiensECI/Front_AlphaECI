import '../../../../core/errors/result.dart';
import '../entities/chat.dart';

/// Contrato contra chat-service (REST /api/chat + STOMP /ws-chat).
abstract interface class ChatRepository {
  /// GET /api/chat/connections.
  Future<Result<List<ChatConnection>>> getConnections();

  /// POST /api/chat/connections/friend/{friendId} — get-or-create, idempotente.
  /// Backfill natural para amistades de antes de que existiera el consumer
  /// de friendship.created: si la sala aún no existe, se crea en el momento.
  Future<Result<ChatConnection>> ensureFriendRoom(String friendId);

  /// POST /api/chat/connections/parche/{parcheId} — get-or-create, idempotente.
  /// Parches-Service no publica parche.created, así que la sala grupal solo
  /// nace cuando alguien abre el chat; también agrega al caller como miembro
  /// (sin esto el historial devuelve 403 para miembros previos al consumer).
  Future<Result<void>> ensureParcheRoom(String parcheId);

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
