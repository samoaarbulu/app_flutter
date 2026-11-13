# 📱 05. Pantallas y Flujo Completo de Onboarding

Este documento describe la arquitectura, diseño visual y navegación de todas las pantallas construidas para **Creds** basadas en los mockups de Figma.

---

## 🗺️ Diagrama del Flujo de Navegación

```mermaid
flowchart TD
    A["1. PreloadingScreen (3D Float creds)"] -->|2.6s o tap| B["2. PresentationScreen (Video)"]
    B -->|Get started| C["3. AuthLandingScreen (Build your Creds)"]
    C -->|Continue with Google (Login exitoso)| F["6. AddPhotoScreen (Add your photo)"]
    C -->|Continue with Email| D["4. CreateAccountScreen (Email + Pass)"]
    D -->|Send code| E["5. VerifyEmailScreen (Check your email / OTP)"]
    E -->|Change email address| D
    E -->|Verify email| F
    F -->|Save and continue o Not now| G["7. SetupProfileScreen (Set up your profile)"]
    G -->|Save and continue| H["8. LocationPermissionScreen (Location permission)"]
    H -->|Enable permissions o Do this later| I["Home / Exploración de Gimnasios"]
```

---

## 📋 Catálogo de Pantallas Construidas

### 1. `PreloadingScreen` (`lib/features/auth/presentation/screens/preloading_screen.dart`)
* **Concepto:** Pantalla inicial de arranque (Splash) con física GPU "3D Float".
* **Diseño:**
  * Wordmark `"creds"` en minúsculas, peso **Black (Poppins w900)** y tamaño de **58 px** (`3.625.rem`) en color `#1E1E1E`.
  * Tagline oficial: `"Where your people go."` (`#666666`, 16 px).
  * **Animación 3D Float:** Levitación vertical continua ($\pm 10\text{ px}$) mediante aceleración senoidal en 2.4 segundos.
  * **Sombra física en el suelo:** Reactiva a la altura; se expande, difumina y aclara cuando el texto se eleva, y se contrae, enfoca y oscurece cuando desciende.
* **Comportamiento:** Transición de desvanecimiento suave (*cross-fade*) de 550 ms hacia `PresentationScreen` tras 2.6 segundos o mediante toque directo en pantalla.

---

### 2. `PresentationScreen` (`lib/features/auth/presentation/screens/presentacion.dart`)
* **Concepto:** Pantalla de bienvenida oficial con video de alta resolución en bucle.
* **Diseño:**
  * Fondo: `video_player` reproduciendo `assets/video/fondo_presentacion.mp4` silenciado en bucle continuo.
  * Capa protectora (*Scrim*): Gradiente semitransparente oscuro en la base para garantizar legibilidad de textos blancos.
  * **Encabezado:** Título `"Find your place.\nCompare it your way."` (Poppins 32px w800) y subtítulo explicativo de 2 líneas.
  * **Acción principal:** Botón `AppButton` (`Get started`) con borde de 16px.
  * **Enlace inferior:** RichText interactivo `"Already have an account? Sign in"`.

---

### 3. `AuthLandingScreen` (`lib/features/auth/presentation/screens/auth_landing.dart`)
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

### 4. `CreateAccountScreen` (`lib/features/auth/presentation/screens/create_account_screen.dart`)
* **Concepto:** Formulario de registro por correo y contraseña.
* **Diseño:**
  * Encabezado: `AppHeader(title: 'Create your account', description: 'We\'ll send you a code...')`.
  * **Inputs (`AppTextField`):**
    * `AppTextField.email`: Preconfigurado con teclado de correo e icono de sobre.
    * `AppTextField.password`: Preconfigurado con ocultación de caracteres y botón de alternancia de visibilidad (icono de ojo).
    * Mensaje de ayuda inferior: `"Use 8 or more characters, a letter and a number."`.
  * Aviso de términos: `"You agree to your Terms of Service and Privacy Policy."`.
  * Botón principal: `"Send code"` con estado de carga interactivo.

---

### 5. `VerifyEmailScreen` (`lib/features/auth/presentation/screens/verify_email_screen.dart`)
* **Concepto:** Verificación del código de 6 dígitos enviado por correo.
* **Diseño:**
  * Badge superior: Contenedor suave con icono de sobre.
  * Encabezado: `AppHeader(title: 'Check your email', description: 'We sent a 6-digit code to ana.torres@correo.com.')`.
  * **Componente todo-en-uno `AppOtpSection`:**
    * Etiqueta: `"Verification code"`.
    * 6 casillas OTP estilizadas de 48px de ancho con auto-avance y soporte de backspace.
    * Fila de reenvío: `"Didn't get the code?"` y temporizador `"Resend in 00:28"`.
    * Tarjeta informativa: Icono de información y aviso de expiración en 10 minutos.
  * Botón principal: `"Verify email"`.
  * Enlace secundario: `AppLinkButton(text: 'Change email address')` que regresa a la pantalla anterior.

---

### 6. `AddPhotoScreen` (`lib/features/auth/presentation/screens/add_photo_screen.dart`)
* **Concepto:** Subida y personalización de foto de perfil.
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
  * Botón principal: `"Save and continue"`.
  * Enlace secundario: `AppLinkButton(text: 'Not now')`.

---

### 7. `SetupProfileScreen` (`lib/features/auth/presentation/screens/setup_profile_screen.dart`)
* **Concepto:** Configuración de datos del usuario y comunidad.
* **Autocompletado desde Google:**
  * **First name y Last name:** Se extraen y separan automáticamente desde `user.displayName`.
  * **Username:** Se sugiere automáticamente el identificador limpio extraído del correo **sin el símbolo `@`** (ej. `jelizabeth.dev`), con placeholder `e.g. ana.entrena`.
  * **Mobile number:** Inicia **completamente vacío** para que el usuario escriba su propio número sin tener que borrar texto previo, utilizando `+52  55 1234 5678` únicamente como texto guía en gris (*hintText*).
  * Si no viene de Google, mantiene los valores por defecto del diseño de Figma (`Ana`, `Torres`, `ana.entrena`).
* **Diseño:**
  * Top Bar: Título centrado `PROFILE`.
  * Encabezado: `AppHeader(title: 'Set up your profile', description: 'This is how your community will find you.')`.
  * **Formulario completo (`AppTextField`):**
    1. **Username:** Campo de texto limpio con icono de check (`Icons.check`) como `suffixIcon`.
    2. **Mobile number:** Inicia vacío con teclado telefónico, placeholder en gris suave y mensaje informativo: `"Your number will not appear on your profile."`.
    3. **Fila de dos columnas:** Distribución equitativa para **First name** y **Last name**.
  * Botón principal: `"Save and continue"`.

---

### 8. `LocationPermissionScreen` (`lib/features/auth/presentation/screens/location_permission_screen.dart`)
* **Concepto:** Solicitud de permisos GPS para mapas y recomendaciones.
* **Diseño:**
  * Top Bar: Título centrado `LOCATION`.
  * **Badge circular:** Diámetro de 120 px (`7.5.rem`) con fondo `AppColors.badgeSurface` e icono de pin de ubicación (`Icons.location_on_outlined`).
  * Encabezado: `AppHeader.centered(title: 'Location permission', description: 'Enable location access for a more detailed map with\nthe best recommendations.')`.
  * Botón principal: `"Enable permissions"`.
  * Enlace secundario: `AppLinkButton(text: 'Do this later')`.

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

