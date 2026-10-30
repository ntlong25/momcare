import 'package:image_picker/image_picker.dart';

/// Where the bump photo journal gets older photos from;
/// [ImagePickerBumpSource] in the app, a fake in tests. New photos come from
/// the in-app camera (`BumpCameraSource`).
abstract class BumpImageSource {
  /// Opens the photo picker; empty when the user cancels.
  Future<List<XFile>> pickFromGallery();

  /// Android only: images picked before the activity was killed. The picker
  /// is another activity, so Android may kill the app behind it.
  Future<List<XFile>> retrieveLost();
}

class ImagePickerBumpSource implements BumpImageSource {
  ImagePickerBumpSource([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int imageQuality = 85;
  static const double maxWidth = 2048;

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
