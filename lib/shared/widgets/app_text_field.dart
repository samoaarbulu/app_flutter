import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_rem.dart';

/// Campo de entrada de texto reutilizable y modular del Design System (Creds).
///
/// Integra de forma cohesiva:
/// - **Etiqueta superior (`label`):** En negrita (Poppins 15px w700), alineada sobre el campo.
/// - **Caja de entrada estilizada:** Fondo `#F9F9FB`, bordes suaves de 16px (#E5E5EA) y foco nítido (#262626).
/// - **Mensaje de ayuda opcional (`helperText`):** En la base con color atenuado (Poppins 13px w400).
/// - **Constructores nombrados de conveniencia:**
///   - `AppTextField.email(...)`: Preconfigura teclado de correo e icono de sobre.
///   - `AppTextField.password(...)`: Preconfigura ocultación y alternancia de visibilidad con icono de ojo.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final bool readOnly;

  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.autofocus = false,
    this.readOnly = false,
  });

  /// Constructor de conveniencia para campos de Correo Electrónico
  const AppTextField.email({
    super.key,
    this.controller,
    this.focusNode,
    this.label = 'Email address',
    this.hintText,
    this.helperText,
    this.prefixIcon,
    Widget? suffixIcon,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.autofocus = false,
    this.readOnly = false,
  })  : suffixIcon = suffixIcon ??
            const Icon(
              Icons.mail_outline_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
        isPassword = false,
        obscureText = false,
        keyboardType = TextInputType.emailAddress;

  /// Constructor de conveniencia para campos de Contraseña
  const AppTextField.password({
    super.key,
    this.controller,
    this.focusNode,
    this.label = 'Create a password',
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.autofocus = false,
    this.readOnly = false,
  })  : isPassword = true,
        obscureText = true,
        keyboardType = TextInputType.visiblePassword;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool _isFocused = false;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword ? true : widget.obscureText;
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _effectiveFocusNode.addListener(_onFocusChange);
    }
    if (widget.isPassword != oldWidget.isPassword ||
        widget.obscureText != oldWidget.obscureText) {
      _obscureText = widget.isPassword ? _obscureText : widget.obscureText;
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

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffix = widget.suffixIcon;

    if (widget.isPassword && effectiveSuffix == null) {
      effectiveSuffix = IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: _isFocused ? AppColors.textPrimary : AppColors.textMuted,
          size: 22,
        ),
        onPressed: _togglePasswordVisibility,
        splashRadius: 20,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Etiqueta superior en negrita
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.poppins(
              fontSize: 0.9375.rem, // 15 px
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 0.5.rem), // 8 px
        ],

        // 2. Caja de entrada interactiva
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9FB),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: _isFocused
                  ? AppColors.primaryAction
                  : const Color(0xFFE5E5EA),
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _effectiveFocusNode,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: widget.validator,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            style: AppTypography.input.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppColors.primaryAction,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTypography.inputHint.copyWith(
                color: AppColors.textMuted,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? IconTheme(
                      data: IconThemeData(
                        color: _isFocused
                            ? AppColors.primaryAction
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      child: widget.prefixIcon!,
                    )
                  : null,
              suffixIcon: effectiveSuffix != null
                  ? IconTheme(
                      data: IconThemeData(
                        color: _isFocused
                            ? AppColors.primaryAction
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      child: effectiveSuffix,
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 1.0.rem,
                vertical: 1.0.rem, // 56 px de altura visual
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),

        // 3. Mensaje de ayuda inferior opcional
        if (widget.helperText != null) ...[
          SizedBox(height: 0.375.rem), // 6 px
          Text(
            widget.helperText!,
            style: GoogleFonts.poppins(
              fontSize: 0.8125.rem, // 13 px
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
