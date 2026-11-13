import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/main.dart';
import 'package:app_flutter/shared/widgets/widgets.dart';

void main() {
  testWidgets('PreloadingScreen and PresentationScreen smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CredsApp());

    // 1. Verifica pantalla de Preloading
    expect(find.text('creds'), findsOneWidget);
    expect(find.text('Where your people go.'), findsOneWidget);

    // 2. Transición a PresentationScreen tras toque
    await tester.tap(find.text('creds'));
    await tester.pumpAndSettle();

    // 3. Verifica elementos de la pantalla de bienvenida
    expect(find.text('Find your place.\nCompare it your way.'), findsOneWidget);
    expect(
      find.text(
        'Save the gyms you know, compare your experience\nand discover your favorites.',
      ),
      findsOneWidget,
    );
    expect(find.text('Get started'), findsOneWidget);

    // Verifica el texto de acceso con RichText
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Already have an account? Sign in'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Navigation flow: Preloading -> Presentation -> AuthLanding -> CreateAccount',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CredsApp());

    // 0. Saltar Preloading
    await tester.tap(find.text('creds'));
    await tester.pumpAndSettle();

    // 1. Ir a AuthLandingScreen
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Build your Creds'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);

    // 2. Ir a CreateAccountScreen
    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(
      find.text('We\'ll send you a code to confirm this email address is yours.'),
      findsOneWidget,
    );
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Create a password'), findsOneWidget);
    expect(
      find.text('Use 8 or more characters, a letter and a number.'),
      findsOneWidget,
    );
    expect(
      find.text('You agree to your Terms of Service and Privacy Policy.'),
      findsOneWidget,
    );
    expect(find.text('Send code'), findsOneWidget);

    // 3. Ir a VerifyEmailScreen
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('Verification code'), findsOneWidget);
    expect(find.text('Didn\'t get the code?'), findsOneWidget);
    expect(find.text('Verify email'), findsOneWidget);
    expect(find.text('Change email address'), findsOneWidget);

    // 4. Ir a AddPhotoScreen al presionar "Verify email"
    await tester.tap(find.text('Verify email'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('Add your photo'), findsOneWidget);
    expect(find.text('Lorem ipsum dolor'), findsOneWidget);
    expect(find.text('Upload your profile photo'), findsOneWidget);
    expect(find.text('Optional · You can change it later'), findsOneWidget);
    expect(find.text('Save and continue'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);

    // 5. Ir a SetupProfileScreen al presionar "Save and continue"
    await tester.tap(find.text('Save and continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('Set up your profile'), findsOneWidget);
    expect(
      find.text('This is how your community will find you.'),
      findsOneWidget,
    );
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('ana.entrena'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('+52  55 1234 5678'), findsOneWidget);
    expect(
      find.text('Your number will not appear on your profile.'),
      findsOneWidget,
    );
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Torres'), findsOneWidget);
    expect(find.text('Save and continue'), findsOneWidget);

    // 6. Ir a LocationPermissionScreen al presionar "Save and continue"
    await tester.tap(find.text('Save and continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('LOCATION'), findsOneWidget);
    expect(find.text('Location permission'), findsOneWidget);
    expect(
      find.text(
        'Enable location access for a more detailed map with\nthe best recommendations.',
      ),
      findsOneWidget,
    );
    expect(find.text('Enable permissions'), findsOneWidget);
    expect(find.text('Do this later'), findsOneWidget);

    // 7. Volver a SetupProfileScreen
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Set up your profile'), findsOneWidget);

    // 8. Volver a AddPhotoScreen
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Add your photo'), findsOneWidget);

    // 9. Volver a VerifyEmailScreen
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);

    // 10. Volver a CreateAccountScreen mediante "Change email address"
    await tester.tap(find.text('Change email address'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);

    // 11. Volver a AuthLandingScreen
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Build your Creds'), findsOneWidget);

    // 12. Volver a PresentationScreen
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('AppHeader and atomic components test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppHeader.title('Solo Titulo'),
              AppHeader.description('Solo Descripcion'),
              AppHeader(title: 'Titulo Dual', description: 'Desc Dual'),
              AppTitle('Titulo Atomico'),
              AppDescription('Desc Atomica'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Solo Titulo'), findsOneWidget);
    expect(find.text('Solo Descripcion'), findsOneWidget);
    expect(find.text('Titulo Dual'), findsOneWidget);
    expect(find.text('Desc Dual'), findsOneWidget);
    expect(find.text('Titulo Atomico'), findsOneWidget);
    expect(find.text('Desc Atomica'), findsOneWidget);
  });
}
