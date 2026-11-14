import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/features/auth/presentation/screens/setup_profile_screen.dart';
import 'package:app_flutter/shared/widgets/app_button.dart';
import 'package:app_flutter/shared/widgets/app_text_field.dart';

void main() {
  group('SetupProfileScreen - Validation, Country Picker & Button States', () {
    testWidgets('Username must start with @ and only @ is considered empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SetupProfileScreen(),
        ),
      );

      // El nombre de usuario inicia con '@'
      expect(find.text('@ana.entrena'), findsOneWidget);

      // Dejar únicamente '@' en el campo
      final usernameField = find.widgetWithText(AppTextField, 'Username');
      await tester.enterText(
        find.descendant(of: usernameField, matching: find.byType(TextFormField)),
        '@',
      );
      await tester.pump();

      // Perder el foco cambiando al siguiente campo
      final phoneField = find.widgetWithText(AppTextField, 'Mobile number');
      await tester.tap(phoneField);
      await tester.pumpAndSettle();

      // Debe mostrar mensaje de que se requiere username y borde en rojo
      expect(find.text('Please enter a username'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsWidgets);
    });

    testWidgets('Username blocks strange characters like = in real time and accepts - _ .',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SetupProfileScreen(),
        ),
      );

      final usernameField = find.widgetWithText(AppTextField, 'Username');
      final inputFinder = find.descendant(
        of: usernameField,
        matching: find.byType(TextFormField),
      );

      // 1. Intentar escribir caracteres extraños como '===='
      await tester.enterText(inputFinder, '@====');
      await tester.pump();

      // El formateador debe bloquearlos de inmediato, dejando únicamente '@'
      expect(find.text('@'), findsOneWidget);
      expect(find.text('@===='), findsNothing);

      // 2. Intentar escribir caracteres extraños entre letras como 'ana=entrena!'
      await tester.enterText(inputFinder, '@ana=entrena!');
      await tester.pump();

      // Solo deben quedar las letras 'anaentrena'
      expect(find.text('@anaentrena'), findsOneWidget);
      expect(find.text('@ana=entrena!'), findsNothing);

      // 3. Escribir caracteres permitidos: letras, números, -, _, .
      await tester.enterText(inputFinder, '@ana_entrena.dev-99');
      await tester.pump();

      // Todos los caracteres permitidos deben mantenerse
      expect(find.text('@ana_entrena.dev-99'), findsOneWidget);
    });

    testWidgets('Mobile number blocks letters and country picker works',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SetupProfileScreen(),
        ),
      );

      // Verifica prefijo por defecto México (+52)
      expect(find.text('+52'), findsOneWidget);
      expect(find.text('🇲🇽'), findsOneWidget);

      // Abrir el CountryPickerBottomSheet mediante el trigger
      await tester.tap(find.byKey(const Key('country_picker_trigger')));
      await tester.pumpAndSettle();

      // Verifica el modal con la lista de países
      expect(find.text('Select country'), findsOneWidget);
      expect(find.text('Estados Unidos'), findsOneWidget);

      // Seleccionar Estados Unidos (+1)
      await tester.tap(find.text('Estados Unidos'));
      await tester.pumpAndSettle();

      // Ahora el prefijo debe ser +1 con bandera de EEUU
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('🇺🇸'), findsOneWidget);

      // Intentar ingresar letras en el teléfono: FilteringTextInputFormatter las bloquea
      final phoneField = find.widgetWithText(AppTextField, 'Mobile number');
      final phoneInput = find.descendant(
        of: phoneField,
        matching: find.byType(TextFormField),
      );

      await tester.enterText(phoneInput, 'trtrt45');
      await tester.pump();

      // Solo debe quedar '45', las letras fueron descartadas automáticamente
      expect(find.text('45'), findsOneWidget);
      expect(find.text('trtrt45'), findsNothing);
    });

    testWidgets('Save and continue button is enabled ONLY when all inputs are valid',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SetupProfileScreen(),
        ),
      );

      // Inicialmente el teléfono está vacío, por lo tanto el botón debe estar deshabilitado
      final buttonFinder = find.widgetWithText(AppButton, 'Save and continue');
      AppButton button = tester.widget<AppButton>(buttonFinder);
      expect(button.onPressed, isNull);

      // Ingresar teléfono válido (10 dígitos)
      final phoneField = find.widgetWithText(AppTextField, 'Mobile number');
      final phoneInput = find.descendant(
        of: phoneField,
        matching: find.byType(TextFormField),
      );

      await tester.enterText(phoneInput, '5512345678');
      await tester.pumpAndSettle();

      // Ahora todos los campos son válidos: el botón debe estar habilitado
      button = tester.widget<AppButton>(buttonFinder);
      expect(button.onPressed, isNotNull);

      // Si borramos el First name, el botón debe deshabilitarse nuevamente
      final firstNameField = find.widgetWithText(AppTextField, 'First name');
      final firstNameInput = find.descendant(
        of: firstNameField,
        matching: find.byType(TextFormField),
      );

      await tester.enterText(firstNameInput, '');
      await tester.pumpAndSettle();

      button = tester.widget<AppButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });
  });
}
