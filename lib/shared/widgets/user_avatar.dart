import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/media_service.dart';
import '../../core/theme/app_colors.dart';

/// Avatar circular reutilizable del Design System.
///
/// Muestra en orden de prioridad:
/// 1. Foto personalizada local ([customPhoto]).
/// 2. Foto de red ([photoUrl]) con respaldo automático en caso de error.
/// 3. Iniciales del usuario ([initials]) sobre [AppColors.badgeSurface].
class UserAvatar extends StatelessWidget {
  final double size;
  final String initials;
  final PickedImage? customPhoto;
  final String? photoUrl;

  const UserAvatar({
    super.key,
    required this.size,
    required this.initials,
    this.customPhoto,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildInitials() {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.badgeSurface,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials,
            style: GoogleFonts.poppins(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      );
    }

    if (customPhoto != null) {
      return ClipOval(
        child: Image.memory(
          customPhoto!.bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => buildInitials(),
        ),
      );
    }

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => buildInitials(),
        ),
      );
    }

    return buildInitials();
  }
}
