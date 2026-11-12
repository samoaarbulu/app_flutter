import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_rem.dart';

/// Botón de texto/enlace interactivo secundario del Design System (Creds).
///
/// Utilizado para acciones secundarias como:
/// - `"Not now"`
/// - `"Do this later"`
/// - `"Change email address"`
///
/// Garantiza un área táctil mínima recomendada para dispositivos móviles (mínimo 44px)
/// y centrado tipográfico estándar con [AppTypography.linkBold].
class AppLinkButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const AppLinkButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = textStyle ??
        AppTypography.linkBold.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 44.0,
          minWidth: 44.0,
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(vertical: 0.625.rem, horizontal: 1.0.rem),
          child: Center(
            widthFactor: 1.0,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: effectiveStyle,
            ),
          ),
        ),
      ),
    );
  }
}

