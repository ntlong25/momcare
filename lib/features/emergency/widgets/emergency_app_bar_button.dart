import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/navigation_helper.dart';

/// Hôm nay AppBar shortcut to the existing "Dấu hiệu cần đi khám" screen,
/// so the warning signs and "Gọi 115" are reachable at any scroll position.
/// Solid emergency fill, so it does not read as a brand pink action.
class EmergencyAppBarButton extends StatelessWidget {
  static const String tooltip = 'Dấu hiệu cần đi khám';

  const EmergencyAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return IconButton.filled(
      key: const ValueKey('home-emergency-button'),
      tooltip: tooltip,
      icon: const Icon(Icons.emergency_outlined),
      style: IconButton.styleFrom(
        backgroundColor: semantic.emergency,
        foregroundColor: semantic.onEmergency,
      ),
      onPressed: () => NavigationHelper.toEmergencyWarning(context),
    );
  }
}
