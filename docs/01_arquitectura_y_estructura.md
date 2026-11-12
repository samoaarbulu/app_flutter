# 🏗️ 01. Arquitectura, Estructura y Design System

Este documento explica los principios de ingeniería de software, la organización de carpetas y el sistema de diseño utilizados en este proyecto para garantizar alta mantenibilidad, escalabilidad y legibilidad.

---

## 1. Filosofía de Arquitectura (Feature-First)

El proyecto utiliza una arquitectura **Feature-First** (por funcionalidades) combinada con principios de **Clean Code**. Cada funcionalidad vive en su propio módulo autocontenido:

```text
lib/
├── core/                         # Núcleo compartido global (no depende de features)
│   ├── config/                   # Configuraciones globales (Mapbox, APIs)
│   ├── services/                 # Servicios globales del sistema (GPS, Ubicación)
│   ├── theme/                    # Design System (Colores, Espaciados, Tipografías)
│   └── utils/                    # Extensiones y utilidades (AppRem)
├── features/                     # Módulos de funcionalidad de negocio
│   ├── auth/                     # Autenticación (Login, Registro, Bienvenida, AuthService)
│   │   ├── presentation/screens/ # Pantallas modulares
│   │   └── services/             # Servicios específicos de autenticación
│   ├── gyms/                     # Gimnasios y Mapas
│   │   ├── data/                 # Modelos y fuentes de datos locales
│   │   └── presentation/screens/ # Pantalla de mapa y widgets interactivos
│   └── home/                     # Pantalla principal y detalle de restaurante
│       └── presentation/screens/ # Dashboard y Detalle
├── shared/                       # Componentes visuales reutilizables entre features
│   └── widgets/                  # Botones globales, inputs, logos, etiquetas
├── firebase_options.dart         # Opciones generadas por FlutterFire CLI
└── main.dart                     # Punto de entrada de la aplicación
```

---

## 2. Patrón de "Componentes Modulares" (Estilo Vue/Angular)

Para evitar el problema común en Flutter del *"Widget Hell"* (árboles de widgets con 20 niveles de anidación imposibles de leer), cada pantalla se estructura emulando la separación de `<script>` y `<template>` de frameworks modernos como Vue o Angular:

### Estructura de un archivo de pantalla:
```dart
class MyScreen extends StatefulWidget { ... }

class _MyScreenState extends State<MyScreen> {
  // -------------------------------------------------------------
  // 1. ESTADO Y CONTROLADORES (Equivalente al <script setup>)
  // -------------------------------------------------------------
  int _selectedTab = 0;
  final TextEditingController _controller = TextEditingController();

  void _handleSubmit() { ... }

  // -------------------------------------------------------------
  // 2. VISTA PRINCIPAL (Equivalente al <template>)
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),        // <-- Modular y legible a primera vista
            _buildHeaderSection(),
            _buildContentList(),
            _buildFooterAction(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. SUBCOMPONENTES MODULARES (Desglose limpio)
  // -------------------------------------------------------------
  Widget _buildTopBar() { ... }
  Widget _buildHeaderSection() { ... }
  Widget _buildContentList() { ... }
  Widget _buildFooterAction() { ... }
}
```

---

## 3. Sistema de Diseño (Design Tokens)

Todos los valores visuales están centralizados en `lib/core/theme/` para que cualquier cambio de marca se realice en un solo archivo.

### A. Matemática de Unidades REM (`lib/core/utils/app_rem.dart`)
Para replicar con exactitud los mockups de Figma basados en múltiplos de 16 píxeles:

```dart
extension RemExtension on num {
  /// Convierte rems a píxeles en pantalla: 1.0.rem = 16.0 px
  double get rem => toDouble() * 16.0;
}
```
* **Uso:** `SizedBox(height: 1.5.rem)` = 24 px exactos.

### B. Paleta de Colores (`lib/core/theme/app_colors.dart`)
```dart
abstract final class AppColors {
  /// Fondo principal oscuro (#3F3B6C)
  static const Color background = Color(0xFF3F3B6C);

  /// Fondo de inputs y tarjetas (#624F82)
  static const Color inputSurface = Color(0xFF624F82);

  /// Color de acción primaria / acento celeste pastel (#A3C7D6)
  static const Color primaryAction = Color(0xFFA3C7D6);

  /// Color lila para texto secundario e iconos suaves (#9F73AB)
  static const Color textMuted = Color(0xFF9F73AB);

  /// Blanco puro (#FFFFFF)
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
}
```

### C. Tipografía Dinámica (`lib/core/theme/app_typography.dart`)
> [!IMPORTANT]
> **Regla de oro de Dart/Flutter:** Nunca declarar estilos de texto como `static final TextStyle` cuando se usan fuentes de `google_fonts`, porque la máquina virtual de Dart los almacena en caché estática y no se actualizan con Hot Reload (`r`). **Siempre usar getters dinámicos** (`static TextStyle get headlineLarge => ...`).

```dart
abstract final class AppTypography {
  static const String fontFamily = 'Poppins';

  /// Título grande (39px Bold)
  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 2.4375.rem, // 39 px
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
    height: 1.15,
  );

  /// Subtítulo descriptivo (16px Regular)
  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 1.0.rem, // 16 px
    fontWeight: FontWeight.w400,
    color: AppColors.textLight.withValues(alpha: 0.85),
    height: 1.4,
  );

  /// Texto de botones de acción
  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 1.0.rem,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.onPrimary,
  );
}
```

---

## 4. Componentes Compartidos (`lib/shared/widgets/`)

Cualquier widget que se utilice en más de una pantalla debe crearse aquí:

1. **`AppButton`**: Botón principal de 56px de altura con color `#A3C7D6` y borde redondeado de 28px.
2. **`AppTextField`**: Caja de texto de 56px con fondo `#624F82`, iconos de prefijo/sufijo y animación de foco en color lila.
3. **`AppLogo`**: Isotipo oficial con dimensiones parametrizables y soporte para animaciones `Hero(tag: 'app_logo')`.
4. **`AppTagsText`**: Widget para renderizar subtítulos/etiquetas secundarias con control automático de overflow y color `AppColors.textMuted`.

