/// Modelo inmutable de país y prefijo telefónico internacional.
class CountryCode {
  final String name;
  final String flag;
  final String dialCode;
  final String code;

  const CountryCode({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.code,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryCode &&
          runtimeType == other.runtimeType &&
          dialCode == other.dialCode &&
          code == other.code;

  @override
  int get hashCode => dialCode.hashCode ^ code.hashCode;
}

/// Lista curada de países para el selector de prefijos telefónicos.
///
/// Utiliza emojis Unicode de banderas nativas (Apple Color Emoji en iOS)
/// para un renderizado vectorial instantáneo sin requerir assets de red o paquetes pesados.
abstract final class CountryCodes {
  /// País por defecto del diseño oficial de Figma: México (+52)
  static const CountryCode defaultCountry = CountryCode(
    name: 'México',
    flag: '🇲🇽',
    dialCode: '+52',
    code: 'MX',
  );

  static const List<CountryCode> all = [
    CountryCode(name: 'México', flag: '🇲🇽', dialCode: '+52', code: 'MX'),
    CountryCode(name: 'Estados Unidos', flag: '🇺🇸', dialCode: '+1', code: 'US'),
    CountryCode(name: 'Canadá', flag: '🇨🇦', dialCode: '+1', code: 'CA'),
    CountryCode(name: 'España', flag: '🇪🇸', dialCode: '+34', code: 'ES'),
    CountryCode(name: 'Colombia', flag: '🇨🇴', dialCode: '+57', code: 'CO'),
    CountryCode(name: 'Argentina', flag: '🇦🇷', dialCode: '+54', code: 'AR'),
    CountryCode(name: 'Perú', flag: '🇵🇪', dialCode: '+51', code: 'PE'),
    CountryCode(name: 'Chile', flag: '🇨🇱', dialCode: '+56', code: 'CL'),
    CountryCode(name: 'Brasil', flag: '🇧🇷', dialCode: '+55', code: 'BR'),
    CountryCode(name: 'Ecuador', flag: '🇪🇨', dialCode: '+593', code: 'EC'),
    CountryCode(name: 'Guatemala', flag: '🇬🇹', dialCode: '+502', code: 'GT'),
    CountryCode(name: 'Costa Rica', flag: '🇨🇷', dialCode: '+506', code: 'CR'),
    CountryCode(name: 'Panamá', flag: '🇵🇦', dialCode: '+507', code: 'PA'),
    CountryCode(name: 'Rep. Dominicana', flag: '🇩🇴', dialCode: '+1', code: 'DO'),
    CountryCode(name: 'Uruguay', flag: '🇺🇾', dialCode: '+598', code: 'UY'),
    CountryCode(name: 'Bolivia', flag: '🇧🇴', dialCode: '+591', code: 'BO'),
    CountryCode(name: 'Paraguay', flag: '🇵🇾', dialCode: '+595', code: 'PY'),
    CountryCode(name: 'Venezuela', flag: '🇻🇪', dialCode: '+58', code: 'VE'),
    CountryCode(name: 'Reino Unido', flag: '🇬🇧', dialCode: '+44', code: 'GB'),
    CountryCode(name: 'Francia', flag: '🇫🇷', dialCode: '+33', code: 'FR'),
    CountryCode(name: 'Alemania', flag: '🇩🇪', dialCode: '+49', code: 'DE'),
    CountryCode(name: 'Italia', flag: '🇮🇹', dialCode: '+39', code: 'IT'),
  ];
}

