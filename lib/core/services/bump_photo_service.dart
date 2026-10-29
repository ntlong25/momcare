import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/bump_photo.dart';
import '../utils/app_logger.dart';
import '../utils/share_helper.dart';

/// Persists "Nhật ký ảnh bụng bầu": metadata as JSON under
/// [AppConstants.bumpPhotosKey], image files in
/// `<app documents>/[folderName]/`.
class BumpPhotoService {
  static const String folderName = 'bump_photos';

  /// Extensions kept as picked; anything else is stored as `.jpg`.
  static const Set<String> keptExtensions = {'.jpg', '.png', '.heic', '.webp'};

  /// App documents directory; replaced by a temp directory in tests.
  @visibleForTesting
  static Future<Directory> Function() debugDocumentsDir =
      getApplicationDocumentsDirectory;

  /// Restores the real documents directory (tests).
  @visibleForTesting
  static void resetDebugDocumentsDir() {
    debugDocumentsDir = getApplicationDocumentsDirectory;
  }

  /// Week desc, then newest added first.
  static List<BumpPhoto> sorted(Iterable<BumpPhoto> photos) =>
      photos.toList()..sort((a, b) {
        final byWeek = b.week.compareTo(a.week);
        if (byWeek != 0) return byWeek;
        return b.addedAt.compareTo(a.addedAt);
      });

  /// Never throws: corrupt values give an empty list and invalid entries
  /// are skipped.
  static List<BumpPhoto> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return sorted(decoded.map(BumpPhoto.fromJson).whereType<BumpPhoto>());
    } catch (_) {
      return const [];
    }
  }

  static String encode(List<BumpPhoto> photos) =>
      jsonEncode(photos.map((photo) => photo.toJson()).toList());

  /// One entry per week that has photos, week desc; photos keep the
  /// [sorted] order inside a week.
  static List<MapEntry<int, List<BumpPhoto>>> groupByWeek(
    List<BumpPhoto> photos,
  ) {
    final byWeek = <int, List<BumpPhoto>>{};
    for (final photo in sorted(photos)) {
      byWeek.putIfAbsent(photo.week, () => []).add(photo);
    }
    return byWeek.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
  }

  /// `.jpg`, `.png`, `.heic` or `.webp` from [name] (`.jpeg` -> `.jpg`).
  static String extensionFor(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return '.jpg';
    var ext = name.substring(dot).toLowerCase();
    if (ext == '.jpeg') ext = '.jpg';
    return keptExtensions.contains(ext) ? ext : '.jpg';
  }

  static Future<Directory> folder() async {
    final docs = await debugDocumentsDir();
    return Directory('${docs.path}${Platform.pathSeparator}$folderName');
  }

  static Future<File> fileFor(BumpPhoto photo) async =>
      fileIn(await folder(), photo);

  static File fileIn(Directory folder, BumpPhoto photo) =>
      File('${folder.path}${Platform.pathSeparator}${photo.fileName}');

  static Future<List<BumpPhoto>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(AppConstants.bumpPhotosKey));
  }

  static Future<void> save(List<BumpPhoto> photos) async =>
      saveTo(await SharedPreferences.getInstance(), photos);

  static Future<void> saveTo(
    SharedPreferences prefs,
    List<BumpPhoto> photos,
  ) async {
    if (photos.isEmpty) {
      await prefs.remove(AppConstants.bumpPhotosKey);
      return;
    }
    await prefs.setString(AppConstants.bumpPhotosKey, encode(photos));
  }

  /// Removes the metadata key and the whole photo folder (delete-all-data).
  /// Never throws; failures are logged.
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.bumpPhotosKey);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Could not remove bump photo metadata',
        error: error,
        stackTrace: stackTrace,
      );
    }
    try {
      final dir = await folder();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Could not delete bump photo folder',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Bump photo journal state: all photos, week desc then newest first.
class BumpPhotoNotifier extends StateNotifier<List<BumpPhoto>> {
  BumpPhotoNotifier({DateTime Function()? now})
    : now = now ?? DateTime.now,
      super(const []) {
    _loading = _load();
  }

  final DateTime Function() now;

  late final Future<void> _loading;
  bool _loaded = false;
  SharedPreferences? _prefs;

  Directory? _folder;

  /// Photo folder, known once [ready] completes (null if the documents
  /// directory is unavailable).
  Directory? get folder => _folder;

  Future<void> _load() async {
    try {
      _folder = await BumpPhotoService.folder();
    } catch (error) {
      AppLogger.instance.warning('Bump photo folder unavailable: $error');
    }
    try {
      final prefs = _prefs = await SharedPreferences.getInstance();
      final photos = BumpPhotoService.decode(
        prefs.getString(AppConstants.bumpPhotosKey),
      );
      if (mounted) state = photos;
    } catch (error) {
      AppLogger.instance.warning('Could not load bump photos: $error');
    }
    _loaded = true;
  }

  // Skips the await once loaded, so later calls do not depend on the zone
  // the first load ran in (widget tests mix fake and real async).
  Future<void> _ensureLoaded() async {
    if (!_loaded) await _loading;
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs != null) {
      await BumpPhotoService.saveTo(prefs, state);
    } else {
      await BumpPhotoService.save(state);
    }
  }

  /// Completes once the persisted photos are loaded.
  Future<void> get ready => _loading;

  /// The image file of [photo], or null before [ready].
  File? fileFor(BumpPhoto photo) {
    final dir = _folder;
    return dir == null ? null : BumpPhotoService.fileIn(dir, photo);
  }

  /// Copies [files] into the photo folder as photos of [week], then removes
  /// image_picker's temp copies (best effort). A file that fails to copy
  /// is skipped; returns the number of photos added.
  Future<int> addFiles(int week, List<XFile> files) async {
    await _ensureLoaded();
    if (files.isEmpty) return 0;
    final targetWeek = week.clamp(BumpPhoto.minWeek, BumpPhoto.maxWeek);
    final dir = _folder ??= await BumpPhotoService.folder();
    await dir.create(recursive: true);
    final added = <BumpPhoto>[];
    for (final file in files) {
      final ext = BumpPhotoService.extensionFor(
        file.name.isNotEmpty ? file.name : file.path,
      );
      final id = const Uuid().v4();
      final photo = BumpPhoto(
        id: id,
        week: targetWeek,
        fileName: '$id$ext',
        addedAt: now(),
      );
      try {
        await file.saveTo(BumpPhotoService.fileIn(dir, photo).path);
        added.add(photo);
        // Privacy: image_picker leaves its copy in the temp directory.
        await ShareHelper.deletePickerTempFile(file.path);
      } catch (error) {
        AppLogger.instance.warning('Could not copy bump photo: $error');
      }
    }
    // Also the originals behind resized picks (`<uuid>/` folders).
    await ShareHelper.clearPickerLeftovers();
    if (added.isEmpty) return 0;
    state = BumpPhotoService.sorted([...state, ...added]);
    await _save();
    return added.length;
  }

  /// Deletes the entry and its file; an already missing file is fine.
  Future<void> delete(BumpPhoto photo) async {
    await _ensureLoaded();
    try {
      final file = _folder != null
          ? BumpPhotoService.fileIn(_folder!, photo)
          : await BumpPhotoService.fileFor(photo);
      // One small unlink; sync keeps the viewer's delete flow simple.
      if (file.existsSync()) file.deleteSync();
    } catch (error) {
      AppLogger.instance.warning('Could not delete bump photo file: $error');
    }
    state = state.where((entry) => entry.id != photo.id).toList();
    await _save();
  }

  /// Clears the in-memory photos (the persisted ones are removed by the
  /// caller, e.g. the delete-all-data flow).
  void resetLocal() {
    state = const [];
  }
}

final bumpPhotoProvider =
    StateNotifierProvider<BumpPhotoNotifier, List<BumpPhoto>>(
      (ref) => BumpPhotoNotifier(),
    );
