import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/features/auth/screens/create_account_screen.dart';
import 'package:app_flutter/shared/widgets/app_button.dart';
import 'package:app_flutter/shared/widgets/app_text_field.dart';

void main() {
  group('CreateAccountScreen - Password & Email Validation, Button States', () {
    testWidgets('Password requires at least 8 chars, 1 letter and 1 number', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateAccountScreen(initialEmail: 'ana.torres@correo.com'),
        ),
      );

      final passwordField = find.widgetWithText(
        AppTextField,
        'Create a password',
      );
      final passwordInput = find.descendant(
        of: passwordField,
        matching: find.byType(TextFormField),
      );
      final emailField = find.widgetWithText(AppTextField, 'Email address');

      // 1. Password con menos de 8 caracteres (ej. 'abc1')
      await tester.enterText(passwordInput, 'abc1');
      await tester.pump();

      // Perder el foco hacia el campo de email
      await tester.tap(emailField);
      await tester.pumpAndSettle();

      expect(
        find.text('Use 8 or more characters, a letter and a number'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsWidgets);

      // 2. Password con 8 caracteres pero sin números (ej. 'sololetras')
      await tester.enterText(passwordInput, 'sololetras');
      await tester.pump();

      await tester.tap(emailField);
      await tester.pumpAndSettle();

      expect(
        find.text('Use 8 or more characters, a letter and a number'),
        findsOneWidget,
      );

      // 3. Password con 8 caracteres pero sin letras (ej. '12345678')
      await tester.enterText(passwordInput, '12345678');
      await tester.pump();

      await tester.tap(emailField);
      await tester.pumpAndSettle();

      expect(
        find.text('Use 8 or more characters, a letter and a number'),
        findsOneWidget,
      );

      // 4. Password válido: 8 caracteres con letra y número (ej. 'pass1234')
      await tester.enterText(passwordInput, 'pass1234');
      await tester.pump();

      // El error se limpia reactivamente en tiempo real
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets(
      'Send code button is disabled when email or password is invalid and helper text hides when valid',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: CreateAccountScreen()));

        final buttonFinder = find.widgetWithText(AppButton, 'Send code');
        AppButton button = tester.widget<AppButton>(buttonFinder);

        // Con el password inicial vacío, el botón debe estar deshabilitado
        expect(button.onPressed, isNull);

        // El helper text se muestra inicialmente para guiar al usuario
        expect(
          find.text('Use 8 or more characters, a letter and a number.'),
          findsOneWidget,
        );

        // 1. Ingresar email y password válidos
        final emailField = find.widgetWithText(AppTextField, 'Email address');
        final emailInput = find.descendant(
          of: emailField,
          matching: find.byType(TextFormField),
        );
        await tester.enterText(emailInput, 'ana.torres@correo.com');

        final passwordField = find.widgetWithText(
          AppTextField,
          'Create a password',
        );
        final passwordInput = find.descendant(
          of: passwordField,
          matching: find.byType(TextFormField),
        );

        await tester.enterText(passwordInput, 'password123');
        await tester.pumpAndSettle();

        // Sin confirmar contraseña, el botón sigue deshabilitado
        button = tester.widget<AppButton>(buttonFinder);
        expect(button.onPressed, isNull);

        final confirmField = find.widgetWithText(
          AppTextField,
          'Confirm password',
        );
        final confirmInput = find.descendant(
          of: confirmField,
          matching: find.byType(TextFormField),
        );

        // Si no coincide, el botón sigue deshabilitado y al perder foco muestra error
        await tester.enterText(confirmInput, 'otraClave123');
        await tester.pumpAndSettle();
        button = tester.widget<AppButton>(buttonFinder);
        expect(button.onPressed, isNull);

        await tester.tap(find.widgetWithText(AppTextField, 'Email address'));
        await tester.pumpAndSettle();
        expect(find.text('Passwords do not match'), findsOneWidget);

        // Al coincidir, el botón se habilita
        await tester.enterText(confirmInput, 'password123');
        await tester.pumpAndSettle();

        // Ahora con email inicial ('ana.torres@correo.com') y password válido, el botón se habilita
        button = tester.widget<AppButton>(buttonFinder);
        expect(button.onPressed, isNotNull);

        // El mensaje de ayuda se oculta automáticamente para no confundir al usuario
        expect(
          find.text('Use 8 or more characters, a letter and a number.'),
          findsNothing,
        );

        // 2. Invalidar email borrándolo o poniendo formato erróneo
        await tester.enterText(emailInput, 'correo_invalido');
        await tester.pumpAndSettle();

        button = tester.widget<AppButton>(buttonFinder);
        expect(button.onPressed, isNull);

        // 3. Corregir email
        await tester.enterText(emailInput, 'usuario@empresa.com');
        await tester.pumpAndSettle();

        button = tester.widget<AppButton>(buttonFinder);
        expect(button.onPressed, isNotNull);

        // 4. Invalidar password (menos de 8 caracteres)
        await tester.enterText(passwordInput, '123');
        await tester.pumpAndSettle();

        button = tester.widget<AppButton>(buttonFinder);
        expect(button.onPressed, isNull);

        // El helper text reaparece al volverse inválido
        expect(
          find.text('Use 8 or more characters, a letter and a number.'),
          findsOneWidget,
        );

        // 5. Corregir password y confirm password
        await tester.enterText(passwordInput, 'claveSegura2026');
        await tester.enterText(confirmInput, 'claveSegura2026');
        await tester.pumpAndSettle();

        button = tester.widget<AppButton>(buttonFinder);
        expect(button.onPressed, isNotNull);

        // El helper text vuelve a ocultarse
        expect(
          find.text('Use 8 or more characters, a letter and a number.'),
          findsNothing,
        );
      },
    );
  });
}
