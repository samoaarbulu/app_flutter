import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/services/firebase_initializer.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/preloading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseInitializer.initialize();

  // Configuración de la barra de estado y navegación del sistema (Creds Light)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const CredsApp());
}

class CredsApp extends StatelessWidget {
  const CredsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Creds',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const PreloadingScreen(),
    );
  }
}
