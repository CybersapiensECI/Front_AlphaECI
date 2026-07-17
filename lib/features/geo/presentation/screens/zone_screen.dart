import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/env.dart';
import '../../../../core/constants/campus_places.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../matching/presentation/providers/matching_provider.dart';
import '../../../parches/domain/entities/parche.dart';
import '../../../parches/presentation/providers/parche_provider.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../data/zone_repository.dart';
import '../providers/location_provider.dart';

final zoneRepositoryProvider = Provider<ZoneRepository>((ref) {
  if (Env.demoMode) return MockZoneRepository();
  return ZoneRepositoryImpl(ref.watch(apiClientProvider(Env.geoUrl)));
});

final zoneCatalogProvider = FutureProvider<List<String>>((ref) async {
  final result = await ref.watch(zoneRepositoryProvider).getCatalog();
  return result.when(
      success: (zones) => zones, error: (failure) => throw failure);
});

final myZoneProvider = FutureProvider<CampusZone?>((ref) async {
  final result = await ref.watch(zoneRepositoryProvider).getMyZone();
  return result.when(
      success: (zone) => zone, error: (failure) => throw failure);
});

/// Zonas del campus (Escuela Colombiana de Ingeniería Julio Garavito).
/// Coordenadas reales tomadas de Google Maps — ver
/// GeoService/MONAS_GEOLOCALIZACION.md. Claves = valores reales del enum
/// `CampusZone` de GeoService, deben coincidir exactos con GET /api/zone/catalog.
const Map<String, LatLng> _zoneCoordinates = {
  'EDIFICIO_A': LatLng(4.782699855684707, -74.04264918379),
  'EDIFICIO_B': LatLng(4.7830399485075255, -74.04270964402168),
  'EDIFICIO_C': LatLng(4.782389074571274, -74.04247753949225),
  'EDIFICIO_D': LatLng(4.783130774183006, -74.04354547558216),
  'EDIFICIO_E': LatLng(4.782681035143461, -74.04385407917442),
  'EDIFICIO_F': LatLng(4.783590080825507, -74.04332219644444),
  'EDIFICIO_G': LatLng(4.78349313377599, -74.04288042271563),
  'EDIFICIO_H': LatLng(4.781775204352766, -74.04493800488173),
  'EDIFICIO_I': LatLng(4.781918241337216, -74.04435269456233),
  'CAFETERIA_REGIO': LatLng(4.782980848558539, -74.04400996864427),
  'CAFETERIA_2': LatLng(4.78323330585694, -74.0446541217452),
  'CAFETERIA_3': LatLng(4.783855976183257, -74.04583457286611),
  'CAFETERIA_4': LatLng(4.7823632440346735, -74.04299435757378),
  'LAGO': LatLng(4.783042637971193, -74.04428261122634),
  'REFLEXION': LatLng(4.78303796045251, -74.04448109469203),
};

/// Zona del campus: selección manual (geolocalización simplificada, M13).
class ZoneScreen extends ConsumerStatefulWidget {
  const ZoneScreen({super.key});

  @override
  ConsumerState<ZoneScreen> createState() => _ZoneScreenState();
}

class _ZoneScreenState extends ConsumerState<ZoneScreen> {
  String? _selected;
  bool _enabled = true;
  bool _saving = false;
  bool _initialized = false;

  Future<void> _save() async {
    if (_selected == null) {
      showAppSnackBar(context, 'Elige una zona primero.');
      return;
    }
    setState(() => _saving = true);
    final result =
        await ref.read(zoneRepositoryProvider).saveZone(_selected!, _enabled);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        ref.invalidate(myZoneProvider);
        showAppSnackBar(context, 'Zona actualizada 📍');
      },
      error: (failure) => showAppSnackBar(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(zoneCatalogProvider);
    final myZone = ref.watch(myZoneProvider);
    final theme = Theme.of(context);

    final gpsSharing = ref.watch(gpsSharingProvider);
    final friends = ref.watch(friendsProvider).valueOrNull ?? const [];
    final friendIds = {for (final f in friends) f.profile.id};
    final peerLocations =
        ref.watch(peerLocationsProvider).valueOrNull ?? const {};
    final friendPositions = {
      for (final entry in peerLocations.entries)
        if (friendIds.contains(entry.key)) entry.key: entry.value,
    };
    final friendNames = {for (final f in friends) f.profile.id: f.profile.name};

    ref.listen(gpsSharingProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) => showAppSnackBar(context, error.toString()),
      );
    });

    // Preseleccionar zona actual.
    myZone.whenData((zone) {
      if (!_initialized && zone != null) {
        _initialized = true;
        _selected = zone.currentZone;
        _enabled = zone.currentZone != null;
      }
    });

    return GradientScaffold(
      appBar: AppBar(title: const Text('Mi zona del campus')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Selecciona dónde sueles estar. Sin GPS: tú eliges la zona '
                  'y priorizamos parches cercanos.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                // ── Mapa del campus (Escuela Julio Garavito) ──
                // Muestra zonas + parches activos + mi GPS + amigos conectados.
                catalog.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (zones) => _CampusMap(
                    zones: zones,
                    parches: ref.watch(parcheFeedProvider).valueOrNull ??
                        const [],
                    selected: _selected,
                    enabled: _enabled,
                    onZoneTap: (zone) => setState(() => _selected = zone),
                    myPosition: gpsSharing.valueOrNull,
                    friendPositions: friendPositions,
                    friendNames: friendNames,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los pines de colores son parches activos: tócalos para '
                  'ver el plan. El pin azul sos vos, los verdes son amigos '
                  'compartiendo su ubicación.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ver mi ubicación GPS'),
                  subtitle: Text(
                    'Muestra tu posición real y la de tus amigos conectados',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: gpsSharing.valueOrNull != null,
                  onChanged: (v) {
                    if (v) {
                      ref.read(gpsSharingProvider.notifier).start();
                    } else {
                      ref.read(gpsSharingProvider.notifier).stop();
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compartir mi zona'),
                  subtitle: Text('Apágalo y tu zona se borra',
                      style: theme.textTheme.bodySmall),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                const SizedBox(height: 8),
                catalog.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      const Text('No se pudo cargar el catálogo de zonas.'),
                  data: (zones) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final zone in zones)
                        ChoiceChip(
                          label: Text(zone.replaceAll('_', ' ')),
                          selected: _selected == zone,
                          onSelected: _enabled
                              ? (_) => setState(() => _selected = zone)
                              : null,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Guardar zona',
                  icon: Icons.place_outlined,
                  loading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: 20),
                myZone.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (zone) {
                    if (zone == null || zone.nearbyParches.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return FadeSlideIn(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Parches cerca de ti',
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              for (final name in zone.nearbyParches)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  leading: const Icon(
                                      Icons.celebration_outlined),
                                  title: Text(name),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mapa interactivo del campus con marcadores de zona tocables.
/// Tiles de OpenStreetMap (sin API key).
class _CampusMap extends StatelessWidget {
  const _CampusMap({
    required this.zones,
    required this.parches,
    required this.selected,
    required this.enabled,
    required this.onZoneTap,
    this.myPosition,
    this.friendPositions = const {},
    this.friendNames = const {},
  });

  final List<String> zones;
  final List<Parche> parches;
  final String? selected;
  final bool enabled;
  final ValueChanged<String> onZoneTap;
  final LatLng? myPosition;
  final Map<String, LatLng> friendPositions;
  final Map<String, String> friendNames;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.soft(context),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: SizedBox(
          height: 300,
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: campusCenter,
              initialZoom: 16.6,
              interactionOptions: InteractionOptions(
                // Pinch + drag; sin rotación (mapa siempre norte arriba).
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'co.edu.escuelaing.alphaeci',
              ),
              MarkerLayer(
                markers: [
                  for (final zone in zones)
                    if (_zoneCoordinates[zone] != null)
                      Marker(
                        point: _zoneCoordinates[zone]!,
                        width: 46,
                        height: 46,
                        child: _ZoneMarker(
                          label: zone,
                          selected: selected == zone,
                          onTap: enabled ? () => onZoneTap(zone) : null,
                        ),
                      ),
                  // Parches activos ubicados por su lugar del campus.
                  for (final parche in parches)
                    if (parche.status == 'ACTIVE')
                      Marker(
                        point: campusPlaceLatLng(parche.place),
                        width: 40,
                        height: 40,
                        child: _ParcheMarker(parche: parche),
                      ),
                  // Amigos compartiendo su ubicación GPS en vivo.
                  for (final entry in friendPositions.entries)
                    Marker(
                      point: entry.value,
                      width: 40,
                      height: 40,
                      child: _PersonMarker(
                        label: friendNames[entry.key] ?? 'Amigo',
                        color: Colors.green,
                      ),
                    ),
                  // Mi posición GPS en vivo.
                  if (myPosition != null)
                    Marker(
                      point: myPosition!,
                      width: 44,
                      height: 44,
                      child: const _PersonMarker(
                        label: 'Yo',
                        color: Colors.blue,
                        isMe: true,
                      ),
                    ),
                ],
              ),
              // Atribución obligatoria OSM.
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pin de posición GPS en vivo: la mía o la de un amigo conectado.
class _PersonMarker extends StatelessWidget {
  const _PersonMarker({
    required this.label,
    required this.color,
    this.isMe = false,
  });

  final String label;
  final Color color;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: AppShadows.glow(color),
        ),
        child: Icon(
          isMe ? Icons.my_location : Icons.person,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Pin de parche en el mapa: color de su categoría, tap abre el detalle.
class _ParcheMarker extends StatelessWidget {
  const _ParcheMarker({required this.parche});

  final Parche parche;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = AppCategoryStyles.of(parche.category);
    return BouncyTap(
      onTap: () => context.push(
        Routes.parcheDetailPath(parche.id),
        extra: parche,
      ),
      child: Tooltip(
        message: parche.name,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: AppShadows.glow(color),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _ZoneMarker extends StatelessWidget {
  const _ZoneMarker({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BouncyTap(
      onTap: onTap,
      child: Tooltip(
        message: label.replaceAll('_', ' '),
        child: AnimatedContainer(
          duration: AppDurations.base,
          curve: AppCurves.spring,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: selected ? AppGradients.buttonOf(context) : null,
            color: selected ? null : scheme.surface,
            border: Border.all(
              color: selected ? Colors.white : scheme.primary,
              width: 2,
            ),
            boxShadow: selected
                ? AppShadows.glow(scheme.tertiary)
                : AppShadows.soft(context),
          ),
          child: Icon(
            selected ? Icons.place : Icons.place_outlined,
            size: selected ? 26 : 20,
            color: selected ? Colors.white : scheme.primary,
          ),
        ),
      ),
    );
  }
}
