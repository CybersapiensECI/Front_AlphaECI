import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Flags de "ya visto" para popups de bienvenida por pantalla. Reutiliza
/// flutter_secure_storage (ya usado para tokens) en vez de sumar la
/// dependencia shared_preferences solo para esto.
class OnboardingStorage {
  const OnboardingStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _monasWelcomeKey = 'seen_welcome_monas';

  Future<bool> hasSeenMonasWelcome() async =>
      (await _storage.read(key: _monasWelcomeKey)) == 'true';

  Future<void> markMonasWelcomeSeen() =>
      _storage.write(key: _monasWelcomeKey, value: 'true');
}
