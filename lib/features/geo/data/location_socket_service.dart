import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/config/env.dart';

/// Posición de un usuario transmitida por GeoService.
class UserLocation {
  const UserLocation({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  final String userId;
  final double lat;
  final double lng;
  final int timestamp;

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
        userId: json['userId'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      );
}

/// WebSocket STOMP nativo (sin SockJS) contra GeoService
/// (/ws-location/websocket -> /app/location -> /topic/locations), mismo
/// patrón que ChatRepositoryImpl (ver ese archivo para por qué no SockJS).
/// Envía mi posición GPS y escucha la de los demás usuarios en tiempo real.
class LocationSocketService {
  LocationSocketService({required String userId}) : _userId = userId;

  final String _userId;
  StompClient? _stomp;
  bool _connected = false;
  final _pendingSends = <UserLocation>[];
  final _positionsController = StreamController<UserLocation>.broadcast();

  Stream<UserLocation> get positions => _positionsController.stream;

  void _ensureConnected() {
    if (_stomp != null) return;
    _stomp = StompClient(
      config: StompConfig(
        url: '${Env.toWs(Env.geoUrl)}/ws-location/websocket',
        onConnect: (frame) {
          _connected = true;
          _stomp?.subscribe(
            destination: '/topic/locations',
            callback: (frame) {
              final body = frame.body;
              if (body == null) return;
              try {
                final json = jsonDecode(body) as Map<String, dynamic>;
                _positionsController.add(UserLocation.fromJson(json));
              } catch (_) {
                // Mensaje con formato inesperado: ignorar.
              }
            },
          );
          for (final pending in _pendingSends) {
            _sendInternal(pending);
          }
          _pendingSends.clear();
        },
        onDisconnect: (_) => _connected = false,
        onWebSocketError: (_) {},
      ),
    );
    _stomp!.activate();
  }

  void _sendInternal(UserLocation location) {
    _stomp?.send(
      destination: '/app/location',
      body: jsonEncode({
        'userId': location.userId,
        'lat': location.lat,
        'lng': location.lng,
        'timestamp': location.timestamp,
      }),
    );
  }

  /// Envía mi posición actual. Se conecta al socket la primera vez que se
  /// llama; si aún no hay conexión activa, la encola.
  void sendMyLocation(double lat, double lng) {
    _ensureConnected();
    final location = UserLocation(
      userId: _userId,
      lat: lat,
      lng: lng,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    if (_connected) {
      _sendInternal(location);
    } else {
      _pendingSends.add(location);
    }
  }

  void disconnect() {
    _stomp?.deactivate();
    _stomp = null;
    _connected = false;
    _pendingSends.clear();
  }

  void dispose() {
    disconnect();
    _positionsController.close();
  }
}
