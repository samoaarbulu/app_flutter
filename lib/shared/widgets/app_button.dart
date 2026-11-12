import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_rem.dart';

/// Variantes de estilo para los botones del Design System.
enum AppButtonVariant {
  /// Botón principal con fondo oscuro (#262626) y texto blanco.
  primary,

  /// Botón secundario con superficie gris suave (#F5F5F7) y texto oscuro.
  secondary,

  /// Botón con fondo blanco/transparente y borde sutil (#E5E5EA).
  outline,

  /// Botón plano sin fondo ni borde, estilo texto interactivo.
  text,
}

/// Botón global reutilizable del Design System (Creds).
///
/// Centraliza todos los estilos visuales (altura de 56px, bordes de 16px,
/// tipografía y colores según variante).
///
/// Soporta iconos a la izquierda, espaciado parametrizable y estado de carga (`isLoading`).
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double iconSpacing;
  final double? width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;

  // Parámetros de anulación opcionales para casos excepcionales
  final Color? customBackgroundColor;
  final Color? customTextColor;
  final BorderSide? customBorderSide;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.iconSpacing = 12.0,
    this.width,
    this.height = 56.0,
    this.borderRadius = 16.0,
    this.textStyle,
    this.customBackgroundColor,
    this.customTextColor,
    this.customBorderSide,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Resolución de color de fondo según la variante
    final backgroundColor = customBackgroundColor ??
        switch (variant) {
          AppButtonVariant.primary => AppColors.primaryAction,
          AppButtonVariant.secondary => AppColors.inputSurface,
          AppButtonVariant.outline => Colors.white,
          AppButtonVariant.text => Colors.transparent,
        };

    // 2. Resolución de color de texto según la variante
    final textColor = customTextColor ??
        switch (variant) {
          AppButtonVariant.primary => AppColors.onPrimary,
          AppButtonVariant.secondary => AppColors.textPrimary,
          AppButtonVariant.outline => AppColors.textPrimary,
          AppButtonVariant.text => AppColors.textPrimary,
        };

    // 3. Resolución de borde según la variante (borde nítido de 1px en outline)
    final borderSide = customBorderSide ??
        switch (variant) {
          AppButtonVariant.outline =>
            const BorderSide(color: Color(0xFFE5E5EA), width: 1.0),
          _ => BorderSide.none,
        };

    final isInteractive = onPressed != null && !isLoading;
    final effectiveTextStyle = (textStyle ?? AppTypography.button).copyWith(
      color: textColor,
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          surfaceTintColor: Colors.transparent,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
          disabledForegroundColor: textColor.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderSide,
          ),
          padding: EdgeInsets.symmetric(horizontal: 1.25.rem),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: iconSpacing),
                  ],
                  Text(
                    text,
                    style: effectiveTextStyle,
                  ),
                ],
              ),
      ),
    );
  }
}
