# 📱 05. Pantallas y Flujo Completo de Onboarding

Este documento describe la arquitectura, diseño visual y navegación de todas las pantallas construidas para **Creds** basadas en los mockups de Figma.

---

## 🗺️ Diagrama del Flujo de Navegación

```mermaid
flowchart TD
    A["1. PreloadingScreen (3D Float creds)"] -->|2.6s o tap| B["2. PresentationScreen (Video)"]
    B -->|Get started| C["3. AuthLandingScreen (Build your Creds)"]
    B -->|Sign in| SI["SignInScreen (Welcome back)"]
    C -->|Sign in| SI
    C -->|Continue with Google (Login exitoso)| F["6. AddPhotoScreen (Add your photo)"]
    C -->|Continue with Email| D["4. CreateAccountScreen (Email + Pass)"]
    D -->|Send code| E["5. VerifyEmailScreen (Check your email / OTP)"]
    E -->|Change email address| D
    E -->|Verify email| F
    F -->|Save and continue o Not now| G["7. SetupProfileScreen (Set up your profile)"]
    G -->|Save and continue| H["8. LocationPermissionScreen (Location permission)"]
    H -->|Enable permissions o Do this later| ACT["9. ActivitiesScreen (22 disciplinas oficiales)"]
    ACT -->|Continue| HOME["10. HomeScreen (Onboarding completed)"]
    SI -->|Login / onboardingStep| HOME
```

---

## 📋 Catálogo de Pantallas Construidas

### 1. `PreloadingScreen` (`lib/features/splash/screens/preloading_screen.dart`)
* **Concepto:** Pantalla inicial de arranque (Splash) con física GPU "3D Float".
* **Diseño:**
  * Wordmark `"creds"` en minúsculas, peso **Black (Poppins w900)** y tamaño de **58 px** (`3.625.rem`) en color `#1E1E1E`.
  * Tagline oficial: `"Where your people go."` (`#666666`, 16 px).
  * **Animación 3D Float:** Levitación vertical continua ($\pm 10\text{ px}$) mediante aceleración senoidal en 2.4 segundos.
  * **Sombra física en el suelo:** Reactiva a la altura; se expande, difumina y aclara cuando el texto se eleva, y se contrae, enfoca y oscurece cuando desciende.
* **Comportamiento:** Transición de desvanecimiento suave (*cross-fade*) de 550 ms hacia `PresentationScreen` tras 2.6 segundos o mediante toque directo en pantalla.

---

### 2. `PresentationScreen` (`lib/features/splash/screens/presentacion.dart`)
* **Concepto:** Pantalla de bienvenida oficial con video de alta resolución en bucle.
* **Diseño:**
  * Fondo: `video_player` reproduciendo `assets/video/fondo_presentacion.mp4` silenciado en bucle continuo.
  * Capa protectora (*Scrim*): Gradiente semitransparente oscuro en la base para garantizar legibilidad de textos blancos.
  * **Encabezado:** Título `"Find your place.\nCompare it your way."` (Poppins 32px w800) y subtítulo explicativo de 2 líneas.
  * **Acción principal:** Botón `AppButton` (`Get started`) con borde de 16px.
  * **Enlace inferior:** RichText interactivo `"Already have an account? Sign in"`.

---

### 3. `AuthLandingScreen` (`lib/features/auth/screens/auth_landing.dart`)
* **Concepto:** Selector de método de autenticación.
* **Diseño:**
  * Top Bar: Botón atrás y título centrado en mayúsculas `ACCOUNT` (`letterSpacing: 2.0`).
  * Encabezado: Reutiliza `AppHeader` con `title: 'Build your Creds'` y descripción explicativa.
  * **3 Botones de acción (`AppButtonVariant.outline`):**
    1. **"Continue with Google":** Con isotipo oficial `AppGoogleIcon`, estado de carga interactivo y llamada directa a `AuthService.instance.signInWithGoogle()`.
    2. **"Continue with Apple":** Con icono `Icons.apple`.
    3. **"Continue with Email":** Con icono de sobre, navega a `CreateAccountScreen`.
  * **Enlace al pie:** `AppLinkText` (`"Already have an account? Sign in"`).

---

### 4. `CreateAccountScreen` (`lib/features/auth/screens/create_account_screen.dart`)
* **Concepto:** Formulario de registro por correo y contraseña.
* **Diseño:**
  * Encabezado: `AppHeader(title: 'Create your account', description: 'We\'ll send you a code...')`.
  * **Inputs y Validación Reactiva (`AppTextField`):**
    * `AppTextField.email`: Validación de formato de correo con borde rojo (`AppColors.error`), icono y mensaje explicativo al perder el foco (blur).
    * `AppTextField.password`: Validación estricta que exige **8 o más caracteres, al menos una letra y un número**.
      * **Helper text dinámico inteligente:** Muestra `"Use 8 or more characters, a letter and a number."` cuando el campo está vacío o incompleto. En cuanto la contraseña ingresada cumple todos los requisitos, el mensaje se **oculta automáticamente** para no confundir al usuario ni dar la falsa impresión de que su contraseña es inválida.
      * **Error visual al perder foco:** Si no cumple, resalta el borde en rojo (`AppColors.error`) con icono de advertencia. Al corregirse, el estado de error se limpia en tiempo real.
  * Aviso de términos: `"You agree to your Terms of Service and Privacy Policy."`.
  * **Botón dinámico "Send code":** Permanece **deshabilitado** (estilo atenuado al 50%, no clickeable) hasta que ambos campos (Email y Password) cumplan con todos los requisitos de validación, habilitándose automáticamente.

---

### 5. `VerifyEmailScreen` (`lib/features/auth/screens/verify_email_screen.dart`)
* **Concepto:** Verificación del código de 6 dígitos enviado por correo.
* **Diseño:**
  * Badge superior: Contenedor suave con icono de sobre.
  * Encabezado: `AppHeader(title: 'Check your email', description: 'We sent a 6-digit code to ana.torres@correo.com')`.
  * **Componente todo-en-uno `AppOtpSection`:**
    * Etiqueta: `"Verification code"`.
    * 6 casillas OTP estilizadas de 48px de ancho con auto-avance y soporte de backspace.
    * Fila de reenvío: `"Didn't get the code?"` y temporizador `"Resend in 00:28"`.
    * Tarjeta informativa: Icono de información y aviso de expiración en 10 minutos.
  * Botón principal: `"Verify email"`.
  * Enlace secundario: `AppLinkButton(text: 'Change email address')` que regresa a la pantalla anterior.

---

### 6. `AddPhotoScreen` (`lib/features/onboarding/screens/add_photo_screen.dart`)
* **Concepto:** Subida, captura y personalización de foto de perfil con reemplazo en tiempo real.
* **Diseño e Integración Inteligente:**
  * Top Bar: Botón atrás y título centrado `PROFILE`.
  * Encabezado: `AppHeader(title: 'Add your photo', description: 'Lorem ipsum dolor')`.
  * **Avatar circular central (168 px / 10.5.rem):**
    * **Si el usuario viene de Google (`photoURL != null`):**
      * Carga la foto real en alta definición (resolución optimizada a 400x400 px con `=s400-c`).
      * **Solución CORS en Flutter Web:** En Chrome/Web (`kIsWeb`), el motor CanvasKit bloquea peticiones de imágenes a dominios externos sin cabeceras CORS. La función `_resolvePhotoUrl` solventa esto mediante un proxy transparente, mientras que en Android/iOS carga directamente la URL nativa.
      * Muestra un **badge flotante de cámara** en la esquina inferior derecha para indicar que puede tocar para cambiarla.
      * Título y subtítulo adaptativos: `"Your profile photo"` y `"Imported from Google · You can change it"`.
    * **Si viene por Email / no tiene foto:**
      * Muestra el placeholder circular gris con el icono de cámara por defecto.
      * Título y subtítulo: `"Upload your profile photo"` y `"Optional · You can change it later"`.
    * **Selección y Reemplazo de Foto (`MediaService`):**
      * Al tocar el avatar o su insignia se despliega un **Modal Bottom Sheet** nativo del Design System:
        1. 📸 **"Take photo"**: Abre la cámara del dispositivo (`ImageSource.camera`).
        2. 🖼️ **"Choose from gallery"**: Abre la galería del dispositivo (`ImageSource.gallery`).
        3. 🗑️ **"Remove current photo"**: Disponible cuando hay una foto activa (local o de Google), permitiendo restablecer el avatar a su estado por defecto.
      * **Universalidad Multiplataforma:** La imagen seleccionada se procesa en memoria como `Uint8List` optimizada a 1024x1024 px con calidad 85%, funcionando idénticamente en Web (sin colapsos por `dart:io.File`), Android e iOS.
      * **Persistencia en sesión:** Al pulsar `"Save and continue"`, la foto elegida se almacena en `AuthService.instance.customPhoto` para que esté disponible en los siguientes pasos del onboarding.
  * Botón principal: `"Save and continue"`.
  * **Enlace secundario dinámico y animado (`AnimatedSwitcher`):**
    * Solo se muestra `"Not now"` cuando el usuario **no tiene una foto activa**.
    * Si la pantalla abre con foto de Google o tras subir una foto de galería/cámara, `"Not now"` se **desvanece y oculta suavemente** (con animación de opacidad y tamaño), concentrando la atención únicamente en `"Save and continue"`.
    * Si el usuario elimina la foto activa, `"Not now"` vuelve a aparecer suavemente.

---

### 7. `SetupProfileScreen` (`lib/features/onboarding/screens/setup_profile_screen.dart`)
* **Concepto:** Configuración de perfil del usuario con validación estricta y selector de países para iPhone.
* **Autocompletado desde Google:**
  * **First name y Last name:** Se extraen y separan automáticamente desde `user.displayName`.
  * **Username:** Inicia con prefijo `@` (ej. `@jelizabeth.dev` o `@ana.entrena`).
  * **Mobile number:** Inicia **vacío** para que el usuario escriba su propio número sin tener que borrar texto previo, con bandera y prefijo por defecto de México (`🇲🇽 +52`).
* **Reglas de Negocio y Validación:**
  1. **Username:**
     * Formateador automático `UsernameTextInputFormatter` que garantiza que siempre comience con `@`.
     * Únicamente el carácter `@` se considera campo vacío (`"Please enter a username"`).
     * **Bloqueo en tiempo real:** Filtra e impide físicamente teclear cualquier carácter extraño (ej. `=`, `!`, `$`, `%`, espacios o caracteres especiales); solo permite escribir letras, números, `-`, `_` y `.`.
     * Indicador visual de check (`Icons.check`) reactivo en color verde al ser válido.
  2. **Mobile number:**
     * Bloqueo estricto de letras mediante `FilteringTextInputFormatter.digitsOnly` y teclado telefónico.
     * **Selector de prefijos internacionales (`CountryPickerBottomSheet`):**
       * Optimizado para iOS/iPhones: banderas con emojis nativos Unicode (Apple Color Emoji), físicas inerciales con rebote (`BouncingScrollPhysics`) y retroalimentación háptica táctil (`HapticFeedback.selectionClick()`).
       * Buscador en tiempo real por nombre de país o código internacional.
     * Validación de longitud mínima (mínimo 8 dígitos).
  3. **First name y Last name:**
     * Obligatorios (no vacíos).
     * Solo letras y espacios (permite acentos y caracteres del español como `á, é, í, ó, ú, ñ, ü`). Bloquea números y símbolos.
  4. **Feedback visual de error (*Focus Loss*):**
     * Al perder el foco (blur), si el campo no cumple las reglas se resalta con borde rojo (`AppColors.error`), icono en rojo y fila inferior con icono `Icons.error_outline_rounded` y texto explicativo.
     * Al corregir el valor, el error se limpia reactivamente en tiempo real.
  5. **Botón "Save and continue" dinámico:**
     * Permanece **deshabilitado** (estilo atenuado con opacidad al 50%, no clickeable) hasta que todos los campos cumplan con los requisitos.
     * Se **habilita automáticamente** tan pronto todos los inputs son válidos.

---

### 8. `LocationPermissionScreen` (`lib/features/onboarding/screens/location_permission_screen.dart`)
* **Concepto:** Solicitud de permisos GPS para mapas y recomendaciones.
* **Diseño:**
  * Top Bar: Título centrado `LOCATION`.
  * **Badge circular:** Diámetro de 120 px (`7.5.rem`) con fondo `AppColors.badgeSurface` e icono de pin de ubicación (`Icons.location_on_outlined`).
  * Encabezado: `AppHeader.centered(title: 'Location permission', description: 'Enable location access for a more detailed map with\nthe best recommendations.')`.
  * Botón principal: `"Enable permissions"` (registra `locationPermissionGranted: true` en `/v1/users/preferences` y avanza a `ActivitiesScreen`).
  * Enlace secundario: `AppLinkButton(text: 'Do this later')` (registra `locationPermissionGranted: false` y avanza a `ActivitiesScreen`).

---

### 9. `ActivitiesScreen` (`lib/features/onboarding/screens/activities_screen.dart`)
* **Concepto:** Selección múltiple de disciplinas habituales (`"How do you like to train?"`).
* **Catálogo e Integración Backend:**
  * Renderiza el catálogo oficial de **22 actividades** sincronizadas con PostgreSQL (`auth_core.activity_types`) mediante `GET /v1/users/activities/catalog` y mantiene la lista completa como respaldo offline.
  * Al pulsar `"Continue with N activities"`, envía `activityCodes` a `PATCH /v1/users/preferences` (marcando `profileCompleted = true` en backend) y navega a `HomeScreen`.

---

### 10. `SignInScreen` (`lib/features/auth/screens/sign_in_screen.dart`) y `HomeScreen` (`lib/features/home/screens/home_screen.dart`)
* **`SignInScreen`:** Pantalla `01B Sign in` conectada a `POST /v1/auth/login` y Google Sign-In, que redirige automáticamente según `onboardingStep` usando `OnboardingNavigator`.
* **`HomeScreen`:** Pantalla de destino una vez completado el onboarding, mostrando el resumen de usuario y cierre de sesión (`AuthService.instance.signOut()`).

---

## 🛡️ Resiliencia y Responsividad

Todas las pantallas implementan el patrón:
```dart
LayoutBuilder(
  builder: (context, constraints) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Column(...),
        ),
      ),
    );
  },
)
```
Esto garantiza:
1. **Cero desbordamientos (*RenderFlex overflowed*):** Funciona en pantallas compactas (ej. iPhone SE) o con fuentes de accesibilidad gigantes activadas en el sistema.
2. **Botón pegado al pie con espacio adaptable:** Si la pantalla es alta, el botón descansa abajo; si la pantalla es baja o el teclado virtual se abre, el contenido se desliza suavemente sin romper la interfaz.

