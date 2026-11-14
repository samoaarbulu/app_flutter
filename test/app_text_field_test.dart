import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/shared/widgets/app_text_field.dart';

void main() {
  group('AppTextField - Focus Loss Email Validation', () {
    testWidgets('shows error when invalid email loses focus',
        (WidgetTester tester) async {
      final emailFocusNode = FocusNode();
      final otherFocusNode = FocusNode();
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppTextField.email(
                  controller: controller,
                  focusNode: emailFocusNode,
                ),
                TextField(
                  focusNode: otherFocusNode,
                ),
              ],
            ),
          ),
        ),
      );

      // Inicialmente no hay error
      expect(find.text('Please enter a valid email address'), findsNothing);

      // 1. Obtener foco en el campo de email
      emailFocusNode.requestFocus();
      await tester.pump();

      // 2. Escribir email incompleto / inválido
      await tester.enterText(find.byType(TextFormField), 'correo_invalido');
      await tester.pump();

      // Mientras tiene foco, todavía no se muestra el error de desenfoque
      expect(find.text('Please enter a valid email address'), findsNothing);

      // 3. Perder foco pasando al siguiente campo
      otherFocusNode.requestFocus();
      await tester.pumpAndSettle();

      // Ahora debe mostrar el mensaje de error y el icono de alerta
      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      // 4. Regresar el foco y corregir a un correo válido
      emailFocusNode.requestFocus();
      await tester.pump();
      await tester.enterText(
          find.byType(TextFormField), 'valido@empresa.com');
      await tester.pump();

      // El error debe desaparecer en tiempo real tan pronto el texto es válido
      expect(find.text('Please enter a valid email address'), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('shows custom error message on blur when provided',
        (WidgetTester tester) async {
      final emailFocusNode = FocusNode();
      final otherFocusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppTextField.email(
                  focusNode: emailFocusNode,
                  emailErrorMessage: 'Formato de correo no válido',
                ),
                TextField(focusNode: otherFocusNode),
              ],
            ),
          ),
        ),
      );

      emailFocusNode.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'invalido@');
      await tester.pump();

      otherFocusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Formato de correo no válido'), findsOneWidget);
    });

    testWidgets('shows empty email message on blur when left empty',
        (WidgetTester tester) async {
      final emailFocusNode = FocusNode();
      final otherFocusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppTextField.email(
                  focusNode: emailFocusNode,
                ),
                TextField(focusNode: otherFocusNode),
              ],
            ),
          ),
        ),
      );

      emailFocusNode.requestFocus();
      await tester.pump();

      otherFocusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
    });

    testWidgets('does not show error when valid email loses focus',
        (WidgetTester tester) async {
      final emailFocusNode = FocusNode();
      final otherFocusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppTextField.email(
                  focusNode: emailFocusNode,
                ),
                TextField(focusNode: otherFocusNode),
              ],
            ),
          ),
        ),
      );

      emailFocusNode.requestFocus();
      await tester.pump();
      await tester.enterText(
          find.byType(TextFormField), 'ana.torres@gmail.com');
      await tester.pump();

      otherFocusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsNothing);
      expect(find.text('Please enter your email address'), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });
  });
}

