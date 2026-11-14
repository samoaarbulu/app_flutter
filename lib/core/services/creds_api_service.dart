import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Excepción tipada para errores al comunicarse con CREDS Core API (`/v1`).
class CredsApiException implements Exception {
  final int? statusCode;
  final String message;

  /// `true` cuando no hubo respuesta JSON del servidor (offline, servidor local
  /// apagado o entorno de widget tests sin backend real).
  final bool isNetworkOrOfflineError;

  const CredsApiException({
    this.statusCode,
    required this.message,
    this.isNetworkOrOfflineError = false,
  });

  @override
  String toString() =>
      'CredsApiException(statusCode: $statusCode, offline: $isNetworkOrOfflineError, message: $message)';
}

/// Perfil de usuario retornado por `GET /v1/auth/me` y endpoints `/v1/users/*`.
class CredsUserProfile {
  final String id;
  final String email;
  final bool emailVerified;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final String primaryCity;

  /// Valores oficiales del backend:
  /// `'verify_email'`, `'add_photo'`, `'setup_profile'`,
  /// `'location_permission'`, `'activities'`, `'completed'`.
  final String onboardingStep;
  final bool profileCompleted;
  final bool hasLocationPermission;
  final List<String> activities;

  const CredsUserProfile({
    required this.id,
    required this.email,
    required this.emailVerified,
    this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    required this.primaryCity,
    required this.onboardingStep,
    required this.profileCompleted,
    required this.hasLocationPermission,
    required this.activities,
  });

  factory CredsUserProfile.fromJson(Map<String, dynamic> json) {
    final rawActivities = json['activities'];
    return CredsUserProfile(
      id: (json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      emailVerified: json['emailVerified'] == true,
      username: json['username'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      primaryCity: (json['primaryCity'] ?? 'Miami') as String,
      onboardingStep: (json['onboardingStep'] ?? 'verify_email') as String,
      profileCompleted: json['profileCompleted'] == true,
      hasLocationPermission: json['hasLocationPermission'] == true,
      activities: rawActivities is List
          ? rawActivities.map((item) => item.toString()).toList()
          : const <String>[],
    );
  }

  String get displayName {
    final full = [firstName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (full.isNotEmpty) return full;
    if (username != null && username!.isNotEmpty) return '@$username';
    return email;
  }
}

/// Par de tokens JWT + refresh emitido por `/v1/auth/*`.
class CredsAuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const CredsAuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresIn,
  });

  factory CredsAuthTokens.fromJson(Map<String, dynamic> json) {
    return CredsAuthTokens(
      accessToken: (json['accessToken'] ?? '') as String,
      refreshToken: (json['refreshToken'] ?? '') as String,
      tokenType: (json['tokenType'] ?? 'Bearer') as String,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 3600,
    );
  }
}

/// Respuesta unificada de sesión (`/verify-otp`, `/login`, `/social`, `/refresh`).
class CredsAuthResponse {
  final CredsAuthTokens tokens;
  final bool? isNewUser;
  final CredsUserProfile user;

  const CredsAuthResponse({
    required this.tokens,
    this.isNewUser,
    required this.user,
  });

  factory CredsAuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = (json['user'] as Map<String, dynamic>?) ?? const {};
    return CredsAuthResponse(
      tokens: CredsAuthTokens.fromJson(json),
      isNewUser: json['isNewUser'] as bool?,
      user: CredsUserProfile.fromJson(userJson),
    );
  }
}

/// Respuesta de inicio de registro y reenvío OTP.
class CredsRegisterStartResponse {
  final String message;
  final String email;
  final int expiresInSeconds;
  final int resendAvailableInSeconds;
  final String? devOtpCode;

  const CredsRegisterStartResponse({
    required this.message,
    required this.email,
    required this.expiresInSeconds,
    required this.resendAvailableInSeconds,
    this.devOtpCode,
  });

  factory CredsRegisterStartResponse.fromJson(Map<String, dynamic> json) {
    return CredsRegisterStartResponse(
      message: (json['message'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 600,
      resendAvailableInSeconds:
          (json['resendAvailableInSeconds'] as num?)?.toInt() ?? 30,
      devOtpCode: json['devOtpCode'] as String?,
    );
  }
}

/// Elemento del catálogo oficial `GET /v1/users/activities/catalog`.
class CredsActivityCatalogItem {
  final String id;
  final String code;
  final String label;
  final String iconKey;
  final int displayOrder;

  const CredsActivityCatalogItem({
    required this.id,
    required this.code,
    required this.label,
    required this.iconKey,
    required this.displayOrder,
  });

  factory CredsActivityCatalogItem.fromJson(Map<String, dynamic> json) {
    return CredsActivityCatalogItem(
      id: (json['id'] ?? '') as String,
      code: (json['code'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      iconKey: (json['iconKey'] ?? 'sparkles') as String,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Resultado de `GET /v1/users/check-username`.
class CredsCheckUsernameResponse {
  final String username;
  final bool available;

  const CredsCheckUsernameResponse({
    required this.username,
    required this.available,
  });

  factory CredsCheckUsernameResponse.fromJson(Map<String, dynamic> json) {
    return CredsCheckUsernameResponse(
      username: (json['username'] ?? '') as String,
      available: json['available'] == true,
    );
  }
}

/// Cliente HTTP singleton para los endpoints de Autenticación y Usuarios (Hito 1).
class CredsApiService {
  CredsApiService._({http.Client? client}) : _client = client ?? http.Client();

  static final CredsApiService instance = CredsApiService._();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 6);

  /// Permite que las pantallas continúen el flujo visual si no hay servidor
  /// levantado (útil en `flutter test` o revisión UI offline).
  bool offlineFallbackEnabled = true;

  // Tokens guardados en RAM durante la sesión actual (se borran al cerrar/recargar).
  String? _accessToken;
  String? _refreshToken;
  CredsUserProfile? _currentUser;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  CredsUserProfile? get currentUser => _currentUser;

  /// Devuelve `true` si existe un accessToken en memoria listo para enviar en Bearer.
  bool get hasSession => _accessToken != null && _accessToken!.isNotEmpty;

  String get _baseUrl => AppConfig.apiBaseUrl;

  /// Guarda los tokens JWT y el perfil actualizado en memoria RAM.
  void setSession({
    required String accessToken,
    required String refreshToken,
    CredsUserProfile? user,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    if (user != null) {
      _currentUser = user;
    }
  }

  /// Borra tokens y perfil de la memoria (usado en logout o sesión expirada).
  void clearSession() {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
  }

  String get _devicePlatform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  // ---------------------------------------------------------------------------
  // ENDPOINTS DE AUTH (`/v1/auth/*`)
  // ---------------------------------------------------------------------------

  /// `GET /v1/auth/me`
  /// Valida el Bearer actual y, si expiró (401), intenta refrescar una vez.
  Future<CredsUserProfile> getMe() async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'No hay sesión activa.',
      );
    }

    try {
      final json = await _sendJson(
        method: 'GET',
        path: '/auth/me',
        requiresAuth: true,
      );
      final profile = CredsUserProfile.fromJson(json);
      _currentUser = profile;
      return profile;
    } on CredsApiException catch (e) {
      if (e.statusCode == 401 &&
          _refreshToken != null &&
          _refreshToken!.isNotEmpty) {
        await refreshTokens();
        final json = await _sendJson(
          method: 'GET',
          path: '/auth/me',
          requiresAuth: true,
        );
        final profile = CredsUserProfile.fromJson(json);
        _currentUser = profile;
        return profile;
      }
      rethrow;
    }
  }

  /// `POST /v1/auth/refresh`
  Future<CredsAuthResponse> refreshTokens([String? refreshToken]) async {
    final tokenToUse = refreshToken ?? _refreshToken;
    if (tokenToUse == null || tokenToUse.isEmpty) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'No refresh token disponible.',
      );
    }

    final json = await _sendJson(
      method: 'POST',
      path: '/auth/refresh',
      body: {
        'refreshToken': tokenToUse,
        'devicePlatform': _devicePlatform,
      },
    );
    final auth = CredsAuthResponse.fromJson(json);
    setSession(
      accessToken: auth.tokens.accessToken,
      refreshToken: auth.tokens.refreshToken,
      user: auth.user,
    );
    return auth;
  }

  /// `POST /v1/auth/register/start`
  Future<CredsRegisterStartResponse> registerStart({
    required String email,
    required String password,
    bool acceptedTerms = true,
  }) async {
    final json = await _sendJson(
      method: 'POST',
      path: '/auth/register/start',
      body: {
        'email': email.trim(),
        'password': password,
        'acceptedTerms': acceptedTerms,
      },
    );
    return CredsRegisterStartResponse.fromJson(json);
  }

  /// `POST /v1/auth/resend-otp`
  Future<CredsRegisterStartResponse> resendOtp({required String email}) async {
    final json = await _sendJson(
      method: 'POST',
      path: '/auth/resend-otp',
      body: {'email': email.trim()},
    );
    return CredsRegisterStartResponse.fromJson(json);
  }

  /// `POST /v1/auth/verify-otp`
  Future<CredsAuthResponse> verifyOtp({
    required String email,
    required String code,
  }) async {
    final json = await _sendJson(
      method: 'POST',
      path: '/auth/verify-otp',
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'devicePlatform': _devicePlatform,
      },
    );
    final auth = CredsAuthResponse.fromJson(json);
    setSession(
      accessToken: auth.tokens.accessToken,
      refreshToken: auth.tokens.refreshToken,
      user: auth.user,
    );
    return auth;
  }

  /// `POST /v1/auth/login`
  Future<CredsAuthResponse> login({
    required String email,
    required String password,
  }) async {
    final json = await _sendJson(
      method: 'POST',
      path: '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
        'devicePlatform': _devicePlatform,
      },
    );
    final auth = CredsAuthResponse.fromJson(json);
    setSession(
      accessToken: auth.tokens.accessToken,
      refreshToken: auth.tokens.refreshToken,
      user: auth.user,
    );
    return auth;
  }

  /// `POST /v1/auth/social`
  /// Acepta `provider`: `'google'` o `'apple'`.
  Future<CredsAuthResponse> socialAuth({
    required String provider,
    required String idToken,
    String? firstName,
    String? lastName,
  }) async {
    final normalizedProvider = provider.trim().toLowerCase();
    final body = <String, dynamic>{
      'provider': normalizedProvider,
      'idToken': idToken.trim(),
      'devicePlatform': _devicePlatform,
    };
    if (firstName != null && firstName.trim().isNotEmpty) {
      body['firstName'] = firstName.trim();
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      body['lastName'] = lastName.trim();
    }

    final json = await _sendJson(
      method: 'POST',
      path: '/auth/social',
      body: body,
    );
    final auth = CredsAuthResponse.fromJson(json);
    setSession(
      accessToken: auth.tokens.accessToken,
      refreshToken: auth.tokens.refreshToken,
      user: auth.user,
    );
    return auth;
  }

  // ---------------------------------------------------------------------------
  // ENDPOINTS DE USERS (`/v1/users/*`)
  // ---------------------------------------------------------------------------

  /// `GET /v1/users/check-username?username=...`
  Future<CredsCheckUsernameResponse> checkUsernameAvailability(
    String username,
  ) async {
    final cleaned = username.trim().replaceFirst(RegExp(r'^@+'), '');
    final json = await _sendJson(
      method: 'GET',
      path: '/users/check-username',
      queryParameters: {'username': cleaned},
    );
    return CredsCheckUsernameResponse.fromJson(json);
  }

  /// `GET /v1/users/activities/catalog`
  Future<List<CredsActivityCatalogItem>> getActivitiesCatalog() async {
    final decoded = await _sendDynamic(
      method: 'GET',
      path: '/users/activities/catalog',
    );
    if (decoded is! List) {
      throw const CredsApiException(
        message: 'Formato inesperado al obtener el catálogo de actividades.',
      );
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CredsActivityCatalogItem.fromJson)
        .toList();
  }

  /// `PATCH /v1/users/profile/setup`
  Future<CredsUserProfile> setupProfile({
    String? username,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bio,
  }) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para guardar perfil en backend.',
        isNetworkOrOfflineError: true,
      );
    }

    final body = <String, dynamic>{};
    if (username != null) {
      body['username'] = username.trim().replaceFirst(RegExp(r'^@+'), '');
    }
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      body['phoneNumber'] = phoneNumber.trim();
    }
    if (firstName != null) {
      body['firstName'] = firstName.trim();
    }
    if (lastName != null) {
      body['lastName'] = lastName.trim();
    }
    if (avatarUrl != null) {
      body['avatarUrl'] = avatarUrl.trim();
    }
    if (bio != null) {
      body['bio'] = bio.trim();
    }

    final json = await _sendJson(
      method: 'PATCH',
      path: '/users/profile/setup',
      requiresAuth: true,
      body: body,
    );
    final profile = CredsUserProfile.fromJson(json);
    _currentUser = profile;
    return profile;
  }

  /// `PATCH /v1/users/preferences`
  Future<CredsUserProfile> updatePreferences({
    bool? locationPermissionGranted,
    String? primaryCity,
    List<String>? activityCodes,
  }) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para actualizar preferencias en backend.',
        isNetworkOrOfflineError: true,
      );
    }

    final body = <String, dynamic>{};
    if (locationPermissionGranted != null) {
      body['locationPermissionGranted'] = locationPermissionGranted;
    }
    if (primaryCity != null && primaryCity.trim().isNotEmpty) {
      body['primaryCity'] = primaryCity.trim();
    }
    if (activityCodes != null) {
      body['activityCodes'] = activityCodes;
    }

    final json = await _sendJson(
      method: 'PATCH',
      path: '/users/preferences',
      requiresAuth: true,
      body: body,
    );
    final profile = CredsUserProfile.fromJson(json);
    _currentUser = profile;
    return profile;
  }

  // ---------------------------------------------------------------------------
  // TRANSPORTE HTTP PRIVADO
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _sendJson({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final decoded = await _sendDynamic(
      method: method,
      path: path,
      queryParameters: queryParameters,
      body: body,
      requiresAuth: requiresAuth,
    );
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const CredsApiException(
      message: 'Respuesta inesperada del servidor.',
      isNetworkOrOfflineError: true,
    );
  }

  Future<dynamic> _sendDynamic({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final baseUri = Uri.parse('$_baseUrl$path');
    final uri = queryParameters != null && queryParameters.isNotEmpty
        ? baseUri.replace(queryParameters: queryParameters)
        : baseUri;

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (requiresAuth && _accessToken != null && _accessToken!.isNotEmpty)
        'Authorization': 'Bearer $_accessToken',
    };

    try {
      final http.Response response;
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(_requestTimeout);
        case 'POST':
          response = await _client
              .post(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_requestTimeout);
        case 'PATCH':
          response = await _client
              .patch(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_requestTimeout);
        default:
          throw UnsupportedError('HTTP method $method no soportado');
      }

      final dynamic decoded = _tryDecodeJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded == null) {
          throw CredsApiException(
            statusCode: response.statusCode,
            message: 'Respuesta vacía o no JSON del servidor.',
            isNetworkOrOfflineError: true,
          );
        }
        return decoded;
      }

      // En widget tests, Flutter devuelve HTTP 400 con body vacío "".
      if (decoded is! Map<String, dynamic>) {
        throw CredsApiException(
          statusCode: response.statusCode,
          message: 'No se pudo conectar con el servidor CREDS.',
          isNetworkOrOfflineError: true,
        );
      }

      throw CredsApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(decoded, response.statusCode),
        isNetworkOrOfflineError: false,
      );
    } on CredsApiException {
      rethrow;
    } on TimeoutException {
      throw const CredsApiException(
        message: 'Tiempo de espera agotado al conectar con CREDS API.',
        isNetworkOrOfflineError: true,
      );
    } catch (e) {
      debugPrint('CredsApiService [$method $path] network/offline error: $e');
      throw CredsApiException(
        message: 'No fue posible conectar con CREDS API ($e).',
        isNetworkOrOfflineError: true,
      );
    }
  }

  dynamic _tryDecodeJson(String rawBody) {
    final trimmed = rawBody.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(Map<String, dynamic> payload, int statusCode) {
    final rawMessage = payload['message'];
    if (rawMessage is List && rawMessage.isNotEmpty) {
      return rawMessage.map((item) => item.toString()).join('\n');
    }
    if (rawMessage is String && rawMessage.trim().isNotEmpty) {
      return rawMessage.trim();
    }
    final error = payload['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }
    return 'Error HTTP $statusCode en el servidor.';
  }
}
