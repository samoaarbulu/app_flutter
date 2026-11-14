import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/features/onboarding/screens/activities_screen.dart';
import 'package:app_flutter/features/onboarding/screens/location_permission_screen.dart';
import 'package:app_flutter/shared/widgets/app_button.dart';

void main() {
  group('ActivitiesScreen Tests', () {
    testWidgets('Renders header, grid items, and excludes bottom helper label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivitiesScreen(),
        ),
      );

      expect(find.text('ACTIVITIES'), findsOneWidget);
      expect(find.text('How do you like to train?'), findsOneWidget);
      expect(
        find.text(
          'Choose your usual activities. You can select more than one.',
        ),
        findsOneWidget,
      );

      expect(find.text('Strength training'), findsOneWidget);
      expect(find.text('HIIT'), findsOneWidget);
      expect(find.text('Pilates'), findsOneWidget);
      expect(find.text('Yoga'), findsOneWidget);

      // Verificar que el label excluido no esté presente
      expect(find.textContaining('Your workout, no labels.'), findsNothing);

      // Botón deshabilitado inicialmente con texto 'Continue'
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.text, 'Continue');
      expect(button.onPressed, isNull);
    });

    testWidgets(
        'Selecting and deselecting activities updates button text and state',
        (WidgetTester tester) async {
      List<String>? submittedIds;

      await tester.pumpWidget(
        MaterialApp(
          home: ActivitiesScreen(
            onContinue: (ids) => submittedIds = ids,
          ),
        ),
      );

      // Seleccionar 1 actividad
      await tester.tap(find.text('Strength training'));
      await tester.pumpAndSettle();

      var button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.text, 'Continue with 1 activity');
      expect(button.onPressed, isNotNull);

      // Seleccionar 2da y 3ra actividad (asegurando visibilidad si la pantalla de test es corta)
      await tester.tap(find.text('HIIT'));
      await tester.ensureVisible(find.text('Pilates'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilates'));
      await tester.pumpAndSettle();

      button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.text, 'Continue with 3 activities');

      // Deseleccionar 1 actividad
      await tester.ensureVisible(find.text('Pilates'));
      await tester.tap(find.text('Pilates'));
      await tester.pumpAndSettle();

      button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.text, 'Continue with 2 activities');

      // Confirmar envío
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(submittedIds, containsAll(['strength_training', 'hiit']));
      expect(submittedIds?.length, 2);
    });

    testWidgets(
        'LocationPermissionScreen navigates to ActivitiesScreen on Enable permissions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LocationPermissionScreen(),
        ),
      );

      await tester.tap(find.text('Enable permissions'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVITIES'), findsOneWidget);
      expect(find.text('How do you like to train?'), findsOneWidget);
    });

    testWidgets(
        'LocationPermissionScreen navigates to ActivitiesScreen on Do this later',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LocationPermissionScreen(),
        ),
      );

      await tester.tap(find.text('Do this later'));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVITIES'), findsOneWidget);
      expect(find.text('How do you like to train?'), findsOneWidget);
    });
  });
}
