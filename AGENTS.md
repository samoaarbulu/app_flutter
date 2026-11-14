# CREDS Flutter App (`app_flutter`) — Reglas e Instrucciones para Agentes y Desarrolladores

## 1. Protección Estricta del Design System (No Romper UI)
- **Prohibido modificar colores, tipografías, paddings, escalas `.rem` ni animaciones** de las pantallas aprobadas sin instrucción explícita.
- Toda nueva pantalla debe construirse exclusivamente usando los tokens y widgets compartidos:
  - Colores: `lib/core/theme/app_colors.dart` (`AppColors`)
  - Tipografía: `lib/core/theme/app_typography.dart` (`AppTypography`)
  - Unidades: `lib/core/utils/app_rem.dart` (`.rem`, base `16.0 px`)
  - Feedback: `lib/core/utils/app_feedback.dart` (`AppFeedback.showSuccess`, `AppFeedback.showError`)
  - Componentes: `lib/shared/widgets/` (`AppHeader`, `AppTextField`, `AppButton`, `AppLinkText`, `AppLinkButton`, `AppOtpSection`, `AppGoogleIcon`)

## 2. Arquitectura de Integración con Backend (`/v1`)
- **Configuración de URL:** Usar `AppConfig.apiBaseUrl` (`lib/core/config/app_config.dart`), que por defecto apunta al entorno remoto DEV `https://api-dev.getcreds.co/v1` (`https://api.getcreds.co/v1` con `--dart-define=ENV=prod`), sobreescribible con `--dart-define=API_BASE_URL=...`.
- **Cliente API Centralizado:** Todas las llamadas al backend NestJS pasan por `CredsApiService.instance` (`lib/core/services/creds_api_service.dart`). No crear instancias aisladas de `http.Client` dentro de pantallas.
- **Documentación OpenAPI / Swagger del Backend:** https://api-dev.getcreds.co/docs (auth Bearer `access-token`).
- **Guía de endpoints y modelos conectados:** Leer `docs/06_integracion_apis_backend_m1.md`.

## 3. Máquina de Estados del Onboarding (`onboardingStep`)
- `OnboardingNavigator` (`lib/features/onboarding/navigation/onboarding_navigator.dart`) traduce los valores oficiales de `UserProfileDto.onboardingStep`:
  - `verify_email` → `VerifyEmailScreen`
  - `add_photo` → `AddPhotoScreen`
  - `setup_profile` → `SetupProfileScreen`
  - `location_permission` → `LocationPermissionScreen`
  - `activities` → `ActivitiesScreen`
  - `completed` (o `profileCompleted == true`) → `HomeScreen`

## 4. Catálogo Oficial de Disciplinas (`activity_types`)
- La lista oficial de 22 códigos de entrenamiento vive en PostgreSQL (`auth_core.activity_types`), se expone por `GET /v1/users/activities/catalog` y está replicada como respaldo offline en `ActivitiesScreen`.
- Códigos oficiales: `strength_training`, `hiit`, `pilates`, `yoga`, `running`, `walking`, `dance`, `padel`, `tennis`, `boxing`, `meditation`, `breathwork`, `soundbath`, `ice_plunge`, `sauna`, `golf`, `barre`, `cycling`, `bootcamp`, `cross_fit`, `martial_arts`, `recovery`.

## 5. Calidad y Verificación Obligatoria
Antes de dar por terminado cualquier cambio, ejecutar en la raíz de `app_flutter`:
```powershell
flutter analyze
flutter test
```
Ambas verificaciones deben finalizar con 0 errores y 0 advertencias. No romper el soporte offline de `CredsApiService` necesario para los widget tests.
