import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Servicio global para desplegar alertas y notificaciones (SnackBars)
/// posicionadas en la zona superior (debajo del AppBar) para no tapar
/// los botones de acción inferiores.
abstract final class AppFeedback {
  /// Despliega un mensaje informativo estándar.
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2000),
    bool preferBottom = false,
  }) {
    _displaySnackBar(
      context,
      message: message,
      backgroundColor: AppColors.primaryAction,
      textColor: AppColors.onPrimary,
      duration: duration,
      preferBottom: preferBottom,
    );
  }

  /// Despliega un mensaje de éxito con icono de confirmación.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 2000),
    bool preferBottom = false,
  }) {
    _displaySnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFF1E7E34),
      textColor: Colors.white,
      icon: Icons.check_circle_rounded,
      duration: duration,
      preferBottom: preferBottom,
    );
  }

  /// Despliega un mensaje de error con icono de alerta.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3000),
    bool preferBottom = false,
  }) {
    _displaySnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFD32F2F),
      textColor: Colors.white,
      icon: Icons.error_rounded,
      duration: duration,
      preferBottom: preferBottom,
    );
  }

  static void _displaySnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
    required Duration duration,
    bool preferBottom = false,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    scaffoldMessenger.hideCurrentSnackBar();

    final hasFab =
        preferBottom || (Scaffold.maybeOf(context)?.hasFloatingActionButton ?? false);
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenHeight = mediaQuery?.size.height ?? 0;
    final topInset = mediaQuery?.padding.top ?? 0;
    final double bottomMargin = (!hasFab && screenHeight > 300)
        ? (screenHeight - topInset - 140).clamp(16.0, screenHeight)
        : 16.0;

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
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        elevation: 4,
      ),
    );
  }
}
