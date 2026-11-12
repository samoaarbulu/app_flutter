import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_rem.dart';
import 'app_otp_input.dart';

/// Componente integral y modular para secciones de verificación con código OTP.
///
/// Encapsula en un único bloque visual:
/// 1. **Etiqueta superior:** ("Verification code").
/// 2. **Casillas numéricas:** [AppOtpInput] de 6 dígitos con auto-avance.
/// 3. **Fila de reenvío interactiva:** "¿Didn't get the code? Resend in 00:28" con temporizador vivo.
/// 4. **Tarjeta informativa opcional:** Aviso de expiración y bandeja de spam con icono (i).
class AppOtpSection extends StatefulWidget {
  /// Etiqueta superior del bloque
  final String label;

  /// Cantidad de casillas del código (por defecto 6)
  final int length;

  /// Valores iniciales opcionales para prellenar
  final List<String>? initialValues;

  /// Callback cada vez que cambia el código
  final ValueChanged<String>? onChanged;

  /// Callback al completar los 6 dígitos
  final ValueChanged<String>? onCompleted;

  /// Texto de pregunta de reenvío (por defecto "Didn't get the code?")
  final String resendPrompt;

  /// Segundos del temporizador de reenvío (por defecto 28)
  final int resendCountdownSeconds;

  /// Acción a ejecutar al pulsar "Resend code"
  final VoidCallback? onResend;

  /// Mensaje para la tarjeta informativa inferior (opcional)
  final String? infoMessage;

  const AppOtpSection({
    super.key,
    this.label = 'Verification code',
    this.length = 6,
    this.initialValues,
    this.onChanged,
    this.onCompleted,
    this.resendPrompt = 'Didn\'t get the code?',
    this.resendCountdownSeconds = 28,
    this.onResend,
    this.infoMessage =
        'The code expires in 10 minutes. Check your spam folder too.',
  });

  @override
  State<AppOtpSection> createState() => _AppOtpSectionState();
}

class _AppOtpSectionState extends State<AppOtpSection> {
  late int _secondsRemaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.resendCountdownSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() => _secondsRemaining--);
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResend() {
    if (_secondsRemaining > 0) return;
    widget.onResend?.call();
    setState(() {
      _secondsRemaining = widget.resendCountdownSeconds;
      _startCountdown();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerString =
        '00:${_secondsRemaining.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Etiqueta superior
        Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 0.9375.rem, // 15 px
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 0.875.rem), // 14 px

        // 2. Casillas numéricas OTP
        AppOtpInput(
          length: widget.length,
          initialValues: widget.initialValues,
          onChanged: widget.onChanged,
          onCompleted: widget.onCompleted,
        ),

        SizedBox(height: 0.875.rem), // 14 px

        // 3. Fila de reenvío con temporizador
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.resendPrompt,
              style: GoogleFonts.poppins(
                fontSize: 0.875.rem, // 14 px
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: _secondsRemaining == 0 ? _handleResend : null,
              behavior: HitTestBehavior.opaque,
              child: Text(
                _secondsRemaining > 0
                    ? 'Resend in $timerString'
                    : 'Resend code',
                style: GoogleFonts.poppins(
                  fontSize: 0.875.rem, // 14 px
                  fontWeight: FontWeight.w600,
                  color: _secondsRemaining > 0
                      ? AppColors.textPrimary
                      : AppColors.primaryAction,
                ),
              ),
            ),
          ],
        ),

        // 4. Tarjeta informativa inferior opcional
        if (widget.infoMessage != null) ...[
          SizedBox(height: 1.5.rem), // 24 px
          Container(
            padding: EdgeInsets.all(1.0.rem), // 16 px
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF71717A),
                  size: 20,
                ),
                SizedBox(width: 0.75.rem), // 12 px
                Expanded(
                  child: Text(
                    widget.infoMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 0.84375.rem, // 13.5 px
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

