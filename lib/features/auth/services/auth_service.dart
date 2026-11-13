import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio singleton de autenticación con soporte para Web y Móvil (Android/iOS).
///
/// Implementa:
/// - **Web:** Flujo oficial con `signInWithPopup(GoogleAuthProvider())` sin errores de ClientID.
/// - **Móvil:** Selector nativo con `GoogleSignIn().signIn()` y canje de credenciales OAuth.
/// - **Resiliencia:** Verificación previa de inicialización de Firebase (`Firebase.apps.isNotEmpty`).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth? get _auth {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Usuario actualmente autenticado
  User? get currentUser => _auth?.currentUser;

  /// Stream reactivo para escuchar cambios en la sesión
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  /// Inicia sesión unificado con Google
  Future<UserCredential?> signInWithGoogle() async {
    if (Firebase.apps.isEmpty) {
      debugPrint(
        '⚠️ Firebase no ha sido inicializado. Ejecuta "flutterfire configure" para vincular tu proyecto.',
      );
      throw FirebaseException(
        plugin: 'firebase_auth',
        message:
            'Firebase no inicializado. Vincula tu proyecto con flutterfire configure.',
      );
    }

    try {
      // 1. En Web: Flujo de Popup oficial de Firebase
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth!.signInWithPopup(googleProvider);
      }

      // 2. En Móvil (Android/iOS): Flujo nativo interactivo
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

      return await _auth!.signInWithCredential(credential);
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
    await _auth?.signOut();
  }
}

