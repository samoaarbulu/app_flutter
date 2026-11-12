import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_rem.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'verify_email_screen.dart';

/// Pantalla de Creación de Cuenta con Correo Electrónico ("Create your account").
///
/// Réplica exacta del diseño oficial de Figma:
/// - **Top Bar:** Botón atrás y título centrado ("ACCOUNT").
/// - **Encabezado:** Título ("Create your account") y mensaje explicativo sobre el código.
/// - **Formulario:**
///   - Campo "Email address" con icono de correo.
///   - Campo "Create a password" con alternancia de visibilidad y texto de validación.
///   - Texto legal ("You agree to your Terms of Service and Privacy Policy.").
/// - **Acción inferior:** Botón principal "Send code" (#262626).
class CreateAccountScreen extends StatefulWidget {
  final ValueChanged<String>? onSendCode;

  const CreateAccountScreen({
    super.key,
    this.onSendCode,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // -------------------------------------------------------------
  // 1. CONTROLADORES Y ESTADO (<script setup>)
  // -------------------------------------------------------------
  final TextEditingController _emailController = TextEditingController(
    text: 'ana.torres@correo.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'password123',
  );

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppFeedback.showError(context, 'Por favor ingresa un correo válido');
      return;
    }

    setState(() => _isLoading = true);

    // Simulación de envío de código y navegación
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.onSendCode != null) {
          widget.onSendCode!(email);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(email: email),
            ),
          );
        }
      }
    });
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

  /// Barra superior con botón de retorno y título "ACCOUNT"
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textPrimary,
          size: 24,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'ACCOUNT',
        style: GoogleFonts.poppins(
          fontSize: 0.8125.rem, // 13 px
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.textPrimary,
        ),
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
        // 1. Campo de Email con constructor especializado
        AppTextField.email(
          controller: _emailController,
          hintText: 'ana.torres@correo.com',
        ),

        SizedBox(height: 1.25.rem), // 20 px

        // 2. Campo de Contraseña con helperText y visibilidad automática
        AppTextField.password(
          controller: _passwordController,
          helperText: 'Use 8 or more characters, a letter and a number.',
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

  /// Botón principal "Send code"
  Widget _buildFooterAction() {
    return AppButton(
      text: 'Send code',
      variant: AppButtonVariant.primary,
      isLoading: _isLoading,
      onPressed: _handleSendCode,
    );
  }
}

