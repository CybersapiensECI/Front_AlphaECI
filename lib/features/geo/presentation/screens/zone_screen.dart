import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/widgets/auth_layout.dart'
    show showAppSnackBar;
import '../../data/zone_repository.dart';

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
