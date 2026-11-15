# 🏗️ 01. Arquitectura, Estructura y Design System

Este documento detalla los principios de ingeniería de software, la organización de carpetas y el sistema de diseño visual implementados en **Creds**.

---

## 1. Filosofía de Arquitectura (Feature-First)

El proyecto utiliza una arquitectura **Feature-First** (modular por funcionalidades) combinada con principios de **Clean Code**. Cada funcionalidad vive en su propio módulo autocontenido:

```text
lib/
├── main.dart                         # Punto de entrada de la aplicación
├── core/                             # Núcleo compartido global (no depende de features)
│   ├── config/                       # Configuración de entornos y Firebase (app_config, firebase_options_dev)
│   ├── constants/                    # Constantes globales (country_codes)
│   ├── services/                     # Servicios globales (CredsApiService, FirebaseInitializer, MediaService)
│   ├── theme/                        # Design System (AppColors, AppTypography, AppTheme)
│   └── utils/                        # Extensiones y utilidades (AppRem, AppFeedback)
├── shared/                           # Componentes visuales reutilizables en toda la aplicación
│   └── widgets/                      # AppButton, AppHeader, AppTextField, AppOtpSection, AppLinkButton, etc.
└── features/                         # Módulos por flujo funcional (sin capas innecesarias)
    ├── splash/                       # Arranque y bienvenida
    │   └── screens/                  # PreloadingScreen, PresentationScreen
    ├── auth/                         # Acceso, registro y verificación
    │   ├── screens/                  # AuthLandingScreen, SignInScreen, CreateAccountScreen, VerifyEmailScreen
    │   └── services/                 # AuthService (Google Sign-In y Firebase)
    ├── onboarding/                   # Configuración guiada del perfil inicial
    │   ├── navigation/               # OnboardingNavigator (enrutado según onboardingStep)
    │   ├── screens/                  # AddPhotoScreen, SetupProfileScreen, LocationPermissionScreen, ActivitiesScreen
    │   └── widgets/                  # CountryPickerBottomSheet
    └── home/                         # Módulo principal de la app
        └── screens/                  # HomeScreen
```

---

## 2. Patrón de "Componentes Modulares" (Estilo Vue/Angular)

Para mantener la legibilidad y evitar árboles de widgets anidados (*Widget Hell*), cada pantalla se estructura dividiendo el estado, la vista principal y los subcomponentes:

```dart
class MyScreen extends StatefulWidget { ... }

class _MyScreenState extends State<MyScreen> {
  // -------------------------------------------------------------
  // 1. ESTADO Y CONTROLADORES (<script setup>)
  // -------------------------------------------------------------
  final _controller = TextEditingController();
  bool _isLoading = false;

  void _handleSubmit() { ... }

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
              padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildForm(),
                      const Spacer(),
                      _buildFooterAction(),
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

  // -------------------------------------------------------------
  // 3. SUBCOMPONENTES MODULARES
  // -------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) { ... }
  Widget _buildHeader() { ... }
  Widget _buildForm() { ... }
  Widget _buildFooterAction() { ... }
}
```

---

## 3. Sistema de Diseño Oficial (Creds Tokens)

Todos los valores visuales están centralizados en `lib/core/theme/` para garantizar consistencia absoluta con los mockups de Figma.

### A. Matemática de Unidades REM (`lib/core/utils/app_rem.dart`)
Para replicar con precisión milimétrica los espaciados basados en múltiplos de 16 píxeles:
```dart
extension RemExtension on num {
  /// Convierte rems a píxeles en pantalla: 1.0.rem = 16.0 px
  double get rem => toDouble() * 16.0;
}
```
* **Ejemplos:**
  * `0.5.rem` = 8 px
  * `1.0.rem` = 16 px
  * `1.25.rem` = 20 px
  * `1.5.rem` = 24 px
  * `2.0.rem` = 32 px

### B. Paleta de Colores Oficial (`lib/core/theme/app_colors.dart`)
```dart
abstract final class AppColors {
  /// Fondo principal (#FFFFFF)
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  /// Color de acción primaria / botón principal (#262626)
  static const Color primaryAction = Color(0xFF262626);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Textos oficiales
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF8E8E93);

  /// Superficies y badges
  static const Color inputSurface = Color(0xFFF5F5F7);
  static const Color badgeSurface = Color(0xFFEEEEF2);
  static const Color border = Color(0xFFE5E5EA);

  /// Iconos
  static const Color iconSecondary = Color(0xFF71717A);

  /// Estados y validación
  static const Color error = Color(0xFFFF3B30);
}
```

### C. Tipografía Dinámica (`lib/core/theme/app_typography.dart`)
Implementada mediante **getters dinámicos** con `GoogleFonts.poppins` para garantizar compatibilidad con Hot Reload:
* **`brandTitle`:** Poppins 32px w800 (título de presentación).
* **`headlineLarge`:** Poppins 30px w700 (títulos de pantalla).
* **`bodyDescription`:** Poppins 15px w400 (`#666666`).
* **`button`:** Poppins 16px w700 (`#FFFFFF`).
* **`input` / `inputHint`:** Poppins 15px w500 / w400.
* **`linkBold` / `linkNormal`:** Poppins 14px w700 / w400 para enlaces táctiles.

---

## 4. Catálogo de Componentes Globales (`lib/shared/widgets/`)

1. **`AppButton`:**
   * Botón principal de 56px de altura y radio de 16px.
   * Variantes: `primary` (oscuro `#262626`), `secondary` (`#F5F5F7`), `outline` (borde de 1px) y `text`.
   * Soporte integrado de iconos a la izquierda con espaciado (`iconSpacing`), y estado de carga (`isLoading`).

2. **`AppHeader` (con `AppTitle` y `AppDescription`):**
   * Encabezado unificado que resuelve declarativamente: solo título, solo descripción o ambos combinados con espaciado automático.
   * Constructor nombrado `AppHeader.centered(...)` para pantallas con alineación al centro.

3. **`AppTextField`:**
   * Campo de entrada estilizado con etiqueta superior en negrita (`label`), caja interactiva `#F9F9FB` con bordes suaves de 16px, foco animado y mensaje de ayuda al pie (`helperText`).
   * **Soporte de Prefijos y Filtros:** Parámetros `prefix`, `prefixText` e `inputFormatters` para selectores de país, prefijos `@`, formato de números o letras.
   * **Validación reactiva al perder el foco (`validateOnFocusLoss` / `focusLossValidator` / `isEmail`):**
     * En `AppTextField.email` y campos con `focusLossValidator`, al perder el foco (blur) se evalúan los requisitos de validación.
     * Si el contenido es inválido o está vacío, el borde y el icono se tornan en color `AppColors.error` (`#FF3B30`), y se muestra una fila de alerta con icono `Icons.error_outline_rounded` y mensaje explicativo.
     * Al volver a escribir un valor válido en `onChanged`, el estado de error se limpia automáticamente en tiempo real.
     * Soporta `emailErrorMessage` para personalizar el mensaje de error y `focusLossValidator` para reglas personalizadas.
   * Constructores nombrados de conveniencia: `AppTextField.email(...)` y `AppTextField.password(...)` (con alternancia de visibilidad mediante icono de ojo).
   * Parámetro `onFieldSubmitted` para envíos desde el teclado.

4. **`AppOtpSection` y `AppOtpInput`:**
   * Componente todo-en-uno para verificación de 6 dígitos OTP.
   * Incluye etiqueta superior, 6 casillas con auto-enfoque y manejo de tecla backspace, fila de reenvío con temporizador de cuenta regresiva (00:28) y tarjeta de aviso con icono de expiración (10 minutos).

5. **`AppLinkButton`:**
   * Botón de texto interactivo con área táctil accesible mínima (44 px) y tipografía `AppTypography.linkBold` (`"Not now"`, `"Do this later"`, `"Change email address"`).

6. **`AppLinkText`:**
   * Texto mixto interactivo (`"Already have an account? Sign in"`), con estilos separados para prefijo y acción.
   * Normaliza automáticamente los espacios entre `prefixText` y `actionText` garantizando exactamente un espacio separador (evitando concatenaciones accidentales como `"account?Sign in"`).

7. **`AppGoogleIcon`:**
   * Isotipo oficial monocromático de Google ("G" bold) extraído fielmente del diseño de Figma.

8. **`AppFeedback`:**
   * Sistema centralizado de SnackBar / Notificaciones con variantes `.show()`, `.showSuccess()` y `.showError()`.
