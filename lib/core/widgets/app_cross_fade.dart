import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Cross-fades to a new [child] (give it a key per value) while the size
/// follows, so nothing around it jumps. A zero [duration] swaps within one
/// frame: `AnimatedSize` cannot lay out with no duration, and the tree has to
/// stay the same for a later non-zero [duration] to fade.
class AppCrossFade extends StatelessWidget {
  static const Duration _oneFrame = Duration(milliseconds: 1);

  final Duration duration;
  final Alignment alignment;
  final Widget child;

  const AppCrossFade({
    super.key,
    required this.duration,
    this.alignment = Alignment.center,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final shown = duration == Duration.zero ? _oneFrame : duration;
    return AnimatedSize(
      duration: shown,
      curve: AppMotion.standard,
      alignment: alignment,
      child: AnimatedSwitcher(duration: shown, child: child),
    );
  }
}
