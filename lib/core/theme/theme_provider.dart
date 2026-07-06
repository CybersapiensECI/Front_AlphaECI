import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Modo de tema seleccionable (Sistema/Claro/Oscuro), persistido
/// en secure storage — sin dependencias nuevas.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    Future(() async {
      final saved = await _storage.read(key: _key);
      final mode = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      if (mode != state) state = mode;
    });
    return ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _storage.write(
      key: _key,
      value: switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
