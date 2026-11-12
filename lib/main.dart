import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/presentacion.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de la barra de estado y navegación del sistema
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const CredsApp());
}

class CredsApp extends StatelessWidget {
  const CredsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CREDS / Demo Samoa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const PresentationScreen(),
    );
  }
}
