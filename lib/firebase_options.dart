// GENERADO — este archivo se reemplaza ejecutando:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Ese comando pide iniciar sesión con tu cuenta Google, elegir/crear el
// proyecto Firebase y las plataformas (Android/iOS/Web), y SOBREESCRIBE
// este archivo con las claves reales. Sin eso, la subida de fotos a
// Firebase Storage falla — el resto de la app (modo DEMO, backends propios)
// no depende de esto y sigue funcionando igual.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no configurado para esta plataforma. '
          'Corre `flutterfire configure`.',
        );
    }
  }

  // Placeholders — reemplazados por `flutterfire configure`.
  static const web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
  );

  static const android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
  );

  static const ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
    iosBundleId: 'com.example.alphafront',
  );
}
