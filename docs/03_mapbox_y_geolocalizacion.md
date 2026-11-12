# 🗺️ 03. Mapbox Maps SDK v11, Geolocalización y Marcadores

Esta guía técnica explica paso a paso la integración del SDK oficial de **Mapbox Maps v11** para Flutter (`mapbox_maps_flutter`), junto con la obtención de ubicación GPS por `geolocator`, renderizado de marcadores interactivos con `PointAnnotationManager` y despliegue de tarjetas flotantes.

---

## 1. Conceptos de Tokens en Mapbox

Para usar Mapbox en Flutter se requieren **dos tokens distintos**:

| Tipo de Token | Prefijo | Dónde se usa | Para qué sirve |
| :--- | :--- | :--- | :--- |
| **Token Público** | `pk.eyJ...` | Código Flutter / `strings.xml` | Carga las capas, estilos y tiles del mapa en pantalla. |
| **Token Secreto** | `sk.eyJ...` | `gradle.properties` (Gradle) | Permiso `Downloads:Read` para descargar el SDK nativo de Android desde los servidores privados de Mapbox. |

### Cómo generar el Token Secreto:
1. En [account.mapbox.com](https://account.mapbox.com/), ir a **Tokens** > **Create a token**.
2. Nombre: `download_token`.
3. En **Secret scopes**, marcar obligatoriamente la casilla: **`Downloads:Read`**.
4. Crear y copiar el token (`sk...`).

---

## 2. Configuración Nativa en Android

### A. Guardar el Token en `android/gradle.properties`
Añadir al final del archivo:

```properties
MAPBOX_DOWNLOADS_TOKEN=sk.eyJ1Ijoi...tu_token_secreto_aqui...
SDK_REGISTRY_TOKEN=sk.eyJ1Ijoi...tu_token_secreto_aqui...
# Ruta del JDK (para evitar advertencias de Gradle Language Server)
org.gradle.java.home=C:\\Program Files\\Android\\Android Studio\\jbr
```

### B. Repositorio Maven y Solución AGP 9+ en `android/build.gradle.kts`
El SDK nativo de Mapbox no está en Google ni en MavenCentral, está en el Maven privado de Mapbox:

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        // Repositorio oficial autenticado de Mapbox
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication {
                create<BasicAuthentication>("basic")
            }
            credentials {
                username = "mapbox" // Siempre debe ser "mapbox", no tu usuario
                password = (project.findProperty("MAPBOX_DOWNLOADS_TOKEN") ?: project.findProperty("SDK_REGISTRY_TOKEN") ?: System.getenv("MAPBOX_DOWNLOADS_TOKEN")) as String? ?: ""
            }
        }
    }
}
```

> [!CRITICAL]
> **Solución al error `Could not find method kotlin() on project :mapbox_maps_flutter`:**
> En proyectos con Android Gradle Plugin 9+ (AGP 9), Mapbox omite la aplicación del plugin de Kotlin por una condición interna obsoleta (`if (agpMajor < 9)`). Para solucionarlo de raíz, añade esta regla en `android/build.gradle.kts`:
> ```kotlin
> subprojects {
>     pluginManager.withPlugin("com.android.library") {
>         if (!plugins.hasPlugin("org.jetbrains.kotlin.android")) {
>             pluginManager.apply("org.jetbrains.kotlin.android")
>         }
>     }
> }
> ```

### C. Guardar el Token Público en `android/app/src/main/res/values/strings.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="mapbox_access_token">pk.eyJ1Ijoi...tu_token_publico_aqui...</string>
</resources>
```

### D. Permisos de GPS en `android/app/src/main/AndroidManifest.xml`
Dentro de la etiqueta `<manifest>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

---

## 3. Dependencias en `pubspec.yaml`

```yaml
dependencies:
  mapbox_maps_flutter: ^2.6.0
  geolocator: ^13.0.2
```

> [!NOTE]
> `mapbox_maps_flutter` está desarrollado con motores nativos en C++, Metal y OpenGL para **Android e iOS**. No tiene soporte para Flutter Web (Chrome).

---

## 4. Servicio de Geolocalización (`LocationService`)

Archivo: `lib/core/services/location_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      return null;
    }
  }
}
```

---

## 5. Implementación del Mapa en Flutter (`GymsMapScreen`)

### A. Evitar colisiones de nombres con `hide Size`
Tanto Flutter (`dart:ui`) como Mapbox exportan una clase llamada `Size`. Para evitar errores de tipo `isn't a const constructor`, importa Mapbox así:
```dart
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
```

### B. Inicialización y Renderizado de Marcadores
```dart
class _GymsMapScreenState extends State<GymsMapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  final Map<String, Gym> _annotationGymMap = {};

  @override
  void initState() {
    super.initState();
    // 1. Establecer el token público
    MapboxOptions.setAccessToken(MapboxConfig.publicToken);
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Activar el Puck de ubicación del usuario
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    // 2. Crear el PointAnnotationManager
    _pointAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager();

    // 3. Escuchar clics en marcadores
    _pointAnnotationManager?.addOnPointAnnotationClickListener(
      _GymPointClickListener((annotation) {
        final gym = _annotationGymMap[annotation.id];
        if (gym != null) {
          setState(() => _selectedGym = gym);
          // Centrar cámara en el pin pulsado
          _mapboxMap?.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(gym.longitude, gym.latitude)),
              zoom: 14.5,
            ),
            MapAnimationOptions(duration: 800),
          );
        }
      }),
    );

    // 4. Pintar marcadores
    await _renderMarkers();
  }

  Future<void> _renderMarkers() async {
    final markerBytes = await _createCustomMarkerBitmap();
    for (final gym in _gyms) {
      final options = PointAnnotationOptions(
        geometry: Point(coordinates: Position(gym.longitude, gym.latitude)),
        image: markerBytes,
        iconSize: 1.0,
      );
      final annotation = await _pointAnnotationManager?.create(options);
      if (annotation != null) {
        _annotationGymMap[annotation.id] = gym;
      }
    }
  }
```

### C. Generar Marcadores Vectoriales en Memoria (Sin archivos PNG externos)
Para no depender de agregar imágenes en `assets/` ni lidiar con resoluciones `@2x/@3x`, se dibujan en memoria con `ui.PictureRecorder`:

```dart
Future<Uint8List> _createCustomMarkerBitmap() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(64, 88);

  final pinPath = Path()
    ..moveTo(32, 82)
    ..cubicTo(20, 58, 6, 42, 6, 26)
    ..cubicTo(6, 11.5, 17.5, 0, 32, 0)
    ..cubicTo(46.5, 0, 58, 11.5, 58, 26)
    ..cubicTo(58, 42, 44, 58, 32, 82)
    ..close();

  // Pin azul
  canvas.drawPath(pinPath, Paint()..color = const Color(0xFF2E6BFF)..isAntiAlias = true);
  // Círculo blanco central
  canvas.drawCircle(const Offset(32, 26), 10, Paint()..color = Colors.white..isAntiAlias = true);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
```

### D. Botón Flotante para Centrar GPS
```dart
Future<void> _centerOnUserLocation() async {
  final position = await LocationService.instance.getCurrentPosition();
  if (position != null && _mapboxMap != null) {
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(position.longitude, position.latitude)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }
}
```

---

## 6. Checklist de Replicación en un Nuevo Proyecto

1. [ ] Crear token secreto en Mapbox con `Downloads:Read`.
2. [ ] Configurar `android/gradle.properties` (`MAPBOX_DOWNLOADS_TOKEN` y `org.gradle.java.home`).
3. [ ] Añadir repositorio Maven autenticado y la regla `subprojects` en `android/build.gradle.kts`.
4. [ ] Agregar token público en `strings.xml`.
5. [ ] Añadir permisos de GPS en `AndroidManifest.xml`.
6. [ ] Instalar `mapbox_maps_flutter: ^2.6.0` y `geolocator: ^13.0.2`.
7. [ ] Usar `import ... hide Size;` al importar Mapbox en Flutter.
8. [ ] Ejecutar en emulador o dispositivo físico Android/iOS con `flutter run`.

