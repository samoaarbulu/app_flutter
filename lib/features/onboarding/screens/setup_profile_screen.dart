import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/country_codes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/creds_api_service.dart';
import '../widgets/country_picker_bottom_sheet.dart';
import 'location_permission_screen.dart';

/// Formateador que asegura el prefijo '@' inicial y bloquea en tiempo real
/// cualquier carácter no permitido (solo admite letras, números, '-', '_' y '.').
class UsernameTextInputFormatter extends TextInputFormatter {
  static final RegExp _allowedChars = RegExp(r'[a-zA-Z0-9._-]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    if (text.isEmpty) {
      return const TextEditingValue(
        text: '@',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    final buffer = StringBuffer('@');
    final startIndex = text.startsWith('@') ? 1 : 0;
    for (int i = startIndex; i < text.length; i++) {
      final char = text[i];
      if (_allowedChars.hasMatch(char)) {
        buffer.write(char);
      }
    }

    final formattedText = buffer.toString();
    int cursorPosition = newValue.selection.end;
    if (!text.startsWith('@')) {
      cursorPosition += 1;
    }
    cursorPosition = cursorPosition.clamp(1, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

/// Pantalla de Configuración de Perfil ("Set up your profile").
///
/// **Reglas de negocio y validación implementadas:**
/// - **Username:** Prefijo '@' al inicio; únicamente '@' se considera vacío.
///   Caracteres permitidos: letras, números, `-`, `_`, `.`.
/// - **Mobile number:** Bloqueo de letras (solo números), selector nativo de países con banderas
///   y prefijos internacionales optimizado para iPhone.
/// - **First name & Last name:** Obligatorios, solo letras y espacios (permite acentos/tildes).
/// - **Feedback visual de error:** Borde rojo (`AppColors.error`), icono y descripción inferior
///   al perder el foco (blur), con limpieza en tiempo real.
/// - **Botón dinámico:** "Save and continue" permanece deshabilitado hasta que todos los campos
///   cumplan los requisitos de validación.
class SetupProfileScreen extends StatefulWidget {
  final String? initialUsername;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialPhone;
  final VoidCallback? onSaveAndContinue;

  const SetupProfileScreen({
    super.key,
    this.initialUsername,
    this.initialFirstName,
    this.initialLastName,
    this.initialPhone,
    this.onSaveAndContinue,
  });

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

  CountryCode _selectedCountry = CountryCodes.defaultCountry;
  bool _isLoading = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    final apiUser = CredsApiService.instance.currentUser;

    // 1. Obtener First name y Last name desde backend, Google o Figma por defecto
    String defaultFirstName =
        widget.initialFirstName ?? apiUser?.firstName ?? 'Ana';
    String defaultLastName =
        widget.initialLastName ?? apiUser?.lastName ?? 'Torres';
    if (widget.initialFirstName == null &&
        apiUser?.firstName == null &&
        user?.displayName != null &&
        user!.displayName!.trim().isNotEmpty) {
      final parts = user.displayName!.trim().split(' ');
      defaultFirstName = parts.first;
      defaultLastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    // 2. Obtener Username sugerido asegurando el prefijo '@'
    String defaultUsername =
        widget.initialUsername ?? apiUser?.username ?? 'ana.entrena';
    if (widget.initialUsername == null && apiUser?.username == null) {
      final emailSource = apiUser?.email ?? user?.email;
      if (emailSource != null && emailSource.contains('@')) {
        defaultUsername = emailSource.split('@').first;
      }
    }
    if (!defaultUsername.startsWith('@')) {
      defaultUsername = '@$defaultUsername';
    }

    // 3. Teléfono inicial (inicia vacío para que el usuario escriba su número real)
    final defaultPhone = widget.initialPhone ??
        (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty
            ? user.phoneNumber!
            : '');

    _usernameController = TextEditingController(text: defaultUsername);
    _phoneController = TextEditingController(text: defaultPhone);
    _firstNameController = TextEditingController(text: defaultFirstName);
    _lastNameController = TextEditingController(text: defaultLastName);

    // Escuchar cambios para habilitar/deshabilitar el botón en tiempo real
    _usernameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);

    _isButtonEnabled = _isFormValid;
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _firstNameController.removeListener(_onFieldChanged);
    _lastNameController.removeListener(_onFieldChanged);

    _usernameController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final isValid = _isFormValid;
    if (isValid != _isButtonEnabled) {
      setState(() {
        _isButtonEnabled = isValid;
      });
    }
  }

  // -------------------------------------------------------------
  // VALIDACIONES
  // -------------------------------------------------------------

  /// Username: No vacío, más que solo '@', permitido solo letras, números, guion, guion bajo y punto
  String? _validateUsername(String? value) {
    final text = (value ?? '').trim();
    final raw = text.startsWith('@') ? text.substring(1) : text;
    if (raw.trim().isEmpty) {
      return 'Please enter a username';
    }
    final allowedRegex = RegExp(r'^[a-zA-Z0-9._-]+$');
    if (!allowedRegex.hasMatch(raw)) {
      return 'Only letters, numbers, and - _ . are allowed';
    }
    return null;
  }

  /// Mobile number: Solo números, no vacío y longitud mínima de 8 dígitos
  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (text.length < 8) {
      return 'Please enter a valid mobile number (min. 8 digits)';
    }
    return null;
  }

  /// First name: No vacío, solo letras y espacios
  String? _validateFirstName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'First name is required';
    }
    final lettersRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$');
    if (!lettersRegex.hasMatch(text)) {
      return 'Only letters allowed';
    }
    return null;
  }

  /// Last name: No vacío, solo letras y espacios
  String? _validateLastName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Last name is required';
    }
    final lettersRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$');
    if (!lettersRegex.hasMatch(text)) {
      return 'Only letters allowed';
    }
    return null;
  }

  bool get _isFormValid {
    return _validateUsername(_usernameController.text) == null &&
        _validatePhone(_phoneController.text) == null &&
        _validateFirstName(_firstNameController.text) == null &&
        _validateLastName(_lastNameController.text) == null;
  }

  bool get _isUsernameValid =>
      _validateUsername(_usernameController.text) == null;

  Future<void> _handleSaveAndContinue() async {
    if (!_isFormValid) {
      return;
    }

    setState(() => _isLoading = true);

    final cleanedUsername = _usernameController.text
        .trim()
        .replaceFirst(RegExp(r'^@+'), '');
    final phoneNumber =
        '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

    try {
      await CredsApiService.instance.setupProfile(
        username: cleanedUsername,
        phoneNumber: phoneNumber,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (widget.onSaveAndContinue != null) {
        widget.onSaveAndContinue!();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const LocationPermissionScreen(),
          ),
        );
      }
    } on CredsApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (e.isNetworkOrOfflineError &&
          CredsApiService.instance.offlineFallbackEnabled) {
        debugPrint('⚠️ Backend offline en SetupProfileScreen: ${e.message}');
        if (widget.onSaveAndContinue != null) {
          widget.onSaveAndContinue!();
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LocationPermissionScreen(),
            ),
          );
        }
        return;
      }

      AppFeedback.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.showError(context, 'Error al guardar el perfil: $e');
    }
  }

  Future<void> _openCountryPicker() async {
    final picked = await CountryPickerBottomSheet.show(
      context,
      selectedCountry: _selectedCountry,
    );
    if (picked != null && picked != _selectedCountry) {
      setState(() {
        _selectedCountry = picked;
      });
    }
  }

  /// Selector de país incrustado como prefijo en el campo de teléfono
  Widget _buildCountryPickerPrefix() {
    return GestureDetector(
      key: const Key('country_picker_trigger'),
      onTap: _openCountryPicker,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(right: 6, left: 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCountry.flag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 6),
            Text(
              _selectedCountry.dialCode,
              style: GoogleFonts.poppins(
                fontSize: 0.9375.rem, // 15 px
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.iconSecondary,
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 20,
              color: const Color(0xFFE5E5EA),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
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
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
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

                        // 2. Campo Username con prefijo '@' y validación
                        AppTextField(
                          label: 'Username',
                          controller: _usernameController,
                          hintText: 'e.g. @ana.entrena',
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            UsernameTextInputFormatter(),
                            LengthLimitingTextInputFormatter(30),
                          ],
                          validateOnFocusLoss: true,
                          focusLossValidator: _validateUsername,
                          suffixIcon: Icon(
                            Icons.check,
                            size: 20,
                            color: _isUsernameValid
                                ? const Color(0xFF34C759)
                                : AppColors.iconSecondary,
                          ),
                        ),

                        SizedBox(height: 1.25.rem), // 20 px

                        // 3. Campo Mobile number con bandera, código y bloqueo de letras
                        AppTextField(
                          label: 'Mobile number',
                          controller: _phoneController,
                          hintText: '55 1234 5678',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          prefix: _buildCountryPickerPrefix(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          validateOnFocusLoss: true,
                          focusLossValidator: _validatePhone,
                          helperText:
                              'Your number will not appear on your profile.',
                        ),

                        SizedBox(height: 1.25.rem), // 20 px

                        // 4. Fila First name y Last name (solo letras)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'First name',
                                controller: _firstNameController,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]'),
                                  ),
                                  LengthLimitingTextInputFormatter(30),
                                ],
                                validateOnFocusLoss: true,
                                focusLossValidator: _validateFirstName,
                              ),
                            ),
                            SizedBox(width: 0.875.rem), // 14 px
                            Expanded(
                              child: AppTextField(
                                label: 'Last name',
                                controller: _lastNameController,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]'),
                                  ),
                                  LengthLimitingTextInputFormatter(30),
                                ],
                                validateOnFocusLoss: true,
                                focusLossValidator: _validateLastName,
                                onFieldSubmitted: (_) =>
                                    _handleSaveAndContinue(),
                              ),
                            ),
                          ],
                        ),

                        // Espacio flexible inferior
                        const Spacer(),

                        SizedBox(height: 1.5.rem),

                        // 5. Botón de acción al pie dinámico (habilitado solo si el formulario es válido)
                        AppButton(
                          text: 'Save and continue',
                          variant: AppButtonVariant.primary,
                          isLoading: _isLoading,
                          onPressed:
                              _isButtonEnabled ? _handleSaveAndContinue : null,
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
