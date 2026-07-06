import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'session_expiry_bus.dart';

final tokenStorageProvider = Provider<TokenStorage>((_) => const TokenStorage());

final sessionExpiryBusProvider =
    Provider<SessionExpiryBus>((_) => SessionExpiryBus());

/// Un Dio por servicio backend (family por baseUrl).
/// Uso: `ref.watch(apiClientProvider(Env.authUrl))`.
final apiClientProvider = Provider.family<Dio, String>((ref, baseUrl) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: ref.watch(tokenStorageProvider),
      expiryBus: ref.watch(sessionExpiryBusProvider),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(responseBody: false));
  }

  return dio;
});
