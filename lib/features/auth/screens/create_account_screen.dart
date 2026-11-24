import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../core/services/creds_api_service.dart';
import 'verify_email_screen.dart';

/// Pantalla de Creación de Cuenta con Correo Electrónico ("Create your account").
///
/// **Reglas de validación y UX implementadas:**
/// - **Email address:** Formato de correo electrónico válido.
/// - **Create a password:** 8 o más caracteres, al menos una letra y un número.
/// - **Helper text dinámico:** El texto de ayuda ("Use 8 or more characters, a letter and a number.")
///   se oculta automáticamente cuando la contraseña cumple los requisitos para no confundir al usuario.
/// - **Feedback visual de error:** Borde en rojo (`AppColors.error`), icono y mensaje inferior
///   al perder el foco (blur) si alguno de los campos no cumple.
/// - **Botón dinámico:** "Send code" permanece inhabilitado hasta que ambos campos
///   cumplen los requisitos de validación.
class CreateAccountScreen extends StatefulWidget {
  final ValueChanged<String>? onSendCode;
  final String? initialEmail;
  final String? initialPassword;

  const CreateAccountScreen({
    super.key,
    this.onSendCode,
    this.initialEmail,
    this.initialPassword,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // -------------------------------------------------------------
  // 1. CONTROLADORES Y ESTADO (<script setup>)
  // -------------------------------------------------------------
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool _isLoading = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initialEmail ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.initialPassword ?? '',
    );
    _confirmPasswordController = TextEditingController(
      text: widget.initialPassword ?? '',
    );

    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
    _isButtonEnabled = _isFormValid;
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final valid = _isFormValid;
    setState(() {
      _isButtonEnabled = valid;
    });
  }

  // -------------------------------------------------------------
  // VALIDACIONES
  // -------------------------------------------------------------

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Please enter your email address';
    }
    if (!_emailRegExp.hasMatch(text)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Please enter a password';
    }
    if (text.length < 8) {
      return 'Use 8 or more characters, a letter and a number';
    }
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(text);
    final hasNumber = RegExp(r'[0-9]').hasMatch(text);

    if (!hasLetter || !hasNumber) {
      return 'Use 8 or more characters, a letter and a number';
    }

    return null;
  }

  bool get _isPasswordValid =>
      _validatePassword(_passwordController.text) == null;

  String? _validateConfirmPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Please confirm your password';
    }
    if (text != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool get _isConfirmPasswordValid =>
      _validateConfirmPassword(_confirmPasswordController.text) == null;

  String? get _confirmPasswordMismatchError {
    final confirmText = _confirmPasswordController.text;
    if (confirmText.isEmpty) {
      return null;
    }
    if (confirmText != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Helper text dinámico: se oculta cuando la contraseña ya cumple
  String? get _effectivePasswordHelperText {
    if (_isPasswordValid) {
      return null;
    }
    return 'Use 8 or more characters, a letter and a number.';
  }

  bool get _isFormValid =>
      _validateEmail(_emailController.text) == null &&
      _isPasswordValid &&
      _isConfirmPasswordValid;

  Future<void> _handleSendCode() async {
    if (!_isFormValid) {
      AppFeedback.showError(
        context,
        'Please check the form fields',
      );
      return;
    }

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      final response = await CredsApiService.instance.registerStart(
        email: email,
        password: _passwordController.text,
      );

      if (response.devOtpCode != null && response.devOtpCode!.isNotEmpty) {
        debugPrint('🔐 CREDS Dev OTP para $email: ${response.devOtpCode}');
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (widget.onSendCode != null) {
        widget.onSendCode!(email);
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(
              email: email,
              devOtpCode: response.devOtpCode,
            ),
          ),
        );
      }
    } on CredsApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (e.isNetworkOrOfflineError &&
          CredsApiService.instance.offlineFallbackEnabled) {
        debugPrint('⚠️ Backend offline en CreateAccountScreen: ${e.message}');
        if (widget.onSendCode != null) {
          widget.onSendCode!(email);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(email: email),
            ),
          );
        }
        return;
      }

      AppFeedback.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.showError(context, 'Could not send code: $e');
    }
  }

  // -------------------------------------------------------------
  // 2. VISTA PRINCIPAL (<template>)
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 1.5.rem), // 24 px
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 1.5.rem),

                      // Encabezado
                      _buildHeader(),

                      SizedBox(height: 1.75.rem), // 28 px

                      // Formulario de credenciales
                      _buildFormFields(),

                      SizedBox(height: 1.25.rem), // 20 px

                      // Disclaimer legal
                      _buildLegalDisclaimer(),

                      // Espacio flexible hacia la acción inferior
                      const Spacer(),

                      // Botón de acción principal al pie
                      _buildFooterAction(),

                      SizedBox(height: 1.0.rem),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. SUBCOMPONENTES MODULARES
  // -------------------------------------------------------------

  /// Barra superior con botón de retorno
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textPrimary,
          size: 24,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  /// Encabezado con título principal y explicación usando el componente global AppHeader
  Widget _buildHeader() {
    return const AppHeader(
      title: 'Create your account',
      description:
          'We\'ll send you a code to confirm this email address is yours.',
    );
  }

  /// Campos de entrada reutilizando AppTextField
  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Campo de Email con constructor especializado y validación al desenfocar
        AppTextField.email(
          controller: _emailController,
          hintText: 'ana.torres@correo.com',
          validateOnFocusLoss: true,
          focusLossValidator: _validateEmail,
        ),

        SizedBox(height: 1.25.rem), // 20 px

        // 2. Campo de Contraseña con helperText dinámico (se oculta al cumplir)
        AppTextField.password(
          controller: _passwordController,
          helperText: _effectivePasswordHelperText,
          textInputAction: TextInputAction.next,
          validateOnFocusLoss: true,
          focusLossValidator: _validatePassword,
        ),

        SizedBox(height: 1.25.rem), // 20 px

        // 3. Campo Confirm password (debe coincidir con la contraseña)
        AppTextField.password(
          controller: _confirmPasswordController,
          label: 'Confirm password',
          hintText: 'Confirm your password',
          errorText: _confirmPasswordMismatchError,
          textInputAction: TextInputAction.done,
          validateOnFocusLoss: true,
          focusLossValidator: _validateConfirmPassword,
          onFieldSubmitted: (_) {
            if (_isButtonEnabled) {
              _handleSendCode();
            }
          },
        ),
      ],
    );
  }

  /// Texto de términos legales y política de privacidad
  Widget _buildLegalDisclaimer() {
    return Text(
      'You agree to your Terms of Service and Privacy Policy.',
      style: GoogleFonts.poppins(
        fontSize: 0.875.rem, // 14 px
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    );
  }

  /// Botón principal "Send code" dinámico (inhabilitado si los campos no cumplen)
  Widget _buildFooterAction() {
    return AppButton(
      text: 'Send code',
      variant: AppButtonVariant.primary,
      isLoading: _isLoading,
      onPressed: _isButtonEnabled ? _handleSendCode : null,
    );
  }
}
