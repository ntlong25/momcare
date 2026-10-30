import 'package:flutter/material.dart';

import '../../../core/utils/navigation_helper.dart';

/// Hôm nay AppBar shortcut to the existing "Dấu hiệu cần đi khám" screen,
/// so the warning signs and "Gọi 115" are reachable at any scroll position.
class EmergencyAppBarButton extends StatelessWidget {
  static const String tooltip = 'Dấu hiệu cần đi khám';

  const EmergencyAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('home-emergency-button'),
      tooltip: tooltip,
      icon: const Icon(Icons.emergency_outlined),
      color: Theme.of(context).colorScheme.error,
      onPressed: () => NavigationHelper.toEmergencyWarning(context),
    );
  }
}
