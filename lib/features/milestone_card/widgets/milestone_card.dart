import 'package:flutter/material.dart';

import '../../../core/models/week_detail_model.dart';
import '../../../core/theme/app_theme.dart';
import '../milestone_card_text.dart';

/// Shareable 4:5 milestone card, laid out at [width] x [height] logical
/// pixels and rendered at 3x (1080 x 1350 px). Fixed light colours (it is an
/// image), the bundled Be Vietnam Pro font and no device text scaling, so
/// the PNG looks the same on every phone.
class MilestoneCard extends StatelessWidget {
  static const double width = 360;
  static const double height = 450;
  static const String fontFamily = 'BeVietnamPro';

  static const Color _ink = AppTheme.textPrimaryColor;
  static const Color _inkSoft = Color(0xFF5C4A4D);

  final WeekDetail detail;

  const MilestoneCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final details = MilestoneCardText.details(detail);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: fontFamily,
          color: _ink,
          decoration: TextDecoration.none,
        ),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF1F2), Color(0xFFFFDDE0)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: AppTheme.primaryDarkColor,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Hành trình của mẹ',
                    style: TextStyle(fontSize: 16, color: _inkSoft),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'TUẦN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: _inkSoft,
                ),
              ),
              Text(
                '${detail.week}',
                key: const ValueKey('milestone-week-number'),
                style: const TextStyle(
                  fontSize: 120,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 96,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: width - 56),
                    child: Text(
                      MilestoneCardText.headline(detail),
                      key: const ValueKey('milestone-headline'),
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      details,
                      key: const ValueKey('milestone-details'),
                      style: const TextStyle(fontSize: 16, color: _inkSoft),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              const Row(
                children: [
                  Icon(
                    Icons.child_care,
                    color: AppTheme.primaryDarkColor,
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'MomCare+',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
