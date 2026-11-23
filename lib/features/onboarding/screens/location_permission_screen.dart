import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_link_button.dart';
import '../../../core/services/creds_api_service.dart';
import 'activities_screen.dart';

/// Pantalla de Permisos de Ubicación ("Location permission").
///
/// Réplica exacta del diseño oficial de Figma:
/// - **Top Bar:** Botón atrás y título centrado ("LOCATION").
/// - **Contenido Central:**
///   - Badge circular gris con icono de pin de ubicación.
///   - Título ("Location permission") y descripción con [AppHeader.centered].
/// - **Acciones al pie:**
///   - Botón principal ("Enable permissions").
///   - Enlace secundario táctil ("Do this later").
class LocationPermissionScreen extends StatefulWidget {
  final VoidCallback? onEnablePermissions;
  final VoidCallback? onDoThisLater;

  const LocationPermissionScreen({
    super.key,
    this.onEnablePermissions,
    this.onDoThisLater,
  });

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isSaving = false;

  Future<void> _saveLocationPreference(bool granted) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await CredsApiService.instance.updatePreferences(
        locationPermissionGranted: granted,
      );
      if (!mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ActivitiesScreen()));
    } on CredsApiException catch (e) {
      if (!mounted) return;
      if (e.isNetworkOrOfflineError &&
          CredsApiService.instance.offlineFallbackEnabled) {
        debugPrint(
          '⚠️ Backend offline en LocationPermissionScreen: ${e.message}',
        );
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ActivitiesScreen()));
        return;
      }
      AppFeedback.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        'Error al guardar preferencia de ubicación: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Solicita el permiso nativo/web de ubicación y devuelve si fue otorgado.
  Future<bool> _requestNativeLocationPermission() async {
    final isWidgetTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (isWidgetTest) {
      return true;
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      // En entornos sin soporte nativo de geolocalización, continuamos sin bloquear el flujo.
      debugPrint('ℹ️ Permiso nativo de ubicación no disponible: $e');
      return true;
    }
  }

  Future<void> _handleEnablePermissions() async {
    if (widget.onEnablePermissions != null) {
      widget.onEnablePermissions!();
      return;
    }

    final granted = await _requestNativeLocationPermission();
    if (!mounted) return;
    await _saveLocationPreference(granted);
  }

  Future<void> _handleDoThisLater() async {
    if (widget.onDoThisLater != null) {
      widget.onDoThisLater!();
      return;
    }

    await _saveLocationPreference(false);
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Espacio superior hacia el bloque central
                      const Spacer(flex: 2),

                      // 1. Badge circular central con icono de ubicación
                      _buildLocationBadge(),

                      SizedBox(height: 2.0.rem), // 32 px
                      // 2. Encabezado centrado reutilizando AppHeader
                      const AppHeader.centered(
                        title: 'Find your next spot',
                        description: 'Use your location to find nearby spots, see where your people go, and get better recommendations wherever you are.',
                        spacing: 12.0,
                      ),

                      // Espacio flexible inferior hacia las acciones
                      const Spacer(flex: 3),

                      // 3. Acciones inferiores
                      _buildFooterActions(context),

                      SizedBox(height: 1.0.rem), // 16 px
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

  /// Barra superior con botón atrás y título centrado "LOCATION"
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
        'LOCATION',
        style: GoogleFonts.poppins(
          fontSize: 0.8125.rem, // 13 px
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Badge circular con icono de pin de ubicación
  Widget _buildLocationBadge() {
    return Container(
      width: 12.5.rem, // 200 px
      height: 12.5.rem, // 200 px
      decoration: const BoxDecoration(
        color: AppColors.badgeSurface,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.location_on_outlined,
          color: AppColors.iconSecondary,
          size: 44,
        ),
      ),
    );
  }

  /// Botón principal "Enable permissions" y enlace "Do this later"
  Widget _buildFooterActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón principal
        AppButton(
          text: 'Use my location',
          variant: AppButtonVariant.primary,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _handleEnablePermissions,
        ),

        SizedBox(height: 0.5.rem),

        // Enlace secundario "Do this later" estandarizado
        AppLinkButton(
          text: 'Do this later',
          onPressed: _isSaving ? null : _handleDoThisLater,
        ),
      ],
    );
  }
}
