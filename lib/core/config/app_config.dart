/// Configuración de entornos de ejecución para Creds (DEV y PROD).
enum Environment {
  dev,
  prod,
}

abstract final class AppConfig {
  /// Determina el entorno activo mediante --dart-define=ENV=prod (por defecto 'dev')
  static const String _env =
      String.fromEnvironment('ENV', defaultValue: 'dev');

  static Environment get environment =>
      _env.toLowerCase() == 'prod' ? Environment.prod : Environment.dev;

  static bool get isProd => environment == Environment.prod;
  static bool get isDev => environment == Environment.dev;

  static String get projectId => isProd ? 'getcreds-prod' : 'getcreds-dev';
  static String get appName => isProd ? 'Creds' : 'Creds (Dev)';
}

