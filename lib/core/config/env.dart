/// URLs base por servicio. Se sobreescriben con --dart-define:
///   flutter run --dart-define=AUTH_URL=http://10.0.2.2:8080
///
/// TODO(gateway): cuando se confirme el API Gateway (Kong), colapsar
/// todo a una sola GATEWAY_URL.
abstract final class Env {
  /// TODO(firebase-test): flag TEMPORAL para probar Firebase Storage sin
  /// levantar los backends — mocks para todo, Firebase real para subir
  /// fotos. Eliminar cuando el back esté desplegado.
  /// Activar: flutter run -d windows --dart-define=FIREBASE_TEST=true
  static const firebaseTest = bool.fromEnvironment('FIREBASE_TEST');

  /// Modo demo: sin backends. Repositories mock con datos de muestra.
  /// Activar: flutter run --dart-define=DEMO=true
  static const demoMode = bool.fromEnvironment('DEMO') || firebaseTest;

  static const authUrl = String.fromEnvironment(
    'AUTH_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const profileUrl = String.fromEnvironment(
    'PROFILE_URL',
    defaultValue: 'http://localhost:8081',
  );

  static const matchingUrl = String.fromEnvironment(
    'MATCHING_URL',
    defaultValue: 'http://localhost:8083',
  );

  static const chatUrl = String.fromEnvironment(
    'CHAT_URL',
    defaultValue: 'http://localhost:8084',
  );

  static const notificationUrl = String.fromEnvironment(
    'NOTIFICATION_URL',
    defaultValue: 'http://localhost:8085',
  );

  static const eventUrl = String.fromEnvironment(
    'EVENT_URL',
    defaultValue: 'http://localhost:8086',
  );

  static const bienestarUrl = String.fromEnvironment(
    'BIENESTAR_URL',
    defaultValue: 'http://localhost:8087',
  );

  static const geoUrl = String.fromEnvironment(
    'GEO_URL',
    defaultValue: 'http://localhost:8088',
  );

  static const gamificationUrl = String.fromEnvironment(
    'GAMIFICATION_URL',
    defaultValue: 'http://localhost:8089',
  );

  static const statsUrl = String.fromEnvironment(
    'STATS_URL',
    defaultValue: 'http://localhost:8082',
  );

  static const parchesUrl = String.fromEnvironment(
    'PARCHES_URL',
    defaultValue: 'http://localhost:8090',
  );
}
