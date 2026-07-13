import 'package:flutter/material.dart';

import '../../domain/entities/mona.dart';

/// Estilo visual del álbum de monas: colores vivos por rareza y gradientes
/// metálicos por categoría (ver LISTA_MONAS.md para el catálogo completo).
/// Todo deriva de [Mona.rarity]/[Mona.category] cuando el backend los envía;
/// si el backend aún no manda `category`, se infiere desde [Mona.code].

/// Categorías del catálogo (LISTA_MONAS.md).
const kMonaCategoryNetworking = 'NETWORKING';
const kMonaCategoryCafeterias = 'CAFETERIAS';
const kMonaCategoryEdificios = 'EDIFICIOS';
const kMonaCategoryEstiloDeVida = 'ESTILO_DE_VIDA';
const kMonaCategoryEventos = 'EVENTOS';
const kMonaCategoryLegendarias = 'LEGENDARIAS';

/// Códigos exactos de LISTA_MONAS.md → categoría, para inferir cuando el
/// backend no envía `category` explícitamente.
const Map<String, String> _codeToCategory = {
  'PRIMER_CONTACTO': kMonaCategoryNetworking,
  'NETWORKING_5': kMonaCategoryNetworking,
  'NETWORKING_10': kMonaCategoryNetworking,
  'NETWORKING_25': kMonaCategoryNetworking,
  'INICIADOR_PARCHE': kMonaCategoryNetworking,
  'CAPITAN_EQUIPO': kMonaCategoryNetworking,
  'ORGANIZADOR_ELITE': kMonaCategoryNetworking,
  'PRIMER_MENSAJERO': kMonaCategoryNetworking,
  'ANFITRION': kMonaCategoryNetworking,
  'CONECTOR_VELOZ': kMonaCategoryNetworking,
  'EXPLORADOR_CAFETERIAS': kMonaCategoryCafeterias,
  'FAN_REGIO': kMonaCategoryCafeterias,
  'CLIENTE_FRECUENTE': kMonaCategoryCafeterias,
  'RUTA_CAFE': kMonaCategoryCafeterias,
  'EDIFICIO_A': kMonaCategoryEdificios,
  'EDIFICIO_B': kMonaCategoryEdificios,
  'EDIFICIO_C': kMonaCategoryEdificios,
  'EDIFICIO_D': kMonaCategoryEdificios,
  'EDIFICIO_E': kMonaCategoryEdificios,
  'EDIFICIO_F': kMonaCategoryEdificios,
  'EDIFICIO_G': kMonaCategoryEdificios,
  'EDIFICIO_H': kMonaCategoryEdificios,
  'EDIFICIO_I': kMonaCategoryEdificios,
  'TOUR_CAMPUS': kMonaCategoryEdificios,
  'ZEN_MASTER': kMonaCategoryEstiloDeVida,
  'ATLETA_PATIO': kMonaCategoryEstiloDeVida,
  'MARATON_UNIVERSITARIA': kMonaCategoryEstiloDeVida,
  'NOCTAMBULO_ACADEMICO': kMonaCategoryEstiloDeVida,
  'AMANECER_PRODUCTIVO': kMonaCategoryEstiloDeVida,
  'ASISTENTE_VIP': kMonaCategoryEventos,
  'INVITADO_ESPECIAL': kMonaCategoryEventos,
  'CONQUISTADOR_CAMPUS': kMonaCategoryLegendarias,
  'LEYENDA_CAMPUS': kMonaCategoryLegendarias,
  'NETWORKING_50': kMonaCategoryLegendarias,
  'EMBAJADOR_CAMPUS': kMonaCategoryLegendarias,
};

/// Códigos → archivo en assets/monas (snake_case, sin espacios: los
/// espacios en nombres de asset rompen la carga en Flutter Web por
/// doble URL-encoding).
const Map<String, String> _codeToImage = {
  'PRIMER_CONTACTO': 'primer_contacto.png',
  'NETWORKING_5': 'networking_5.png',
  'NETWORKING_10': 'networking_10.png',
  'NETWORKING_25': 'networking_25.png',
  'NETWORKING_50': 'networking_50.png',
  'INICIADOR_PARCHE': 'iniciador_de_parche.png',
  'CAPITAN_EQUIPO': 'capitan_de_equipo.png',
  'ORGANIZADOR_ELITE': 'organizador_de_elite.png',
  'PRIMER_MENSAJERO': 'primer_mensajero.png',
  'ANFITRION': 'anfitrion.png',
  'CONECTOR_VELOZ': 'conector_veloz.png',
  'EXPLORADOR_CAFETERIAS': 'explorador_de_cafeterias.png',
  'FAN_REGIO': 'fan_del_regio.png',
  'CLIENTE_FRECUENTE': 'cliente_frecuente.png',
  'RUTA_CAFE': 'ruta_del_cafe.png',
  'EDIFICIO_A': 'edificio_a.png',
  'EDIFICIO_B': 'edificio_b.png',
  'EDIFICIO_C': 'edificio_c.png',
  'EDIFICIO_D': 'edificio_d.png',
  'EDIFICIO_E': 'edificio_e.png',
  'EDIFICIO_F': 'edificio_f.png',
  'EDIFICIO_G': 'edificio_g.png',
  'EDIFICIO_H': 'edificio_h.png',
  'EDIFICIO_I': 'edificio_i.png',
  'TOUR_CAMPUS': 'tour_campus.png',
  'ZEN_MASTER': 'zen_master.png',
  'ATLETA_PATIO': 'atleta_de_patio.png',
  'MARATON_UNIVERSITARIA': 'maraton_universitaria.png',
  'NOCTAMBULO_ACADEMICO': 'noctambulo_academico.png',
  'AMANECER_PRODUCTIVO': 'amanecer_productivo.png',
  'ASISTENTE_VIP': 'asistente_vip.png',
  'INVITADO_ESPECIAL': 'invitado_especial.png',
  'CONQUISTADOR_CAMPUS': 'conquistador_del_campus.png',
  'LEYENDA_CAMPUS': 'leyenda_del_campus.png',
  'EMBAJADOR_CAMPUS': 'embajador_del_campus.png',
};

String _normalize(String value) => value
    .toUpperCase()
    .replaceAll('Á', 'A')
    .replaceAll('É', 'E')
    .replaceAll('Í', 'I')
    .replaceAll('Ó', 'O')
    .replaceAll('Ú', 'U');

/// Categoría de una mona: usa [Mona.category] si el backend lo envía,
/// si no la infiere de [Mona.code] por catálogo o por palabras clave.
String monaCategoryOf(Mona mona) {
  if (mona.category != null && mona.category!.isNotEmpty) {
    return _normalize(mona.category!);
  }
  final code = _normalize(mona.code);
  final exact = _codeToCategory[code];
  if (exact != null) return exact;
  if (code.contains('CAFE')) return kMonaCategoryCafeterias;
  if (code.contains('EDIFICIO') || code.contains('CAMPUS')) {
    return kMonaCategoryEdificios;
  }
  if (code.contains('ZEN') ||
      code.contains('ATLETA') ||
      code.contains('MARATON') ||
      code.contains('NOCTAMBULO') ||
      code.contains('AMANECER')) {
    return kMonaCategoryEstiloDeVida;
  }
  if (code.contains('EVENTO') ||
      code.contains('ASISTENTE') ||
      code.contains('INVITADO')) {
    return kMonaCategoryEventos;
  }
  if (mona.rarity != null && _normalize(mona.rarity!).contains('LEGEND')) {
    return kMonaCategoryLegendarias;
  }
  return kMonaCategoryNetworking;
}

/// Ruta del arte real de la mona en assets/monas, si existe en el
/// catálogo. `null` cuando el código no tiene imagen asociada (usar
/// ícono de respaldo en ese caso).
String? monaImageAsset(Mona mona) {
  final file = _codeToImage[_normalize(mona.code)];
  return file == null ? null : 'assets/monas/$file';
}

/// Gradiente metálico de 4 tonos (claro → medio → oscuro → reflejo) por
/// categoría — simula el brillo de una medalla/pin metálico.
List<Color> monaCategoryMetallic(String category) => switch (category) {
  kMonaCategoryCafeterias => const [
    Color(0xFFFCE3C6),
    Color(0xFFCE8A4E),
    Color(0xFF7A431A),
    Color(0xFFF2B98A),
  ],
  kMonaCategoryEdificios => const [
    Color(0xFFF2F4F7),
    Color(0xFFB9C2CC),
    Color(0xFF5B6673),
    Color(0xFFE3E8ED),
  ],
  kMonaCategoryEstiloDeVida => const [
    Color(0xFFDFFFEA),
    Color(0xFF34D399),
    Color(0xFF0F7A55),
    Color(0xFFA8F0C6),
  ],
  kMonaCategoryEventos => const [
    Color(0xFFFFE6EA),
    Color(0xFFE59AAE),
    Color(0xFF9C4D63),
    Color(0xFFFAC7D2),
  ],
  kMonaCategoryLegendarias => const [
    Color(0xFFFFF3D0),
    Color(0xFFFFD166),
    Color(0xFFB8860B),
    Color(0xFFFFE9A8),
  ],
  _ => const [
    // NETWORKING (cromo azulado) — también fallback por defecto.
    Color(0xFFEAF6FF),
    Color(0xFF7FD1FF),
    Color(0xFF0B72B9),
    Color(0xFFBEEBFF),
  ],
};

/// Icono representativo de cada categoría.
IconData monaCategoryIcon(String category) => switch (category) {
  kMonaCategoryCafeterias => Icons.coffee_rounded,
  kMonaCategoryEdificios => Icons.apartment_rounded,
  kMonaCategoryEstiloDeVida => Icons.self_improvement_rounded,
  kMonaCategoryEventos => Icons.confirmation_number_rounded,
  kMonaCategoryLegendarias => Icons.workspace_premium_rounded,
  _ => Icons.diversity_3_rounded,
};

/// Gradiente metálico por rareza (135°, igual al CSS de referencia):
/// Común=Hierro, Poco Común=Bronce, Raro=Plata, Épico=Amatista metálica,
/// Legendario=Oro puro. El brillo lo da el propio degradado — sin
/// animación de shine encima.
List<Color> monaRarityGradient(String? rarity) {
  final r = rarity == null ? '' : _normalize(rarity);
  if (r.contains('LEGEND')) {
    return const [
      Color(0xFFBF953F),
      Color(0xFFFCF6BA),
      Color(0xFFB38728),
      Color(0xFFFBF5B7),
      Color(0xFFAA771C),
    ];
  }
  if (r.contains('EPIC')) {
    return const [Color(0xFF61045F), Color(0xFFAA77BC), Color(0xFF330033)];
  }
  if (r.startsWith('RAR')) {
    return const [Color(0xFFBDC3C7), Color(0xFFFFFFFF), Color(0xFF9EA7AA)];
  }
  if (r.contains('POCO') || r.startsWith('UNCOMMON')) {
    return const [Color(0xFF804A00), Color(0xFFCAA066), Color(0xFF613800)];
  }
  return const [
    Color(0xFF757F9A),
    Color(0xFFD7DDE8),
    Color(0xFF757F9A),
  ]; // Hierro — COMMON / COMUN
}

/// Tono único de acento derivado de la rareza — para bordes, glow y
/// elementos que no admiten degradado (barra de progreso, sombra).
Color monaRarityColor(String? rarity) {
  final r = rarity == null ? '' : _normalize(rarity);
  if (r.contains('LEGEND')) return const Color(0xFFBF953F); // oro
  if (r.contains('EPIC')) return const Color(0xFFAA77BC); // amatista
  if (r.startsWith('RAR')) return const Color(0xFF9EA7AA); // plata
  if (r.contains('POCO') || r.startsWith('UNCOMMON')) {
    return const Color(0xFFCAA066); // bronce
  }
  return const Color(0xFF757F9A); // hierro — COMMON / COMUN
}

/// Etiqueta corta en español para el chip de rareza.
String monaRarityLabel(String? rarity) {
  final r = rarity == null ? '' : _normalize(rarity);
  if (r.contains('LEGEND')) return 'LEGENDARIO';
  if (r.contains('EPIC')) return 'ÉPICO';
  if (r.startsWith('RAR')) return 'RARO';
  if (r.contains('POCO') || r.startsWith('UNCOMMON')) return 'POCO COMÚN';
  if (r.isEmpty) return '';
  return 'COMÚN';
}
