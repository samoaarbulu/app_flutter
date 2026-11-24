import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/home/models/home_feed_item.dart';
import '../../features/onboarding/models/onboarding_place.dart';
import '../config/app_config.dart';
import 'media_service.dart';
import 'push_notification_service.dart';

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
  final bool hasContactsPermission;
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
    this.hasContactsPermission = false,
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
      hasContactsPermission: json['hasContactsPermission'] == true,
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
    if ((user ?? _currentUser)?.profileCompleted == true) {
      unawaited(PushNotificationService.instance.syncTokenWithBackend());
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
    bool clearAvatar = false,
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
    if (clearAvatar) {
      body['avatarUrl'] = null;
    } else if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
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
    bool? contactsPermissionGranted,
    bool? notificationsPermissionGranted,
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
    if (contactsPermissionGranted != null) {
      body['contactsPermissionGranted'] = contactsPermissionGranted;
    }
    if (notificationsPermissionGranted != null) {
      body['notificationsPermissionGranted'] = notificationsPermissionGranted;
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

  /// `POST /v1/users/me/devices`
  /// Registra o actualiza el `fcmToken` del dispositivo actual en el backend.
  Future<void> registerDeviceToken({
    required String fcmToken,
    String? deviceName,
  }) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para registrar dispositivo.',
        isNetworkOrOfflineError: true,
      );
    }

    final body = <String, dynamic>{
      'fcmToken': fcmToken,
    };
    if (_devicePlatform == 'ios' || _devicePlatform == 'android') {
      body['platform'] = _devicePlatform;
    }
    if (deviceName != null && deviceName.trim().isNotEmpty) {
      body['deviceName'] = deviceName.trim();
    }

    await _sendJson(
      method: 'POST',
      path: '/users/me/devices',
      requiresAuth: true,
      body: body,
    );
  }

  /// `DELETE /v1/users/me/devices`
  /// Desvincula el `fcmToken` del dispositivo (logout o al desactivar push).
  Future<void> unregisterDeviceToken({required String fcmToken}) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para desvincular dispositivo.',
        isNetworkOrOfflineError: true,
      );
    }

    await _sendJson(
      method: 'DELETE',
      path: '/users/me/devices',
      requiresAuth: true,
      body: {'fcmToken': fcmToken},
    );
  }

  // ---------------------------------------------------------------------------
  // ENDPOINTS DE PLACES Y ONBOARDING DUELS (`/v1/places/*`, `/v1/users/onboarding/*`)
  // ---------------------------------------------------------------------------

  /// `GET /v1/places/search` buscando por nombre/marca (`q`), localidad (`locality`)
  /// y categoría (`category`) en paralelo para unificar resultados en un solo buscador.
  Future<List<OnboardingPlace>> searchPlaces({
    required String query,
    int limit = 20,
  }) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para buscar lugares en backend.',
        isNetworkOrOfflineError: true,
      );
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      final json = await _sendJson(
        method: 'GET',
        path: '/places/search',
        queryParameters: {'limit': limit.toString()},
        requiresAuth: true,
      );
      return _parsePlacesItems(json);
    }

    final requests = <Future<Map<String, dynamic>>>[
      _sendJson(
        method: 'GET',
        path: '/places/search',
        queryParameters: {
          'q': trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed,
          'limit': limit.toString(),
        },
        requiresAuth: true,
      ),
      if (trimmed.length <= 80)
        _sendJson(
          method: 'GET',
          path: '/places/search',
          queryParameters: {
            'locality': trimmed,
            'limit': limit.toString(),
          },
          requiresAuth: true,
        ),
      if (trimmed.length <= 80)
        _sendJson(
          method: 'GET',
          path: '/places/search',
          queryParameters: {
            'category': trimmed.toLowerCase(),
            'limit': limit.toString(),
          },
          requiresAuth: true,
        ),
    ];

    final responses = await Future.wait(requests);
    final seenIds = <String>{};
    final merged = <OnboardingPlace>[];

    for (final json in responses) {
      for (final place in _parsePlacesItems(json)) {
        if (seenIds.add(place.id)) {
          merged.add(place);
        }
      }
    }

    return merged.take(limit).toList();
  }

  List<OnboardingPlace> _parsePlacesItems(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) {
      return const [];
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(OnboardingPlace.fromApiJson)
        .toList();
  }

  /// `POST /v1/users/onboarding/duels/prepare`
  Future<void> prepareOnboardingDuels(List<String> placeIds) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para preparar duelos en backend.',
        isNetworkOrOfflineError: true,
      );
    }

    await _sendJson(
      method: 'POST',
      path: '/users/onboarding/duels/prepare',
      requiresAuth: true,
      body: {'placeIds': placeIds},
    );
  }

  /// `POST /v1/users/onboarding/ranking` con duelos A/B completados.
  Future<CredsUserRankingResponse> submitOnboardingRanking({
    required List<String> placeIds,
    required List<CredsDuelComparisonInput> comparisons,
  }) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para guardar el ranking en backend.',
        isNetworkOrOfflineError: true,
      );
    }

    final json = await _sendJson(
      method: 'POST',
      path: '/users/onboarding/ranking',
      requiresAuth: true,
      body: {
        'placeIds': placeIds,
        'comparisons': comparisons.map((c) => c.toJson()).toList(),
        'skipped': false,
      },
    );
    return CredsUserRankingResponse.fromJson(json);
  }

  /// `GET /v1/users/me/ranking` — consulta el ranking guardado del usuario autenticado.
  Future<CredsUserRankingResponse> getUserRanking() async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para consultar el ranking en backend.',
        isNetworkOrOfflineError: true,
      );
    }

    final json = await _sendJson(
      method: 'GET',
      path: '/users/me/ranking',
      requiresAuth: true,
    );
    return CredsUserRankingResponse.fromJson(json);
  }

  /// `POST /v1/users/onboarding/ranking` con `skipped: true`
  Future<void> skipOnboardingRanking() async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para omitir el ranking en backend.',
        isNetworkOrOfflineError: true,
      );
    }

    await _sendJson(
      method: 'POST',
      path: '/users/onboarding/ranking',
      requiresAuth: true,
      body: {'skipped': true},
    );
  }

  /// `GET /v1/users/suggestions`
  Future<List<CredsSuggestedUser>> getSuggestions() async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para cargar sugerencias en backend.',
        isNetworkOrOfflineError: true,
      );
    }

    final json = await _sendJson(
      method: 'GET',
      path: '/users/suggestions',
      requiresAuth: true,
    );

    final rawItems = json['items'];
    if (rawItems is! List) {
      return const [];
    }
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(CredsSuggestedUser.fromJson)
        .toList();
  }

  /// `POST /v1/users/onboarding/follows` — finaliza onboarding (`profileCompleted = true`).
  Future<CredsUserProfile> completeOnboardingFollows(
    List<String> targetUserIds,
  ) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para finalizar onboarding en backend.',
        isNetworkOrOfflineError: true,
      );
    }

    final json = await _sendJson(
      method: 'POST',
      path: '/users/onboarding/follows',
      requiresAuth: true,
      body: {'targetUserIds': targetUserIds},
    );
    final profile = CredsUserProfile.fromJson(json);
    _currentUser = profile;
    return profile;
  }

  /// `GET /v1/users/invite-link`
  Future<CredsInviteLinkResponse> getInviteLink() async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para obtener enlace de invitación.',
        isNetworkOrOfflineError: true,
      );
    }

    final json = await _sendJson(
      method: 'GET',
      path: '/users/invite-link',
      requiresAuth: true,
    );
    return CredsInviteLinkResponse.fromJson(json);
  }

  /// `POST /v1/users/contacts/match` (envía en lotes de máximo 200 contactos).
  Future<CredsMatchContactsResponse> matchContacts(
    List<CredsContactMatchInput> contacts,
  ) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para cruzar contactos en backend.',
        isNetworkOrOfflineError: true,
      );
    }

    if (contacts.isEmpty) {
      final link = await getInviteLink();
      return CredsMatchContactsResponse(
        onCreds: const [],
        toInvite: const [],
        inviteUrl: link.inviteUrl,
        shareMessage: link.shareMessage,
      );
    }

    final onCredsById = <String, CredsSuggestedUser>{};
    final toInvite = <CredsInvitableContact>[];
    var inviteUrl = '';
    var shareMessage = '';

    const batchSize = 200;
    for (var i = 0; i < contacts.length; i += batchSize) {
      final end = (i + batchSize < contacts.length)
          ? i + batchSize
          : contacts.length;
      final batch = contacts.sublist(i, end);

      final json = await _sendJson(
        method: 'POST',
        path: '/users/contacts/match',
        requiresAuth: true,
        body: {
          'contacts': batch.map((c) => c.toJson()).toList(),
        },
      );

      final parsed = CredsMatchContactsResponse.fromJson(json);
      for (final user in parsed.onCreds) {
        onCredsById[user.id] = user;
      }
      toInvite.addAll(parsed.toInvite);
      if (parsed.inviteUrl.isNotEmpty) inviteUrl = parsed.inviteUrl;
      if (parsed.shareMessage.isNotEmpty) shareMessage = parsed.shareMessage;
    }

    return CredsMatchContactsResponse(
      onCreds: onCredsById.values.toList(),
      toInvite: toInvite,
      inviteUrl: inviteUrl,
      shareMessage: shareMessage,
    );
  }

  /// `POST /v1/users/invites`
  Future<void> createUserInvite({
    String? contactName,
    String? contactPhone,
    String? contactEmail,
  }) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para registrar invitación.',
        isNetworkOrOfflineError: true,
      );
    }

    final body = <String, dynamic>{};
    if (contactName != null && contactName.trim().isNotEmpty) {
      body['contactName'] = contactName.trim();
    }
    if (contactPhone != null && contactPhone.trim().isNotEmpty) {
      body['contactPhone'] = contactPhone.trim();
    }
    if (contactEmail != null && contactEmail.trim().isNotEmpty) {
      body['contactEmail'] = contactEmail.trim();
    }

    await _sendJson(
      method: 'POST',
      path: '/users/invites',
      requiresAuth: true,
      body: body,
    );
  }

  // ---------------------------------------------------------------------------
  // ENDPOINTS DE MEDIA (`/v1/media/*`)
  // ---------------------------------------------------------------------------

  /// `POST /v1/media/presign`
  Future<CredsPresignMediaResponse> presignMediaUpload({
    required String purpose,
    required String contentType,
    int? fileSizeBytes,
  }) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para subir archivos.',
        isNetworkOrOfflineError: true,
      );
    }

    final body = <String, dynamic>{
      'purpose': purpose,
      'contentType': contentType,
    };
    if (fileSizeBytes != null && fileSizeBytes > 0) {
      body['fileSizeBytes'] = fileSizeBytes;
    }

    final json = await _sendJson(
      method: 'POST',
      path: '/media/presign',
      requiresAuth: true,
      body: body,
    );
    return CredsPresignMediaResponse.fromJson(json);
  }

  /// Sube un avatar a Cloudflare R2 vía URL prefirmada y devuelve `publicUrl`.
  Future<String> uploadAvatarImage(PickedImage image) async {
    final contentType = _resolveImageContentType(image);
    final presign = await presignMediaUpload(
      purpose: 'avatar',
      contentType: contentType,
      fileSizeBytes: image.sizeInBytes,
    );

    try {
      final putResponse = await _client
          .put(
            Uri.parse(presign.uploadUrl),
            headers: presign.requiredHeaders,
            body: image.bytes,
          )
          .timeout(const Duration(seconds: 30));

      if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
        throw CredsApiException(
          statusCode: putResponse.statusCode,
          message:
              'No se pudo subir la foto de perfil (${putResponse.statusCode}).',
        );
      }
      return presign.publicUrl;
    } on CredsApiException {
      rethrow;
    } catch (e) {
      throw CredsApiException(
        message: 'Error de red al subir la foto: $e',
        isNetworkOrOfflineError: true,
      );
    }
  }

  /// `DELETE /v1/media`
  Future<void> deleteMedia(String key) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para eliminar archivos.',
        isNetworkOrOfflineError: true,
      );
    }

    await _sendJson(
      method: 'DELETE',
      path: '/media',
      requiresAuth: true,
      body: {'key': key},
    );
  }

  String _resolveImageContentType(PickedImage image) {
    final mime = image.mimeType?.toLowerCase().trim();
    if (mime == 'image/png' || mime == 'image/webp' || mime == 'image/jpeg') {
      return mime!;
    }
    if (mime == 'image/jpg') return 'image/jpeg';

    final lowerName = image.name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  // ---------------------------------------------------------------------------
  // ENDPOINTS DE FEED (`/v1/feed`)
  // ---------------------------------------------------------------------------

  /// `GET /v1/feed?tab=...&limit=...&offset=...`
  Future<List<HomeFeedItem>> getFeed({
    String tab = 'all',
    int limit = 20,
    int offset = 0,
  }) async {
    if (!hasSession) {
      throw const CredsApiException(
        statusCode: 401,
        message: 'Sin sesión activa para cargar el feed.',
        isNetworkOrOfflineError: true,
      );
    }

    final json = await _sendJson(
      method: 'GET',
      path: '/feed',
      queryParameters: {
        'tab': tab,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
      requiresAuth: true,
    );

    final rawItems = json['items'];
    if (rawItems is! List) {
      return const [];
    }
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(HomeFeedItem.fromApiJson)
        .toList();
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
        case 'DELETE':
          response = await _client
              .delete(
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

/// Resultado individual de un duelo A/B para enviar a `POST /v1/users/onboarding/ranking`.
class CredsDuelComparisonInput {
  final String placeAId;
  final String placeBId;

  /// `'place_a'`, `'place_b'` o `'tie'`.
  final String outcome;

  const CredsDuelComparisonInput({
    required this.placeAId,
    required this.placeBId,
    required this.outcome,
  });

  Map<String, dynamic> toJson() => {
        'placeAId': placeAId,
        'placeBId': placeBId,
        'outcome': outcome,
      };
}

/// Respuesta de `POST /v1/users/onboarding/ranking` y `GET /v1/users/me/ranking`.
class CredsUserRankingResponse {
  final bool skipped;
  final String onboardingStep;
  final List<RankedPlace> items;

  const CredsUserRankingResponse({
    required this.skipped,
    required this.onboardingStep,
    required this.items,
  });

  factory CredsUserRankingResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(RankedPlace.fromApiJson)
            .toList()
        : const <RankedPlace>[];

    return CredsUserRankingResponse(
      skipped: json['skipped'] as bool? ?? false,
      onboardingStep: (json['onboardingStep'] ?? '').toString(),
      items: items,
    );
  }
}

/// Elemento de sugerencia de usuario devuelto por `GET /v1/users/suggestions`.
class CredsSuggestedUser {
  final String id;
  final String displayName;
  final String initials;
  final String? avatarUrl;
  final String placesLabel;
  final bool isFollowing;

  const CredsSuggestedUser({
    required this.id,
    required this.displayName,
    required this.initials,
    this.avatarUrl,
    required this.placesLabel,
    required this.isFollowing,
  });

  factory CredsSuggestedUser.fromJson(Map<String, dynamic> json) {
    return CredsSuggestedUser(
      id: (json['id'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      initials: (json['initials'] ?? 'CR').toString(),
      avatarUrl: json['avatarUrl'] as String?,
      placesLabel: (json['placesLabel'] ?? '').toString(),
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }
}

/// Respuesta de `POST /v1/media/presign`.
class CredsPresignMediaResponse {
  final String key;
  final String uploadUrl;
  final String publicUrl;
  final int expiresInSeconds;
  final Map<String, String> requiredHeaders;

  const CredsPresignMediaResponse({
    required this.key,
    required this.uploadUrl,
    required this.publicUrl,
    required this.expiresInSeconds,
    required this.requiredHeaders,
  });

  factory CredsPresignMediaResponse.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['requiredHeaders'];
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((k, v) {
        headers[k.toString()] = v.toString();
      });
    }

    return CredsPresignMediaResponse(
      key: (json['key'] ?? '').toString(),
      uploadUrl: (json['uploadUrl'] ?? '').toString(),
      publicUrl: (json['publicUrl'] ?? '').toString(),
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 300,
      requiredHeaders: headers,
    );
  }
}

/// Contacto enviado a `POST /v1/users/contacts/match`.
class CredsContactMatchInput {
  final String name;
  final String? phoneNumber;
  final String? email;

  const CredsContactMatchInput({
    required this.name,
    this.phoneNumber,
    this.email,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': name};
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      map['phoneNumber'] = phoneNumber!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      map['email'] = email!.trim();
    }
    return map;
  }
}

/// Contacto invitable devuelto por `POST /v1/users/contacts/match`.
class CredsInvitableContact {
  final String name;
  final String? phoneNumber;
  final String? email;
  final bool alreadyInvited;

  const CredsInvitableContact({
    required this.name,
    this.phoneNumber,
    this.email,
    required this.alreadyInvited,
  });

  factory CredsInvitableContact.fromJson(Map<String, dynamic> json) {
    return CredsInvitableContact(
      name: (json['name'] ?? '').toString(),
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      alreadyInvited: json['alreadyInvited'] as bool? ?? false,
    );
  }
}

/// Respuesta de `GET /v1/users/invite-link`.
class CredsInviteLinkResponse {
  final String inviteCode;
  final String inviteUrl;
  final String shareMessage;

  const CredsInviteLinkResponse({
    required this.inviteCode,
    required this.inviteUrl,
    required this.shareMessage,
  });

  factory CredsInviteLinkResponse.fromJson(Map<String, dynamic> json) {
    return CredsInviteLinkResponse(
      inviteCode: (json['inviteCode'] ?? '').toString(),
      inviteUrl: (json['inviteUrl'] ?? '').toString(),
      shareMessage: (json['shareMessage'] ?? '').toString(),
    );
  }
}

/// Respuesta de `POST /v1/users/contacts/match`.
class CredsMatchContactsResponse {
  final List<CredsSuggestedUser> onCreds;
  final List<CredsInvitableContact> toInvite;
  final String inviteUrl;
  final String shareMessage;

  const CredsMatchContactsResponse({
    required this.onCreds,
    required this.toInvite,
    required this.inviteUrl,
    required this.shareMessage,
  });

  factory CredsMatchContactsResponse.fromJson(Map<String, dynamic> json) {
    final rawOnCreds = json['onCreds'];
    final rawToInvite = json['toInvite'];

    return CredsMatchContactsResponse(
      onCreds: rawOnCreds is List
          ? rawOnCreds
              .whereType<Map<String, dynamic>>()
              .map(CredsSuggestedUser.fromJson)
              .toList()
          : const [],
      toInvite: rawToInvite is List
          ? rawToInvite
              .whereType<Map<String, dynamic>>()
              .map(CredsInvitableContact.fromJson)
              .toList()
          : const [],
      inviteUrl: (json['inviteUrl'] ?? '').toString(),
      shareMessage: (json['shareMessage'] ?? '').toString(),
    );
  }
}
