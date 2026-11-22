import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/core/services/media_service.dart';
import 'package:app_flutter/features/auth/services/auth_service.dart';
import 'package:app_flutter/features/home/screens/home_screen.dart';

void main() {
  tearDown(() {
    AuthService.instance.setCustomPhoto(null);
  });

  group('HomeScreen Redesign Tests', () {
    testWidgets(
        'Renders CREDS header, invite banner, user name/initials fallback, filters, feed and bottom nav',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.text('CREDS'), findsOneWidget);
      expect(find.text('Invite 5 friends'), findsOneWidget);
      expect(
        find.text('This will unlock more activities in Creds'),
        findsOneWidget,
      );

      // Iniciales de respaldo cuando no hay foto y compositor "Ask your people"
      expect(find.text('AT'), findsOneWidget);
      expect(find.text('Ask your people'), findsOneWidget);

      // Filtros y feed
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('For you'), findsOneWidget);
      expect(find.text('Sofía Martínez gave creds to Atlas Fitness'), findsOneWidget);

      // Bottom navigation bar (5 tabs)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My lists'), findsOneWidget);
      expect(find.text('Log'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets(
        'Shows user profile photo instead of initials when customPhoto is available',
        (WidgetTester tester) async {
      // PNG válido de 1x1 pixel transparente
      final valid1x1Png = Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      AuthService.instance.setCustomPhoto(
        PickedImage(bytes: valid1x1Png, name: 'avatar.png'),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      // Ya no muestra 'AT' en el compositor porque tiene foto de perfil
      expect(find.text('AT'), findsNothing);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets(
        'Filters feed posts, toggles likes, and switches to Profile tab with Sign out',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Filtrar por "For you" y volver a "All"
      await tester.tap(find.text('For you'));
      await tester.pumpAndSettle();
      expect(find.text('Sofía Martínez gave creds to Atlas Fitness'), findsNothing);
      expect(find.text('Luis Chacon gave creds to Gym Fitness'), findsOneWidget);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Like en primer post: 24 -> 25
      expect(find.text('24'), findsOneWidget);
      await tester.ensureVisible(find.text('24'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('24'));
      await tester.pumpAndSettle();
      expect(find.text('25'), findsOneWidget);

      // Cambiar a tab Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets(
        'Recommendations flow: opens NewRecommendationScreen, posts, opens RecommendationShareScreen and prepends to Home feed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // 1. Tocar "Ask your people"
      await tester.tap(find.text('Ask your people'));
      await tester.pumpAndSettle();

      expect(find.text('Ask your people'), findsWidgets);

      // 2. Seleccionar actividad en el bottom sheet "Select activity"
      await tester.tap(find.text('Add activity'));
      await tester.pumpAndSettle();
      expect(find.text('Select activity'), findsOneWidget);
      await tester.tap(find.text('Pilates').last);
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Pilates'), findsWidgets);

      // 3. Seleccionar ubicación en el bottom sheet
      await tester.tap(find.text('Select location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lima, Peru'));
      await tester.pumpAndSettle();
      expect(find.text('Lima, Peru'), findsOneWidget);

      // 4. Ingresar detalles
      await tester.enterText(
        find.byType(TextField),
        'Looking for morning vinyasa classes with good natural light.',
      );
      await tester.pump();

      // 5. Publicar ("Post") -> navega a RecommendationShareScreen
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      expect(find.text('@ana.torres'), findsOneWidget);
      expect(find.textContaining('Pilates'), findsWidgets);
      expect(find.textContaining('Lima, Peru'), findsWidgets);
      expect(find.text('Copy link'), findsOneWidget);

      // 6. Probar acción "Copy link"
      await tester.tap(find.text('Copy link'));
      await tester.pump();
      expect(find.text('Recommendation link copied'), findsOneWidget);

      // 7. Regresar al Home y verificar que aparece en el feed
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(
        find.text('Ana Torres asked about Pilates'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Add Visit flow: opens AddVisitSheet from +, edits tags/notes, resolves Versus, opens VisitShareScreen and prepends to Home feed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // 1. Tocar botón '+' de la primera tarjeta (Atlas Fitness)
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Atlas Fitness'), findsWidgets);
      expect(find.text('How was it?'), findsOneWidget);
      expect(find.text('Loved it'), findsOneWidget);
      expect(find.text('Which list would you add it to?'), findsOneWidget);

      // 2. Ir a Add tags -> seleccionar Atmosphere -> Done
      await tester.ensureVisible(find.text('Add tags'));
      await tester.tap(find.text('Add tags'));
      await tester.pumpAndSettle();
      expect(find.text('Most used'), findsOneWidget);
      await tester.tap(find.text('Atmosphere'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Atmosphere'), findsOneWidget);

      // 3. Ir a Add notes -> escribir nota -> Done
      await tester.ensureVisible(find.text('Add notes'));
      await tester.tap(find.text('Add notes'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Great strength equipment!',
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Great strength equipment!'), findsOneWidget);

      // 4. Tocar 'Add' -> abre paso Versus ("Which place do you prefer?")
      await tester.ensureVisible(find.text('Add'));
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Which place do you prefer?'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('Hard to decide'), findsOneWidget);

      // 5. Elegir 'Atlas Fitness' en el Versus -> navega a VisitShareScreen
      await tester.tap(find.text('Atlas Fitness').last);
      await tester.pumpAndSettle();

      expect(find.text('@ana.torres'), findsOneWidget);
      expect(find.text('9.0'), findsOneWidget);
      expect(find.text('1 visit'), findsOneWidget);
      expect(find.text('Share to get more responses'), findsOneWidget);

      // 6. Probar Copy link
      await tester.tap(find.text('Copy link'));
      await tester.pump();
      expect(find.text('Visit link copied'), findsOneWidget);

      // 7. Cerrar VisitShareScreen y verificar publicación en Home
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Ana Torres rated Atlas Fitness'), findsOneWidget);
    });

    testWidgets(
        'Add Favorite flow: opens AddFavoriteSheet from bookmark, selects list/notes, saves and toggles bookmark',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // 1. Tocar bookmark en la primera tarjeta (Atlas Fitness)
      final firstBookmark = find.byIcon(Icons.bookmark_border_rounded).first;
      await tester.ensureVisible(firstBookmark);
      await tester.pumpAndSettle();
      await tester.tap(firstBookmark);
      await tester.pumpAndSettle();

      expect(find.text('Which list would you add it to?'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Add notes'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // 2. Cambiar lista a "Want to try"
      await tester.tap(find.text('Which list would you add it to?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Want to try'));
      await tester.pumpAndSettle();
      expect(find.text('Want to try'), findsOneWidget);

      // 3. Agregar nota
      await tester.tap(find.text('Add notes'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Must try weekend reformer class',
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Must try weekend reformer class'), findsOneWidget);

      // 4. Guardar favorito
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Atlas Fitness saved to Want to try'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

      // 5. Verificar en la pestaña "My lists" que aparece el favorito guardado
      await tester.tap(find.text('My lists'));
      await tester.pumpAndSettle();
      expect(find.text('Saved favorites'), findsOneWidget);
      expect(find.text('Want to try'), findsOneWidget);

      // 6. Volver a Home y tocar el bookmark relleno para mostrar/quitar el favorito
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bookmark_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Want to try'), findsOneWidget);
      expect(find.text('Must try weekend reformer class'), findsOneWidget);
      expect(find.text('Update favorite'), findsOneWidget);
      expect(find.text('Remove from favorites'), findsOneWidget);

      await tester.tap(find.text('Remove from favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Atlas Fitness removed from favorites'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
    });
  });
}
