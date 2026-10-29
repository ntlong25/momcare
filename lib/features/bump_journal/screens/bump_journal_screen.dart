import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/bump_photo.dart';
import '../../../core/services/bump_photo_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/app_logger.dart';
import '../bump_image_source.dart';
import 'bump_photo_viewer.dart';

/// "Nhật ký ảnh bụng bầu": photos per pregnancy week, stored on the device
/// only (Phase 21, B10).
class BumpJournalScreen extends ConsumerStatefulWidget {
  /// Week selected on open; defaults to the active pregnancy's week.
  final int? initialWeek;

  const BumpJournalScreen({super.key, this.initialWeek});

  /// Replaces the camera/photo picker in tests.
  @visibleForTesting
  static BumpImageSource Function()? debugImageSource;

  /// Replaces the active pregnancy's week in tests (avoids Hive).
  @visibleForTesting
  static int? Function()? debugCurrentWeek;

  static const String permissionMessage =
      'Chưa có quyền dùng camera/thư viện ảnh. Bạn có thể bật quyền trong Cài đặt của máy.';
  static const String errorMessage = 'Không thêm được ảnh. Vui lòng thử lại.';

  @override
  ConsumerState<BumpJournalScreen> createState() => _BumpJournalScreenState();
}

class _BumpJournalScreenState extends ConsumerState<BumpJournalScreen> {
  late int _week;
  late final BumpImageSource _source;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _week = (widget.initialWeek ?? _activeWeek()).clamp(
      BumpPhoto.minWeek,
      BumpPhoto.maxWeek,
    );
    _source =
        BumpJournalScreen.debugImageSource?.call() ?? ImagePickerBumpSource();
    // Show thumbnails once the photo folder is known.
    ref.read(bumpPhotoProvider.notifier).ready.then((_) {
      if (mounted) setState(() {});
    });
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _recoverLostImages();
    }
  }

  static int _activeWeek() {
    final override = BumpJournalScreen.debugCurrentWeek;
    if (override != null) return override() ?? 0;
    try {
      return DatabaseService.getActivePregnancy()?.currentWeekAt(
            DateTime.now(),
          ) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _recoverLostImages() async {
    try {
      final files = await _source.retrieveLost();
      if (files.isEmpty || !mounted) return;
      await _addFiles(files);
    } catch (error) {
      AppLogger.instance.warning('Could not recover lost images: $error');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addFiles(List<XFile> files) async {
    final week = _week;
    final added = await ref
        .read(bumpPhotoProvider.notifier)
        .addFiles(week, files);
    if (added == 0) {
      _showSnack(BumpJournalScreen.errorMessage);
    } else {
      _showSnack('Đã thêm $added ảnh vào tuần $week');
    }
  }

  Future<void> _pick(Future<List<XFile>> Function() pick) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = await pick();
      if (files.isEmpty || !mounted) return;
      await _addFiles(files);
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      _showSnack(
        code.contains('denied') || code.contains('permission')
            ? BumpJournalScreen.permissionMessage
            : BumpJournalScreen.errorMessage,
      );
    } catch (error) {
      AppLogger.instance.warning('Could not add bump photo: $error');
      _showSnack(BumpJournalScreen.errorMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takePhoto() => _pick(() async {
    final file = await _source.takePhoto();
    return file == null ? const <XFile>[] : [file];
  });

  Future<void> _pickFromGallery() => _pick(_source.pickFromGallery);

  void _setWeek(int week) =>
      setState(() => _week = week.clamp(BumpPhoto.minWeek, BumpPhoto.maxWeek));

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(bumpPhotoProvider);
    final notifier = ref.read(bumpPhotoProvider.notifier);
    final theme = Theme.of(context);
    final groups = BumpPhotoService.groupByWeek(photos);

    return Scaffold(
      appBar: AppBar(title: const Text('Nhật ký ảnh bụng bầu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _WeekSelector(week: _week, onChanged: _busy ? null : _setWeek),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const ValueKey('bump-camera'),
                  style: AppTheme.tonalButtonStyle(theme.colorScheme),
                  onPressed: _busy ? null : _takePhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Chụp ảnh', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const ValueKey('bump-gallery'),
                  style: AppTheme.tonalButtonStyle(theme.colorScheme),
                  onPressed: _busy ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text(
                    'Chọn từ thư viện',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ảnh chỉ lưu trên thiết bị này.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (groups.isEmpty)
            Padding(
              key: const ValueKey('bump-empty'),
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có ảnh nào. Chụp hoặc chọn ảnh để lưu lại hành trình của mẹ.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  'Tuần ${group.key} · ${group.value.length} ảnh',
                  key: ValueKey('bump-section-${group.key}'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [
                  for (final photo in group.value)
                    _Thumbnail(
                      photo: photo,
                      file: notifier.fileFor(photo),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BumpPhotoViewer(photo: photo),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _WeekSelector extends StatelessWidget {
  final int week;
  final ValueChanged<int>? onChanged;

  const _WeekSelector({required this.week, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return Row(
      key: const ValueKey('bump-week'),
      children: [
        IconButton(
          key: const ValueKey('bump-week-prev'),
          tooltip: 'Tuần trước',
          icon: const Icon(Icons.chevron_left),
          onPressed: change != null && week > BumpPhoto.minWeek
              ? () => change(week - 1)
              : null,
        ),
        Expanded(
          child: Text(
            'Tuần $week',
            key: const ValueKey('bump-week-label'),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          key: const ValueKey('bump-week-next'),
          tooltip: 'Tuần sau',
          icon: const Icon(Icons.chevron_right),
          onPressed: change != null && week < BumpPhoto.maxWeek
              ? () => change(week + 1)
              : null,
        ),
      ],
    );
  }
}

/// Placeholder for a photo whose file is missing or cannot be decoded.
class BumpPhotoPlaceholder extends StatelessWidget {
  const BumpPhotoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          key: const ValueKey('bump-photo-missing'),
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final BumpPhoto photo;
  final File? file;
  final VoidCallback onTap;

  const _Thumbnail({
    required this.photo,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = file;
    final Widget child = image == null || !image.existsSync()
        ? const BumpPhotoPlaceholder()
        : Image.file(
            image,
            cacheWidth: 300,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const BumpPhotoPlaceholder(),
          );
    return Semantics(
      button: true,
      label:
          'Ảnh tuần ${photo.week}, ngày ${DateFormatter.formatDate(photo.displayDate)}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          child: InkWell(
            key: ValueKey('bump-photo-${photo.id}'),
            onTap: onTap,
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}
