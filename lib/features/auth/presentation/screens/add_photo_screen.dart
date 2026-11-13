import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_rem.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_link_button.dart';
import '../../services/auth_service.dart';
import 'setup_profile_screen.dart';

/// Pantalla de Selección de Foto de Perfil ("Add your photo").
///
/// Réplica exacta del diseño oficial de Figma:
/// - **Top Bar:** Botón atrás y título centrado ("PROFILE").
/// - **Encabezado:** Título ("Add your photo") y descripción ("Lorem ipsum dolor") con [AppHeader].
/// - **Selector de Foto Central:**
///   - Si el usuario se autenticó con Google (o ya posee foto), se muestra su imagen real
///     mediante `Image.network` con badge de cámara para edición.
///   - Si no posee foto, muestra el avatar circular con icono de cámara por defecto.
/// - **Acciones al pie:** Botón principal ("Save and continue") y enlace secundario ("Not now").
class AddPhotoScreen extends StatefulWidget {
  final String? initialPhotoUrl;
  final VoidCallback? onSaveAndContinue;
  final VoidCallback? onSkip;

  const AddPhotoScreen({
    super.key,
    this.initialPhotoUrl,
    this.onSaveAndContinue,
    this.onSkip,
  });

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  late String? _photoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Recupera la foto provista o la foto oficial de la cuenta de Google
    _photoUrl =
        widget.initialPhotoUrl ?? AuthService.instance.currentUser?.photoURL;
  }

  void _handleSaveAndContinue() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.onSaveAndContinue != null) {
          widget.onSaveAndContinue!();
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SetupProfileScreen(),
            ),
          );
        }
      }
    });
  }

  void _handleSkip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SetupProfileScreen(),
        ),
      );
    }
  }

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

                      // 1. Encabezado principal (reutilizando AppHeader)
                      const AppHeader(
                        title: 'Add your photo',
                        description: 'Lorem ipsum dolor',
                      ),

                      // Espacio flexible superior hacia el selector central
                      const Spacer(flex: 2),

                      // 2. Selector circular de foto de perfil (con soporte de foto de Google)
                      _buildPhotoUploadSection(),

                      // Espacio flexible inferior hacia los botones
                      const Spacer(flex: 3),

                      // 3. Acciones inferiores (Save and continue + Not now)
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

  /// Barra superior con botón de retorno y título "PROFILE"
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
        'PROFILE',
        style: GoogleFonts.poppins(
          fontSize: 0.8125.rem, // 13 px
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Resuelve la URL optimizando la resolución y resolviendo CORS en Flutter Web
  String _resolvePhotoUrl(String url) {
    String targetUrl = url;
    if (targetUrl.contains('=s96-c')) {
      targetUrl = targetUrl.replaceAll('=s96-c', '=s400-c');
    }

    if (kIsWeb) {
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(targetUrl)}';
    }
    return targetUrl;
  }

  /// Bloque visual central con avatar circular e indicaciones
  Widget _buildPhotoUploadSection() {
    final hasPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar circular táctil
          GestureDetector(
            onTap: () {
              AppFeedback.show(
                context,
                'Selector de galería / cámara próximamente',
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 10.5.rem, // ~168 px
                  height: 10.5.rem, // ~168 px
                  decoration: BoxDecoration(
                    color: AppColors.badgeSurface,
                    shape: BoxShape.circle,
                    border: hasPhoto
                        ? Border.all(color: AppColors.border, width: 2.0)
                        : null,
                  ),
                  child: hasPhoto
                      ? ClipOval(
                          child: Image.network(
                            _resolvePhotoUrl(_photoUrl!),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.primaryAction,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: AppColors.iconSecondary,
                                size: 32,
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: AppColors.iconSecondary,
                            size: 32,
                          ),
                        ),
                ),
                // Badge de cámara flotante si ya tiene foto cargada
                if (hasPhoto)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAction,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 1.25.rem), // 20 px

          // Título debajo de la foto
          Text(
            hasPhoto ? 'Your profile photo' : 'Upload your profile photo',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 1.0625.rem, // 17 px
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 0.375.rem), // 6 px

          // Subtítulo descriptivo
          Text(
            hasPhoto
                ? 'Imported from Google · You can change it'
                : 'Optional · You can change it later',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 0.875.rem, // 14 px
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Botón principal "Save and continue" y enlace "Not now"
  Widget _buildFooterActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Acción principal: Botón global AppButton
        AppButton(
          text: 'Save and continue',
          variant: AppButtonVariant.primary,
          isLoading: _isLoading,
          onPressed: _handleSaveAndContinue,
        ),

        SizedBox(height: 0.5.rem),

        // Enlace secundario "Not now" estandarizado
        AppLinkButton(
          text: 'Not now',
          onPressed: _handleSkip,
        ),
      ],
    );
  }
}
