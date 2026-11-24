import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/creds_api_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_link_button.dart';
import '../../auth/services/auth_service.dart';
import 'setup_profile_screen.dart';

/// Pantalla de Selección y Actualización de Foto de Perfil ("Add your photo").
///
/// **Mejores prácticas implementadas:**
/// - **Carga e Intercambio de Fotos:** Permite seleccionar desde la galería o capturar
///   desde la cámara reemplazando la foto por defecto o la importada desde Google.
/// - **Universalidad Multiplataforma:** Emplea [MediaService] y `Uint8List` (bytes en memoria),
///   garantizando soporte idéntico en Flutter Web, Android, iOS y Desktop sin fallos de `dart:io`.
/// - **Feedback Reactivo y Eliminación:** Permite eliminar la foto para volver al estado inicial
///   y ofrece feedback visual contextual con [AppFeedback].
/// - **Inyección de Dependencias:** Acepta [MediaService] inyectado para facilitar pruebas unitarias.
class AddPhotoScreen extends StatefulWidget {
  final String? initialPhotoUrl;
  final VoidCallback? onSaveAndContinue;
  final VoidCallback? onSkip;
  final MediaService? mediaService;
  final void Function(PickedImage? image)? onPhotoChanged;

  const AddPhotoScreen({
    super.key,
    this.initialPhotoUrl,
    this.onSaveAndContinue,
    this.onSkip,
    this.mediaService,
    this.onPhotoChanged,
  });

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  late final MediaService _mediaService;
  late String? _photoUrl;
  PickedImage? _customImage;
  bool _isRemoved = false;
  bool _isLoading = false;
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _mediaService = widget.mediaService ?? MediaService.instance;
    _customImage = AuthService.instance.customPhoto;
    _photoUrl = widget.initialPhotoUrl ??
        CredsApiService.instance.currentUser?.avatarUrl ??
        AuthService.instance.currentUser?.photoURL;
  }

  /// Indica si hay una imagen activa (personalizada o remota no eliminada)
  bool get _hasActivePhoto =>
      _customImage != null ||
      (!_isRemoved && _photoUrl != null && _photoUrl!.isNotEmpty);

  Future<void> _handleSaveAndContinue() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Persistir la foto en el servicio de autenticación en memoria
    if (_isRemoved) {
      AuthService.instance.setCustomPhoto(null);
    } else if (_customImage != null) {
      AuthService.instance.setCustomPhoto(_customImage);
    }

    if (widget.onSaveAndContinue != null) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onSaveAndContinue!();
      return;
    }

    if (CredsApiService.instance.hasSession) {
      try {
        if (_isRemoved) {
          await CredsApiService.instance.setupProfile(clearAvatar: true);
        } else if (_customImage != null) {
          final publicUrl =
              await CredsApiService.instance.uploadAvatarImage(_customImage!);
          await CredsApiService.instance.setupProfile(avatarUrl: publicUrl);
        } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
          await CredsApiService.instance.setupProfile(avatarUrl: _photoUrl);
        } else {
          await CredsApiService.instance.setupProfile(clearAvatar: true);
        }
      } on CredsApiException catch (e) {
        if (!mounted) return;
        if (!(e.isNetworkOrOfflineError &&
            CredsApiService.instance.offlineFallbackEnabled)) {
          setState(() => _isLoading = false);
          AppFeedback.showError(context, e.message);
          return;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppFeedback.showError(context, 'Could not save your photo: $e');
        return;
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SetupProfileScreen(),
      ),
    );
  }

  Future<void> _handleSkip() async {
    if (_isLoading) return;
    if (widget.onSkip != null) {
      widget.onSkip!();
      return;
    }

    if (CredsApiService.instance.hasSession) {
      setState(() => _isLoading = true);
      try {
        await CredsApiService.instance.setupProfile(clearAvatar: true);
      } on CredsApiException catch (e) {
        if (!mounted) return;
        if (!(e.isNetworkOrOfflineError &&
            CredsApiService.instance.offlineFallbackEnabled)) {
          setState(() => _isLoading = false);
          AppFeedback.showError(context, e.message);
          return;
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SetupProfileScreen(),
      ),
    );
  }

  /// Abre el modal de selección de origen (Cámara / Galería / Eliminar)
  void _showPhotoSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          padding: EdgeInsets.fromLTRB(
            1.5.rem,
            1.0.rem,
            1.5.rem,
            MediaQuery.of(bottomSheetContext).padding.bottom + 1.25.rem,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra de arrastre superior
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Título del bottom sheet
              Text(
                'Profile photo',
                style: GoogleFonts.poppins(
                  fontSize: 1.125.rem, // 18 px
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              // Opción: Tomar foto con la cámara
              _buildSourceOption(
                icon: Icons.photo_camera_outlined,
                title: 'Take photo',
                subtitle: 'Use your camera to take a new picture',
                onTap: () => _pickImage(ImageSource.camera),
              ),

              const SizedBox(height: 8),

              // Opción: Elegir de la galería
              _buildSourceOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from gallery',
                subtitle: 'Select a photo from your library',
                onTap: () => _pickImage(ImageSource.gallery),
              ),

              // Opción: Eliminar foto actual (solo si existe una activa)
              if (_hasActivePhoto) ...[
                const SizedBox(height: 8),
                const Divider(color: AppColors.border, height: 16),
                _buildSourceOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove current photo',
                  textColor: AppColors.error,
                  iconColor: AppColors.error,
                  onTap: _removePhoto,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Ejecuta la captura/selección mediante el MediaService
  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // Cierra el modal

    setState(() => _isImageLoading = true);

    try {
      final PickedImage? image = source == ImageSource.camera
          ? await _mediaService.pickImageFromCamera()
          : await _mediaService.pickImageFromGallery();

      if (!mounted) return;

      if (image != null) {
        setState(() {
          _customImage = image;
          _isRemoved = false;
        });
        widget.onPhotoChanged?.call(image);
        AppFeedback.showSuccess(context, 'Photo updated successfully');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'Could not access the image. Please verify device permissions.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImageLoading = false);
      }
    }
  }

  /// Elimina la foto y restablece el avatar al estado por defecto
  void _removePhoto() {
    Navigator.of(context).pop(); // Cierra el modal

    setState(() {
      _customImage = null;
      _isRemoved = true;
    });

    widget.onPhotoChanged?.call(null);
    AppFeedback.show(context, 'Profile photo removed');
  }

  /// Elemento interactivo de cada opción del modal
  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final effectiveIconColor = iconColor ?? AppColors.primaryAction;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 0.9375.rem, // 15 px
                      fontWeight: FontWeight.w600,
                      color: textColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 0.75.rem, // 12 px
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
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
                        description:
                            'Add a photo so your community can recognize you.',
                      ),

                      // Espacio flexible superior hacia el selector central
                      const Spacer(flex: 2),

                      // 2. Selector circular de foto de perfil con carga/reemplazo
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

  /// Renderiza el contenido interno del avatar según el estado actual
  Widget _buildAvatarContent() {
    if (_isImageLoading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primaryAction,
          ),
        ),
      );
    }

    // Prioridad 1: Imagen local recién seleccionada
    if (_customImage != null) {
      return ClipOval(
        child: Image.memory(
          _customImage!.bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    // Prioridad 2: Imagen remota de Google (si no ha sido eliminada por el usuario)
    if (!_isRemoved && _photoUrl != null && _photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _resolvePhotoUrl(_photoUrl!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
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
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.camera_alt_outlined,
              color: AppColors.iconSecondary,
              size: 32,
            ),
          ),
        ),
      );
    }

    // Prioridad 3: Placeholder gris oficial de Figma
    return const Center(
      child: Icon(
        Icons.camera_alt_outlined,
        color: AppColors.iconSecondary,
        size: 32,
      ),
    );
  }

  /// Bloque visual central con avatar circular e indicaciones
  Widget _buildPhotoUploadSection() {
    final hasPhoto = _hasActivePhoto;

    // Subtítulo adaptativo según la procedencia de la foto
    String subtitleText;
    if (_customImage != null) {
      subtitleText = 'Custom photo selected · You can change it';
    } else if (!_isRemoved && _photoUrl != null && _photoUrl!.isNotEmpty) {
      subtitleText = 'Imported from Google · You can change it';
    } else {
      subtitleText = 'Optional · You can change it later';
    }

    return Center(
      child: GestureDetector(
        key: const Key('photo_avatar_gesture'),
        onTap: _showPhotoSourceBottomSheet,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar circular táctil
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 12.5.rem, // 200 px
                  height: 12.5.rem, // 200 px
                  decoration: BoxDecoration(
                    color: AppColors.badgeSurface,
                    shape: BoxShape.circle,
                    border: hasPhoto
                        ? Border.all(color: AppColors.border, width: 2.0)
                        : null,
                  ),
                  child: _buildAvatarContent(),
                ),

                // Badge de cámara flotante para indicar interactividad de reemplazo
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
              subtitleText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 0.875.rem, // 14 px
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón principal "Save and continue" y enlace animado "Not now"
  Widget _buildFooterActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Acción principal: Botón global AppButton
          AppButton(
            text: 'Save and continue',
            variant: AppButtonVariant.primary,
            isLoading: _isLoading,
            onPressed: _handleSaveAndContinue,
          ),

          // Transición suave para ocultar "Not now" cuando ya existe una foto activa
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
            child: _hasActivePhoto
                ? const SizedBox.shrink(key: ValueKey('empty_skip'))
                : SizedBox(
                    key: const ValueKey('skip_column'),
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 0.625.rem), // 10 px
                        AppLinkButton(
                          text: 'Not now',
                          onPressed: _isLoading ? null : _handleSkip,
                          textStyle: GoogleFonts.poppins(
                            fontSize: 1.0.rem, // 16 px (mismo tamaño y peso del diseño)
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
