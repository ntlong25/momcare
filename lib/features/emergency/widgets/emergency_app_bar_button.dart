import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/navigation_helper.dart';

/// Hôm nay AppBar shortcut to the existing "Dấu hiệu cần đi khám" screen,
/// so the warning signs and "Gọi 115" are reachable at any scroll position.
/// Light theme: red icon on a light red fill, so it does not compete with
/// the solid red "Gọi 115" actions it leads to. Dark theme: solid emergency
/// fill, because the dark red container disappears into the AppBar.
class EmergencyAppBarButton extends StatelessWidget {
  static const String tooltip = 'Dấu hiệu cần đi khám';

  const EmergencyAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton.filled(
      key: const ValueKey('home-emergency-button'),
      tooltip: tooltip,
      icon: const Icon(Icons.emergency_outlined),
      style: IconButton.styleFrom(
        backgroundColor: dark
            ? semantic.emergency
            : semantic.emergencyContainer,
        foregroundColor: dark ? semantic.onEmergency : semantic.emergency,
      ),
      onPressed: () => NavigationHelper.toEmergencyWarning(context),
    );
  }
}
