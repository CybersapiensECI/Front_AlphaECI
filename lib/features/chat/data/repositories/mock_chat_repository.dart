// TODO(demo): chat falso con bot que responde. Eliminar en prod.
import 'dart:async';

import '../../../../core/errors/result.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';

class MockChatRepository implements ChatRepository {
  MockChatRepository();

  static const _me = '11111111-1111-1111-1111-111111111111';

  final _controllers = <String, StreamController<ChatMessage>>{};
  var _nextId = 100;

  final Map<String, List<ChatMessage>> _history = {
    'room-ana': [
      ChatMessage(
        id: 'c1',
        chatRoomId: 'room-ana',
        senderId: 'u2',
        content: '¡Hola! Vi que también te gusta programar 💻',
        sentAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatMessage(
        id: 'c2',
        chatRoomId: 'room-ana',
        senderId: _me,
        content: '¡Sí! ¿Vas a la hackathon del sábado?',
        sentAt: DateTime.now().subtract(const Duration(minutes: 28)),
      ),
      ChatMessage(
        id: 'c3',
        chatRoomId: 'room-ana',
        senderId: 'u2',
        content: 'Obvio, ¿armamos equipo?',
        sentAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
    ],
    'room-juana': [
      ChatMessage(
        id: 'c4',
        chatRoomId: 'room-juana',
        senderId: 'u4',
        content: 'Nos vemos en el repaso de cálculo 📚',
        sentAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ],
  };

  Future<Result<T>> _ok<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 350), () => Success(value));

  @override
  Future<Result<List<ChatConnection>>> getConnections() => _ok(const [
        ChatConnection(
            chatRoomId: 'room-ana', otherUserId: 'u2', status: 'ACTIVE'),
        ChatConnection(
            chatRoomId: 'room-juana', otherUserId: 'u4', status: 'ACTIVE'),
      ]);

  @override
  Future<Result<List<ChatMessage>>> getHistory(String chatRoomId) =>
      _ok(List.of(_history[chatRoomId] ?? const []));

  @override
  Stream<ChatMessage> subscribe(String chatRoomId) {
    return _controllers
        .putIfAbsent(chatRoomId, StreamController<ChatMessage>.broadcast)
        .stream;
  }

  @override
  Future<Result<void>> sendMessage(String chatRoomId, String content) async {
    final mine = ChatMessage(
      id: 'c${_nextId++}',
      chatRoomId: chatRoomId,
      senderId: _me,
      content: content,
      sentAt: DateTime.now(),
    );
    (_history[chatRoomId] ??= []).add(mine);
    _controllers[chatRoomId]?.add(mine);

    // Bot responde a los 1.2s.
    Future.delayed(const Duration(milliseconds: 1200), () {
      final reply = ChatMessage(
        id: 'c${_nextId++}',
        chatRoomId: chatRoomId,
        senderId: chatRoomId == 'room-ana' ? 'u2' : 'u4',
        content: '¡Dale! 🙌 (respuesta demo)',
        sentAt: DateTime.now(),
      );
      _history[chatRoomId]?.add(reply);
      _controllers[chatRoomId]?.add(reply);
    });
    return const Success(null);
  }

  @override
  void disconnect() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
