import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/pregnancy_model.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/services/database_service.dart';
import '../../onboarding/screens/pregnancy_setup_screen.dart';
import '../screens/main_navigation.dart';

/// "Tôi đã có thai" flow shared by the pre-pregnancy Hôm nay cards.
///
/// After a confirm dialog: with an active pregnancy the app switches straight
/// to pregnancy mode; otherwise it opens [PregnancySetupScreen] in mode-switch
/// mode, which only changes the mode once the pregnancy is saved.
///
/// [activePregnancy] overrides the active-pregnancy lookup (tests only).
Future<void> confirmAndSwitchToPregnancy(
  BuildContext context,
  WidgetRef ref, {
  PregnancyModel? Function()? activePregnancy,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chuyển sang chế độ Đang mang thai?'),
      content: const Text(
        'MomCare+ sẽ theo dõi thai kỳ theo tuần. Nếu chưa có thông tin thai '
        'kỳ, bạn sẽ được hỏi ngày dự sinh. Dữ liệu chu kỳ vẫn được giữ lại.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Tiếp tục'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  // Guarded: returns null when the pregnancy box is unavailable.
  final pregnancy = (activePregnancy ?? DatabaseService.getActivePregnancy)();
  if (pregnancy == null) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PregnancySetupScreen(fromModeSwitch: true),
      ),
    );
    return;
  }

  // The mode change rebuilds MainNavigation and disposes this card, so capture
  // everything up front and never touch ref/context after the await. The root
  // ScaffoldMessenger survives the rebuild.
  final modeNotifier = ref.read(appModeProvider.notifier);
  final navIndex = ref.read(navigationIndexProvider.notifier);
  final messenger = ScaffoldMessenger.maybeOf(context);
  navIndex.state = 0;
  await modeNotifier.setMode(AppMode.pregnancy);
  messenger?.showSnackBar(
    const SnackBar(content: Text('Đã chuyển sang chế độ Đang mang thai')),
  );
}

/// "Tôi đã có thai" card at the bottom of the pre-pregnancy Hôm nay (A4).
class PregnantSwitchCard extends ConsumerWidget {
  /// Overrides the active-pregnancy lookup (tests only).
  @visibleForTesting
  final PregnancyModel? Function()? debugActivePregnancy;

  const PregnantSwitchCard({super.key, this.debugActivePregnancy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.75);

    return Card(
      key: const ValueKey('pregnant-switch-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pregnant_woman, color: Colors.pink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tôi đã có thai',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Chuyển sang chế độ Đang mang thai để theo dõi thai kỳ theo tuần.',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('pregnant-switch-button'),
                onPressed: () => confirmAndSwitchToPregnancy(
                  context,
                  ref,
                  activePregnancy: debugActivePregnancy,
                ),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Chuyển chế độ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
