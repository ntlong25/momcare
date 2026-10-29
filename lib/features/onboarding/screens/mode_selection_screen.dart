import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../home/screens/main_navigation.dart';
import 'pregnancy_setup_screen.dart';
import '../../../core/theme/app_tokens.dart';

class ModeSelectionScreen extends ConsumerWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  size: 50,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chào mừng đến với MomCare+',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn đang ở giai đoạn nào?',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _ModeCard(
                icon: Icons.eco,
                tone: AppTone.success,
                title: 'Đang lên kế hoạch mang thai',
                subtitle:
                    'Theo dõi chu kỳ, dinh dưỡng chuẩn bị và gợi ý thụ thai',
                onTap: () async {
                  await ref
                      .read(appModeProvider.notifier)
                      .setMode(AppMode.prePregnancy);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.pregnant_woman,
                tone: AppTone.primary,
                title: 'Đã mang thai',
                subtitle: 'Theo dõi thai kỳ, sức khỏe và dinh dưỡng theo tuần',
                onTap: () async {
                  await ref
                      .read(appModeProvider.notifier)
                      .setMode(AppMode.pregnancy);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const PregnancySetupScreen(),
                      ),
                    );
                  }
                },
              ),
              const Spacer(),
              Text(
                'Bạn có thể thay đổi lựa chọn này sau trong Cài đặt',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final AppTone tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = tone.of(context);
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.container,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: colors.onContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
