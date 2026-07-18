/// Configuración de entorno. Con el API Gateway (AlphaGateway) todos los
/// servicios REST se consumen por UNA sola URL:
///   flutter run --dart-define=GATEWAY_URL=https://url-del-gateway
/// (default: gateway local en :8080 — `mvnw spring-boot:run` en AlphaGateway).
///
/// Cada servicio conserva su override individual por si hay que apuntar
/// directo a un despliegue puntual (p. ej. --dart-define=AUTH_URL=...).
abstract final class Env {
  /// TODO(firebase-test): flag TEMPORAL para probar Firebase Storage sin
  /// levantar los backends — mocks para todo, Firebase real para subir
  /// fotos. Eliminar cuando el back esté desplegado.
  /// Activar: flutter run -d windows --dart-define=FIREBASE_TEST=true
  static const firebaseTest = bool.fromEnvironment('FIREBASE_TEST');

  /// Modo demo: sin backends. Repositories mock con datos de muestra.
  /// Activar: flutter run --dart-define=DEMO=true
  static const demoMode = bool.fromEnvironment('DEMO') || firebaseTest;

  /// Valor por defecto cuando no se pasa --dart-define=GATEWAY_URL=...
  /// (gateway local de desarrollo). Un release compilado con este valor
  /// "funciona" pero cada request de red falla en el teléfono — ver la
  /// guardia en main.dart.
  static const localhostDefault = 'http://localhost:8080';

  /// URL base del API Gateway (única puerta de entrada REST).
  static const gatewayUrl = String.fromEnvironment(
    'GATEWAY_URL',
    defaultValue: localhostDefault,
  );

  // ── Servicios REST: por defecto, todos via gateway ──────────────
  static const authUrl =
      String.fromEnvironment('AUTH_URL', defaultValue: gatewayUrl);

  static const profileUrl =
      String.fromEnvironment('PROFILE_URL', defaultValue: gatewayUrl);

  static const matchingUrl =
      String.fromEnvironment('MATCHING_URL', defaultValue: gatewayUrl);

  static const chatUrl =
      String.fromEnvironment('CHAT_URL', defaultValue: gatewayUrl);

  static const notificationUrl =
      String.fromEnvironment('NOTIFICATION_URL', defaultValue: gatewayUrl);

  static const eventUrl =
      String.fromEnvironment('EVENT_URL', defaultValue: gatewayUrl);

  static const bienestarUrl =
      String.fromEnvironment('BIENESTAR_URL', defaultValue: gatewayUrl);

  static const geoUrl =
      String.fromEnvironment('GEO_URL', defaultValue: gatewayUrl);

  static const gamificationUrl =
      String.fromEnvironment('GAMIFICATION_URL', defaultValue: gatewayUrl);

  static const statsUrl =
      String.fromEnvironment('STATS_URL', defaultValue: gatewayUrl);

  static const parchesUrl =
      String.fromEnvironment('PARCHES_URL', defaultValue: gatewayUrl);

  /// WebSocket del chat (STOMP/SockJS /ws-chat). El gateway ya rutea
  /// /ws-chat/** hacia chat-service, así que por defecto va vía gateway.
  /// Override directo al servicio si hiciera falta: --dart-define=CHAT_WS_URL=...
  static const chatWsUrl =
      String.fromEnvironment('CHAT_WS_URL', defaultValue: gatewayUrl);

  /// http(s):// -> ws(s)://. AlphaGateway solo puede proxiar el upgrade real
  /// de WebSocket (probado: 101), no el handshake HTTP plano que SockJS hace
  /// contra /info antes de abrir transporte — por eso los sockets STOMP
  /// deben conectarse en modo WebSocket nativo (sin SockJS) usando esta URL.
  static String toWs(String httpUrl) {
    if (httpUrl.startsWith('https://')) return 'wss://${httpUrl.substring(8)}';
    if (httpUrl.startsWith('http://')) return 'ws://${httpUrl.substring(7)}';
    return httpUrl;
  }
}
