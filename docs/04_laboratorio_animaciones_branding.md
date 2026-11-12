# 💎 04. Laboratorio de Animaciones de Marca y Preloaders

Este documento detalla la arquitectura, las fórmulas matemáticas de GPU y el código listo para replicar del **Laboratorio Interactivo de Animaciones de Marca** (`presentacion.dart`). 

Permite prototipar, comparar y validar micro-interacciones de preloading y branding de alto impacto en tiempo real mediante un selector interactivo de 4 alternativas.

---

## 📑 Índice de Alternativas

1. [**Opción 1: Prisma (Barrido Especular con Pausa Orgánica)**](#1-opción-1-prisma-barrido-especular-con-pausa-orgánica)
2. [**Opción 2: CREDS (Gema Líquida 3D Translúcida y Tipografía Cinética)**](#2-opción-2-creds-gema-líquida-3d-translúcida-y-tipografía-cinética)
3. [**Opción 3: 3D Float (Levitación Vertical con Sombra Física Dinámica)**](#3-opción-3-3d-float-levitación-vertical-con-sombra-física-dinámica)
4. [**Opción 4: Emblema (Giro 3D en Perspectiva de 360°)**](#4-opción-4-emblema-giro-3d-en-perspectiva-de-360)
5. [**Barra Selectora Modular con Respuesta Háptica**](#5-barra-selectora-modular-con-respuesta-háptica)

---

## 1. Opción 1: Prisma (Barrido Especular con Pausa Orgánica)

### Concepto Óptico:
Un haz de luz oblicuo a 65° con un gradiente especular (Cian Neón `#00E5FF` -> Blanco puro -> Cian Neón) barre el logotipo de izquierda a derecha. 

> [!IMPORTANT]
> **Lección Crítica sobre `ShaderMask` en Flutter:**
> Nunca uses `BlendMode.screen` o `BlendMode.overlay` directamente sobre imágenes PNG con fondo transparente. Al hacerlo, el shader ilumina el bounding box rectangular completo de la imagen. **Siempre utiliza `BlendMode.srcATop`**, el cual recorta y aplica el brillo exclusivamente sobre los píxeles visibles del canal alfa del logotipo.

### Ciclo y Física Temporal:
Para que la animación se sienta elegante y no canse la vista del usuario:
- **Duración del barrido activo:** 1.5 segundos con aceleración física `Curves.easeInOutSine`.
- **Pausa orgánica de reposo:** 1.3 segundos estáticos entre cada barrido.
- **Duración total del controlador:** 2800 ms (`_shimmerController`).

```dart
// En initState():
_shimmerController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 2800),
)..repeat();

// Widget de la Opción 1:
Widget _buildShimmerSweepOption() {
  return AnimatedBuilder(
    animation: _shimmerController,
    builder: (context, child) {
      final t = _shimmerController.value;
      const activeWindow = 1500.0 / 2800.0; // 0.0 a 0.535

      double sweepProgress;
      if (t <= activeWindow) {
        final localNorm = t / activeWindow;
        sweepProgress = Curves.easeInOutSine.transform(localNorm);
      } else {
        sweepProgress = 1.0; // Pausa orgánica de reposo
      }

      return SizedBox(
        width: 190,
        height: 190,
        child: Center(
          child: ShaderMask(
            blendMode: BlendMode.srcATop, // <-- Crucial para respetar la transparencia PNG
            shaderCallback: (bounds) {
              final xPos = (sweepProgress * 3.4) - 1.2;
              return LinearGradient(
                begin: Alignment(xPos - 0.7, -1.0),
                end: Alignment(xPos + 0.7, 1.0),
                colors: const [
                  Colors.white,
                  Color(0xFF00E5FF),
                  Colors.white,
                  Color(0xFF00E5FF),
                  Colors.white,
                ],
                stops: const [0.0, 0.44, 0.50, 0.56, 1.0],
              ).createShader(bounds);
            },
            child: const AppLogo(width: 90, height: 110),
          ),
        ),
      );
    },
  );
}
```

---

## 2. Opción 2: CREDS (Gema Líquida 3D Translúcida y Tipografía Cinética)

### Concepto Visual:
Inspirada en interfaces fluidas de última generación. Muestra una gema de cristal en forma de cojín/diamante redondeado (Squircle a 45°) con interior translúcido del color lila de la pantalla, arista axial 3D, borde perimetral neón con ciclo cromático y un rayo anamórfico a 45°. En la parte inferior, la palabra **`C R E D S`** se revela letra por letra deslizándose de izquierda a derecha.

### A. Tipografía Cinética Horizontal (`_buildCredsKineticText`)
- Cada letra tiene una ventana temporal escalonada (`letterStep = 0.12`).
- Entrada en eje X (`translateX` de `-18px` a `0px`) con curva `Curves.easeOutCubic`.
- Destello de sombra luminosa (`glowIntensity`) en el instante exacto de revelación.

```dart
Widget _buildCredsKineticText(double t) {
  const letters = ['C', 'R', 'E', 'D', 'S'];
  const letterStep = 0.12;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(letters.length, (index) {
      final start = index * letterStep;
      final end = start + letterStep;

      double opacity = 0.0;
      double translateX = -18.0;
      double glowIntensity = 0.0;

      if (t >= start && t < end) {
        final p = Curves.easeOutCubic.transform((t - start) / letterStep);
        opacity = p;
        translateX = (1.0 - p) * -18.0;
        glowIntensity = (1.0 - p);
      } else if (t >= end && t <= 0.82) {
        opacity = 1.0;
        translateX = 0.0;
        glowIntensity = 0.25 + (math.sin(t * 4 * math.pi) * 0.15);
      } else if (t > 0.82) {
        final fadeOut = (1.0 - ((t - 0.82) / 0.18)).clamp(0.0, 1.0);
        opacity = fadeOut;
        translateX = (1.0 - fadeOut) * 10.0;
        glowIntensity = 0.0;
      }

      return Transform.translate(
        offset: Offset(translateX, 0),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              letters[index],
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 1.30.rem,
                fontWeight: FontWeight.w800,
                color: AppColors.textLight,
                letterSpacing: 3.0,
                shadows: [
                  Shadow(
                    color: const Color(0xFF00FF66).withValues(
                      alpha: glowIntensity.clamp(0.0, 1.0) * 0.90,
                    ),
                    blurRadius: 14.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }),
  );
}
```

### B. Pintor GPU de la Gema 3D (`_FluidOrbPainter`)
Implementa curvaturas Bézier continuas, elasticidad *Squash & Stretch* balanceada (2.2px) para mantener la silueta impecable sin deformaciones bruscas, y shader translúcido con los tokens de color del proyecto:

```dart
class _FluidOrbPainter extends CustomPainter {
  final double progress;
  _FluidOrbPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = progress * 2 * math.pi;

    // 1. Rayo anamórfico sutil a 45°
    final flarePaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1.4, -1.1),
        end: const Alignment(1.4, 1.1),
        colors: [
          Colors.transparent,
          const Color(0xFF00FF66).withValues(alpha: 0.15 + (math.sin(t) * 0.08)),
          Colors.white.withValues(alpha: 0.45 + (math.sin(t) * 0.18)),
          const Color(0xFF00E5FF).withValues(alpha: 0.20 + (math.sin(t) * 0.08)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.46, 0.50, 0.54, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx - 95, center.dy - 75),
      Offset(center.dx + 95, center.dy + 75),
      flarePaint,
    );

    // 2. Geometría limpia de Cojín/Diamante Squircle (proporciones áureas)
    const baseR = 62.0;
    final stretchH = math.sin(t) * 2.2;
    final stretchV = math.cos(t) * 2.2;

    final topP = Offset(center.dx, center.dy - baseR + stretchV);
    final rightP = Offset(center.dx + baseR + stretchH, center.dy);
    final bottomP = Offset(center.dx, center.dy + baseR - stretchV);
    final leftP = Offset(center.dx - baseR - stretchH, center.dy);

    final fullPath = Path()..moveTo(topP.dx, topP.dy);
    fullPath.cubicTo(
      center.dx + baseR * 0.58, center.dy - baseR * 0.58,
      center.dx + baseR * 0.88, center.dy - baseR * 0.18,
      rightP.dx, rightP.dy,
    );
    fullPath.cubicTo(
      center.dx + baseR * 0.88, center.dy + baseR * 0.18,
      center.dx + baseR * 0.58, center.dy + baseR * 0.58,
      bottomP.dx, bottomP.dy,
    );
    fullPath.cubicTo(
      center.dx - baseR * 0.58, center.dy + baseR * 0.58,
      center.dx - baseR * 0.88, center.dy + baseR * 0.18,
      leftP.dx, leftP.dy,
    );
    fullPath.cubicTo(
      center.dx - baseR * 0.88, center.dy - baseR * 0.18,
      center.dx - baseR * 0.58, center.dy - baseR * 0.58,
      topP.dx, topP.dy,
    );
    fullPath.close();

    // 3. Relleno de Cristal Translúcido con el color Lila de la app (sin negro)
    final baseGlassPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.30),
        radius: 0.85,
        colors: [
          AppColors.inputSurface.withValues(alpha: 0.35),
          AppColors.background.withValues(alpha: 0.50),
          const Color(0xFF2C274E).withValues(alpha: 0.65),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 75))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fullPath, baseGlassPaint);

    // 4. Arista axial 3D fluida conectando el ápice superior con el inferior
    final leftFacetPath = Path()..moveTo(topP.dx, topP.dy);
    leftFacetPath.quadraticBezierTo(
      center.dx - 10 + (math.sin(t) * 4), center.dy,
      bottomP.dx, bottomP.dy,
    );
    leftFacetPath.lineTo(leftP.dx, leftP.dy);
    leftFacetPath.close();

    final leftFacetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.08 + (math.sin(t) * 0.03)),
          Colors.white.withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 70))
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftFacetPath, leftFacetPaint);

    // 5. Borde Neón Iridiscente con Ciclo Cromático
    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: t,
      endAngle: t + (2 * math.pi),
      colors: const [
        Color(0xFF00FF66), // Verde esmeralda
        Color(0xFFFF9100), // Ámbar dorado
        Color(0xFFE040FB), // Magenta neón
        Color(0xFF76FF03), // Verde lima
        Color(0xFF00FF66),
      ],
    );

    // Halo difuso exterior
    final haloPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: 74))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0);
    canvas.drawPath(fullPath, haloPaint);

    // Rim perimetral nítido
    final rimPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: 74))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawPath(fullPath, rimPaint);

    // 6. Destello especular estelar en el ápice superior
    final topSpotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70 + (math.sin(t * 2) * 0.20))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(Offset(topP.dx, topP.dy + 3), 3.2, topSpotPaint);
  }

  @override
  bool shouldRepaint(covariant _FluidOrbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
```

---

## 3. Opción 3: 3D Float (Levitación Vertical con Sombra Física Dinámica)

### Concepto de Física Óptica:
El logotipo flota suavemente arriba y abajo ($\pm 8\text{ px}$) con aceleración senoidal en GPU. Al mismo tiempo, proyecta una sombra en el suelo virtual que reacciona con física lumínica real:
- **Al subir:** La sombra se expande en anchura (50px a 76px), se vuelve más difusa (`blurRadius` de 8px a 20px) y su opacidad disminuye.
- **Al bajar:** La sombra se contrae, se enfoca y se oscurece.

```dart
Widget _buildLevitation3DOption() {
  return AnimatedBuilder(
    animation: _rippleController,
    builder: (context, child) {
      final progress = _rippleController.value;
      final floatOffset = math.sin(progress * 2 * math.pi) * 8.0;
      final heightFactor = (floatOffset + 8.0) / 16.0; // 0.0 (alto) a 1.0 (bajo)

      final shadowWidth = 50.0 + ((1.0 - heightFactor) * 26.0);
      final shadowHeight = 9.0 + ((1.0 - heightFactor) * 4.0);
      final shadowOpacity = 0.20 + (heightFactor * 0.35);
      final shadowBlur = 8.0 + ((1.0 - heightFactor) * 12.0);

      return SizedBox(
        width: 220,
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logotipo en levitación pura
            Transform.translate(
              offset: Offset(0, floatOffset),
              child: const AppLogo(width: 90, height: 110),
            ),
            const SizedBox(height: 18),
            // Sombra física dinámica en el suelo
            Container(
              width: shadowWidth,
              height: shadowHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.elliptical(shadowWidth / 2, shadowHeight / 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: shadowOpacity),
                    blurRadius: shadowBlur,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
```

---

## 4. Opción 4: Emblema (Giro 3D en Perspectiva de 360°)

### Concepto Matemático:
Gira el logotipo en el eje Y en un espacio tridimensional auténtico con perspectiva fotográfica (`setEntry(3, 2, 0.0018)`).
- La sombra del suelo acompaña la rotación comprimiéndose horizontalmente de forma proporcional al valor absoluto del coseno (`|cos(angle)|`), emulando la proyección de un disco que gira.

```dart
Widget _buildEmblem3DOption() {
  return AnimatedBuilder(
    animation: _emblem3DController,
    builder: (context, child) {
      final angle = _emblem3DController.value * 2 * math.pi;
      final compression = (math.cos(angle)).abs(); // 0.0 a 1.0
      final shadowWidth = 18.0 + (compression * 42.0);

      return SizedBox(
        width: 220,
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Moneda 3D con perspectiva real
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018) // Perspectiva óptica focal
                ..rotateY(angle),
              child: const AppLogo(width: 90, height: 110),
            ),
            const SizedBox(height: 18),
            // Sombra en suelo sincronizada con el perfil angular
            Container(
              width: shadowWidth,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.elliptical(shadowWidth / 2, 5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15 + (compression * 0.30)),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
```

---

## 5. Barra Selectora Modular con Respuesta Háptica

Para alternar entre las 4 opciones sin recargar la pantalla y con respuesta física al tacto (`HapticFeedback.lightImpact()`):

```dart
Widget _buildDemoSwitcher() {
  const demos = ['1. Prisma', '2. CREDS', '3. 3D Float', '4. Emblema'];

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 1.0.rem),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.inputSurface.withValues(alpha: 0.70),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.primaryAction.withValues(alpha: 0.20),
        width: 1,
      ),
    ),
    child: Row(
      children: List.generate(demos.length, (index) {
        final isSelected = _selectedDemoIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact(); // Respuesta háptica nativa
              setState(() => _selectedDemoIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryAction : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                demos[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 0.72.rem,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.background : AppColors.textLight,
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}
```

