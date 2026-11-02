import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bump_photo.dart';
import '../../../core/services/bump_photo_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/share_helper.dart';
import '../../tools/widgets/tool_confirm_dialog.dart';
import '../bump_photo_share.dart';
import 'bump_journal_screen.dart';

/// Full-screen bump photo with zoom, share and delete.
class BumpPhotoViewer extends ConsumerStatefulWidget {
  final BumpPhoto photo;

  const BumpPhotoViewer({super.key, required this.photo});

  @override
  ConsumerState<BumpPhotoViewer> createState() => _BumpPhotoViewerState();
}

class _BumpPhotoViewerState extends ConsumerState<BumpPhotoViewer> {
  bool _sharing = false;

  BumpPhoto get photo => widget.photo;

  Future<void> _share(BuildContext buttonContext) async {
    if (_sharing) return;
    final origin = ShareHelper.originOf(buttonContext);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      final file =
          ref.read(bumpPhotoProvider.notifier).fileFor(photo) ??
          await BumpPhotoService.fileFor(photo);
      if (!await file.exists()) throw StateError('missing file');
      if (mounted) {
        await BumpPhotoShare.offer(
          context,
          photo: photo,
          file: file,
          origin: origin,
        );
      }
    } catch (error) {
      AppLogger.instance.warning('Could not share bump photo: $error');
      messenger.showSnackBar(
        const SnackBar(content: Text(BumpPhotoShare.errorMessage)),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmToolDelete(
      context,
      title: 'Xóa ảnh này?',
      message: 'Ảnh sẽ bị xóa khỏi nhật ký trên thiết bị này.',
    );
    if (!confirmed) return;
    await ref.read(bumpPhotoProvider.notifier).delete(photo);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final file = ref.read(bumpPhotoProvider.notifier).fileFor(photo);
    return Scaffold(
      appBar: AppBar(
        // Two lines, scaled down when needed, so the date stays fully
        // visible at large text scales.
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tuần ${photo.week}',
                key: const ValueKey('bump-viewer-week'),
                maxLines: 1,
                softWrap: false,
                // Inherits the AppBar title font and colour.
                style: const TextStyle(fontSize: 18, height: 1.2),
              ),
              Text(
                DateFormatter.formatDate(photo.displayDate),
                key: const ValueKey('bump-viewer-date'),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (buttonContext) => IconButton(
              key: const ValueKey('bump-share'),
              tooltip: 'Chia sẻ',
              icon: _sharing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share),
              onPressed: _sharing ? null : () => _share(buttonContext),
            ),
          ),
          IconButton(
            key: const ValueKey('bump-delete'),
            tooltip: 'Xóa ảnh',
            icon: const Icon(Icons.delete_outline),
            onPressed: _sharing ? null : _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: file == null || !file.existsSync()
              ? const SizedBox(
                  width: 160,
                  height: 160,
                  child: BumpPhotoPlaceholder(),
                )
              : InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 160,
                      height: 160,
                      child: BumpPhotoPlaceholder(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
