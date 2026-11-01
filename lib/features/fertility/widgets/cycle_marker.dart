import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// What a day on the Chu kỳ calendar is marked as.
///
/// [logged] and [intimacy] are small corner marks for what the user wrote
/// down; the others are the one mark under the day number.
enum CycleMarkerKind {
  period,
  ovulation,
  fertile,
  predictedPeriod,
  logged,
  intimacy,
}

/// How a [CycleMarkerKind] is drawn. Each kind has its own shape so the
/// markers can be told apart without relying on colour (colour-vision
/// deficiency, dark mode).
enum CycleMarkerShape { filledDot, star, band, dashedRing, square, ring }

/// Shape, colour and legend label of one marker kind.
@immutable
class CycleMarkerSpec {
  final CycleMarkerKind kind;
  final CycleMarkerShape shape;
  final Color color;
  final String label;

  const CycleMarkerSpec({
    required this.kind,
    required this.shape,
    required this.color,
    required this.label,
  });

  /// Period = filled error dot, ovulation = warning (amber) star, fertile =
  /// info (blue) band, predicted period = hollow dashed error ring. The
  /// three different colours are far apart in lightness/hue in both themes
  /// (checked by `test/cycle_marker_test.dart`).
  factory CycleMarkerSpec.of(BuildContext context, CycleMarkerKind kind) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(scheme);
    return switch (kind) {
      CycleMarkerKind.period => CycleMarkerSpec(
        kind: kind,
        shape: CycleMarkerShape.filledDot,
        color: scheme.error,
        label: 'Kỳ kinh',
      ),
      CycleMarkerKind.ovulation => CycleMarkerSpec(
        kind: kind,
        shape: CycleMarkerShape.star,
        color: semantic.warning,
        label: 'Rụng trứng',
      ),
      CycleMarkerKind.fertile => CycleMarkerSpec(
        kind: kind,
        shape: CycleMarkerShape.band,
        color: semantic.info,
        label: 'Dễ thụ thai',
      ),
      CycleMarkerKind.predictedPeriod => CycleMarkerSpec(
        kind: kind,
        shape: CycleMarkerShape.dashedRing,
        color: scheme.error,
        label: 'Kỳ kinh dự kiến',
      ),
      CycleMarkerKind.logged => CycleMarkerSpec(
        kind: kind,
        shape: CycleMarkerShape.square,
        color: semantic.success,
        label: 'Đã ghi',
      ),
      CycleMarkerKind.intimacy => CycleMarkerSpec(
        kind: kind,
        shape: CycleMarkerShape.ring,
        color: scheme.onSurface,
        label: 'Ngày gần gũi',
      ),
    };
  }
}

/// One calendar marker, used both under the day numbers and in the legend
/// so the two always look the same.
class CycleMarker extends StatelessWidget {
  final CycleMarkerKind kind;

  /// Height of the marker box (the band is twice as wide).
  final double size;

  const CycleMarker({super.key, required this.kind, this.size = 8});

  @override
  Widget build(BuildContext context) {
    final spec = CycleMarkerSpec.of(context, kind);
    final width = spec.shape == CycleMarkerShape.band ? size * 2 : size;
    return Semantics(
      label: spec.label,
      child: SizedBox(
        width: width,
        height: size,
        child: CustomPaint(
          painter: _CycleMarkerPainter(spec.shape, spec.color),
        ),
      ),
    );
  }
}

class _CycleMarkerPainter extends CustomPainter {
  final CycleMarkerShape shape;
  final Color color;

  _CycleMarkerPainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final center = size.center(Offset.zero);
    switch (shape) {
      case CycleMarkerShape.filledDot:
        canvas.drawCircle(center, size.shortestSide / 2, fill);
      case CycleMarkerShape.star:
        canvas.drawPath(_starPath(center, size.shortestSide / 2 + 1), fill);
      case CycleMarkerShape.band:
        final height = size.height * 0.55;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: size.width, height: height),
            Radius.circular(height / 2),
          ),
          fill,
        );
      case CycleMarkerShape.square:
        canvas.drawRect(Offset.zero & size, fill);
      case CycleMarkerShape.ring:
        final stroke = math.max(1.5, size.shortestSide * 0.18);
        canvas.drawCircle(
          center,
          size.shortestSide / 2 - stroke / 2,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..isAntiAlias = true,
        );
      case CycleMarkerShape.dashedRing:
        final stroke = math.max(1.5, size.shortestSide * 0.18);
        final ring = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..isAntiAlias = true;
        final rect = Rect.fromCircle(
          center: center,
          radius: size.shortestSide / 2 - stroke / 2,
        );
        const dashes = 6;
        const sweep = 2 * math.pi / dashes;
        for (var i = 0; i < dashes; i++) {
          canvas.drawArc(rect, i * sweep, sweep * 0.6, false, ring);
        }
    }
  }

  Path _starPath(Offset c, double outer) {
    final inner = outer * 0.45;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_CycleMarkerPainter old) =>
      old.shape != shape || old.color != color;
}

/// The 'Chú giải lịch' legend: every marker kind with its label. The
/// intimacy mark stays out of it until the user enables that row.
class CycleMarkerLegend extends StatelessWidget {
  final bool showIntimacy;

  const CycleMarkerLegend({super.key, this.showIntimacy = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final kind in CycleMarkerKind.values)
          if (showIntimacy || kind != CycleMarkerKind.intimacy)
            Row(
              key: ValueKey('cycle-legend-${kind.name}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                CycleMarker(kind: kind, size: 12),
                const SizedBox(width: 6),
                Text(
                  CycleMarkerSpec.of(context, kind).label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
      ],
    );
  }
}
