import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/core/services/media_service.dart';
import 'package:app_flutter/features/auth/presentation/screens/add_photo_screen.dart';

class FakeMediaService extends MediaService {
  PickedImage? nextImage;

  @override
  Future<PickedImage?> pickImageFromGallery({
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    return nextImage;
  }

  @override
  Future<PickedImage?> pickImageFromCamera({
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    return nextImage;
  }
}

// 1x1 pixel valid PNG bytes
final sampleImageBytes = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
  0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84,
  120, 1, 99, 248, 255, 255, 63, 0, 5, 254, 2, 254, 167, 53, 129, 132, 0, 0,
  0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _FakeHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => sampleImageBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(sampleImageBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('AddPhotoScreen - Photo upload & replacement tests', () {
    testWidgets('Opens bottom sheet on tapping avatar',
        (WidgetTester tester) async {
      final fakeMedia = FakeMediaService();

      await tester.pumpWidget(
        MaterialApp(
          home: AddPhotoScreen(
            mediaService: fakeMedia,
          ),
        ),
      );

      // Inicialmente en estado por defecto (muestra 'Not now')
      expect(find.text('Upload your profile photo'), findsOneWidget);
      expect(find.text('Optional · You can change it later'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);

      // Tocar el avatar circular mediante su key
      await tester.tap(find.byKey(const Key('photo_avatar_gesture')));
      await tester.pumpAndSettle();

      // Debe abrirse el bottom sheet con las opciones
      expect(find.text('Profile photo'), findsOneWidget);
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
      // Como no tiene foto activa, no debe mostrar opción de eliminar
      expect(find.text('Remove current photo'), findsNothing);
    });

    testWidgets('Replaces photo when choosing from gallery and can remove it',
        (WidgetTester tester) async {
      final fakeMedia = FakeMediaService();
      fakeMedia.nextImage = PickedImage(
        bytes: sampleImageBytes,
        name: 'avatar_test.png',
      );

      PickedImage? notifiedImage;

      await tester.pumpWidget(
        MaterialApp(
          home: AddPhotoScreen(
            mediaService: fakeMedia,
            onPhotoChanged: (img) => notifiedImage = img,
          ),
        ),
      );

      // 1. Abrir selector
      await tester.tap(find.byKey(const Key('photo_avatar_gesture')));
      await tester.pumpAndSettle();

      // 2. Seleccionar de la galería
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

      // 3. Verifica actualización del estado y textos
      expect(find.text('Your profile photo'), findsOneWidget);
      expect(
        find.text('Custom photo selected · You can change it'),
        findsOneWidget,
      );
      expect(notifiedImage, isNotNull);
      expect(notifiedImage!.name, 'avatar_test.png');
      expect(find.byType(Image), findsOneWidget);
      // Al tener foto activa, 'Not now' se oculta suavemente
      expect(find.text('Not now'), findsNothing);

      // 4. Volver a abrir el modal: ahora sí debe mostrar la opción de eliminar
      await tester.tap(find.byKey(const Key('photo_avatar_gesture')));
      await tester.pumpAndSettle();

      expect(find.text('Remove current photo'), findsOneWidget);

      // 5. Eliminar foto seleccionada
      await tester.tap(find.text('Remove current photo'));
      await tester.pumpAndSettle();

      expect(find.text('Upload your profile photo'), findsOneWidget);
      expect(find.text('Optional · You can change it later'), findsOneWidget);
      // Al eliminar la foto, 'Not now' reaparece
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('Allows removing Google photo and returning to placeholder',
        (WidgetTester tester) async {
      final fakeMedia = FakeMediaService();

      await tester.pumpWidget(
        MaterialApp(
          home: AddPhotoScreen(
            initialPhotoUrl: 'https://lh3.googleusercontent.com/test-photo',
            mediaService: fakeMedia,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your profile photo'), findsOneWidget);
      expect(
        find.text('Imported from Google · You can change it'),
        findsOneWidget,
      );
      // Al venir con foto de Google, 'Not now' no se muestra
      expect(find.text('Not now'), findsNothing);

      // Abrir modal y eliminar
      await tester.tap(find.byKey(const Key('photo_avatar_gesture')));
      await tester.pumpAndSettle();

      expect(find.text('Remove current photo'), findsOneWidget);
      await tester.tap(find.text('Remove current photo'));
      await tester.pumpAndSettle();

      expect(find.text('Upload your profile photo'), findsOneWidget);
      expect(find.text('Optional · You can change it later'), findsOneWidget);
      // Al eliminar la foto de Google, 'Not now' vuelve a aparecer
      expect(find.text('Not now'), findsOneWidget);
    });
  });
}
