import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Colour variants of [AppCard].
enum AppCardVariant {
  /// Plain content card on `surfaceContainerLow`.
  standard,

  /// The one emphasised card of a screen, on `primaryContainer`.
  hero,

  /// A bright invitation below the hero (bump photo card), on the semantic
  /// spotlight container, which differs from the hero in both themes.
  spotlight,

  /// Warning signs and urgent entry points, on `errorContainer`.
  alert,

  /// Notes and guidance, on the semantic `warningContainer`.
  notice,

  /// Solid red emergency entry, on the semantic `emergency` colour, so it
  /// never reads as a pink card next to the brand colour.
  emergency,

  /// The thai giáo card of the day, on the semantic peach container.
  peach,

  /// The daily tip card, on the semantic mint container.
  mint,
}

/// The resolved colours of an [AppCardVariant] in the current theme.
@immutable
class AppCardColors {
  final Color background;
  final Color foreground;
  final Color icon;

  const AppCardColors({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  factory AppCardColors.of(BuildContext context, AppCardVariant variant) {
    final scheme = Theme.of(context).colorScheme;
    switch (variant) {
      case AppCardVariant.standard:
        return AppCardColors(
          background: scheme.surfaceContainerLow,
          foreground: scheme.onSurface,
          icon: scheme.primary,
        );
      case AppCardVariant.hero:
        return AppCardColors(
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          icon: scheme.onPrimaryContainer,
        );
      case AppCardVariant.spotlight:
        final s = context.semantic;
        return AppCardColors(
          background: s.spotlightContainer,
          foreground: s.onSpotlightContainer,
          icon: s.onSpotlightContainer,
        );
      case AppCardVariant.alert:
        return AppCardColors(
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
          icon: scheme.onErrorContainer,
        );
      case AppCardVariant.notice:
        final s = context.semantic;
        return AppCardColors(
          background: s.warningContainer,
          foreground: s.onWarningContainer,
          icon: s.onWarningContainer,
        );
      case AppCardVariant.emergency:
        final s = context.semantic;
        return AppCardColors(
          background: s.emergency,
          foreground: s.onEmergency,
          icon: s.onEmergency,
        );
      case AppCardVariant.peach:
        final s = context.semantic;
        return AppCardColors(
          background: s.peachContainer,
          foreground: s.onPeachContainer,
          icon: s.onPeachContainer,
        );
      case AppCardVariant.mint:
        final s = context.semantic;
        return AppCardColors(
          background: s.mintContainer,
          foreground: s.onMintContainer,
          icon: s.onMintContainer,
        );
    }
  }
}

/// Shared card: optional header (leading icon, title, trailing action) and
/// a body, with 16 dp padding and a 16 dp radius. Text and icons inside
/// default to the variant's foreground colour.
class AppCard extends StatelessWidget {
  final AppCardVariant variant;
  final IconData? icon;
  final String? title;

  /// Style of [title]; defaults to `titleMedium` bold.
  final TextStyle? titleStyle;

  /// Widget at the end of the header row (e.g. a "Xem tất cả" button).
  final Widget? trailing;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  /// Outer margin; `null` keeps the theme's card margin.
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    this.variant = AppCardVariant.standard,
    this.icon,
    this.title,
    this.titleStyle,
    this.trailing,
    this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppCardColors.of(context, variant);
    final hasHeader = icon != null || title != null || trailing != null;

    Widget content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader)
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colors.icon),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: title == null
                      ? const SizedBox.shrink()
                      : Text(
                          title!,
                          style: (titleStyle ?? theme.textTheme.titleMedium)
                              ?.copyWith(
                                fontWeight: titleStyle == null
                                    ? FontWeight.bold
                                    : null,
                                color: colors.foreground,
                              ),
                        ),
                ),
                ?trailing,
              ],
            ),
          if (hasHeader && child != null) const SizedBox(height: AppSpacing.md),
          ?child,
        ],
      ),
    );

    content = IconTheme.merge(
      data: IconThemeData(color: colors.foreground),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.foreground),
        child: content,
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: content,
      );
    }

    return Card(
      color: colors.background,
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
