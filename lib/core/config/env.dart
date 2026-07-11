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

  /// URL base del API Gateway (única puerta de entrada REST).
  static const gatewayUrl = String.fromEnvironment(
    'GATEWAY_URL',
    defaultValue: 'http://localhost:8080',
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

  // TODO(gateway): la ruta /api/gamification/** del gateway usa
  // StripPrefix=1 pero GamificationService sirve /api/v1/gamification/**
  // — vía gateway hoy da 404. Igual /api/estadisticas/** vs
  // /api/v1/metrics/**, y parches declara /api/v1/parches/** pero el
  // backend sirve /api/parches/** (y faltan /api/invitations,
  // /api/posts). Corregir en AlphaGateway/application.yml.
  static const gamificationUrl =
      String.fromEnvironment('GAMIFICATION_URL', defaultValue: gatewayUrl);

  static const statsUrl =
      String.fromEnvironment('STATS_URL', defaultValue: gatewayUrl);

  static const parchesUrl =
      String.fromEnvironment('PARCHES_URL', defaultValue: gatewayUrl);

  /// WebSocket del chat (STOMP /ws-chat). El gateway NO rutea este WS
  /// (solo tiene /ws-location de geo), así que va DIRECTO al despliegue
  /// de chat-service. TODO(gateway): agregar ruta wss para /ws-chat.
  static const chatWsUrl = String.fromEnvironment(
    'CHAT_WS_URL',
    defaultValue:
        'https://chat-service-prod.gentlebeach-15ecf803.eastus.azurecontainerapps.io',
  );
}
