import 'package:flutter/material.dart';

/// Isotipo "G" estilizado en monocromo para el botón de autenticación con Google.
class AppGoogleIcon extends StatelessWidget {
  final double size;
  final Color color;

  const AppGoogleIcon({
    super.key,
    this.size = 20,
    this.color = const Color(0xFF1E1E1E),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: size * 0.95,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

