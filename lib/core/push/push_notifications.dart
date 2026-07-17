import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Publicidad de eventos nuevos: todo dispositivo con la app instalada se
/// suscribe a este topic FCM y notification-service publica ahí cuando se
/// crea un evento (EventService -> RabbitMQ -> notification-service ->
/// FCM). Sin registro de token por usuario: es puramente broadcast.
const eventsBroadcastTopic = 'events_broadcast';

/// Para mostrar un banner cuando llega un push con la app en primer plano
/// (FCM no la muestra sola en ese caso, solo en segundo plano/cerrada).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // El payload "notification" hace que el sistema operativo ya muestre el
  // aviso solo; no hay nada más que hacer aquí en segundo plano.
}

/// Pide permiso, suscribe al topic de eventos y engancha el listener de
/// primer plano. Falla en silencio: sin esto la app sigue funcionando
/// normal, solo sin push de eventos.
Future<void> initPushNotifications() async {
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.subscribeToTopic(eventsBroadcastTopic);

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title;
      final body = message.notification?.body;
      final text = [
        title,
        body,
      ].where((s) => s != null && s.isNotEmpty).join(' · ');
      if (text.isEmpty) return;
      scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 5),
        ));
    });
  } catch (e) {
    debugPrint('Push notifications no disponibles: $e');
  }
}
