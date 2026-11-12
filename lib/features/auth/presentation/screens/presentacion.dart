import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_rem.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/app_tags_text.dart';

/// Pantalla de Presentación y Laboratorio Interactivo de Animaciones de Marca.
///
/// Sigue las mejores prácticas de ingeniería en Flutter:
/// - **Arquitectura Modular:** Separación clara entre Estado, Template y Subcomponentes.
/// - **Rendimiento GPU:** Aislamiento con `RepaintBoundary` para evitar repintados globales.
/// - **Eficiencia Energética:** Activación bajo demanda de controladores de animación (pausa de los inactivos).
/// - **Resiliencia de Pantalla:** Layout responsivo libre de desbordamientos (overflows) en pantallas pequeñas.
class PresentationScreen extends StatefulWidget {
  final VoidCallback? onContinue;

  const PresentationScreen({
    super.key,
    this.onContinue,
  });

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen>
    with TickerProviderStateMixin {
  // -------------------------------------------------------------
  // 1. ESTADO Y CONTROLADORES (Equivalente a <script setup>)
  // -------------------------------------------------------------
  int _selectedDemoIndex = 0;

  // Controlador Opción 1: Prisma (Barrido 1.5s + Pausa 1.3s = 2800ms)
  late final AnimationController _shimmerController;

  // Controlador Opción 2: Gema Líquida CREDS y Tipografía Cinética (3000ms)
  late final AnimationController _credsController;

  // Controlador Opción 3: Levitación Vertical 3D Float (2400ms)
  late final AnimationController _rippleController;

  // Controlador Opción 4: Giro 3D Emblema en eje Y (3200ms)
  late final AnimationController _emblem3DController;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _credsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _emblem3DController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Activación selectiva: solo corre el controlador de la opción activa
    _syncActiveControllers();
  }

  /// Optimización de batería y GPU: solo anima el controlador visible
  void _syncActiveControllers() {
    _shimmerController.stop();
    _credsController.stop();
    _rippleController.stop();
    _emblem3DController.stop();

    switch (_selectedDemoIndex) {
      case 0:
        _shimmerController.repeat();
        break;
      case 1:
        _credsController.repeat();
        break;
      case 2:
        _rippleController.repeat();
        break;
      case 3:
        _emblem3DController.repeat();
        break;
    }
  }

  void _onDemoChanged(int newIndex) {
    if (_selectedDemoIndex == newIndex) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDemoIndex = newIndex;
      _syncActiveControllers();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _credsController.dispose();
    _rippleController.dispose();
    _emblem3DController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // 2. VISTA PRINCIPAL (Equivalente al <template>)
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildTopBar(),
                      const Spacer(),
                      _buildAnimationStage(),
                      const Spacer(),
                      _buildBrandInfo(),
                      SizedBox(height: 1.5.rem),
                      _buildDemoSwitcher(),
                      SizedBox(height: 1.25.rem),
                      _buildFooterAction(),
                      SizedBox(height: 0.75.rem),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. SUBCOMPONENTES MODULARES
  // -------------------------------------------------------------

  /// Barra superior con chip de branding y estado
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.25.rem, vertical: 0.75.rem),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 0.75.rem,
              vertical: 0.35.rem,
            ),
            decoration: BoxDecoration(
              color: AppColors.inputSurface.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryAction.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00FF66),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 0.5.rem),
                Text(
                  'Brand Lab v2.0',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AppTagsText.single('CREDS Design System'),
        ],
      ),
    );
  }

  /// Escenario central dinámico aislado con RepaintBoundary
  Widget _buildAnimationStage() {
    return RepaintBoundary(
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<int>(_selectedDemoIndex),
            child: switch (_selectedDemoIndex) {
              0 => _buildShimmerSweepOption(),
              1 => _buildCredsOption(),
              2 => _buildLevitation3DOption(),
              3 => _buildEmblem3DOption(),
              _ => _buildShimmerSweepOption(),
            },
          ),
        ),
      ),
    );
  }

  /// Información textual descriptiva
  Widget _buildBrandInfo() {
    const descriptions = [
      'Barrido especular a 65° con pausa orgánica de 1.3s',
      'Gema 3D en GPU con arista axial y tipografía cinética',
      'Levitación armónica con física de sombra lumínica real',
      'Perspectiva focal 3D en eje Y con compresión angular',
    ];

    return Column(
      children: [
        Text(
          'CREDS',
          style: AppTypography.headlineMedium.copyWith(
            letterSpacing: 4.0,
          ),
        ),
        SizedBox(height: 0.35.rem),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0.rem),
          child: Text(
            descriptions[_selectedDemoIndex],
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  /// Barra selectora horizontal con micro-interacción y respuesta háptica nativa
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
              onTap: () => _onDemoChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryAction
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryAction
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  demos[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 0.72.rem,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.background
                        : AppColors.textLight,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Botón de acción al pie de página
  Widget _buildFooterAction() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.0.rem),
      child: AppButton(
        text: 'Continuar a la Aplicación',
        onPressed: widget.onContinue ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.inputSurface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: Text(
                    '¡Bienvenido a Samoa / CREDS!',
                    style: AppTypography.bodySmall,
                  ),
                ),
              );
            },
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. ANIMACIONES DETALLADAS (Opciones 1 a 4)
  // -------------------------------------------------------------

  /// OPCIÓN 1: Prisma (Barrido Especular con Pausa Orgánica y BlendMode.srcATop)
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
          sweepProgress = 1.0; // Pausa orgánica de reposo (1.3s)
        }

        return SizedBox(
          width: 190,
          height: 190,
          child: Center(
            child: ShaderMask(
              blendMode: BlendMode.srcATop,
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

  /// OPCIÓN 2: CREDS (Gema Líquida 3D Translúcida y Tipografía Cinética)
  Widget _buildCredsOption() {
    return AnimatedBuilder(
      animation: _credsController,
      builder: (context, child) {
        final t = _credsController.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 190,
              height: 180,
              child: CustomPaint(
                painter: _FluidOrbPainter(t),
              ),
            ),
            SizedBox(height: 1.0.rem),
            _buildCredsKineticText(t),
          ],
        );
      },
    );
  }

  /// Tipografía Cinética Horizontal de CREDS
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

  /// OPCIÓN 3: 3D Float (Levitación Vertical con Sombra Física Dinámica)
  Widget _buildLevitation3DOption() {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        final progress = _rippleController.value;
        final floatOffset = math.sin(progress * 2 * math.pi) * 8.0;
        final heightFactor = (floatOffset + 8.0) / 16.0;

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
              Transform.translate(
                offset: Offset(0, floatOffset),
                child: const AppLogo(width: 90, height: 110),
              ),
              const SizedBox(height: 18),
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

  /// OPCIÓN 4: Emblema (Giro 3D en Perspectiva de 360°)
  Widget _buildEmblem3DOption() {
    return AnimatedBuilder(
      animation: _emblem3DController,
      builder: (context, child) {
        final angle = _emblem3DController.value * 2 * math.pi;
        final compression = (math.cos(angle)).abs();
        final shadowWidth = 18.0 + (compression * 42.0);

        return SizedBox(
          width: 220,
          height: 220,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018)
                  ..rotateY(angle),
                child: const AppLogo(width: 90, height: 110),
              ),
              const SizedBox(height: 18),
              Container(
                width: shadowWidth,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(shadowWidth / 2, 5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.15 + (compression * 0.30),
                      ),
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
}

/// Pintor GPU de la Gema 3D Líquida (Squircle 45°, Arista Axial y Rim Neón)
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
          const Color(0xFF00FF66)
              .withValues(alpha: 0.15 + (math.sin(t) * 0.08)),
          Colors.white.withValues(alpha: 0.45 + (math.sin(t) * 0.18)),
          const Color(0xFF00E5FF)
              .withValues(alpha: 0.20 + (math.sin(t) * 0.08)),
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

    // 2. Geometría limpia de Cojín/Diamante Squircle
    const baseR = 62.0;
    final stretchH = math.sin(t) * 2.2;
    final stretchV = math.cos(t) * 2.2;

    final topP = Offset(center.dx, center.dy - baseR + stretchV);
    final rightP = Offset(center.dx + baseR + stretchH, center.dy);
    final bottomP = Offset(center.dx, center.dy + baseR - stretchV);
    final leftP = Offset(center.dx - baseR - stretchH, center.dy);

    final fullPath = Path()..moveTo(topP.dx, topP.dy);
    fullPath.cubicTo(
      center.dx + baseR * 0.58,
      center.dy - baseR * 0.58,
      center.dx + baseR * 0.88,
      center.dy - baseR * 0.18,
      rightP.dx,
      rightP.dy,
    );
    fullPath.cubicTo(
      center.dx + baseR * 0.88,
      center.dy + baseR * 0.18,
      center.dx + baseR * 0.58,
      center.dy + baseR * 0.58,
      bottomP.dx,
      bottomP.dy,
    );
    fullPath.cubicTo(
      center.dx - baseR * 0.58,
      center.dy + baseR * 0.58,
      center.dx - baseR * 0.88,
      center.dy + baseR * 0.18,
      leftP.dx,
      leftP.dy,
    );
    fullPath.cubicTo(
      center.dx - baseR * 0.88,
      center.dy - baseR * 0.18,
      center.dx - baseR * 0.58,
      center.dy - baseR * 0.58,
      topP.dx,
      topP.dy,
    );
    fullPath.close();

    // 3. Relleno de Cristal Translúcido con el color Lila de la app
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
      center.dx - 10 + (math.sin(t) * 4),
      center.dy,
      bottomP.dx,
      bottomP.dy,
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
      ..shader = sweepGradient
          .createShader(Rect.fromCircle(center: center, radius: 74))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0);
    canvas.drawPath(fullPath, haloPaint);

    // Rim perimetral nítido
    final rimPaint = Paint()
      ..shader = sweepGradient
          .createShader(Rect.fromCircle(center: center, radius: 74))
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
