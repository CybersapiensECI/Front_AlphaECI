import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/location_socket_service.dart';

/// Servicio de socket de ubicación, uno por sesión de usuario.
final locationSocketServiceProvider =
    Provider.autoDispose<LocationSocketService?>((ref) {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) return null;
  final service = LocationSocketService(userId: session.userId);
  ref.onDispose(service.dispose);
  return service;
});

/// Presencia en campus en segundo plano: mientras el perfil tenga
/// geolocationEnabled (el usuario lo aceptó al registrarse o en su perfil),
/// envía la posición GPS a GeoService aunque "Mi zona" no esté abierta.
/// Sin esto, las geocercas (edificios/cafeterías/universidad) solo generaban
/// check-ins de monas mientras esa pantalla estuviera en primer plano.
/// Lo mantiene vivo el shell del Home (ref.watch en HomeScreen).
final campusPresenceProvider = Provider<void>((ref) {
  final session = ref.watch(authControllerProvider).session;
  final profile = ref.watch(myProfileProvider).valueOrNull;
  if (session == null || profile == null || !profile.geolocationEnabled) {
    return;
  }
  final socket = ref.watch(locationSocketServiceProvider);
  if (socket == null) return;

  StreamSubscription<Position>? sub;
  var cancelled = false;

  Future<void> start() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (cancelled ||
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled() || cancelled) return;
    try {
      final initial = await Geolocator.getCurrentPosition();
      if (cancelled) return;
      socket.sendMyLocation(initial.latitude, initial.longitude);
    } catch (_) {
      // GPS momentáneamente no disponible: el stream de abajo reintenta.
    }
    sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen(
      (position) => socket.sendMyLocation(position.latitude, position.longitude),
      onError: (_) {},
    );
  }

  start();
  ref.onDispose(() {
    cancelled = true;
    sub?.cancel();
  });
});

/// Estado de "compartir mi ubicación GPS" en Mi zona del campus.
class GpsSharingController extends AutoDisposeAsyncNotifier<LatLng?> {
  StreamSubscription<Position>? _positionSub;

  @override
  Future<LatLng?> build() async {
    ref.onDispose(() => _positionSub?.cancel());
    return null;
  }

  Future<void> start() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = AsyncError(
        'Permiso de ubicación denegado. Actívalo en ajustes del celular.',
        StackTrace.current,
      );
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      state = AsyncError(
        'El GPS está apagado. Actívalo para compartir tu ubicación.',
        StackTrace.current,
      );
      return;
    }

    final socket = ref.read(locationSocketServiceProvider);
    if (socket == null) return;

    // Primera lectura inmediata + stream continuo (cada ~15m de movimiento).
    final initial = await Geolocator.getCurrentPosition();
    state = AsyncData(LatLng(initial.latitude, initial.longitude));
    socket.sendMyLocation(initial.latitude, initial.longitude);

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen((position) {
      state = AsyncData(LatLng(position.latitude, position.longitude));
      socket.sendMyLocation(position.latitude, position.longitude);
    });
  }

  void stop() {
    _positionSub?.cancel();
    _positionSub = null;
    state = const AsyncData(null);
  }
}

final gpsSharingProvider =
    AsyncNotifierProvider.autoDispose<GpsSharingController, LatLng?>(
        GpsSharingController.new);

/// Últimas posiciones conocidas de otros usuarios (userId -> LatLng),
/// alimentado por /topic/locations mientras el socket esté activo.
final peerLocationsProvider =
    StreamProvider.autoDispose<Map<String, LatLng>>((ref) async* {
  final socket = ref.watch(locationSocketServiceProvider);
  if (socket == null) {
    yield const {};
    return;
  }
  final positions = <String, LatLng>{};
  yield positions;
  await for (final loc in socket.positions) {
    positions[loc.userId] = LatLng(loc.lat, loc.lng);
    yield Map.of(positions);
  }
});
