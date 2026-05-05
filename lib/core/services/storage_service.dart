import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageServiceException implements Exception {
  const StorageServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PickedImageFile {
  const PickedImageFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;

  int get sizeInBytes => bytes.lengthInBytes;
}

class StorageService {
  StorageService({
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _imagePicker = imagePicker ?? ImagePicker();

  static const _maxImageSizeInBytes = 3 * 1024 * 1024;
  static const _supportedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const _maxImageWidth = 1600.0;
  static const _maxImageHeight = 1600.0;
  static const _imageQuality = 85;

  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  Future<PickedImageFile?> pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: _imageQuality,
      maxWidth: _maxImageWidth,
      maxHeight: _maxImageHeight,
    );
    if (picked == null) return null;

    final name = picked.name.isEmpty ? 'image.jpg' : picked.name;
    final extension = _extensionFor(name);
    _validateExtension(extension);

    final file = PickedImageFile(
      name: name,
      bytes: await picked.readAsBytes(),
      mimeType: _mimeTypeForExtension(extension),
    );
    _validateSize(file);
    return file;
  }

  Future<Uint8List?> pickImageBytes() async {
    final file = await pickImage();
    return file?.bytes;
  }

  Future<String> uploadProductImage({
    required String uid,
    required String productId,
    required PickedImageFile file,
  }) async {
    _validateImage(file);
    final ref = _storage.ref().child('users/$uid/products/$productId/image.jpg');
    await ref.putData(
      file.bytes,
      SettableMetadata(contentType: file.mimeType),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadLocationImage({
    required String uid,
    required String locationId,
    required PickedImageFile file,
  }) async {
    _validateImage(file);
    final ref = _storage.ref().child('users/$uid/locations/$locationId/image.jpg');
    await ref.putData(
      file.bytes,
      SettableMetadata(contentType: file.mimeType),
    );
    return ref.getDownloadURL();
  }

  Future<void> deleteImageByUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    await _storage.refFromURL(url).delete();
  }

  void _validateImage(PickedImageFile file) {
    _validateExtension(_extensionFor(file.name));
    _validateSize(file);
  }

  void _validateExtension(String extension) {
    if (!_supportedExtensions.contains(extension)) {
      throw const StorageServiceException(
        'Solo se permiten imágenes JPG, JPEG, PNG o WEBP.',
      );
    }
  }

  void _validateSize(PickedImageFile file) {
    if (file.sizeInBytes > _maxImageSizeInBytes) {
      throw const StorageServiceException(
        'La imagen supera el tamaño máximo permitido de 3 MB.',
      );
    }
  }

  String _extensionFor(String name) {
    final segments = name.toLowerCase().split('.');
    return segments.length > 1 ? segments.last : 'jpg';
  }

  String _mimeTypeForExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
  }
}
