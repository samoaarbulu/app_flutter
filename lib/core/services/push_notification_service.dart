import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'creds_api_service.dart';
import 'firebase_initializer.dart';

/// Servicio centralizado para permisos push y sincronización de `fcmToken`
/// con `POST /v1/users/me/devices` y `DELETE /v1/users/me/devices`.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _lastSyncedToken;

  bool get _isWidgetTest => WidgetsBinding.instance.runtimeType
      .toString()
      .contains('TestWidgetsFlutterBinding');

  bool get _isAuthorizedStatus =>
      _lastSettings?.authorizationStatus == AuthorizationStatus.authorized ||
      _lastSettings?.authorizationStatus == AuthorizationStatus.provisional;

  NotificationSettings? _lastSettings;

  void _ensureTokenRefreshListener() {
    if (_isWidgetTest || _tokenRefreshSubscription != null) return;
    if (Firebase.apps.isEmpty) return;

    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (newToken.trim().isEmpty) return;
      _syncSpecificToken(newToken.trim());
    });
  }

  Future<void> _syncSpecificToken(String token) async {
    if (!CredsApiService.instance.hasSession) return;
    try {
      await CredsApiService.instance.registerDeviceToken(fcmToken: token);
      _lastSyncedToken = token;
      debugPrint('✅ FCM token sincronizado con backend.');
    } catch (e) {
      debugPrint('⚠️ No se pudo registrar FCM token en backend: $e');
    }
  }

  /// Solicita permiso nativo de notificaciones y, si se concede, sincroniza el token.
  Future<bool> requestPermissionAndSync() async {
    if (_isWidgetTest) return true;

    try {
      if (!FirebaseInitializer.hasStarted) {
        await FirebaseInitializer.initialize();
      }
      if (Firebase.apps.isEmpty) return false;

      _lastSettings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (!_isAuthorizedStatus) {
        return false;
      }

      _ensureTokenRefreshListener();
      await syncTokenWithBackend();
      return true;
    } catch (e) {
      debugPrint('ℹ️ Error al solicitar permiso de notificaciones: $e');
      return false;
    }
  }

  /// Sincroniza el `fcmToken` actual si la app ya tiene permiso y sesión activa.
  Future<void> syncTokenWithBackend() async {
    if (_isWidgetTest || !CredsApiService.instance.hasSession) return;

    try {
      if (Firebase.apps.isEmpty) return;

      _ensureTokenRefreshListener();
      _lastSettings ??=
          await FirebaseMessaging.instance.getNotificationSettings();
      if (!_isAuthorizedStatus) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) return;

      await _syncSpecificToken(token.trim());
    } catch (e) {
      debugPrint('ℹ️ No se pudo obtener/sincronizar FCM token: $e');
    }
  }

  /// Desvincula el `fcmToken` actual del backend (usado en logout o al desactivar push).
  Future<void> unregisterCurrentToken() async {
    if (_isWidgetTest || !CredsApiService.instance.hasSession) return;

    try {
      String? token = _lastSyncedToken;
      if ((token == null || token.isEmpty) && Firebase.apps.isNotEmpty) {
        token = await FirebaseMessaging.instance.getToken();
      }
      if (token == null || token.trim().isEmpty) return;

      await CredsApiService.instance.unregisterDeviceToken(
        fcmToken: token.trim(),
      );
      _lastSyncedToken = null;
      debugPrint('✅ FCM token desvinculado del backend.');
    } catch (e) {
      debugPrint('⚠️ No se pudo desvincular FCM token del backend: $e');
    }
  }
}
