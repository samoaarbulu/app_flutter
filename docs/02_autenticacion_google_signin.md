# 🔐 02. Autenticación y Google Sign-In Multiplataforma

Esta guía detalla la implementación completa de **Firebase Authentication** y **Google Sign-In** para aplicaciones Flutter, incluyendo la solución técnica definitiva para soportar tanto **Web (Chrome)** como **Móvil (Android / iOS)** sin errores de configuración.

---

## 1. Requisitos Previos en Firebase

1. **Crear proyecto:** Entrar a [console.firebase.google.com](https://console.firebase.google.com/) y crear un nuevo proyecto.
2. **Habilitar el proveedor de Google:**
   - Ir a **Authentication** > pestaña **Sign-in method**.
   - Seleccionar **Google** > habilitar el interruptor y seleccionar el correo de soporte.
   - Guardar.
3. **Configurar FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Esto genera automáticamente el archivo `lib/firebase_options.dart` con las credenciales para Web, Android e iOS.

---

## 2. Dependencias en `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.12.1
  firebase_auth: ^5.5.1
  google_sign_in: ^6.2.2
```

Ejecutar en la terminal:
```bash
flutter pub get
```

---

## 3. Inicialización en `lib/main.dart`

Antes de correr cualquier widget, Firebase debe inicializarse de forma asíncrona:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

---

## 4. El "Secreto" Multiplataforma (Web vs Móvil)

> [!WARNING]
> **Error común:** En Flutter Web, usar `GoogleSignIn().signIn()` provoca el error:
> `Assertion failed: appClientId != null "ClientID not set. Either set it on a <meta name='google-signin-client_id' ..."`
> 
> **La Solución Oficial de Firebase:**
> - En **Web (`kIsWeb`)**: Se debe usar **`FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())`**. Esta función utiliza la configuración web de Firebase (`authDomain`), desplegando la ventana emergente oficial de Google sin requerir etiquetas meta adicionales en `index.html`.
> - En **Móvil (Android/iOS)**: Se utiliza el flujo nativo con **`GoogleSignIn().signIn()`** para obtener los tokens OAuth (`accessToken` e `idToken`).

---

## 5. Implementación del Servicio: `AuthService`

Copia este archivo en `lib/features/auth/services/auth_service.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio singleton de autenticación con soporte Web y Móvil.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;

  /// Stream para escuchar cambios en la sesión
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inicio de sesión unificado con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. En Web: Flujo de Popup oficial de Firebase
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      }

      // 2. En Móvil: Flujo nativo interactivo
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // El usuario canceló la selección de cuenta
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error en signInWithGoogle: $e');
      rethrow;
    }
  }

  /// Cierre de sesión en Firebase y en Google
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}
```

---

## 6. Flujo de Pantallas de Autenticación

El proyecto implementa un flujo en 3 etapas:

1. **`PresentationScreen` ([presentacion.dart](file:///c:/Users/Chuwi%20PC/Documents/Proyectos%20Flutter/demo-samoa/lib/features/auth/presentation/screens/presentacion.dart)):**
   - Pantalla de presentación / splash con el logotipo centrado.
   - Contiene un `Timer` automático de **2 segundos** en `initState()` que redirige a `AuthLandingScreen` sin requerir toques manuales.

2. **`AuthLandingScreen` ([auth_landing.dart](file:///c:/Users/Chuwi%20PC/Documents/Proyectos%20Flutter/demo-samoa/lib/features/auth/presentation/screens/auth_landing.dart)):**
   - Muestra el encabezado centrado y tres botones de acción estilo píldora (56px de alto):
     - **`login with Google`**: Invoca `AuthService.instance.signInWithGoogle()`. Muestra un spinner circular mientras autentica y redirige a `HomeScreen` al terminar con éxito. Incluye el isotipo vectorial oficial de Google en blanco puro (`_GoogleWhiteIcon`).
     - **`Sign in with Apple`**: Opción social secundaria con `Icons.apple`.
     - **`Sign up with email`**: Botón primario en color `#A3C7D6` que abre la pantalla de login tradicional.
     - **`Already have an account? Sign in`**: Enlace al pie que también conduce a la pantalla de login.

3. **`LoginScreen` ([login.dart](file:///c:/Users/Chuwi%20PC/Documents/Proyectos%20Flutter/demo-samoa/lib/features/auth/presentation/screens/login.dart)):**
   - Formulario tradicional con inputs para email, contraseña con visibilidad alternable y botón de acción.

---

## 7. Checklist para Replicar en un Proyecto Nuevo

- [ ] Instalar `firebase_core`, `firebase_auth` y `google_sign_in`.
- [ ] Ejecutar `flutterfire configure`.
- [ ] Habilitar proveedor Google en Firebase Console.
- [ ] En Android: Agregar la huella digital **SHA-1** en la configuración de la app en Firebase Console (obtenida con `./gradlew signingReport`).
- [ ] Copiar `lib/features/auth/services/auth_service.dart`.
- [ ] Inicializar Firebase en `main.dart`.

