import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';

/// REST + STOMP contra chat-service.
/// WebSocket nativo (sin SockJS) en /ws-chat/websocket, enviar a
/// /app/chat/{id}/send, escuchar /topic/parche/{id}/messages (verificado en
/// ChatWebSocketHandler). SockJS se descartó: AlphaGateway solo proxia el
/// upgrade real de WS, no el GET /info que SockJS necesita primero (probado
/// contra prod: /ws-chat/info -> 400 vía gateway, /ws-chat/websocket -> 101).
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required this._dio, required this._userId});

  final Dio _dio;
  final String _userId;

  StompClient? _stomp;
  final _controllers = <String, StreamController<ChatMessage>>{};
  final _pendingSubscriptions = <String>{};
  bool _connected = false;

  static const _base = '/api/chat';

  // ── REST ───────────────────────────────────────────────────

  @override
  Future<Result<List<ChatConnection>>> getConnections() async {
    try {
      final response = await _dio.get<List<dynamic>>('$_base/connections');
      return Success([
        for (final c in response.data ?? const [])
          _connectionFromJson(c as Map<String, dynamic>),
      ]);
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<Result<ChatConnection>> ensureFriendRoom(String friendId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_base/connections/friend/$friendId',
      );
      return Success(_connectionFromJson(response.data!));
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> ensureParcheRoom(String parcheId) async {
    try {
      await _dio.post<void>('$_base/connections/parche/$parcheId');
      return const Success(null);
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  @override
  Future<Result<List<ChatMessage>>> getHistory(String chatRoomId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_base/$chatRoomId/messages',
        queryParameters: {'page': 0, 'size': 50},
      );
      final content = response.data?['content'] as List? ?? const [];
      return Success([
        for (final m in content) messageFromJson(m as Map<String, dynamic>),
      ]);
    } on DioException catch (e) {
      return Error(mapDioError(e));
    } catch (_) {
      return const Error(UnknownFailure());
    }
  }

  // ── STOMP ──────────────────────────────────────────────────

  void _ensureConnected() {
    if (_stomp != null) return;
    _stomp = StompClient(
      config: StompConfig(
        url: '${Env.toWs(Env.chatWsUrl)}/ws-chat/websocket',
        onConnect: (frame) {
          _connected = true;
          for (final roomId in _pendingSubscriptions) {
            _subscribeInternal(roomId);
          }
          _pendingSubscriptions.clear();
        },
        onDisconnect: (_) => _connected = false,
        onWebSocketError: (_) {},
        stompConnectHeaders: {'X-User-Id': _userId},
      ),
    );
    _stomp!.activate();
  }

  void _subscribeInternal(String chatRoomId) {
    _stomp?.subscribe(
      destination: '/topic/parche/$chatRoomId/messages',
      callback: (frame) {
        final body = frame.body;
        if (body == null) return;
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          _controllers[chatRoomId]?.add(messageFromJson(json));
        } catch (_) {
          // Mensaje con formato inesperado: ignorar.
        }
      },
    );
  }

  @override
  Stream<ChatMessage> subscribe(String chatRoomId) {
    _ensureConnected();
    final controller = _controllers.putIfAbsent(
      chatRoomId,
      () => StreamController<ChatMessage>.broadcast(),
    );
    if (_connected) {
      _subscribeInternal(chatRoomId);
    } else {
      _pendingSubscriptions.add(chatRoomId);
    }
    return controller.stream;
  }

  @override
  Future<Result<void>> sendMessage(String chatRoomId, String content) async {
    _ensureConnected();
    if (!_connected) {
      return const Error(NetworkFailure('Chat desconectado. Reintentando…'));
    }
    // Espejo de SendMessageRequest {type, content, mediaUrl}.
    _stomp!.send(
      destination: '/app/chat/$chatRoomId/send',
      headers: {'X-User-Id': _userId},
      body: jsonEncode({'type': 'TEXT', 'content': content}),
    );
    return const Success(null);
  }

  @override
  void disconnect() {
    _stomp?.deactivate();
    _stomp = null;
    _connected = false;
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  // ── parsers ────────────────────────────────────────────────

  static ChatConnection _connectionFromJson(Map<String, dynamic> json) {
    return ChatConnection(
      chatRoomId: json['chatRoomId'] as String? ?? '',
      otherUserId: json['otherUserId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  static ChatMessage messageFromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      chatRoomId: json['chatRoomId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'TEXT',
      mediaUrl: json['mediaUrl'] as String?,
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? ''),
    );
  }
}
