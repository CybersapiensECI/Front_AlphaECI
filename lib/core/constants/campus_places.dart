import 'package:latlong2/latlong.dart';

/// Lugares del campus Escuela Colombiana de Ingeniería Julio Garavito.
/// Coordenadas aproximadas SOLO de front (visual): el backend guarda el
/// lugar como texto. TODO(backend): cuando Parches-Service almacene
/// coordenadas reales, eliminar este mapa.
const campusCenter = LatLng(4.7826, -74.0424);

const Map<String, LatLng> campusPlaces = {
  'Plazoleta central': LatLng(4.7825, -74.0426),
  'Biblioteca': LatLng(4.7828, -74.0422),
  'Biblioteca - Sala 3': LatLng(4.7829, -74.0421),
  'Cafetería central': LatLng(4.7823, -74.0430),
  'Cancha norte': LatLng(4.7838, -74.0414),
  'Canchas': LatLng(4.7819, -74.0410),
  'Sala de juegos': LatLng(4.7827, -74.0432),
  'Edificio D': LatLng(4.7831, -74.0435),
  'Laboratorios': LatLng(4.7833, -74.0428),
  'Zona verde norte': LatLng(4.7836, -74.0424),
};

/// Coordenada para un lugar: match exacto (sin mayúsculas) o posición
/// determinística cerca del centro (mismo lugar = mismo punto siempre).
LatLng campusPlaceLatLng(String? place) {
  if (place == null || place.trim().isEmpty) return campusCenter;
  final normalized = place.trim().toLowerCase();
  for (final entry in campusPlaces.entries) {
    if (entry.key.toLowerCase() == normalized) return entry.value;
  }
  final hash = normalized.hashCode;
  final dLat = ((hash % 21) - 10) * 0.00012;
  final dLng = (((hash ~/ 21) % 21) - 10) * 0.00012;
  return LatLng(campusCenter.latitude + dLat, campusCenter.longitude + dLng);
}
