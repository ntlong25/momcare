import 'package:image_picker/image_picker.dart';

/// Where the bump photo journal gets images from; [ImagePickerBumpSource] in
/// the app, a fake in tests.
abstract class BumpImageSource {
  /// Opens the camera; null when the user cancels.
  Future<XFile?> takePhoto();

  /// Opens the photo picker; empty when the user cancels.
  Future<List<XFile>> pickFromGallery();

  /// Android only: images picked before the activity was killed.
  Future<List<XFile>> retrieveLost();
}

class ImagePickerBumpSource implements BumpImageSource {
  ImagePickerBumpSource([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int imageQuality = 85;
  static const double maxWidth = 2048;

  @override
  Future<XFile?> takePhoto() => _picker.pickImage(
    source: ImageSource.camera,
    imageQuality: imageQuality,
    maxWidth: maxWidth,
  );

  @override
  Future<List<XFile>> pickFromGallery() =>
      _picker.pickMultiImage(imageQuality: imageQuality, maxWidth: maxWidth);

  @override
  Future<List<XFile>> retrieveLost() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return const [];
    return response.files ?? const [];
  }
}
