import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_link_button.dart';
import '../../../shared/widgets/app_otp_section.dart';
import '../../../core/services/creds_api_service.dart';
import '../../onboarding/navigation/onboarding_navigator.dart';
import '../../onboarding/screens/add_photo_screen.dart';

/// Pantalla de Verificación de Código ("Check your email").
///
/// Réplica exacta del diseño oficial de Figma:
/// - **Top Bar:** Botón atrás y título centrado ("ACCOUNT").
/// - **Icon Badge:** Contenedor redondeado con el icono de correo.
/// - **Encabezado:** "Check your email" y mensaje descriptivo ([AppHeader]).
/// - **Sección OTP completa:** [AppOtpSection] con etiqueta, casillas, temporizador y tarjeta informativa.
/// - **Acciones inferiores:** Botón "Verify email" y enlace "Change email address".
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String? devOtpCode;
  final ValueChanged<String>? onVerified;

  const VerifyEmailScreen({
    super.key,
    this.email = 'ana.torres@correo.com',
    this.devOtpCode,
    this.onVerified,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  // -------------------------------------------------------------
  // 1. ESTADO Y CONTROLADORES (<script setup>)
  // -------------------------------------------------------------
  String _enteredCode = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Nunca prellenar el OTP en pantalla (ni en desarrollo ni en producción).
    // El usuario siempre debe ingresar manualmente el código recibido en su correo.
  }

  Future<void> _handleVerify() async {
    if (_enteredCode.length < 6) {
      AppFeedback.showError(
        context,
        'Por favor completa el código de 6 dígitos',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await CredsApiService.instance.verifyOtp(
        email: widget.email,
        code: _enteredCode,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (widget.onVerified != null) {
        widget.onVerified!(_enteredCode);
      } else {
        await OnboardingNavigator.navigateFromProfile(
          context,
          authResponse.user,
          fallbackScreen: const AddPhotoScreen(),
        );
      }
    } on CredsApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (e.isNetworkOrOfflineError &&
          CredsApiService.instance.offlineFallbackEnabled) {
        debugPrint('⚠️ Backend offline en VerifyEmailScreen: ${e.message}');
        if (widget.onVerified != null) {
          widget.onVerified!(_enteredCode);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddPhotoScreen(),
            ),
          );
        }
        return;
      }

      AppFeedback.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.showError(context, 'Error al verificar código: $e');
    }
  }

  Future<void> _handleResendCode() async {
    try {
      final response = await CredsApiService.instance.resendOtp(
        email: widget.email,
      );
      if (response.devOtpCode != null && response.devOtpCode!.isNotEmpty) {
        debugPrint('🔐 CREDS Dev OTP reenviado: ${response.devOtpCode}');
      }
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        'Nuevo código enviado a ${widget.email}',
      );
    } on CredsApiException catch (e) {
      if (!mounted) return;
      if (e.isNetworkOrOfflineError &&
          CredsApiService.instance.offlineFallbackEnabled) {
        AppFeedback.show(context, 'Nuevo código enviado a ${widget.email}');
        return;
      }
      AppFeedback.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'No se pudo reenviar el código: $e');
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 1.0.rem),

                      // 1. Badge superior con icono de sobre
                      _buildEmailBadge(),

                      SizedBox(height: 1.25.rem), // 20 px
                      // 2. Encabezado principal (AppHeader global)
                      AppHeader(
                        title: 'Check your email',
                        description:
                            'We sent a 6-digit code to ${widget.email}.',
                      ),

                      SizedBox(height: 1.75.rem), // 28 px
                      // 3. Sección OTP completa (Componente global AppOtpSection)
                      AppOtpSection(
                        onChanged: (val) => _enteredCode = val,
                        onCompleted: (val) {
                          _enteredCode = val;
                          _handleVerify();
                        },
                        onResend: _handleResendCode,
                      ),

                      // Espacio flexible hacia la acción inferior
                      const Spacer(),

                      // 4. Botón principal y enlace inferior
                      _buildFooterActions(context),

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

  /// Badge / Contenedor del icono de email superior
  Widget _buildEmailBadge() {
    return Container(
      width: 3.5.rem, // 56 px
      height: 3.5.rem, // 56 px
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: const Center(
        child: Icon(
          Icons.mail_outline_rounded,
          color: AppColors.textPrimary,
          size: 28,
        ),
      ),
    );
  }

  /// Botón principal "Verify email" y enlace "Change email address"
  Widget _buildFooterActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          text: 'Verify email',
          variant: AppButtonVariant.primary,
          isLoading: _isLoading,
          onPressed: _handleVerify,
        ),
        SizedBox(height: 0.5.rem),
        AppLinkButton(
          text: 'Change email address',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
