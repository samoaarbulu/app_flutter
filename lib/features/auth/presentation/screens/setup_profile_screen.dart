import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_rem.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'location_permission_screen.dart';

/// Pantalla de Configuración de Perfil ("Set up your profile").
///
/// Réplica exacta del diseño oficial de Figma:
/// - **Top Bar:** Botón atrás y título centrado ("PROFILE").
/// - **Encabezado:** "Set up your profile" y descripción explicativa con [AppHeader].
/// - **Formulario:**
///   - Campo `Username` con icono de verificación (check).
///   - Campo `Mobile number` con mensaje de ayuda informativo.
///   - Fila de 2 columnas para `First name` y `Last name`.
/// - **Acción al pie:** Botón principal ("Save and continue").
class SetupProfileScreen extends StatefulWidget {
  final VoidCallback? onSaveAndContinue;

  const SetupProfileScreen({super.key, this.onSaveAndContinue});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  // -------------------------------------------------------------
  // 1. ESTADO Y CONTROLADORES (<script setup>)
  // -------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Valores iniciales de ejemplo según maqueta de Figma
    _usernameController = TextEditingController(text: '@ana.entrena');
    _phoneController = TextEditingController(text: '+52  55 1234 5678');
    _firstNameController = TextEditingController(text: 'Ana');
    _lastNameController = TextEditingController(text: 'Torres');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _handleSaveAndContinue() {
    if (_formKey.currentState?.validate() == false) {
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.onSaveAndContinue != null) {
          widget.onSaveAndContinue!();
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
          );
        }
      }
    });
  }

  // -------------------------------------------------------------
  // 2. VISTA PRINCIPAL (<template>)
  // -------------------------------------------------------------
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 1.5.rem), // 24 px
                        // 1. Encabezado principal
                        const AppHeader(
                          title: 'Set up your profile',
                          description:
                              'This is how your community will find you.',
                        ),

                        SizedBox(height: 1.5.rem), // 24 px
                        // 2. Campo Username con icono de verificación
                        AppTextField(
                          label: 'Username',
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          suffixIcon: const Icon(
                            Icons.check,
                            size: 20,
                            color: Color(0xFF71717A),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un nombre de usuario';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 1.25.rem), // 20 px
                        // 3. Campo Mobile number con helper text
                        AppTextField(
                          label: 'Mobile number',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          helperText:
                              'Your number will not appear on your profile.',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un número de teléfono';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 1.25.rem), // 20 px
                        // 4. Fila First name y Last name
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'First name',
                                controller: _firstNameController,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Requerido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 0.875.rem), // 14 px
                            Expanded(
                              child: AppTextField(
                                label: 'Last name',
                                controller: _lastNameController,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    _handleSaveAndContinue(),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Requerido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        // Espacio flexible inferior
                        const Spacer(),

                        SizedBox(height: 1.5.rem),

                        // 5. Botón de acción al pie
                        AppButton(
                          text: 'Save and continue',
                          variant: AppButtonVariant.primary,
                          isLoading: _isLoading,
                          onPressed: _handleSaveAndContinue,
                        ),

                        SizedBox(height: 1.0.rem), // 16 px
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Barra superior con botón atrás y título centrado
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
}
