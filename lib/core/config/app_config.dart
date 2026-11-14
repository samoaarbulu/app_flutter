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

  /// URL base del backend NestJS (versionada bajo `/v1`).
  ///
  /// - Por defecto (`dev`): `https://api-dev.getcreds.co/v1` (listo para usar sin backend local).
  /// - Producción (`--dart-define=ENV=prod`): `https://api.getcreds.co/v1`.
  ///
  /// Puede sobreescribirse opcionalmente (ej. para backend local) con:
  /// `--dart-define=API_BASE_URL=http://localhost:3000/v1`
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:3000/v1` (emulador Android)
  static String get apiBaseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final trimmed = customUrl.trim();
    if (trimmed.isNotEmpty) {
      final clean = trimmed.endsWith('/')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed;
      // Garantiza sufijo `/v1` aunque se pase solo el dominio raíz.
      return clean.endsWith('/v1') ? clean : '$clean/v1';
    }
    return isProd
        ? 'https://api.getcreds.co/v1'
        : 'https://api-dev.getcreds.co/v1';
  }
}

