import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_logger.dart';

/// Shares files through the system share sheet (`share_plus`) for the bump
/// photo journal, the milestone card and the health diary PDF, and cleans
/// the temporary directory of what sharing and image picking leave behind.
///
/// Generated files are written to the temporary directory and removed after
/// the share sheet closes; anything left (share_plus copies, image_picker
/// copies) is removed by [clearTempFiles] (delete-all-data).
class ShareHelper {
  /// Replaces the real share sheet in tests.
  @visibleForTesting
  static Future<void> Function(ShareParams params)? debugShare;

  /// Temporary directory; replaced by a temp directory in tests.
  @visibleForTesting
  static Future<Directory> Function() debugTempDir = getTemporaryDirectory;

  /// Whether the temporary directory belongs to this app only, so it may be
  /// emptied completely. True on Android (`Context.getCacheDir()`) and iOS
  /// (the sandbox Caches folder): both are app-private and may be purged by
  /// the OS at any time, so nothing the app or engine needs to run lives
  /// there. On desktop it is the shared system temp folder, so only our own
  /// entries are touched.
  @visibleForTesting
  static bool Function() debugOwnsTempDir = _defaultOwnsTempDir;

  static bool _defaultOwnsTempDir() => Platform.isAndroid || Platform.isIOS;

  /// Restores the real share sheet and temp directory (tests).
  @visibleForTesting
  static void resetDebugOverrides() {
    debugShare = null;
    debugTempDir = getTemporaryDirectory;
    debugOwnsTempDir = _defaultOwnsTempDir;
  }

  /// Folder where share_plus (Android) copies every shared file.
  static const String sharePlusFolder = 'share_plus';

  static final RegExp _generatedName = RegExp(
    r'^(momcare_tuan_\d+\.png|momcare_nhat_ky_\d{8}_\d{8}\.pdf)$',
  );

  static final RegExp _uuidName = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// True for the files this app generates for sharing
  /// (`momcare_tuan_<X>.png`, `momcare_nhat_ky_<from>_<to>.pdf`).
  static bool isGeneratedFileName(String name) => _generatedName.hasMatch(name);

  /// True for what image_picker leaves at the top of the temp directory:
  /// `<uuid>/` folders holding the picked originals (Android), and
  /// `scaled_*` / `image_picker*` files (resized copies, camera photos).
  static bool isPickerLeftover(FileSystemEntity entity) {
    final name = _nameOf(entity.path);
    if (entity is Directory) return _uuidName.hasMatch(name);
    if (entity is File) {
      return name.startsWith('scaled_') || name.startsWith('image_picker');
    }
    return false;
  }

  static String _nameOf(String path) {
    final parts = path
        .split(RegExp(r'[\\/]'))
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.isEmpty ? '' : parts.last;
  }

  static String _normalized(String path) {
    var result = path.replaceAll('\\', '/');
    while (result.length > 1 && result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return Platform.isWindows ? result.toLowerCase() : result;
  }

  /// True when [path] is strictly inside [dir] (not [dir] itself).
  static bool isInside(Directory dir, String path) {
    final root = _normalized(dir.absolute.path);
    final target = _normalized(File(path).absolute.path);
    if (target.split('/').contains('..')) return false;
    return target.startsWith('$root/') && target.length > root.length + 1;
  }

  /// Temp folders this app owns: the temporary directory and, on iOS, the
  /// sandbox `tmp/` where image_picker writes. Empty when
  /// [debugOwnsTempDir] is false.
  static Future<List<Directory>> _ownedTempDirs() async {
    if (!debugOwnsTempDir()) return const [];
    final dirs = [await debugTempDir()];
    if (Platform.isIOS && identical(debugTempDir, getTemporaryDirectory)) {
      final tmp = Directory.systemTemp;
      if (_normalized(tmp.path) != _normalized(dirs.first.path)) dirs.add(tmp);
    }
    return dirs;
  }

  /// Writes [bytes] to `<temp>/<fileName>`, replacing an older copy.
  static Future<File> writeTempFile(String fileName, Uint8List bytes) async {
    final dir = await debugTempDir();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }

  /// Anchor rect for the iPad share popover, from the tapped widget.
  static Rect? originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Opens the share sheet. Afterwards (also on error) our own generated
  /// `momcare_*` files in [params] are deleted from the temp directory; on
  /// Android share_plus has already copied them to `share_plus/`.
  static Future<void> share(ShareParams params) async {
    try {
      final hook = debugShare;
      if (hook != null) {
        await hook(params);
        return;
      }
      await SharePlus.instance.share(params);
    } finally {
      await _deleteGeneratedFiles(params.files);
    }
  }

  /// Shares one file at [path].
  static Future<void> shareFile(
    String path, {
    required String mimeType,
    String? text,
    Rect? origin,
  }) => share(
    ShareParams(
      files: [XFile(path, mimeType: mimeType)],
      text: text,
      sharePositionOrigin: origin,
    ),
  );

  /// Best effort, never throws.
  static Future<void> _deleteGeneratedFiles(List<XFile>? files) async {
    if (files == null || files.isEmpty) return;
    try {
      final dir = await debugTempDir();
      for (final xfile in files) {
        final name = _nameOf(xfile.path);
        if (!isGeneratedFileName(name) || !isInside(dir, xfile.path)) continue;
        try {
          final file = File(xfile.path);
          if (await file.exists()) await file.delete();
        } catch (error) {
          AppLogger.instance.warning('Could not delete $name: $error');
        }
      }
    } catch (error) {
      AppLogger.instance.warning('Could not delete shared temp files: $error');
    }
  }

  /// Deletes [entity] (recursively); never throws. True when it is gone.
  static Future<bool> _deleteQuietly(FileSystemEntity entity) async {
    try {
      await entity.delete(recursive: true);
      return true;
    } catch (error) {
      AppLogger.instance.warning(
        'Could not delete temp entry ${_nameOf(entity.path)}: $error',
      );
      return false;
    }
  }

  /// Deletes the temp copy image_picker made at [path] once the photo is
  /// stored elsewhere, plus its `<uuid>/` folder when that is left empty.
  /// Only touches files inside a temp folder this app owns, never a user's
  /// original. Never throws; true when a file was deleted.
  static Future<bool> deletePickerTempFile(String path) async {
    try {
      if (path.isEmpty) return false;
      for (final dir in await _ownedTempDirs()) {
        if (!isInside(dir, path)) continue;
        final file = File(path);
        if (!await file.exists()) return false;
        await file.delete();
        final parent = file.parent;
        if (isInside(dir, parent.path) && await parent.list().isEmpty) {
          await parent.delete();
        }
        return true;
      }
    } catch (error) {
      AppLogger.instance.warning('Could not delete picker temp file: $error');
    }
    return false;
  }

  /// Deletes image_picker leftovers ([isPickerLeftover]) at the top of the
  /// owned temp folders, e.g. the original behind a resized pick. Call only
  /// when no pick is in progress. Never throws; returns entries removed.
  static Future<int> clearPickerLeftovers() async {
    var removed = 0;
    try {
      for (final dir in await _ownedTempDirs()) {
        if (!await dir.exists()) continue;
        final entries = await dir.list(followLinks: false).toList();
        for (final entity in entries) {
          if (isPickerLeftover(entity) && await _deleteQuietly(entity)) {
            removed++;
          }
        }
      }
    } catch (error) {
      AppLogger.instance.warning('Could not clear picker leftovers: $error');
    }
    return removed;
  }

  /// Delete-all-data. When the temp directory belongs to the app
  /// ([debugOwnsTempDir]) it is emptied recursively (generated files,
  /// `share_plus/` copies, image_picker copies, anything else) and the
  /// folder itself is kept. Otherwise only our generated files and the
  /// `share_plus/` folder are removed. Never throws; returns the number of
  /// top-level entries removed.
  static Future<int> clearTempFiles() async {
    var removed = 0;
    try {
      final owned = await _ownedTempDirs();
      if (owned.isNotEmpty) {
        for (final dir in owned) {
          if (!await dir.exists()) continue;
          final entries = await dir.list(followLinks: false).toList();
          for (final entity in entries) {
            if (await _deleteQuietly(entity)) removed++;
          }
        }
        return removed;
      }
      final dir = await debugTempDir();
      if (!await dir.exists()) return 0;
      final entries = await dir.list(followLinks: false).toList();
      for (final entity in entries) {
        final name = _nameOf(entity.path);
        final ours =
            (entity is File && isGeneratedFileName(name)) ||
            (entity is Directory && name == sharePlusFolder);
        if (ours && await _deleteQuietly(entity)) removed++;
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Could not clear shared temp files',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return removed;
  }
}
