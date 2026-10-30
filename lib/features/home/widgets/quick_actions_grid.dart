import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/section_header.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      QuickActionTile(
        icon: Icons.restaurant_menu,
        title: 'Dinh dưỡng',
        tone: AppTone.primary,
        onTap: () => NavigationHelper.toNutrition(context),
      ),
      QuickActionTile(
        icon: Icons.calendar_today,
        title: 'Lịch hẹn',
        tone: AppTone.secondary,
        onTap: () => NavigationHelper.toAppointments(context),
      ),
      QuickActionTile(
        icon: Icons.favorite,
        title: 'Nhật ký sức khỏe',
        tone: AppTone.primary,
        onTap: () => NavigationHelper.toHealthDiary(context),
      ),
      QuickActionTile(
        icon: Icons.book,
        title: 'Công thức nấu ăn',
        tone: AppTone.success,
        onTap: () => NavigationHelper.toRecipes(context),
      ),
      // Cycle tracking is hidden in pregnancy mode (Home is pregnancy-only).
      QuickActionTile(
        icon: Icons.warning_amber_rounded,
        title: 'Dấu hiệu cần khám',
        tone: AppTone.danger,
        onTap: () => NavigationHelper.toEmergencyWarning(context),
      ),
      QuickActionTile(
        icon: Icons.help_outline,
        title: 'Hướng dẫn',
        tone: AppTone.secondary,
        onTap: () => NavigationHelper.toGuide(context),
      ),
    ];
    return QuickActionTileGrid(tiles: tiles);
  }
}

/// 'Truy cập nhanh' section: [QuickActionTile]s two per row, shared by the
/// pregnancy and pre-pregnancy Hôm nay screens.
class QuickActionTileGrid extends StatelessWidget {
  final List<Widget> tiles;
  final String title;

  const QuickActionTileGrid({
    super.key,
    required this.tiles,
    this.title = 'Truy cập nhanh',
  });

  @override
  Widget build(BuildContext context) {
    // Two tiles per row; each row takes the height of its tallest tile so
    // labels never overflow at large font scales.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < tiles.length
                      ? tiles[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One quick-action tile: a tinted icon above a centred label that wraps
/// only when it does not fit.
class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final AppTone tone;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = tone.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.container,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.onContainer, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
