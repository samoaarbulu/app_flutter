import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/services/firebase_initializer.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/screens/preloading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase en segundo plano sin bloquear el primer frame de la app.
  unawaited(FirebaseInitializer.initialize());

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
