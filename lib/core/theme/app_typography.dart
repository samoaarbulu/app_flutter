import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_rem.dart';
import 'app_colors.dart';

/// Tipografía dinámica del Design System.
///
/// REGLA CRÍTICA: Se emplean getters dinámicos en lugar de constantes estáticas
/// para garantizar compatibilidad con Hot Reload y resolución en runtime de GoogleFonts.
abstract final class AppTypography {
  static const String fontFamily = 'Poppins';

  /// Título grande (39px Bold)
  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 2.4375.rem, // 39 px
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
    height: 1.15,
  );

  /// Título mediano (28px Bold)
  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 1.75.rem, // 28 px
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
    height: 1.2,
  );

  /// Título pequeño / destacados (20.8px Bold)
  static TextStyle get headlineSmall => GoogleFonts.poppins(
    fontSize: 1.30.rem, // ~21 px
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
  );

  /// Subtítulo descriptivo / cuerpo estándar (16px Regular)
  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 1.0.rem, // 16 px
    fontWeight: FontWeight.w400,
    color: AppColors.textLight.withValues(alpha: 0.85),
    height: 1.4,
  );

  /// Texto de cuerpo estándar (16px Medium)
  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 1.0.rem, // 16 px
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  /// Texto de cuerpo grande (18px Regular)
  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 1.125.rem, // 18 px
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  /// Texto de botones de acción
  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 1.0.rem,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.onPrimary,
  );

  /// Texto de campos de entrada (Inputs)
  static TextStyle get input => GoogleFonts.poppins(
    fontSize: 1.0.rem,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  /// Texto de placeholder / sugerencia en inputs
  static TextStyle get inputHint => GoogleFonts.poppins(
    fontSize: 1.0.rem,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Etiquetas secundarias / tags / texto de ayuda
  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 0.75.rem, // 12 px
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}

