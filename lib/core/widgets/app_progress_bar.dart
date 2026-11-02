import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_tokens.dart';

/// Rounded determinate progress bar that animates to a new [value].
class AppProgressBar extends StatelessWidget {
  final double value;
  final double minHeight;
  final Color? color;
  final Color? backgroundColor;

  /// Fills up from zero when first shown. Off for bars inside lists, which
  /// would replay it on every scroll.
  final bool animateIn;

  const AppProgressBar({
    super.key,
    required this.value,
    this.minHeight = 6,
    this.color,
    this.backgroundColor,
    this.animateIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animateIn ? 0 : value, end: value),
        duration: AppMotion.of(context, AppMotion.progress),
        curve: AppMotion.standard,
        builder: (context, shown, _) => LinearProgressIndicator(
          value: shown,
          minHeight: minHeight,
          color: color,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}
