import 'package:flutter/material.dart';

/// Isotipo oficial de la marca con dimensiones parametrizables y soporte para animaciones Hero.
///
/// Implementa carga de imagen `assets/images/logo.png` con un respaldo vectorial
/// generado por código (GPU) para garantizar que los Shaders y animaciones
/// funcionen sin interrupciones incluso si el archivo PNG aún no ha sido colocado.
class AppLogo extends StatelessWidget {
  final double width;
  final double height;
  final String? heroTag;

  const AppLogo({
    super.key,
    this.width = 90,
    this.height = 110,
    this.heroTag = 'app_logo',
  });

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = Image.asset(
      'assets/images/logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Respaldo vectorial de la silueta oficial
        return _VectorLogoFallback(width: width, height: height);
      },
    );

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(
        tag: heroTag!,
        child: logoWidget,
      );
    }

    return logoWidget;
  }
}

/// Dibuja la silueta vectorial de la gema oficial con alfa nítido para que
/// ShaderMask (BlendMode.srcATop) recorte el brillo sobre sus trazos.
class _VectorLogoFallback extends StatelessWidget {
  final double width;
  final double height;

  const _VectorLogoFallback({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CrestPainter(),
      ),
    );
  }
}

class _CrestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) * 0.88;

    final topP = Offset(center.dx, center.dy - radius);
    final rightP = Offset(center.dx + radius * 0.85, center.dy);
    final bottomP = Offset(center.dx, center.dy + radius);
    final leftP = Offset(center.dx - radius * 0.85, center.dy);

    final path = Path()..moveTo(topP.dx, topP.dy);
    path.cubicTo(
      center.dx + radius * 0.55, center.dy - radius * 0.55,
      center.dx + radius * 0.80, center.dy - radius * 0.15,
      rightP.dx, rightP.dy,
    );
    path.cubicTo(
      center.dx + radius * 0.80, center.dy + radius * 0.15,
      center.dx + radius * 0.55, center.dy + radius * 0.55,
      bottomP.dx, bottomP.dy,
    );
    path.cubicTo(
      center.dx - radius * 0.55, center.dy + radius * 0.55,
      center.dx - radius * 0.80, center.dy + radius * 0.15,
      leftP.dx, leftP.dy,
    );
    path.cubicTo(
      center.dx - radius * 0.80, center.dy - radius * 0.15,
      center.dx - radius * 0.55, center.dy - radius * 0.55,
      topP.dx, topP.dy,
    );
    path.close();

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);

    // Faceta central en relieve
    final facetPath = Path()
      ..moveTo(topP.dx, topP.dy)
      ..quadraticBezierTo(center.dx - 8, center.dy, bottomP.dx, bottomP.dy)
      ..lineTo(leftP.dx, leftP.dy)
      ..close();

    final facetPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(facetPath, facetPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

