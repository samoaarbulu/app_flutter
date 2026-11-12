import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_rem.dart';

/// Componente global para enlaces y prompts de texto en línea.
///
/// Ideal para flujos de autenticación ("Already have an account? Sign in",
/// "Don't have an account? Sign up", "Terms & Conditions", etc.).
///
/// Centraliza la tipografía, padding accesible para toques táctiles y estilo de enlace.
class AppLinkText extends StatelessWidget {
  /// Texto previo al enlace (ej. "Already have an account? ")
  final String prefixText;

  /// Texto del enlace accionable (ej. "Sign in")
  final String actionText;

  /// Acción a ejecutar al tocar el enlace
  final VoidCallback? onTap;

  /// Estilo opcional para el texto previo (por defecto `AppTypography.linkNormal`)
  final TextStyle? prefixStyle;

  /// Estilo opcional para el texto de acción (por defecto `AppTypography.linkBold`)
  final TextStyle? actionStyle;

  /// Alineación del texto (por defecto centrada)
  final TextAlign textAlign;

  /// Padding interno para facilitar el toque táctil (hitbox accesible)
  final EdgeInsetsGeometry? padding;

  const AppLinkText({
    super.key,
    required this.prefixText,
    required this.actionText,
    this.onTap,
    this.prefixStyle,
    this.actionStyle,
    this.textAlign = TextAlign.center,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrefixStyle = prefixStyle ?? AppTypography.linkNormal;
    final effectiveActionStyle = actionStyle ?? AppTypography.linkBold;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: padding ?? EdgeInsets.symmetric(vertical: 0.5.rem),
        child: RichText(
          textAlign: textAlign,
          text: TextSpan(
            style: effectivePrefixStyle,
            children: [
              TextSpan(text: prefixText),
              TextSpan(
                text: actionText,
                style: effectiveActionStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

