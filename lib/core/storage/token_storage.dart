import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistencia segura de tokens JWT (Keychain/Keystore; en web usa
/// almacenamiento del navegador — aceptable para desarrollo).
class TokenStorage {
  const TokenStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> get accessToken => _storage.read(key: _accessKey);

  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
