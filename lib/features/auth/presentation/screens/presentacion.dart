import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_rem.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_link_text.dart';
import 'auth_landing.dart';

/// Pantalla de Presentación / Bienvenida con video de fondo (01 - Bienvenida).
///
/// Integra el video de fondo en bucle `assets/video/fondo_presentacion.mp4`
/// manteniendo la estructura visual fiel del diseño de Figma:
/// - **Fondo:** Video en bucle (muted, BoxFit.cover) con degradado para legibilidad.
/// - **Identidad:** Marca ("Creds") superior.
/// - **Espacio central:** Visualización fluida del video.
/// - **Encabezado:** Título ("Find your place.\nCompare it your way.") y subtítulo.
/// - **Continuación / Acceso:** Botón "Get started" y enlace "Already have an account? Sign in".
class PresentationScreen extends StatefulWidget {
  final VoidCallback? onGetStarted;
  final VoidCallback? onSignIn;

  /// Si es `true` (por defecto), muestra el título de marca ("Creds") en la parte superior.
  /// Si es `false`, lo oculta.
  final bool showBrandTitle;

  const PresentationScreen({
    super.key,
    this.onGetStarted,
    this.onSignIn,
    this.showBrandTitle = false, //true para mostrar logo por etxto
  });

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/video/fondo_presentacion.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _videoController!.initialize();
      await _videoController!.setVolume(
        0.0,
      ); // Silenciado esencial para el Autoplay Policy del navegador
      await _videoController!.setLooping(true);
      await _videoController!.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error al inicializar video de fondo: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _videoController?.play();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _videoController?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // -------------------------------------------------------------
          // 1. VIDEO DE FONDO Y CAPA DEGRADADA
          // -------------------------------------------------------------
          _buildVideoBackground(),
          _buildGradientOverlay(),

          // -------------------------------------------------------------
          // 2. CONTENIDO PRINCIPAL (FIGMA)
          // -------------------------------------------------------------
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.5.rem), // 24 px
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.showBrandTitle) ...[
                    SizedBox(height: 1.0.rem),
                    // Identidad (Marca)
                    _buildIdentidad(),
                  ],

                  // Espacio central para apreciar el video de fondo
                  const Spacer(),

                  // Encabezado (Título y Texto de apoyo)
                  _buildEncabezado(),

                  SizedBox(height: 2.25.rem), // 36 px
                  // Continuación / Acceso (Acción principal y Texto de apoyo)
                  _buildContinuacionAcceso(context),

                  SizedBox(height: 1.0.rem),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Capa de video escalada con BoxFit.cover
  Widget _buildVideoBackground() {
    if (_videoController == null || !_isVideoInitialized) {
      return const ColoredBox(color: AppColors.background);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  /// Degradado sutil que garantiza contraste óptimo para los textos
  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.85),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 0.75, 1.0],
        ),
      ),
    );
  }

  /// Identidad de Marca ("Creds")
  Widget _buildIdentidad() {
    if (!widget.showBrandTitle) {
      return const SizedBox.shrink();
    }

    return Center(child: Text('Creds', style: AppTypography.brandTitle));
  }

  /// Encabezado con título principal y texto de apoyo descriptivo usando AppHeader.centered
  Widget _buildEncabezado() {
    return const AppHeader.centered(
      title: 'Find your place.\nCompare it your way.',
      description: 'Save the gyms you know, compare your experience\nand discover your favorites.',
    );
  }

  /// Sección inferior de acceso y llamada a la acción
  Widget _buildContinuacionAcceso(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Acción principal: Botón global "Get started"
        AppButton(
          text: 'Get started',
          onPressed:
              widget.onGetStarted ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthLandingScreen()),
                );
              },
        ),

        SizedBox(height: 1.0.rem), // 16 px
        // Texto de apoyo: Enlace interactivo global "Already have an account? Sign in"
        AppLinkText(
          prefixText: 'Already have an account? ',
          actionText: 'Sign in',
          onTap:
              widget.onSignIn ??
              () => AppFeedback.show(context, 'Sign in presionado'),
        ),
      ],
    );
  }
}
