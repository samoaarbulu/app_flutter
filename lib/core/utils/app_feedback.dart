import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Servicio global para desplegar alertas y notificaciones (SnackBars)
/// centralizando estilos, duración y comportamiento en un solo lugar.
abstract final class AppFeedback {
  /// Despliega un mensaje informativo estándar flotante
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _displaySnackBar(
      context,
      message: message,
      backgroundColor: AppColors.primaryAction,
      textColor: AppColors.onPrimary,
      duration: duration,
    );
  }

  /// Despliega un mensaje de éxito con icono de confirmación
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _displaySnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFF1E7E34),
      textColor: Colors.white,
      icon: Icons.check_circle_rounded,
      duration: duration,
    );
  }

  /// Despliega un mensaje de error con icono de alerta
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _displaySnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFD32F2F),
      textColor: Colors.white,
      icon: Icons.error_rounded,
      duration: duration,
    );
  }

  static void _displaySnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
    required Duration duration,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: AppTypography.button.copyWith(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        elevation: 4,
      ),
    );
  }
}

