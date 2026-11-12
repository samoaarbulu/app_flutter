import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/main.dart';

void main() {
  testWidgets('PresentationScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CredsApp());

    // Verifica que se renderiza el título CREDS y los selectores
    expect(find.text('CREDS'), findsOneWidget);
    expect(find.text('1. Prisma'), findsOneWidget);
    expect(find.text('2. CREDS'), findsOneWidget);
    expect(find.text('3. 3D Float'), findsOneWidget);
    expect(find.text('4. Emblema'), findsOneWidget);
  });
}
