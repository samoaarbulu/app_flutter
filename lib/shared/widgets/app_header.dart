import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

/// Componente global de encabezado del Design System (Creds).
///
/// Soporta todas las combinaciones de forma limpia y declarativa:
/// - **Solo título:** `AppHeader(title: '...')` o `AppHeader.title('...')`
/// - **Solo descripción:** `AppHeader(description: '...')` o `AppHeader.description('...')`
/// - **Ambos:** `AppHeader(title: '...', description: '...')` (con espaciado automático)
/// - **Centrado:** `AppHeader.centered(title: '...', description: '...')`
///
/// También incluye los componentes atómicos directos [AppTitle] y [AppDescription].
class AppHeader extends StatelessWidget {
  /// Título principal opcional
  final String? title;

  /// Descripción secundaria opcional
  final String? description;

  /// Alineación del texto (por defecto a la izquierda)
  final TextAlign textAlign;

  /// Alineación del eje cruzado de la columna
  final CrossAxisAlignment crossAxisAlignment;

  /// Espacio vertical entre título y descripción (solo si ambos existen)
  final double spacing;

  /// Anulación opcional de estilo para el título
  final TextStyle? titleStyle;

  /// Anulación opcional de estilo para la descripción
  final TextStyle? descriptionStyle;

  const AppHeader({
    super.key,
    this.title,
    this.description,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 12.0,
    this.titleStyle,
    this.descriptionStyle,
  });

  /// Constructor con alineación centrada (ej. presentación / splash)
  const AppHeader.centered({
    super.key,
    this.title,
    this.description,
    this.spacing = 12.0,
    this.titleStyle,
    this.descriptionStyle,
  })  : textAlign = TextAlign.center,
        crossAxisAlignment = CrossAxisAlignment.center;

  /// Constructor exclusivo para mostrar solo Título
  const AppHeader.title(
    String this.title, {
    super.key,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.titleStyle,
  })  : description = null,
        spacing = 0.0,
        descriptionStyle = null;

  /// Constructor exclusivo para mostrar solo Descripción
  const AppHeader.description(
    String this.description, {
    super.key,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.descriptionStyle,
  })  : title = null,
        spacing = 0.0,
        titleStyle = null;

  @override
  Widget build(BuildContext context) {
    // Si no se pasa ninguno, no ocupa espacio
    if (title == null && description == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Título (si está presente)
        if (title != null)
          Text(
            title!,
            textAlign: textAlign,
            style: titleStyle ?? AppTypography.headlineLarge,
          ),

        // 2. Espaciador automático (SOLO si ambos existen)
        if (title != null && description != null)
          SizedBox(height: spacing),

        // 3. Descripción (si está presente)
        if (description != null)
          Text(
            description!,
            textAlign: textAlign,
            style: descriptionStyle ?? AppTypography.bodyDescription,
          ),
      ],
    );
  }
}

/// Componente atómico directo para renderizar únicamente el Título principal
class AppTitle extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final TextStyle? style;

  const AppTitle(
    this.text, {
    super.key,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: style ?? AppTypography.headlineLarge,
    );
  }
}

/// Componente atómico directo para renderizar únicamente la Descripción
class AppDescription extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final TextStyle? style;

  const AppDescription(
    this.text, {
    super.key,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: style ?? AppTypography.bodyDescription,
    );
  }
}
