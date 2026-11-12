import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Widget para renderizar subtítulos, categorías y etiquetas secundarias
/// con control automático de desbordamiento (overflow) y color lila atenuado.
class AppTagsText extends StatelessWidget {
  final List<String> tags;
  final String separator;
  final int maxLines;
  final TextOverflow overflow;
  final TextStyle? style;
  final TextAlign textAlign;

  const AppTagsText({
    super.key,
    required this.tags,
    this.separator = ' • ',
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.style,
    this.textAlign = TextAlign.start,
  });

  /// Constructor de conveniencia para un único texto/etiqueta
  factory AppTagsText.single(
    String tag, {
    Key? key,
    int maxLines = 1,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextStyle? style,
    TextAlign textAlign = TextAlign.start,
  }) {
    return AppTagsText(
      key: key,
      tags: [tag],
      maxLines: maxLines,
      overflow: overflow,
      style: style,
      textAlign: textAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    final combinedText = tags.join(separator);
    final effectiveStyle = style ??
        AppTypography.caption.copyWith(
          color: AppColors.textMuted,
        );

    return Text(
      combinedText,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: effectiveStyle,
    );
  }
}

