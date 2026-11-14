import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Modelo de datos inmutable para una imagen seleccionada que garantiza compatibilidad
/// universal entre Web, Android, iOS y Desktop utilizando bytes (`Uint8List`).
class PickedImage {
  final Uint8List bytes;
  final String name;
  final String? path;
  final String? mimeType;
  final int sizeInBytes;

  PickedImage({
    required this.bytes,
    required this.name,
    this.path,
    this.mimeType,
  }) : sizeInBytes = bytes.lengthInBytes;
}

/// Servicio desacoplado para la captura y selección de imágenes del dispositivo.
///
/// **Mejores prácticas implementadas:**
/// - **Optimización de memoria y resolución:** Redimensiona automáticamente a un máximo
///   de 1024x1024 px con calidad al 85% para evitar sobrecargas de RAM y archivos pesados.
/// - **Universalidad (Web + Móvil):** Utiliza `Uint8List` en lugar de `dart:io.File`,
///   garantizando funcionamiento transparente en Flutter Web y Mobile.
/// - **Testabilidad e Inversión de Dependencias:** Permite inyectar instancias de `ImagePicker`
///   para pruebas unitarias y de widgets.
class MediaService {
  final ImagePicker _picker;

  MediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static final MediaService instance = MediaService();

  /// Abre la galería del dispositivo para seleccionar una imagen
  Future<PickedImage?> pickImageFromGallery({
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    return _pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Abre la cámara del dispositivo para tomar una nueva foto
  Future<PickedImage?> pickImageFromCamera({
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    return _pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  Future<PickedImage?> _pickImage({
    required ImageSource source,
    required double maxWidth,
    required double maxHeight,
    required int imageQuality,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (file == null) {
        return null; // El usuario canceló la selección
      }

      final Uint8List bytes = await file.readAsBytes();
      return PickedImage(
        bytes: bytes,
        name: file.name,
        path: file.path,
        mimeType: file.mimeType,
      );
    } catch (e) {
      debugPrint('MediaService: Error al seleccionar imagen: $e');
      rethrow;
    }
  }
}

