import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_rem.dart';
import 'presentacion.dart';

/// Pantalla de Preloading / Splash con animación de marca "3D Float".
///
/// Física y diseño:
/// - **Wordmark:** Texto `"creds"` en minúsculas, extra grueso (Poppins w900, 58px) en escala de grises.
/// - **Tagline:** `"Where your people go."` en gris suave con entrada progresiva.
/// - **Física 3D Float:** Levitación vertical fluida (±10px) con aceleración senoidal en GPU.
/// - **Sombra Física en el suelo:** Se expande, difumina y aclara cuando el texto se eleva,
///   y se contrae, enfoca y oscurece cuando desciende.
/// - **Transición:** Tras 2.6 segundos (o toque en pantalla), realiza un cross-fade suave
///   hacia [PresentationScreen].
class PreloadingScreen extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const PreloadingScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2600),
    this.onComplete,
  });

  @override
  State<PreloadingScreen> createState() => _PreloadingScreenState();
}

class _PreloadingScreenState extends State<PreloadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Controlador de levitación continua (2400ms por ciclo senoidal)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 2. Temporizador para transición automática a la pantalla de presentación
    _navigationTimer = Timer(widget.duration, _navigateToPresentation);
  }

  void _navigateToPresentation() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 550),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const PresentationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: _navigateToPresentation,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                final progress = _floatController.value;
                // Curva senoidal continua de elevación (±10px)
                final floatOffset = math.sin(progress * 2 * math.pi) * 10.0;
                // Factor relativo: 0.0 (punto más alto), 1.0 (punto más bajo)
                final heightFactor = (floatOffset + 10.0) / 20.0;

                // Fórmulas físicas de dispersión de sombra en el suelo
                final shadowWidth = 145.0 + ((1.0 - heightFactor) * 45.0);
                final shadowHeight = 12.0 + ((1.0 - heightFactor) * 5.0);
                final shadowOpacity = 0.08 + (heightFactor * 0.12);
                final shadowBlur = 10.0 + ((1.0 - heightFactor) * 14.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. Wordmark "creds" en levitación 3D
                    Transform.translate(
                      offset: Offset(0, floatOffset),
                      child: Text(
                        'creds',
                        style: GoogleFonts.poppins(
                          fontSize: 3.625.rem, // 58 px
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          height: 1.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    SizedBox(height: 1.75.rem), // 28 px

                    // 2. Sombra física reactiva en el suelo
                    Container(
                      width: shadowWidth,
                      height: shadowHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(shadowWidth / 2, shadowHeight / 2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: shadowOpacity),
                            blurRadius: shadowBlur,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 1.75.rem), // 28 px

                    // 3. Subtítulo / Tagline oficial de Creds
                    Text(
                      'Where your people go.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 1.0.rem, // 16 px
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

