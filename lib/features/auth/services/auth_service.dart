import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/creds_api_service.dart';
import '../../../core/services/push_notification_service.dart';

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

  /// Foto de perfil personalizada seleccionada localmente
  PickedImage? _customPhoto;
  PickedImage? get customPhoto => _customPhoto;

  /// Actualiza la foto de perfil personalizada en memoria
  void setCustomPhoto(PickedImage? photo) {
    _customPhoto = photo;
  }

  /// Usuario actualmente autenticado en Firebase (puede tardar unos ms en hidratarse en Web).
  User? get currentUser => _auth?.currentUser;

  /// Stream reactivo para escuchar cambios en la sesión de Firebase.
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  /// Indica si Firebase ya fue inicializado en este arranque.
  bool get isFirebaseReady => _auth != null;

  /// Espera a que Firebase restaure la sesión guardada en disco / IndexedDB.
  ///
  /// En Web, la respuesta `GetAccountInfoResponse` tarda unos milisegundos tras iniciar.
  Future<User?> waitForRestoredUser({
    Duration timeout = const Duration(milliseconds: 1200),
  }) async {
    final auth = _auth;
    if (auth == null) return null;

    // Si ya está disponible en memoria, lo devolvemos al instante.
    if (auth.currentUser != null) return auth.currentUser;

    try {
      // Escuchamos la primera emisión del estado de sesión tras hidratar caché local.
      return await auth.authStateChanges().first.timeout(timeout);
    } catch (_) {
      return auth.currentUser;
    }
  }

  /// Toma el `idToken` del usuario de Firebase y crea/renueva su sesión en el backend CREDS.
  Future<CredsUserProfile?> syncFirebaseUserWithBackend([
    User? firebaseUser,
  ]) async {
    final targetUser = firebaseUser ?? _auth?.currentUser;
    if (targetUser == null) return null;

    // Obtenemos el JWT firmado por Firebase para autenticar contra POST /v1/auth/social.
    final firebaseIdToken = await targetUser.getIdToken();
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      return null;
    }

    // Separamos nombre y apellido solo como apoyo inicial si es cuenta nueva.
    final nameParts = (targetUser.displayName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final firstName = nameParts.isNotEmpty ? nameParts.first : null;
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;

    final authResponse = await CredsApiService.instance.socialAuth(
      provider: 'google',
      idToken: firebaseIdToken,
      firstName: firstName,
      lastName: lastName,
    );
    return authResponse.user;
  }

  /// Inicia sesión unificado con Google y sincroniza con el backend CREDS.
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
      // 1. En Web: flujo oficial mediante ventana emergente de Google.
      UserCredential userCredential;
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth!.signInWithPopup(googleProvider);
      } else {
        // 2. En Móvil (Android/iOS): selector nativo del sistema.
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return null; // El usuario canceló la selección de cuenta.
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth!.signInWithCredential(credential);
      }

      // 3. Canjeamos el token de Firebase por la sesión JWT de nuestro backend.
      try {
        await syncFirebaseUserWithBackend(userCredential.user);
      } on CredsApiException catch (e) {
        if (!e.isNetworkOrOfflineError ||
            !CredsApiService.instance.offlineFallbackEnabled) {
          rethrow;
        }
        debugPrint('⚠️ Backend offline tras Google Sign-In: ${e.message}');
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error en signInWithGoogle: $e');
      rethrow;
    }
  }

  /// Cierre de sesión en CREDS Backend, Firebase y Google
  Future<void> signOut() async {
    _customPhoto = null;
    await PushNotificationService.instance.unregisterCurrentToken();
    CredsApiService.instance.clearSession();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth?.signOut();
  }
}

