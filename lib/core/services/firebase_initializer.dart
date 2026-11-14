import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_options_dev.dart' as dev_options;

/// Inicializador de Firebase con soporte para entornos de ejecución.
abstract final class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: dev_options.DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase inicializado con éxito (getcreds-dev)');
    } catch (e) {
      debugPrint('ℹ️ Error al inicializar Firebase: $e');
    }
  }
}
