import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_google_icon.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_link_text.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../home/screens/home_screen.dart';
import '../services/auth_service.dart';
import '../../../core/services/creds_api_service.dart';
import '../../onboarding/navigation/onboarding_navigator.dart';
import 'create_account_screen.dart';

/// Pantalla de Inicio de Sesión ("Welcome back" — 01B Sign in / 1.png).
///
/// Construida estrictamente con los componentes globales del Design System (`AppHeader`,
/// `AppTextField`, `AppButton`, `AppGoogleIcon`, `AppLinkText`, `AppColors`, `.rem`).
class SignInScreen extends StatefulWidget {
  final VoidCallback? onSignUp;
  final ValueChanged<String>? onSignedIn;

  const SignInScreen({
    super.key,
    this.onSignUp,
    this.onSignedIn,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final valid = _isFormValid;
    if (valid != _isButtonEnabled) {
      setState(() => _isButtonEnabled = valid);
    }
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Please enter your email address';
    }
    if (!_emailRegExp.hasMatch(text)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  bool get _isFormValid =>
      _validateEmail(_emailController.text) == null &&
      _validatePassword(_passwordController.text) == null;

  Future<void> _handleSignIn() async {
    if (!_isFormValid) {
      AppFeedback.showError(
        context,
        'Por favor verifica tu correo y contraseña',
      );
      return;
    }

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      final response = await CredsApiService.instance.login(
        email: email,
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (widget.onSignedIn != null) {
        widget.onSignedIn!(email);
        return;
      }

      await OnboardingNavigator.navigateFromProfile(
        context,
        response.user,
        fallbackScreen: const HomeScreen(),
        clearStackWhenCompleted: true,
      );
    } on CredsApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (e.isNetworkOrOfflineError &&
          CredsApiService.instance.offlineFallbackEnabled) {
        debugPrint('⚠️ Backend offline en SignInScreen: ${e.message}');
        if (widget.onSignedIn != null) {
          widget.onSignedIn!(email);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
        return;
      }

      AppFeedback.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.showError(context, 'Error al iniciar sesión: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (!mounted) return;

      if (credential != null && credential.user != null) {
        final backendUser = CredsApiService.instance.currentUser;
        await OnboardingNavigator.navigateFromProfile(
          context,
          backendUser,
          fallbackScreen: const HomeScreen(),
          clearStackWhenCompleted: true,
        );
      }
    } on CredsApiException catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        'Error al iniciar sesión con Google: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
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
              padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 1.5.rem),

                      const AppHeader(
                        title: 'Welcome back',
                        description: 'Sign in to your account to continue.',
                      ),

                      SizedBox(height: 1.75.rem),

                      AppTextField.email(
                        controller: _emailController,
                        hintText: 'ana.torres@correo.com',
                        textInputAction: TextInputAction.next,
                        focusLossValidator: _validateEmail,
                      ),

                      SizedBox(height: 1.25.rem),

                      AppTextField.password(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Enter your password',
                        textInputAction: TextInputAction.done,
                        validateOnFocusLoss: true,
                        focusLossValidator: _validatePassword,
                        onFieldSubmitted: (_) {
                          if (_isButtonEnabled && !_isLoading) {
                            _handleSignIn();
                          }
                        },
                      ),

                      SizedBox(height: 1.5.rem),

                      AppButton(
                        text: 'Sign in',
                        variant: AppButtonVariant.primary,
                        isLoading: _isLoading,
                        onPressed:
                            (_isButtonEnabled && !_isLoading) ? _handleSignIn : null,
                      ),

                      SizedBox(height: 1.5.rem),

                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 0.75.rem),
                            child: Text(
                              'or',
                              style: GoogleFonts.poppins(
                                fontSize: 0.8125.rem,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),

                      SizedBox(height: 1.25.rem),

                      AppButton(
                        text: 'Continue with Google',
                        variant: AppButtonVariant.outline,
                        isLoading: _isGoogleLoading,
                        icon: const AppGoogleIcon(size: 20),
                        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      ),

                      SizedBox(height: 1.0.rem),

                      AppButton(
                        text: 'Continue with Apple',
                        variant: AppButtonVariant.outline,
                        icon: const Icon(
                          Icons.apple,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                        onPressed: () => AppFeedback.show(
                          context,
                          'Continue with Apple disponible en iOS',
                        ),
                      ),

                      const Spacer(),

                      SizedBox(height: 1.5.rem),

                      Center(
                        child: AppLinkText(
                          prefixText: 'Don\'t have an account? ',
                          actionText: 'Sign up',
                          onTap: widget.onSignUp ??
                              () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const CreateAccountScreen(),
                                  ),
                                );
                              },
                        ),
                      ),

                      SizedBox(height: 1.25.rem),
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
        'ACCOUNT',
        style: GoogleFonts.poppins(
          fontSize: 0.8125.rem,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
