import 'package:latlong2/latlong.dart';

/// Lugares del campus Escuela Colombiana de Ingeniería Julio Garavito.
/// Claves = valores REALES del enum `Places` de Parches-Service (ver
/// `Parches.Alpha.Domain.Enums.Places`) — deben coincidir exactos, el
/// backend hace `Places.valueOf(place.toUpperCase())` y lanza 500 si no
/// matchea. Coordenadas aproximadas SOLO de front (visual): el backend
/// guarda el lugar como código, no como coordenadas.
const campusCenter = LatLng(4.7826, -74.0424);

const Map<String, LatLng> campusPlaces = {
  'HARVIES': LatLng(4.7823, -74.0430),
  'COLISEO': LatLng(4.7838, -74.0414),
  'BUILDING_A': LatLng(4.7827, -74.0426),
  'BUILDING_B': LatLng(4.7830, -74.0427),
  'BUILDING_C': LatLng(4.7824, -74.0425),
  'BUILDING_D': LatLng(4.7831, -74.0435),
  'BUILDING_E': LatLng(4.7827, -74.0439),
  'BUILDING_F': LatLng(4.7836, -74.0433),
  'BUILDING_H': LatLng(4.7818, -74.0449),
  'BUILDING_I': LatLng(4.7819, -74.0444),
  'SOCCER_COURT_1': LatLng(4.7819, -74.0410),
  'SOCCER_COURT_2': LatLng(4.7841, -74.0409),
  'BASKETBALL_COURT': LatLng(4.7836, -74.0424),
  'TENIS_COURT': LatLng(4.7833, -74.0428),
  'SAND_VOLEY_COURT': LatLng(4.7815, -74.0413),
  'REGIO': LatLng(4.7830, -74.0440),
  'LEYENDA': LatLng(4.7838, -74.0458),
};

/// Etiqueta legible en español para un código de lugar. Mismo patrón que
/// `AppCategoryStyles.labelOf` para categorías: el código va al backend,
/// la etiqueta es solo para mostrar.
String placeLabelOf(String place) {
  const labels = {
    'HARVIES': 'Harvies',
    'COLISEO': 'Coliseo',
    'BUILDING_A': 'Edificio A',
    'BUILDING_B': 'Edificio B',
    'BUILDING_C': 'Edificio C',
    'BUILDING_D': 'Edificio D',
    'BUILDING_E': 'Edificio E',
    'BUILDING_F': 'Edificio F',
    'BUILDING_H': 'Edificio H',
    'BUILDING_I': 'Edificio I',
    'SOCCER_COURT_1': 'Cancha de fútbol 1',
    'SOCCER_COURT_2': 'Cancha de fútbol 2',
    'BASKETBALL_COURT': 'Cancha de baloncesto',
    'TENIS_COURT': 'Cancha de tenis',
    'SAND_VOLEY_COURT': 'Cancha de vóley playa',
    'REGIO': 'Cafetería Regio',
    'LEYENDA': 'Cafetería Leyenda',
  };
  return labels[place] ?? place;
}

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
