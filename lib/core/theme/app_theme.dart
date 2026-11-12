import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Configuración centralizada de temas de la aplicación (Material 3).
abstract final class AppTheme {
  /// Tema oscuro oficial del proyecto
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.primaryAction,
        secondary: AppColors.textMuted,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.textLight,
      ),
      fontFamily: AppTypography.fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAction,
          foregroundColor: AppColors.background,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: AppTypography.button,
        ),
      ),
    );
  }
}

