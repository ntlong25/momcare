import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../../core/utils/app_logger.dart';
import '../../core/utils/share_helper.dart';

enum BumpLens { back, front }

/// Why the camera cannot be shown.
enum BumpCameraFailure { permissionDenied, noCamera, error }

class BumpCameraException implements Exception {
  final BumpCameraFailure failure;

  const BumpCameraException(this.failure);

  @override
  String toString() => 'BumpCameraException($failure)';
}

/// Maps a camera plugin error code to a [BumpCameraFailure]. Android and iOS
/// use `CameraAccessDenied`, `CameraAccessDeniedWithoutPrompt` and
/// `CameraAccessRestricted`.
BumpCameraFailure bumpCameraFailureFor(String code) {
  final lower = code.toLowerCase();
  return lower.contains('accessdenied') ||
          lower.contains('accessrestricted') ||
          lower.contains('permission')
      ? BumpCameraFailure.permissionDenied
      : BumpCameraFailure.error;
}

/// The camera behind `BumpCameraScreen`; [PluginBumpCameraSource] in the app,
/// a fake in tests. [open] and [close] may be called in any order while the
/// app is paused and resumed, implementations run them one at a time.
abstract class BumpCameraSource {
  /// Lenses on this device; empty when it has no camera.
  Future<List<BumpLens>> lenses();

  /// Asks for the permission when needed and starts [lens]. Throws
  /// [BumpCameraException].
  Future<void> open(BumpLens lens);

  /// Width / height of the upright preview. Valid after [open].
  double get previewAspectRatio;

  /// The live picture, drawn at [previewAspectRatio]. Valid after [open].
  Widget buildPreview();

  Future<void> setFlash(bool on);

  /// Takes a photo and returns the camera's own temp file, as soon as it
  /// exists. Throws [BumpCameraException].
  Future<XFile> capture();

  /// The photo to save: a new temp file with [raw] cropped to the square of
  /// the preview frame and, with [mirror], flipped to match the preview.
  /// Runs off the UI thread, leaves [raw] in place and returns [raw] itself
  /// when it cannot be processed, so a photo is never lost to a decoding
  /// problem. Never throws.
  Future<XFile> finish(XFile raw, {required bool mirror});

  /// Releases the camera; safe when it is not open.
  Future<void> close();
}

/// Whether a photo from [lens] is flipped to match the preview. The plugin
/// mirrors the front preview, as selfie cameras do, while CameraX writes the
/// sensor's unmirrored picture. Rear photos are never flipped. iOS keeps the
/// plugin's output: it has not been checked on a device.
bool bumpPhotoMirrored(BumpLens lens, TargetPlatform platform) =>
    lens == BumpLens.front && platform == TargetPlatform.android;

/// JPEG of the centre square of an upright RGBA picture of [width] x
/// [height], flipped left to right with [mirror], without metadata. Pure
/// Dart, so it runs in a background isolate.
Uint8List squareCropRgba(
  Uint8List rgba,
  int width,
  int height, {
  bool mirror = false,
}) {
  final picture = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba.buffer,
    bytesOffset: rgba.offsetInBytes,
    numChannels: 4,
  );
  final side = math.min(width, height);
  var square = img.copyCrop(
    picture,
    x: (width - side) ~/ 2,
    y: (height - side) ~/ 2,
    width: side,
    height: side,
  );
  if (mirror) square = img.flipHorizontal(square);
  return img.encodeJpg(square, quality: 85);
}

Uint8List _cropInIsolate((Uint8List, int, int, bool) job) =>
    squareCropRgba(job.$1, job.$2, job.$3, mirror: job.$4);

/// `camera` plugin implementation.
class PluginBumpCameraSource implements BumpCameraSource {
  /// Asks for 4K, which falls back to the closest lower size a device offers.
  /// Unlike [ResolutionPreset.max] it cannot pick a 50 MP mode, which would
  /// slow every capture.
  static const ResolutionPreset resolution = ResolutionPreset.ultraHigh;

  /// Longest side of the saved square, as on the old picker path.
  static const int maxPhotoSide = 2048;

  /// Whether the plugin holds a flash mode. Once it does, every capture on
  /// Android re-applies it and CameraX waits for that update before it
  /// starts. A new camera has the flash off anyway, so "off" is not sent
  /// until the flash has been used.
  static bool _flashModeSet = false;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  Future<void> _queue = Future.value();

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<List<CameraDescription>> _available() async {
    try {
      return _cameras ??= await availableCameras();
    } on CameraException catch (error) {
      throw BumpCameraException(bumpCameraFailureFor(error.code));
    }
  }

  static BumpLens? _lensOf(CameraDescription camera) =>
      switch (camera.lensDirection) {
        CameraLensDirection.back => BumpLens.back,
        CameraLensDirection.front => BumpLens.front,
        CameraLensDirection.external => null,
      };

  @override
  Future<List<BumpLens>> lenses() async {
    final found = <BumpLens>{};
    for (final camera in await _available()) {
      final lens = _lensOf(camera);
      if (lens != null) found.add(lens);
    }
    return BumpLens.values.where(found.contains).toList();
  }

  @override
  Future<void> open(BumpLens lens) => _serial(() async {
    await _closeNow();
    final cameras = await _available();
    final matching = cameras.where((camera) => _lensOf(camera) == lens);
    if (matching.isEmpty) {
      throw const BumpCameraException(BumpCameraFailure.noCamera);
    }
    final controller = CameraController(
      matching.first,
      resolution,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      // The screen is held in portrait.
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } on CameraException catch (error) {
      await _disposeQuietly(controller);
      throw BumpCameraException(bumpCameraFailureFor(error.code));
    } catch (error) {
      await _disposeQuietly(controller);
      AppLogger.instance.warning('Could not open the camera: $error');
      throw const BumpCameraException(BumpCameraFailure.error);
    }
    _controller = controller;
  });

  CameraController get _open {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const BumpCameraException(BumpCameraFailure.error);
    }
    return controller;
  }

  @override
  double get previewAspectRatio => 1 / _open.value.aspectRatio;

  @override
  Widget buildPreview() => CameraPreview(_open);

  @override
  Future<void> setFlash(bool on) => _serial(() async {
    final android = defaultTargetPlatform == TargetPlatform.android;
    if (android && !on && !_flashModeSet) return;
    _flashModeSet = true;
    await _open.setFlashMode(on ? FlashMode.always : FlashMode.off);
  });

  @override
  Future<XFile> capture() => _serial(() async {
    try {
      return await _open.takePicture();
    } on CameraException catch (error) {
      throw BumpCameraException(bumpCameraFailureFor(error.code));
    }
  });

  @override
  Future<XFile> finish(XFile raw, {required bool mirror}) async {
    try {
      final picture = await _decodeUpright(await raw.readAsBytes());
      final bytes = await compute(_cropInIsolate, (
        picture.$1,
        picture.$2,
        picture.$3,
        mirror,
      ));
      final file = await ShareHelper.writeTempFile(
        '${ShareHelper.cameraTempPrefix}${const Uuid().v4()}.jpg',
        bytes,
      );
      return XFile(file.path, mimeType: 'image/jpeg');
    } catch (error) {
      AppLogger.instance.warning('Could not crop the camera photo: $error');
      return raw;
    }
  }

  /// The photo as upright RGBA with a short side of at most [maxPhotoSide],
  /// with its width and height. The engine's native decoder applies the EXIF
  /// rotation, scales while decoding and stays off the UI thread; decoding a
  /// 4K JPEG in Dart would take seconds.
  static Future<(Uint8List, int, int)> _decodeUpright(Uint8List jpeg) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(jpeg);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final shortSide = math.min(descriptor.width, descriptor.height);
    final scale = math.min(1.0, maxPhotoSide / shortSide);
    final codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * scale).round(),
      targetHeight: (descriptor.height * scale).round(),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final data = await image.toByteData();
      if (data == null) throw StateError('No pixels');
      return (data.buffer.asUint8List(), image.width, image.height);
    } finally {
      image.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }

  @override
  Future<void> close() => _serial(_closeNow);

  Future<void> _closeNow() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) await _disposeQuietly(controller);
  }

  static Future<void> _disposeQuietly(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (error) {
      AppLogger.instance.warning('Could not release the camera: $error');
    }
  }
}
