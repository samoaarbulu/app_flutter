import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_rem.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_google_icon.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_link_text.dart';
import '../../services/auth_service.dart';
import 'add_photo_screen.dart';
import 'create_account_screen.dart';

/// Pantalla de Selección de Método de Autenticación ("Build your Creds").
///
/// Réplica exacta del diseño de Figma:
/// - **Top Bar:** Botón atrás y título centrado en mayúsculas ("ACCOUNT").
/// - **Encabezado:** Título alineado a la izquierda ("Build your Creds") y texto descriptivo.
/// - **Acciones:** 3 botones con borde (Google, Apple y Email) usando el componente global `AppButton`.
/// - **Autenticación con Google:** Integración nativa/web con `AuthService.instance.signInWithGoogle()`.
class AuthLandingScreen extends StatefulWidget {
  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onAppleSignIn;
  final VoidCallback? onEmailSignIn;
  final VoidCallback? onSignIn;

  const AuthLandingScreen({
    super.key,
    this.onGoogleSignIn,
    this.onAppleSignIn,
    this.onEmailSignIn,
    this.onSignIn,
  });

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (widget.onGoogleSignIn != null) {
      widget.onGoogleSignIn!();
      return;
    }

    setState(() => _isGoogleLoading = true);

    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (!mounted) return;

      if (credential != null && credential.user != null) {
        final userName = credential.user!.displayName ?? 'Usuario';
        AppFeedback.showSuccess(context, '¡Bienvenido $userName!');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AddPhotoScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        'Error al iniciar sesión con Google: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.5.rem), // 24 px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.5.rem),

              // -------------------------------------------------------------
              // 1. ENCABEZADO (Título y descripción)
              // -------------------------------------------------------------
              _buildHeader(),

              SizedBox(height: 2.5.rem), // 40 px

              // -------------------------------------------------------------
              // 2. OPCIONES DE AUTENTICACIÓN (Botones con borde e iconos)
              // -------------------------------------------------------------
              _buildAuthOptions(context),

              const Spacer(),

              // -------------------------------------------------------------
              // 3. ENLACE DE ACCESO (Already have an account? Sign in)
              // -------------------------------------------------------------
              Center(
                child: AppLinkText(
                  prefixText: 'Already have an account? ',
                  actionText: 'Sign in',
                  onTap: () {
                    if (widget.onSignIn != null) {
                      widget.onSignIn!();
                    } else {
                      AppFeedback.show(context, 'Pantalla de Sign in próximamente');
                    }
                  },
                ),
              ),

              SizedBox(height: 1.0.rem), // 16 px
            ],
          ),
        ),
      ),
    );
  }

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

  /// Encabezado alineado a la izquierda con el componente global AppHeader
  Widget _buildHeader() {
    return const AppHeader(
      title: 'Build your Creds',
      description:
          'Create an account to rank the places you try and\ndiscover what your people recommend.',
    );
  }

  /// Lista vertical de botones de autenticación
  Widget _buildAuthOptions(BuildContext context) {
    return Column(
      children: [
        // 1. Botón Google con llamada directa a AuthService
        AppButton(
          text: 'Continue with Google',
          variant: AppButtonVariant.outline,
          isLoading: _isGoogleLoading,
          icon: const AppGoogleIcon(size: 20),
          onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
        ),

        SizedBox(height: 1.0.rem), // 16 px

        // 2. Botón Apple
        AppButton(
          text: 'Continue with Apple',
          variant: AppButtonVariant.outline,
          icon: const Icon(Icons.apple, color: AppColors.textPrimary, size: 24),
          onPressed: widget.onAppleSignIn ??
              () => AppFeedback.show(context, 'Continue with Apple presionado'),
        ),

        SizedBox(height: 1.0.rem), // 16 px

        // 3. Botón Email (conduce al flujo de Create Account)
        AppButton(
          text: 'Continue with Email',
          variant: AppButtonVariant.outline,
          icon: const Icon(
            Icons.mail_outline_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: widget.onEmailSignIn ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateAccountScreen(),
                  ),
                );
              },
        ),
      ],
    );
  }
}
