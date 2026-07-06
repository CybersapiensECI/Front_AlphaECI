/// Breakpoints de layout. Decisiones SIEMPRE por ancho disponible
/// (LayoutBuilder / MediaQuery.sizeOf), nunca por tipo de dispositivo
/// ni orientación.
abstract final class Breakpoints {
  /// < 600: móvil (NavigationBar inferior, una columna).
  static const double tablet = 600;

  /// >= 1024: desktop (NavigationRail extendido, contenido con maxWidth).
  static const double desktop = 1024;

  /// Ancho máximo de contenido en pantallas grandes (formularios, listas).
  static const double contentMaxWidth = 720;
}
