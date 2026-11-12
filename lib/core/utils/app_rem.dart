/// Extensión para manejar unidades relativas REM en Flutter.
/// Basado en el estándar de diseño donde 1 rem equivale a 16 px base.
extension RemExtension on num {
  /// Convierte rems a píxeles en pantalla: 1.0.rem = 16.0 px
  double get rem => toDouble() * 16.0;
}

