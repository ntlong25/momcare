// Fake camera for widget tests of the bump camera flow.
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:flutter/widgets.dart';
import 'package:momcare/core/utils/share_helper.dart';
import 'package:momcare/features/bump_journal/bump_camera_source.dart';

class FakeBumpCamera implements BumpCameraSource {
  /// Where "captured" files are written: the test's temp directory.
  final Directory dir;

  FakeBumpCamera(this.dir);

  List<BumpLens> available = const [BumpLens.back, BumpLens.front];
  BumpCameraFailure? openFailure;
  Object? captureError;

  /// Holds capture() open until completed.
  Completer<void>? captureGate;

  final List<BumpLens> opened = [];
  final List<bool> flash = [];
  int closed = 0;
  int captures = 0;
  final List<String> captured = [];

  /// Holds finish() open until completed.
  Completer<void>? finishGate;

  /// The `mirror` argument of each finish() call.
  final List<bool> mirrors = [];
  final List<String> finished = [];

  @override
  Future<List<BumpLens>> lenses() async => available;

  @override
  Future<void> open(BumpLens lens) async {
    opened.add(lens);
    final failure = openFailure;
    if (failure != null) throw BumpCameraException(failure);
  }

  @override
  double get previewAspectRatio => 9 / 16;

  @override
  Widget buildPreview() => const SizedBox.expand(key: ValueKey('fake-preview'));

  @override
  Future<void> setFlash(bool on) async => flash.add(on);

  @override
  Future<XFile> capture() async {
    captures++;
    await captureGate?.future;
    final error = captureError;
    if (error != null) throw error;
    final file = File(
      '${dir.path}/${ShareHelper.cameraTempPrefix}$captures.jpg',
    )..writeAsBytesSync(_png);
    captured.add(file.path);
    return XFile(file.path);
  }

  @override
  Future<XFile> finish(XFile raw, {required bool mirror}) async {
    mirrors.add(mirror);
    await finishGate?.future;
    final file = File(
      '${dir.path}/${ShareHelper.cameraTempPrefix}done_${finished.length}.jpg',
    )..writeAsBytesSync(_png);
    finished.add(file.path);
    return XFile(file.path);
  }

  @override
  Future<void> close() async => closed++;
}

/// 1 x 1 PNG; decoders go by the content, not the extension.
const List<int> _png = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
