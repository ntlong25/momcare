import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/week_detail_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/share_helper.dart';
import '../milestone_card_text.dart';
import '../widgets/milestone_card.dart';

/// Renders the widget under a [RepaintBoundary] key to PNG bytes.
class MilestoneCardRenderer {
  const MilestoneCardRenderer._();

  static Future<Uint8List> toPng(GlobalKey key, {double pixelRatio = 3}) async {
    final boundary = key.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Milestone card is not on screen');
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG encoding failed');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  }
}

/// "Thẻ cột mốc": preview and share a week's milestone card as a PNG.
class MilestoneCardScreen extends StatefulWidget {
  final WeekDetail detail;

  const MilestoneCardScreen({super.key, required this.detail});

  static const String errorMessage = 'Không tạo được thẻ. Vui lòng thử lại.';

  @override
  State<MilestoneCardScreen> createState() => _MilestoneCardScreenState();
}

class _MilestoneCardScreenState extends State<MilestoneCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share(BuildContext buttonContext) async {
    if (_busy) return;
    final origin = ShareHelper.originOf(buttonContext);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await MilestoneCardRenderer.toPng(_cardKey);
      final file = await ShareHelper.writeTempFile(
        MilestoneCardText.fileName(widget.detail),
        bytes,
      );
      await ShareHelper.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: MilestoneCardText.headline(widget.detail),
          sharePositionOrigin: origin,
        ),
      );
    } catch (error) {
      AppLogger.instance.warning('Could not share milestone card: $error');
      messenger.showSnackBar(
        const SnackBar(content: Text(MilestoneCardScreen.errorMessage)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Thẻ cột mốc')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: MilestoneCard.width),
              child: AspectRatio(
                aspectRatio: MilestoneCard.width / MilestoneCard.height,
                child: FittedBox(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: MilestoneCard(detail: widget.detail),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thẻ chỉ có số tuần và thông tin về bé trong tuần này, không có tên hay ngày dự sinh của bạn.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (buttonContext) => FilledButton.tonalIcon(
              key: const ValueKey('milestone-share'),
              style: AppTheme.tonalButtonStyle(theme.colorScheme),
              onPressed: _busy ? null : () => _share(buttonContext),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share),
              label: const Text('Chia sẻ thẻ'),
            ),
          ),
        ],
      ),
    );
  }
}
