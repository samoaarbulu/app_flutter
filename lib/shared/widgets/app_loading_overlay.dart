import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_rem.dart';

/// Overlay bloqueante reutilizable para acciones asíncronas sin botón (`AppButton`).
///
/// Útil cuando una pantalla dispara una petición al backend al tocar una tarjeta,
/// un chip o un gesto directo, evitando que la UI parezca congelada o reciba
/// múltiples toques mientras espera respuesta.
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: AppColors.background.withValues(alpha: 0.75),
                child: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2.0.rem),
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.5.rem,
                      vertical: 1.25.rem,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primaryAction,
                          ),
                        ),
                        if (message != null && message!.trim().isNotEmpty) ...[
                          SizedBox(height: 0.875.rem),
                          Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 0.875.rem,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
