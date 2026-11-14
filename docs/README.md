# 📚 Documentación Técnica y Guía de Arquitectura — Creds (Flutter)

Bienvenido a la documentación técnica oficial de **Creds**. Este repositorio contiene una arquitectura modular basada en **Feature-First**, Clean Code, un Design System pixel-perfect extraído de Figma y una integración multi-entorno robusta para **Firebase Authentication con Google Sign-In**.

---

## 📑 Índice de Contenidos

1. [**01. Arquitectura, Estructura y Design System**](01_arquitectura_y_estructura.md)
   - Filosofía Feature-First y Clean Code.
   - Patrón de Componentes Modulares (separación lógica `<script>` y vista `<template>`).
   - Sistema de Diseño: Unidades relativas **REM** (`1.0.rem = 16.0 px`), paleta de colores oficial (`AppColors`) y tipografía dinámica con `GoogleFonts.poppins` (`AppTypography`).
   - Catálogo de componentes compartidos en `lib/shared/widgets/` (`AppButton`, `AppHeader`, `AppTextField`, `AppOtpSection`, `AppLinkButton`, etc.).

2. [**02. Autenticación, Google Sign-In y Multi-Entornos (DEV / PROD)**](02_autenticacion_google_signin.md)
   - Integración con Firebase Authentication y Google Sign-In multiplataforma (Web vs Android vs iOS).
   - Servicio singleton `AuthService` y el inicializador resiliente `FirebaseInitializer`.
   - **Estrategia Multi-Entorno (Opción B):** Sufijo `.dev` automático en desarrollo (`com.getcreds.app.dev`) y nombre limpio en producción (`com.getcreds.app`), permitiendo tener ambas versiones instaladas a la vez.
   - Sincronización con `getcreds-dev` y `getcreds-prod`.

3. [**03. Mapbox Maps SDK v11, Geolocalización y Marcadores**](03_mapbox_y_geolocalizacion.md)
   - Requisitos de cuenta: Token Público vs Token Secreto de descarga (`sk...`).
   - Configuración nativa de Android (Gradle, Maven autenticado).
   - Permisos y servicio de ubicación GPS con `geolocator`.
   - Renderizado de mapas vectoriales y selección de lugares.

4. [**04. Laboratorio de Animaciones de Marca y Preloaders**](04_laboratorio_animaciones_branding.md)
   - Documentación técnica de las 4 opciones de micro-interacciones de marca:
     - Opción 1: Prisma (Barrido especular con `ShaderMask`).
     - Opción 2: CREDS (Gema translúcida y tipografía cinética).
     - Opción 3: **3D Float** (Levitación vertical y sombra física dinámica en el suelo).
     - Opción 4: Emblema (Giro 3D en perspectiva).

5. [**05. Pantallas y Flujo Completo de Onboarding**](05_pantallas_y_flujo_onboarding.md)
   - Especificación detallada de las pantallas de Onboarding, Login (`SignInScreen`) y `HomeScreen`:
     1. `PreloadingScreen`: Animación 3D Float del wordmark `creds` en escala de grises.
     2. `PresentationScreen`: Video en bucle de fondo con gradiente y CTA "Get started".
     3. `AuthLandingScreen`: "Build your Creds", Google, Apple y Email.
     4. `SignInScreen`: Inicio de sesión "Welcome back" con Email/Password o Google.
     5. `CreateAccountScreen`: Formulario con validación de contraseña y envío OTP.
     6. `VerifyEmailScreen`: Verificación OTP con `AppOtpSection` (6 casillas, temporizador y aviso).
     7. `AddPhotoScreen`: Selector circular de foto de perfil.
     8. `SetupProfileScreen`: Configuración de Username, teléfono y nombre completo.
     9. `LocationPermissionScreen`: Permiso de ubicación con badge circular.
     10. `ActivitiesScreen`: Selección múltiple del catálogo oficial de 22 disciplinas.
     11. `HomeScreen`: Punto de aterrizaje tras completar onboarding (`onboardingStep == 'completed'`).

6. [**06. Integración con Backend CREDS Core API (Hito 1)**](06_integracion_apis_backend_m1.md)
   - Cliente singleton `CredsApiService` (`/v1/auth/*` y `/v1/users/*`), mapeo de `onboardingStep` con `OnboardingNavigator` y catálogo oficial de 22 `activity_types`.
   - Configuración de `--dart-define=API_BASE_URL=...` y modo resiliente para `flutter test` y revisión UI offline.

---

## 🛠️ Requisitos del Entorno

| Herramienta | Versión recomendada | Notas |
| :--- | :--- | :--- |
| **Flutter SDK** | `>= 3.27.0` | Canal Stable |
| **Dart SDK** | `>= 3.6.0` | Null-Safety activado |
| **JDK (Java)** | `OpenJDK 17` a `21` | Compatible con Gradle 9 y Kotlin 2.x |
| **Firebase CLI** | Última versión | `firebase login` con cuenta autorizada |
| **FlutterFire CLI** | `flutterfire` | Activado globalmente con `dart pub global activate flutterfire_cli` |

---

## 🚀 Comandos Rápidos

```powershell
# Instalar dependencias
flutter pub get

# Ejecutar en Desarrollo (getcreds-dev)
flutter run

# Ejecutar o compilar apuntando a Producción (getcreds-prod)
flutter run --dart-define=ENV=prod
flutter build appbundle --dart-define=ENV=prod

# Ejecutar pruebas automatizadas y análisis de calidad
flutter test
flutter analyze
```
