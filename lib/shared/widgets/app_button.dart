import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_rem.dart';

/// Botón principal reutilizable del Design System.
///
/// Altura estándar de 56px (3.5 rem), esquinas redondeadas tipo píldora (28px)
/// y compatibilidad con estado de carga e iconos.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final BorderSide? borderSide;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56.0,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? AppColors.primaryAction;
    final effectiveTextColor = textColor ?? AppColors.background;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBgColor,
          foregroundColor: effectiveTextColor,
          disabledBackgroundColor: effectiveBgColor.withValues(alpha: 0.5),
          disabledForegroundColor: effectiveTextColor.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0),
            side: borderSide ?? BorderSide.none,
          ),
          padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: 0.625.rem), // 10px
                  ],
                  Text(
                    text,
                    style: AppTypography.button.copyWith(
                      color: effectiveTextColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

