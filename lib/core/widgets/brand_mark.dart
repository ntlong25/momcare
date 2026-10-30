import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// The MomCare+ launcher icon (white mother-and-baby heart on the pink
/// adaptive-icon background), drawn with the same geometry as
/// `assets/branding/app_icon_foreground.svg`.
///
/// At the default [size] of 160 dp it matches the Android 12 system splash
/// icon: the 108 dp adaptive canvas is shown at 240 dp and masked to a
/// 160 dp circle, so the in-app splash can take over without a jump.
class BrandMark extends StatelessWidget {
  /// Diameter of the pink circle.
  final double size;

  const BrandMark({super.key, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MomCare+',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: BrandMarkPainter()),
      ),
    );
  }
}

/// Paints [BrandMark]. Public so tests can compare it with the SVG master.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter();

  /// Size of the adaptive-icon foreground canvas in SVG units (108 dp at 4x).
  static const double canvasUnits = 432;

  /// Visible circle of the adaptive icon on the splash (160 of 240 dp).
  static const double maskFraction = 160 / 240;

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.shortestSide;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, d / 2, Paint()..color = AppBrandColors.primary);

    // The circle shows the middle `maskFraction` of the 432-unit canvas.
    final scale = d / (canvasUnits * maskFraction);
    canvas.save();
    canvas.translate(
      center.dx - canvasUnits / 2 * scale,
      center.dy - canvasUnits / 2 * scale,
    );
    canvas.scale(scale);
    // Same transform as the SVG group: translate(83.4 78.2) scale(2.6).
    canvas.translate(83.4, 78.2);
    canvas.scale(2.6);

    final glyph = AppBrandColors.onPrimary;
    final heart = Path()
      ..moveTo(50, 34)
      ..cubicTo(53, 26, 60, 21, 69, 21)
      ..cubicTo(80, 21, 88, 29, 88, 40)
      ..cubicTo(88, 56, 74, 70, 50, 85)
      ..cubicTo(30, 73, 17, 61, 15, 46);
    canvas.drawPath(
      heart,
      Paint()
        ..color = glyph
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = glyph;
    canvas.drawCircle(const Offset(31, 28), 12, dot);
    canvas.drawCircle(const Offset(46, 61), 9.5, dot);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandMarkPainter oldDelegate) => false;
}
