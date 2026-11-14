import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_rem.dart';

/// Campo de entrada de texto reutilizable y modular del Design System (Creds).
///
/// Integra de forma cohesiva:
/// - **Etiqueta superior (`label`):** En negrita (Poppins 15px w700), alineada sobre el campo.
/// - **Caja de entrada estilizada:** Fondo `#F9F9FB`, bordes suaves de 16px (#E5E5EA) y foco nítido (#262626).
/// - **Validación reactiva al perder el foco (`validateOnFocusLoss` / `focusLossValidator` / `isEmail`):**
///   Valida automáticamente al salir del campo (blur), colorea el borde en `AppColors.error`
///   y muestra el mensaje de error con icono descriptivo, limpiándose automáticamente al corregir el valor.
/// - **Soporte de Prefijos y Filtros:** `prefix`, `prefixText`, `inputFormatters` para números de teléfono, nombres de usuario, etc.
/// - **Mensaje de ayuda opcional (`helperText`):** En la base con color atenuado (Poppins 13px w400).
/// - **Constructores nombrados de conveniencia:**
///   - `AppTextField.email(...)`: Preconfigura teclado de correo, icono de sobre y validación automática al desenfocar.
///   - `AppTextField.password(...)`: Preconfigura ocultación y alternancia de visibilidad con icono de ojo.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefix;
  final String? prefixText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool obscureText;
  final bool isEmail;
  final bool validateOnFocusLoss;
  final String? emailErrorMessage;
  final String? Function(String?)? focusLossValidator;
  final List<TextInputFormatter>? inputFormatters;
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
    this.errorText,
    this.prefix,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.obscureText = false,
    this.isEmail = false,
    this.validateOnFocusLoss = false,
    this.emailErrorMessage,
    this.focusLossValidator,
    this.inputFormatters,
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
    this.errorText,
    this.prefix,
    this.prefixText,
    this.prefixIcon,
    Widget? suffixIcon,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.autofocus = false,
    this.readOnly = false,
    this.isEmail = true,
    this.validateOnFocusLoss = true,
    this.emailErrorMessage,
    this.focusLossValidator,
    this.inputFormatters,
  })  : suffixIcon = suffixIcon ??
            const Icon(
              Icons.mail_outline_rounded,
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
    this.errorText,
    this.prefix,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.autofocus = false,
    this.readOnly = false,
    this.validateOnFocusLoss = false,
    this.emailErrorMessage,
    this.focusLossValidator,
    this.inputFormatters,
  })  : isPassword = true,
        obscureText = true,
        isEmail = false,
        keyboardType = TextInputType.visiblePassword;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  TextEditingController? _internalController;
  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  bool _isFocused = false;
  late bool _obscureText;
  String? _localErrorText;

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword ? true : widget.obscureText;
    _isFocused = widget.autofocus || _effectiveFocusNode.hasFocus;
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
    _internalController?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    final hasFocus = _effectiveFocusNode.hasFocus;

    // Detectamos pérdida de foco (blur)
    if (_isFocused && !hasFocus) {
      if (widget.validateOnFocusLoss ||
          widget.isEmail ||
          widget.focusLossValidator != null) {
        final error = _runFocusLossValidation();
        setState(() {
          _localErrorText = error;
          _isFocused = false;
        });
        return;
      }
    }

    setState(() {
      _isFocused = hasFocus;
    });
  }

  String? _runFocusLossValidation() {
    final text = _effectiveController.text;
    if (widget.focusLossValidator != null) {
      return widget.focusLossValidator!(text);
    }
    if (widget.isEmail) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        return widget.emailErrorMessage ?? 'Please enter your email address';
      }
      if (!_emailRegExp.hasMatch(trimmed)) {
        return widget.emailErrorMessage ?? 'Please enter a valid email address';
      }
      return null;
    }
    if (widget.validator != null) {
      return widget.validator!(text);
    }
    return null;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveError = widget.errorText ?? _localErrorText;
    final hasError = effectiveError != null;

    Widget? effectiveSuffix = widget.suffixIcon;

    if (widget.isPassword && effectiveSuffix == null) {
      effectiveSuffix = IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: hasError
              ? AppColors.error
              : (_isFocused ? AppColors.primaryAction : AppColors.textMuted),
          size: 22,
        ),
        onPressed: _togglePasswordVisibility,
        splashRadius: 20,
      );
    }

    final Color iconColor = hasError
        ? AppColors.error
        : (_isFocused ? AppColors.primaryAction : AppColors.iconSecondary);

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
              color: hasError
                  ? AppColors.error
                  : (_isFocused
                      ? AppColors.primaryAction
                      : const Color(0xFFE5E5EA)),
              width: (_isFocused || hasError) ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.prefix != null)
                Padding(
                  padding: EdgeInsets.only(left: 1.0.rem),
                  child: widget.prefix!,
                ),
              Expanded(
                child: TextFormField(
                  controller: _effectiveController,
                  focusNode: _effectiveFocusNode,
                  obscureText: _obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  onChanged: (value) {
                    if (_localErrorText != null ||
                        widget.focusLossValidator != null) {
                      final error = _runFocusLossValidation();
                      if (_localErrorText != null) {
                        setState(() {
                          _localErrorText = error;
                        });
                      }
                    }
                    widget.onChanged?.call(value);
                  },
                  onFieldSubmitted: widget.onFieldSubmitted,
                  validator: widget.validator,
                  autofocus: widget.autofocus,
                  readOnly: widget.readOnly,
                  style: AppTypography.input.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor:
                      hasError ? AppColors.error : AppColors.primaryAction,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: AppTypography.inputHint.copyWith(
                      color: AppColors.textMuted,
                    ),
                    prefixText: widget.prefixText,
                    prefixStyle: widget.prefixText != null
                        ? AppTypography.input.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          )
                        : null,
                    prefixIcon: widget.prefixIcon != null
                        ? IconTheme(
                            data: IconThemeData(
                              color: iconColor,
                              size: 22,
                            ),
                            child: widget.prefixIcon!,
                          )
                        : null,
                    suffixIcon: effectiveSuffix != null
                        ? IconTheme(
                            data: IconThemeData(
                              color: iconColor,
                              size: 22,
                            ),
                            child: effectiveSuffix,
                          )
                        : null,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.prefix != null ? 0.0 : 1.0.rem,
                      vertical: 1.0.rem, // 56 px de altura visual
                    ).copyWith(
                      right: 1.0.rem,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Mensaje de error o ayuda inferior
        if (effectiveError != null) ...[
          SizedBox(height: 0.375.rem), // 6 px
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 16,
              ),
              SizedBox(width: 0.375.rem), // 6 px
              Expanded(
                child: Text(
                  effectiveError,
                  style: GoogleFonts.poppins(
                    fontSize: 0.8125.rem, // 13 px
                    fontWeight: FontWeight.w400,
                    color: AppColors.error,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
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
