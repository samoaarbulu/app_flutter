import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../splash/screens/presentacion.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/creds_api_service.dart';

/// Pantalla principal destino tras completar el onboarding (`onboardingStep == 'completed'`).
///
/// Sirve como punto de aterrizaje del Hito 1 (Log → Bucket → Duel → Share → Discover)
/// manteniendo estrictamente los tokens del Design System (`AppColors`, `AppTypography`, `.rem`).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PresentationScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'No se pudo cerrar sesión: $e');
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = CredsApiService.instance.currentUser;
    final firebaseUser = AuthService.instance.currentUser;

    final greetingName = user != null
        ? (user.firstName?.isNotEmpty == true
            ? user.firstName!
            : user.displayName)
        : (firebaseUser?.displayName ?? 'Athlete');

    final usernameLabel = user?.username != null && user!.username!.isNotEmpty
        ? '@${user.username}'
        : (user?.email ?? firebaseUser?.email ?? 'Offline preview session');

    final activities = user?.activities ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'CREDS',
          style: GoogleFonts.poppins(
            fontSize: 0.8125.rem,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.5.rem),

              AppHeader(
                title: 'Welcome, $greetingName',
                description:
                    'Your profile is set up. Your workout recommendations and friend duels will appear here.',
              ),

              SizedBox(height: 1.5.rem),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(1.25.rem),
                decoration: BoxDecoration(
                  color: AppColors.inputSurface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usernameLabel,
                      style: AppTypography.linkBold,
                    ),
                    if (user != null) ...[
                      SizedBox(height: 0.375.rem),
                      Text(
                        'City: ${user.primaryCity} · Location: ${user.hasLocationPermission ? 'Enabled' : 'Later'}',
                        style: AppTypography.caption,
                      ),
                    ],
                    if (activities.isNotEmpty) ...[
                      SizedBox(height: 0.75.rem),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: activities
                            .map(
                              (code) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  code.replaceAll('_', ' '),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              AppButton(
                text: 'Sign out',
                variant: AppButtonVariant.outline,
                isLoading: _isSigningOut,
                onPressed: _isSigningOut ? null : _handleSignOut,
              ),

              SizedBox(height: 1.25.rem),
            ],
          ),
        ),
      ),
    );
  }
}
