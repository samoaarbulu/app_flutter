import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_rem.dart';

/// Campo de entrada de texto reutilizable del Design System.
///
/// Altura estándar de 56px, fondo contrastado `#624F82` (AppColors.inputSurface),
/// bordes redondeados y foco resaltado en tono lila.
///
/// Soporta inyección de FocusNode externo sin fugas de memoria (memory leaks).
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final bool readOnly;

  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.readOnly = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _effectiveFocusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: _isFocused
              ? AppColors.textMuted
              : AppColors.inputSurface.withValues(alpha: 0.8),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.textMuted.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _effectiveFocusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        validator: widget.validator,
        autofocus: widget.autofocus,
        readOnly: widget.readOnly,
        style: AppTypography.input,
        cursorColor: AppColors.primaryAction,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          hintStyle: AppTypography.inputHint,
          labelStyle: AppTypography.inputHint,
          prefixIcon: widget.prefixIcon != null
              ? IconTheme(
                  data: IconThemeData(
                    color: _isFocused
                        ? AppColors.primaryAction
                        : AppColors.textMuted,
                  ),
                  child: widget.prefixIcon!,
                )
              : null,
          suffixIcon: widget.suffixIcon != null
              ? IconTheme(
                  data: IconThemeData(
                    color: _isFocused
                        ? AppColors.primaryAction
                        : AppColors.textMuted,
                  ),
                  child: widget.suffixIcon!,
                )
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 1.0.rem,
            vertical: 1.0.rem,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }
}
