import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart';

import 'creds_api_service.dart';

/// Servicio multiplataforma para leer la agenda de contactos del dispositivo
/// sin romper Flutter Web ni los widget tests.
class ContactsService {
  ContactsService._();

  static final ContactsService instance = ContactsService._();

  /// Indica si la plataforma soporta lectura directa de la agenda.
  bool get isSupportedOnPlatform => !kIsWeb;

  /// Solicita permiso y lee los contactos con nombre, teléfono o correo.
  /// En Web o si el permiso es denegado, retorna una lista vacía.
  Future<List<CredsContactMatchInput>> readDeviceContacts({
    bool requestPermission = true,
  }) async {
    if (kIsWeb) return const [];

    try {
      final granted = requestPermission
          ? await FlutterContacts.requestPermission(readonly: true)
          : await FlutterContacts.requestPermission(readonly: true);
      if (!granted) return const [];

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final result = <CredsContactMatchInput>[];
      for (final contact in contacts) {
        final name = contact.displayName.trim();
        if (name.isEmpty) continue;

        final phone = contact.phones.isNotEmpty
            ? _normalizePhone(contact.phones.first.number)
            : null;
        final email = contact.emails.isNotEmpty
            ? contact.emails.first.address.trim()
            : null;

        if ((phone == null || phone.isEmpty) &&
            (email == null || email.isEmpty)) {
          continue;
        }

        result.add(
          CredsContactMatchInput(
            name: name,
            phoneNumber: phone,
            email: email,
          ),
        );
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  String? _normalizePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return null;
    return hasPlus ? '+$digits' : digits;
  }
}
