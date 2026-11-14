# 🔌 06. Integración con Backend CREDS Core API — Hito 1 (Auth & Onboarding)

Este documento explica cómo quedó integrada la aplicación Flutter (`app_flutter`) con el backend oficial **CREDS Core API (NestJS + PostgreSQL `auth_core`)**, respetando al 100% el Design System y las pantallas aprobadas de Figma.

---

## 🎯 Principio de Diseño e Integración

* **Cero cambios visuales:** Ningún color (`AppColors`), tipografía (`AppTypography`), tamaño en `.rem`, borde ni animación fue modificado en las pantallas originales. Únicamente se conectó la capa `<script>` / lógica y navegación hacia la API.
* **Resiliencia Offline y en Widget Tests:** `CredsApiService` detecta cuando no hay servidor backend activo o cuando corre dentro de `flutter test` (`CredsApiException.isNetworkOrOfflineError == true`). En ese caso permite continuar la navegación visual sin bloquear las pruebas ni la revisión de UI, mientras que ante errores reales del servidor (`400`, `401`, `409`) muestra el mensaje exacto mediante `AppFeedback.showError(...)`.

---

## 🏗️ Archivos Principales Agregados / Conectados

| Archivo | Propósito |
| :--- | :--- |
| `lib/core/config/app_config.dart` | Expone `AppConfig.apiBaseUrl`: por defecto apunta a `https://api-dev.getcreds.co/v1` en `dev` (`https://api.getcreds.co/v1` en `prod`) y permite sobreescribir con `--dart-define=API_BASE_URL=...`. |
| `lib/core/services/creds_api_service.dart` | Cliente HTTP singleton (`CredsApiService.instance`), modelos DTO (`CredsUserProfile`, `CredsAuthResponse`, `CredsRegisterStartResponse`, `CredsActivityCatalogItem`, `CredsCheckUsernameResponse`) y manejo de tokens en memoria (`accessToken`, `refreshToken`). |
| `lib/features/auth/services/auth_service.dart` | Tras `signInWithGoogle()` o al restaurar sesión guardada de Firebase desde `PreloadingScreen` (`waitForRestoredUser()`), canjea el `idToken` contra `POST /v1/auth/social` vía `syncFirebaseUserWithBackend()` y limpia todo en `signOut()`. |
| `lib/features/onboarding/navigation/onboarding_navigator.dart` | Mapea `onboardingStep` del backend hacia la pantalla exacta de Flutter (`verify_email`, `add_photo`, `setup_profile`, `location_permission`, `activities`, `completed`). |
| `lib/features/auth/screens/sign_in_screen.dart` | Pantalla nueva **01B Sign in** conectada a `POST /v1/auth/login` y Google OAuth usando los componentes del Design System. |
| `lib/features/home/screens/home_screen.dart` | Pantalla destino al finalizar onboarding (`onboardingStep == 'completed'`), mostrando resumen del perfil y botón `Sign out`. |

---

## 📡 Endpoints Conectados (`/v1`)

Swagger interactivo del servidor DEV: https://api-dev.getcreds.co/docs (cabecera Bearer configurada como `access-token`).

| Método | Ruta Backend | Método en `CredsApiService` | Pantalla(s) conectada(s) |
| :--- | :--- | :--- | :--- |
| `GET` | `/v1/auth/me` | `getMe()` (con auto-refresh en 401) | `PreloadingScreen` (validación de sesión activa al arrancar) |
| `POST` | `/v1/auth/refresh` | `refreshTokens()` | Renovación silenciosa automática |
| `POST` | `/v1/auth/register/start` | `registerStart(...)` | `CreateAccountScreen` (`Send code`) |
| `POST` | `/v1/auth/resend-otp` | `resendOtp(...)` | `VerifyEmailScreen` (`Resend code`) |
| `POST` | `/v1/auth/verify-otp` | `verifyOtp(...)` | `VerifyEmailScreen` (`Verify email`) |
| `POST` | `/v1/auth/login` | `login(...)` | `SignInScreen` (`Sign in`) |
| `POST` | `/v1/auth/social` | `socialAuth(...)` | `AuthService.signInWithGoogle()` (`AuthLandingScreen` / `SignInScreen`) |
| `GET` | `/v1/users/check-username` | `checkUsernameAvailability(...)` | Disponible para verificación anticipada de `@username` |
| `GET` | `/v1/users/activities/catalog` | `getActivitiesCatalog()` | `ActivitiesScreen` (`initState`) |
| `PATCH` | `/v1/users/profile/setup` | `setupProfile(...)` | `SetupProfileScreen` (`Save and continue`) |
| `PATCH` | `/v1/users/preferences` | `updatePreferences(...)` | `LocationPermissionScreen` y `ActivitiesScreen` |

---

## 🏋️ Catálogo Oficial de 22 Actividades (`activity_types`)

`ActivitiesScreen` incluye como respaldo offline exactamente los mismos 22 códigos oficiales sincronizados desde PostgreSQL (`auth_core.activity_types`) y los actualiza en caliente al consultar `GET /v1/users/activities/catalog`:

| # | `code` | `label` | `iconKey` |
| :---: | :--- | :--- | :--- |
| 1 | `strength_training` | Strength training | `dumbbell` |
| 2 | `hiit` | HIIT | `flame` |
| 3 | `pilates` | Pilates | `reformer` |
| 4 | `yoga` | Yoga | `lotus` |
| 5 | `running` | Running | `runner` |
| 6 | `walking` | Walking | `footprints` |
| 7 | `dance` | Dance | `music_note` |
| 8 | `padel` | Padel | `padel_racquet` |
| 9 | `tennis` | Tennis | `tennis_ball` |
| 10 | `boxing` | Boxing | `boxing_glove` |
| 11 | `meditation` | Meditation | `sparkles` |
| 12 | `breathwork` | Breathwork | `wind` |
| 13 | `soundbath` | Soundbath | `sound_wave` |
| 14 | `ice_plunge` | Ice plunge | `snowflake` |
| 15 | `sauna` | Sauna | `thermometer_hot` |
| 16 | `golf` | Golf | `golf_flag` |
| 17 | `barre` | Barre | `ballet` |
| 18 | `cycling` | Cycling | `bike` |
| 19 | `bootcamp` | Bootcamp | `whistle` |
| 20 | `cross_fit` | CrossFit | `kettlebell` |
| 21 | `martial_arts` | Martial arts | `martial_arts` |
| 22 | `recovery` | Recovery | `heart_pulse` |

---

## 🚀 Cómo Ejecutar y Probar App Flutter + Backend DEV

```powershell
# 1. Por defecto apunta directamente al servidor remoto DEV (https://api-dev.getcreds.co/v1)
flutter run

# 2. (Opcional) Si en algún momento corres backend local en Chrome / iOS / Windows
flutter run --dart-define=API_BASE_URL=http://localhost:3000/v1

# 3. (Opcional) Backend local desde Emulador Android
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1

# 4. Compilar apuntando a Producción (https://api.getcreds.co/v1)
flutter run --dart-define=ENV=prod
```

> **Tip QA en Desarrollo:** Cuando el backend corre fuera de producción (`NODE_ENV !== 'production'`), `POST /v1/auth/register/start` y `POST /v1/auth/resend-otp` incluyen el campo opcional `devOtpCode`. `CreateAccountScreen` lo imprime en consola (`debugPrint`) y lo pre-carga automáticamente en `VerifyEmailScreen` para agilizar pruebas manuales sin esperar SMTP.

---

## 🔜 Pendientes Naturales para Siguientes PRs

1. **Persistencia local de tokens entre reinicios:** Almacenar `accessToken` y `refreshToken` con `flutter_secure_storage` y cargarlos en `CredsApiService.instance.setSession(...)` al iniciar la app para que `PreloadingScreen` los valide automáticamente vía `GET /v1/auth/me`.
2. **Subida real de Avatar (`AddPhotoScreen`):** Conectar `MediaService` con un endpoint prefirmado S3/Cloudflare R2 en cuanto esté disponible en backend, pasando luego la URL retornada al campo `avatarUrl` de `PATCH /v1/users/profile/setup`.
3. **Verificación en vivo de `@username`:** Usar `CredsApiService.instance.checkUsernameAvailability(...)` al perder foco o con debounce en `SetupProfileScreen` si se desea feedback previo al submit.
