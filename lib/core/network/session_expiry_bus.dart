import 'package:flutter/foundation.dart';

/// Bus mínimo para romper el ciclo de dependencias:
/// AuthInterceptor -> bus <- AuthController.
/// Cuando el refresh falla definitivamente, el interceptor dispara expire()
/// y el AuthController (que escucha) limpia la sesión y redirige a login.
class SessionExpiryBus extends ChangeNotifier {
  void expire() => notifyListeners();
}
