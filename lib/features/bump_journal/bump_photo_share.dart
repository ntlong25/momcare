import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/data/content_pack_service.dart';
import '../../core/models/bump_photo.dart';
import '../../core/models/week_detail_model.dart';
import '../../core/services/bump_photo_service.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/share_helper.dart';
import '../milestone_card/milestone_card_text.dart';
import '../milestone_card/screens/milestone_card_screen.dart';
import 'widgets/framed_bump_photo.dart';

enum BumpShareChoice { original, framed }

/// Sharing a saved bump photo, from the camera review and the journal viewer:
/// the plain file, or a generated PNG in the MomCare+ frame.
class BumpPhotoShare {
  const BumpPhotoShare._();

  static const String errorMessage =
      'Không chia sẻ được ảnh. Vui lòng thử lại.';

  /// Pixel ratio of the framed PNG: 1080 x 1350 like the milestone card.
  static const double _pixelRatio = 3;

  static String mimeTypeFor(String fileName) {
    switch (BumpPhotoService.extensionFor(fileName)) {
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Asks how to share; null when the sheet is dismissed.
  static Future<BumpShareChoice?> askChoice(BuildContext context) {
    return showModalBottomSheet<BumpShareChoice>(
      context: context,
      useSafeArea: true,
      builder: (context) => SingleChildScrollView(
        // useSafeArea leaves the bottom to the sheet's content.
        padding: EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'Chia sẻ ảnh',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              key: const ValueKey('bump-share-original'),
              leading: const Icon(Icons.image_outlined),
              title: const Text('Ảnh gốc'),
              subtitle: const Text(
                'Gửi nguyên bản, có thể còn thông tin trong tệp ảnh.',
              ),
              onTap: () => Navigator.of(context).pop(BumpShareChoice.original),
            ),
            ListTile(
              key: const ValueKey('bump-share-framed'),
              leading: const Icon(Icons.filter_frames_outlined),
              title: const Text('Ảnh kèm khung MomCare+'),
              subtitle: const Text(
                'Có số tuần và kích thước của bé, không có tên hay ngày dự sinh.',
              ),
              onTap: () => Navigator.of(context).pop(BumpShareChoice.framed),
            ),
          ],
        ),
      ),
    );
  }

  /// Asks how to share [photo] stored at [file], then opens the share sheet.
  /// Nothing happens when the choice is dismissed. Throws when the image
  /// cannot be made or shared; the saved photo is never touched.
  static Future<void> offer(
    BuildContext context, {
    required BumpPhoto photo,
    required File file,
    Rect? origin,
  }) async {
    final choice = await askChoice(context);
    if (choice == null || !context.mounted) return;
    if (choice == BumpShareChoice.original) {
      await ShareHelper.shareFile(
        file.path,
        mimeType: mimeTypeFor(photo.fileName),
        origin: origin,
      );
      return;
    }
    final detail = ContentPackService.weekDetail(photo.week);
    final bytes = await renderFramed(
      Overlay.of(context, rootOverlay: true),
      file,
      detail,
    );
    // A generated name: ShareHelper removes the file after sharing.
    final framed = await ShareHelper.writeTempFile(
      MilestoneCardText.fileName(detail),
      bytes,
    );
    await ShareHelper.shareFile(
      framed.path,
      mimeType: 'image/png',
      origin: origin,
    );
  }

  /// [file] in the frame as PNG bytes. A PNG drawn from pixels has no EXIF or
  /// other metadata. The engine decodes and encodes off the UI thread; the
  /// frame is laid out once, outside the visible area of [overlay].
  static Future<Uint8List> renderFramed(
    OverlayState overlay,
    File file,
    WeekDetail detail,
  ) async {
    final image = await _decode(file);
    final key = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -2 * FramedBumpPhoto.width,
        top: 0,
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              key: key,
              child: FramedBumpPhoto(image: image, detail: detail),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      return await MilestoneCardRenderer.toPng(key, pixelRatio: _pixelRatio);
    } finally {
      entry.remove();
      entry.dispose();
      image.dispose();
    }
  }

  /// Decodes upright, no larger than the frame needs.
  static Future<ui.Image> _decode(File file) async {
    final side = FramedBumpPhoto.width * _pixelRatio;
    final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
    final codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (width, height) {
        final scale = math.min(1.0, side / math.min(width, height));
        return ui.TargetImageSize(
          width: (width * scale).round(),
          height: (height * scale).round(),
        );
      },
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }
}
