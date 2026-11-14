import 'package:flutter/material.dart';

import '../../home/screens/home_screen.dart';
import '../../../core/services/creds_api_service.dart';
import '../screens/activities_screen.dart';
import '../screens/add_photo_screen.dart';
import '../screens/location_permission_screen.dart';
import '../screens/setup_profile_screen.dart';
import '../../auth/screens/verify_email_screen.dart';

/// Decide a qué pantalla debe ir el usuario según su avance en backend (`onboardingStep`).
abstract final class OnboardingNavigator {
  /// Convierte el estado guardado en PostgreSQL en el widget destino exacto.
  static Widget screenForProfile(CredsUserProfile profile) {
    // Si ya completó el perfil, entra directo a Home.
    if (profile.profileCompleted || profile.onboardingStep == 'completed') {
      return const HomeScreen();
    }

    // Si dejó el registro a medias, retoma exactamente en el paso pendiente.
    return switch (profile.onboardingStep) {
      'verify_email' => VerifyEmailScreen(email: profile.email),
      'add_photo' => const AddPhotoScreen(),
      'setup_profile' => const SetupProfileScreen(),
      'location_permission' => const LocationPermissionScreen(),
      'activities' => const ActivitiesScreen(),
      _ => const AddPhotoScreen(),
    };
  }

  /// Navega a la pantalla destino reemplazando o apilando según convenga.
  static Future<void> navigateFromProfile(
    BuildContext context,
    CredsUserProfile? profile, {
    Widget fallbackScreen = const AddPhotoScreen(),
    bool clearStackWhenCompleted = false,
  }) async {
    final Widget destination =
        profile != null ? screenForProfile(profile) : fallbackScreen;

    final route = MaterialPageRoute<void>(builder: (_) => destination);
    if (clearStackWhenCompleted &&
        (profile?.profileCompleted == true ||
            profile?.onboardingStep == 'completed')) {
      await Navigator.of(context).pushAndRemoveUntil(route, (r) => false);
      return;
    }

    await Navigator.of(context).push(route);
  }
}
