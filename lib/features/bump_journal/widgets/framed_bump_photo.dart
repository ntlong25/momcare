import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/models/week_detail_model.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../milestone_card/milestone_card_text.dart';
import '../../milestone_card/widgets/milestone_card.dart';

/// Bump photo in the shareable MomCare+ frame, the size of the milestone card
/// and rendered like it: fixed brand colours, the bundled font and no device
/// text scaling. Shows the photo, the week, the size comparison and the mark,
/// never a name, a date or anything else about the mother.
class FramedBumpPhoto extends StatelessWidget {
  static const double width = MilestoneCard.width;
  static const double height = MilestoneCard.height;
  static const double _margin = 16;
  static const double _photoSide = width - 2 * _margin;

  final ui.Image image;
  final WeekDetail detail;

  const FramedBumpPhoto({super.key, required this.image, required this.detail});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: MilestoneCard.fontFamily,
          color: AppBrandColors.ink,
          decoration: TextDecoration.none,
        ),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.fromLTRB(_margin, _margin, _margin, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppBrandColors.background,
                AppBrandColors.backgroundAccent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: RawImage(
                  key: const ValueKey('framed-photo-image'),
                  image: image,
                  width: _photoSide,
                  height: _photoSide,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _photoSide),
                      child: Text(
                        MilestoneCardText.headline(detail),
                        key: const ValueKey('framed-photo-headline'),
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Row(
                children: [
                  BrandMark(size: 22),
                  SizedBox(width: 6),
                  Text(
                    'MomCare+',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
