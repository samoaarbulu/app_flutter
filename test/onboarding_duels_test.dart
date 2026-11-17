import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/features/onboarding/models/onboarding_place.dart';
import 'package:app_flutter/features/onboarding/screens/activities_screen.dart';
import 'package:app_flutter/features/onboarding/screens/your_places_screen.dart';
import 'package:app_flutter/shared/widgets/app_button.dart';

void main() {
  group('Onboarding Step 08 - First Ranking Duels Flow', () {
    testWidgets(
        'YourPlacesScreen starts empty and requires 3 selected places to enable Start ranking',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: YourPlacesScreen(),
        ),
      );

      expect(find.text('0 added'), findsOneWidget);
      var startButton =
          tester.widget<AppButton>(find.widgetWithText(AppButton, 'Start ranking'));
      expect(startButton.onPressed, isNull);

      for (final query in ['Atlas', 'Distrito', 'Norte']) {
        await tester.enterText(
          find.widgetWithText(TextFormField, "Search places you've been"),
          query,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_circle_outline_rounded).first);
        await tester.pumpAndSettle();
      }

      expect(find.text('3 added'), findsOneWidget);
      startButton =
          tester.widget<AppButton>(find.widgetWithText(AppButton, 'Start ranking'));
      expect(startButton.onPressed, isNotNull);
    });

    testWidgets(
        'YourPlacesScreen manages minimum 3 places, search, delete, and navigates to ComparePlacesScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: YourPlacesScreen(
            initialPlaces: OnboardingPlace.defaultSelected,
          ),
        ),
      );

      expect(find.text('YOUR PLACES'), findsOneWidget);
      expect(find.text('3 added'), findsOneWidget);
      expect(find.text('Atlas Fitness'), findsOneWidget);
      expect(find.text('Distrito Fuerza'), findsOneWidget);
      expect(find.text('Norte Club'), findsOneWidget);

      // Start ranking habilitado con 3 lugares
      var startButton =
          tester.widget<AppButton>(find.widgetWithText(AppButton, 'Start ranking'));
      expect(startButton.onPressed, isNotNull);

      // Eliminar Norte Club -> queda en 2 added y se deshabilita Start ranking
      await tester.ensureVisible(find.byTooltip('Remove Norte Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove Norte Club'));
      await tester.pumpAndSettle();

      expect(find.text('2 added'), findsOneWidget);
      startButton =
          tester.widget<AppButton>(find.widgetWithText(AppButton, 'Start ranking'));
      expect(startButton.onPressed, isNull);

      // Buscar 'Koa' y agregarlo -> vuelve a 3 added y habilita Start ranking
      await tester.enterText(
        find.widgetWithText(TextFormField, "Search places you've been"),
        'Koa',
      );
      await tester.pumpAndSettle();

      expect(find.text('Koa Studio'), findsOneWidget);
      await tester.tap(find.text('Koa Studio'));
      await tester.pumpAndSettle();

      expect(find.text('3 added'), findsOneWidget);
      startButton =
          tester.widget<AppButton>(find.widgetWithText(AppButton, 'Start ranking'));
      expect(startButton.onPressed, isNotNull);

      // Navegar a ComparePlacesScreen
      await tester.tap(find.text('Start ranking'));
      await tester.pumpAndSettle();

      expect(find.text('COMPARE'), findsOneWidget);
      expect(find.text('COMPARISON 1 OF 3'), findsOneWidget);
      expect(find.text('Which was better?'), findsOneWidget);
    });

    testWidgets(
        'Completing 3 comparisons navigates to FirstRankingScreen with sorted winners',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: YourPlacesScreen(
            initialPlaces: OnboardingPlace.defaultSelected,
          ),
        ),
      );

      await tester.tap(find.text('Start ranking'));
      await tester.pumpAndSettle();

      // Ronda 1: Atlas Fitness vs Distrito Fuerza -> gana Atlas Fitness
      expect(find.text('COMPARISON 1 OF 3'), findsOneWidget);
      await tester.tap(find.text('Atlas Fitness'));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      // Ronda 2: Atlas Fitness vs Norte Club -> gana Atlas Fitness
      expect(find.text('COMPARISON 2 OF 3'), findsOneWidget);
      await tester.tap(find.text('Atlas Fitness'));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      // Ronda 3: Distrito Fuerza vs Norte Club -> gana Distrito Fuerza
      expect(find.text('COMPARISON 3 OF 3'), findsOneWidget);
      await tester.tap(find.text('Distrito Fuerza'));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      // Resultado final: FirstRankingScreen
      expect(find.text('Your first ranking is in'), findsOneWidget);
      expect(find.text('BASED ON YOUR CHOICES'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('2 of 2 comparisons won'), findsOneWidget);
      expect(find.text('1 of 2 comparisons won'), findsOneWidget);
      expect(find.text('0 of 2 comparisons won'), findsOneWidget);
      expect(find.text('Save and continue'), findsOneWidget);

      // Paso 09: UsefulPermissionsScreen
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      expect(find.text('Make Creds more useful'), findsOneWidget);
      expect(find.text('Find friends who already use Creds.'), findsOneWidget);

      // Paso 10: FollowSuggestionsScreen -> HomeScreen
      await tester.tap(find.text('Continue with my selection'));
      await tester.pumpAndSettle();
      expect(find.text('Training is better together'), findsOneWidget);
      expect(find.text('Follow 2 and go to Home'), findsOneWidget);

      await tester.tap(find.text('Follow 2 and go to Home'));
      await tester.pumpAndSettle();
      expect(find.text('CREDS'), findsOneWidget);
    });

    testWidgets('ActivitiesScreen navigates to YourPlacesScreen on Continue',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivitiesScreen(),
        ),
      );

      await tester.tap(find.text('Strength training'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('YOUR PLACES'), findsOneWidget);
      expect(find.text("Start with places you've\ntried"), findsOneWidget);
    });
  });
}
