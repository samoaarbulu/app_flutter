import 'package:flutter/material.dart';

/// Paleta de colores oficial del Design System (Creds).
abstract final class AppColors {
  /// Fondo principal (#FFFFFF)
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  /// Color de acción primaria / botón principal (#262626)
  static const Color primaryAction = Color(0xFF262626);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Textos oficiales
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF8E8E93);

  /// Superficies y bordes
  static const Color inputSurface = Color(0xFFF5F5F7);
  static const Color badgeSurface = Color(0xFFEEEEF2);
  static const Color border = Color(0xFFE5E5EA);

  /// Iconos
  static const Color iconSecondary = Color(0xFF71717A);

  /// Estados y validación
  static const Color error = Color(0xFFFF3B30);
}
