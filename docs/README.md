# 📚 Documentación Técnica y Guía de Replicación — Demo Samoa

Bienvenido a la documentación oficial de la aplicación **Demo Samoa**. Este conjunto de guías técnicas está diseñado bajo el formato de **Cookbooks / Runbooks** paso a paso: cada documento contiene explicaciones de arquitectura, configuraciones nativas y código listo para copiar, pegar y adaptar en cualquier otro proyecto Flutter.

---

## 📑 Índice de Contenidos

1. [**01. Arquitectura, Estructura y Design System**](01_arquitectura_y_estructura.md)
   - Filosofía Feature-First y Clean Code.
   - Patrón de **Componentes Modulares** (estilo Vue/Angular `<template>`).
   - Sistema de Diseño: Unidades relativas **REM**, paleta de colores y tipografía dinámica con Google Fonts (`Poppins`).
   - Componentes compartidos reutilizables (`lib/shared/widgets/`).

2. [**02. Autenticación y Google Sign-In Multiplataforma**](02_autenticacion_google_signin.md)
   - Integración con Firebase Authentication y Google Sign-In.
   - **Solución Multiplataforma:** Diferencias críticas entre Web (`signInWithPopup`) y Móvil (`GoogleSignIn`).
   - Código del servicio singleton `AuthService`.
   - Flujo de pantallas: Splash automático de 2 segundos, `AuthLandingScreen` y `LoginScreen`.

3. [**03. Mapbox Maps SDK v11, Geolocalización y Marcadores**](03_mapbox_y_geolocalizacion.md)
   - Requisitos de cuenta: Token Público (`pk...`) vs Token Secreto de descarga (`sk...` con `Downloads:Read`).
   - Configuración nativa de Android (Gradle, Maven autenticado y solución para AGP 9+ con Kotlin).
   - Permisos y servicio de ubicación GPS con `geolocator`.
   - Implementación de `MapWidget` con tema oscuro.
   - Pintado de pines vectoriales con `PointAnnotationManager` y despliegue de tarjeta flotante inferior al hacer clic.

4. [**04. Laboratorio de Animaciones de Marca y Preloaders**](04_laboratorio_animaciones_branding.md)
   - Prototipado interactivo de micro-interacciones de marca (`presentacion.dart`).
   - **Opción 1 (Prisma):** Barrido especular con `ShaderMask`, `BlendMode.srcATop` y pausa orgánica de 1.3s.
   - **Opción 2 (CREDS):** Gema 3D cojín translúcida en GPU con `CustomPainter`, borde neón y tipografía cinética horizontal `C R E D S`.
   - **Opción 3 (3D Float):** Levitación vertical con sombra física dinámica en el suelo.
   - **Opción 4 (Emblema):** Giro 3D en perspectiva de 360° en eje Y.
   - Selector modular interactivo con respuesta háptica nativa.

---

## 🛠️ Requisitos del Entorno

| Herramienta | Versión recomendada | Notas |
| :--- | :--- | :--- |
| **Flutter SDK** | `>= 3.27.0` | Canal Stable |
| **Dart SDK** | `>= 3.6.0` | Null-Safety activado |
| **JDK (Java)** | `OpenJDK 17` a `25` | Incluido en Android Studio (`.../jbr`) |
| **Android Gradle Plugin (AGP)** | `9.1.0` | Compatible con Gradle 9.x |
| **Min Android SDK** | `21` (Android 5.0) | Requerido por Mapbox v11 |

---

## 📦 Cómo Replicar en un Nuevo Proyecto (Paso a Paso)

Si vas a iniciar otro proyecto y deseas trasladar todo lo aprendido aquí:

### Paso 1: Crear el proyecto Flutter limpio
Abre la terminal en la carpeta donde crearás el nuevo proyecto:
```bash
flutter create --org com.tudominio --platforms=android,ios nombre_de_tu_app
cd nombre_de_tu_app
```

### Paso 2: Copiar las carpetas clave
Copia desde este proyecto al nuevo proyecto:
1. **La carpeta `docs/`:** Para que el agente o cualquier desarrollador tenga la referencia arquitectónica completa.
2. **La carpeta `assets/images/`:** Copia el logotipo (`logo.png`) o coloca el nuevo logotipo en esa ruta.

### Paso 3: Configurar `pubspec.yaml`
Añade las dependencias base en `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1
  firebase_core: ^3.12.1
  firebase_auth: ^5.5.1
  google_sign_in: ^6.2.2
  mapbox_maps_flutter: ^2.6.0
  geolocator: ^13.0.2

flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

### Paso 4: Configurar Credenciales Específicas
1. **Firebase:** Ejecuta en la terminal `flutterfire configure` para vincular tu nuevo proyecto de Firebase y generar `lib/firebase_options.dart`.
2. **Mapbox:** Coloca tu token público en `lib/core/config/mapbox_config.dart` y tu token secreto `sk...` en `~/.gradle/gradle.properties`.

### Paso 5: Prompt para el Agente de IA en el Nuevo Proyecto
Copia y pega este prompt al asistente de IA en el nuevo proyecto:

> *"He creado este proyecto con `flutter create --platforms=android,ios`. En la carpeta `docs/` tienes la documentación técnica completa del proyecto base anterior. Léela toda y replica la arquitectura de carpetas (`lib/core/`, `lib/features/`, `lib/shared/`), el Design System (AppColors, AppTypography dinámica y la extensión de unidades REM `app_rem.dart`), los componentes base reutilizables y la pantalla de presentación modular con las animaciones de marca."*
