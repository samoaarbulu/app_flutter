# 🔐 02. Autenticación, Google Sign-In y Multi-Entornos (DEV / PROD)

Este documento detalla la integración completa de **Firebase Authentication**, **Google Sign-In** y la arquitectura de **Multi-Entornos (DEV / PROD)** implementada en **Creds**.

---

## 1. Arquitectura Multi-Entorno (Opción B)

Para evitar colisiones entre datos de prueba y datos de producción, el proyecto maneja dos entornos totalmente aislados:

| Parámetro | Desarrollo (DEV) | Producción (PROD) |
| :--- | :--- | :--- |
| **Nombre del proyecto** | `creds-dev` | `creds-prod` |
| **ID del proyecto Firebase** | `getcreds-dev` | `getcreds-prod` |
| **Package Name Android** | `com.getcreds.app.dev` | `com.getcreds.app` |
| **Etiqueta en el celular** | `Creds (Dev)` | `Creds` |
| **Archivo de opciones Dart** | `lib/firebase_options_dev.dart` | `lib/firebase_options_prod.dart` |

### A. Configuración automática en Android (`android/app/build.gradle.kts`)
El sufijo `.dev` se aplica de forma automática en desarrollo mediante Gradle:

```kotlin
defaultConfig {
    applicationId = "com.getcreds.app" // ID base de Producción
}

buildTypes {
    debug {
        // En desarrollo, añade .dev automáticamente:
        applicationIdSuffix = ".dev"
        manifestPlaceholders["appLabel"] = "Creds (Dev)"
    }
    release {
        // En producción, compila sin sufijo (com.getcreds.app):
        manifestPlaceholders["appLabel"] = "Creds"
    }
}
```

### B. Selector de Entorno en Dart (`lib/core/config/app_config.dart`)
```dart
enum Environment { dev, prod }

abstract final class AppConfig {
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static Environment get environment =>
      _env.toLowerCase() == 'prod' ? Environment.prod : Environment.dev;

  static bool get isProd => environment == Environment.prod;
  static bool get isDev => environment == Environment.dev;

  static String get projectId => isProd ? 'getcreds-prod' : 'getcreds-dev';
}
```

### C. Inicializador Resiliente (`lib/core/services/firebase_initializer.dart`)
```dart
abstract final class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: dev_options.DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase inicializado con éxito (getcreds-dev)');
    } catch (e) {
      debugPrint('ℹ️ Error al inicializar Firebase: $e');
    }
  }
}
```

---

## 2. El "Secreto" Multiplataforma (Web vs Móvil)

> [!WARNING]
> En Flutter Web, llamar directamente a `GoogleSignIn().signIn()` genera el error `Assertion failed: appClientId != null`. 

**La solución oficial implementada en `AuthService`:**
* En **Web (`kIsWeb`)**: Se utiliza **`FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())`**. Esto levanta la ventana emergente oficial de Google utilizando el `authDomain` de Firebase sin requerir Client IDs estáticos en `index.html`.
* En **Móvil (Android / iOS)**: Se utiliza el selector nativo con **`GoogleSignIn().signIn()`** para obtener las credenciales OAuth (`accessToken` e `idToken`) y luego canjearlas en Firebase con `signInWithCredential`.

---

## 3. Implementación del Servicio (`lib/features/auth/services/auth_service.dart`)

```dart
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth? get _auth => Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth?.currentUser;
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  Future<UserCredential?> signInWithGoogle() async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseException(plugin: 'firebase_auth', message: 'Firebase no inicializado');
    }

    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth!.signInWithPopup(googleProvider);
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Cancelado por el usuario

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth!.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error en signInWithGoogle: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth?.signOut();
  }
}
```

---

## 4. Comandos de Configuración con FlutterFire CLI

### Para Desarrollo (`getcreds-dev`):
```powershell
flutterfire configure --project=getcreds-dev --out=lib/firebase_options_dev.dart
```

### Para Producción (`getcreds-prod`):
```powershell
flutterfire configure --project=getcreds-prod --out=lib/firebase_options_prod.dart
```

### Compilar para Producción:
```powershell
flutter build appbundle --dart-define=ENV=prod
```

---

## 5. Datos de Perfil Obtenidos y Políticas de Privacidad

Tras una autenticación exitosa con Google, el objeto `credential.user` provee los siguientes datos que son consumidos automáticamente por las pantallas de onboarding:

| Dato de Google | Propiedad Firebase | Uso en el Onboarding de Creds |
| :--- | :--- | :--- |
| **Foto de perfil** | `user.photoURL` | Se muestra en `AddPhotoScreen` en alta definición (`=s400-c`). |
| **Nombre completo** | `user.displayName` | Se divide en primer nombre y apellidos en `SetupProfileScreen`. |
| **Correo electrónico**| `user.email` | Se extrae el identificador previo al `@` para sugerir el `Username`. |
| **Número de teléfono**| `user.phoneNumber` | **Siempre retorna `null`**. Google nunca comparte el teléfono a través de OAuth estándar por políticas de privacidad; por ello la pantalla `SetupProfileScreen` lo solicita con el campo vacío y texto guía. |

### Manejo de CORS para la Foto de Google en Flutter Web:
En entornos de navegador (como Chrome en desarrollo), el motor CanvasKit bloquea peticiones de imágenes directas a `lh3.googleusercontent.com`. El proyecto implementa la función `_resolvePhotoUrl` en `AddPhotoScreen` que aplica un proxy transparente con cabeceras CORS en Web (`kIsWeb`), mientras que en Android/iOS consume la URL nativa directamente.

---

## 6. Sign in with Apple — Guía de Implementación y Requisitos

Para habilitar el botón **"Continue with Apple"** en `AuthLandingScreen` y `SignInScreen`, se deben completar los siguientes 5 pasos:

1. **Membresía Apple Developer Program ($99 USD/año):**
   * Requisito indispensable de Apple para generar identificadores y certificados criptográficos de autenticación.
2. **Apple Developer Portal (`Certificates, Identifiers & Profiles`):**
   * En el App ID (ej. `com.getcreds.app`), activar el capability **Sign in with Apple**.
   * Para soporte adicional en Android/Web: registrar un **Services ID**, configurar dominios/Redirect URIs y generar una **Private Key (`.p8`)** anotando el **Key ID** y **Team ID**.
3. **Xcode (`ios/Runner.xcworkspace`):**
   * En **Signing & Capabilities** añadir **Sign in with Apple** (genera `Runner.entitlements`).
   * Garantizar `iOS Deployment Target >= 13.0`.
4. **Firebase / Backend:**
   * En **Firebase Console ➔ Authentication ➔ Sign-in method**, habilitar el proveedor **Apple** (y cargar Service ID, Team ID, Key ID y `.p8` si se soporta Android/Web).
5. **Integración en Flutter (`AuthService`):**
   * Usar `sign_in_with_apple` o `OAuthProvider('apple.com')` en `firebase_auth` enviando el `identityToken` y `authorizationCode` al backend (`POST /v1/auth/apple` o Firebase).

### ⚠️ Particularidades Críticas de Apple
* **Nombre y correo solo en el primer inicio de sesión:** Apple únicamente envía `fullName` y `email` la **primera vez** que el usuario autoriza la app. En inicios posteriores solo retorna el identificador (`userIdentifier`), por lo que es obligatorio persistirlos inmediatamente en base de datos.
* **Hide My Email (Relay privado):** La app y el backend deben aceptar correos anonimizados del formato `@privaterelay.appleid.com`.
* **Política App Store (Guideline 4.8):** Al ofrecer login con Google, Apple exige obligatoriamente ofrecer también **Sign in with Apple** con igual prominencia visual para aprobar la publicación en iOS.

