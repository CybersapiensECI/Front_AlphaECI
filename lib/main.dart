import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/push/push_notifications.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Demo: sin backends, tampoco necesita Firebase (subida de fotos se
  // simula). Fuera de demo, si el proyecto aún no corrió
  // `flutterfire configure`, seguimos igual — solo falla al subir fotos.
  // TODO(firebase-test): quitar `|| Env.firebaseTest` al eliminar el flag.
  if (!Env.demoMode || Env.firebaseTest) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await initPushNotifications();
    } catch (e) {
      debugPrint('Firebase no inicializado (¿falta flutterfire configure?): $e');
    }
  }
  runApp(const ProviderScope(child: AlphaEciApp()));
}
