import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_rem.dart';
import 'app_colors.dart';

/// Tipografía dinámica del Design System (Creds).
///
/// Implementado con getters dinámicos para garantizar compatibilidad total
/// con Hot Reload y resolución en tiempo de ejecución de Google Fonts (Poppins).
abstract final class AppTypography {
  static const String fontFamily = 'Poppins';

  /// Marca superior ("Creds")
  static TextStyle get brandTitle => GoogleFonts.poppins(
    fontSize: 1.625.rem, // 26 px
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Título principal ("Find your place. Compare it your way.")
  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 2.0.rem, // 32 px
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.6,
  );

  /// Título mediano (24px Bold)
  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 1.5.rem, // 24 px
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  /// Subtítulo descriptivo ("Save the gyms you know...")
  static TextStyle get bodyDescription => GoogleFonts.poppins(
    fontSize: 1.0.rem, // 16 px
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  /// Texto de cuerpo estándar (16px Regular)
  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 1.0.rem, // 16 px
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Texto de botones de acción ("Get started")
  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 1.0.rem, // 16 px
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    letterSpacing: 0.2,
  );

  /// Texto de pie / enlaces de navegación ("Already have an account? Sign in")
  static TextStyle get linkNormal => GoogleFonts.poppins(
    fontSize: 0.875.rem, // 14 px
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get linkBold => GoogleFonts.poppins(
    fontSize: 0.875.rem, // 14 px
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Campos de entrada (Inputs)
  static TextStyle get input => GoogleFonts.poppins(
    fontSize: 1.0.rem,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Placeholder en inputs
  static TextStyle get inputHint => GoogleFonts.poppins(
    fontSize: 1.0.rem,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Etiquetas auxiliares / captions
  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 0.75.rem, // 12 px
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
