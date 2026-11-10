import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../icons/semantic_icons.dart';
import 'icon_wrapper.dart';
import 'pressable.dart';

/// A card on the secondary surface with a hairline border and rounded
/// corners: no elevation and no ripple. An optional leading icon, a label, an
/// optional value, and a chevron when it can be tapped.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.label,
    this.value,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron,
    this.semanticLabel,
  });

  final String label;

  /// A second line under the label, in the quieter text colour.
  final String? value;
  final AppIconGlyph? leading;

  /// A widget at the end, before the chevron (for example a switch).
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Defaults to true when the card can be tapped.
  final bool? showChevron;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final bool chevron = showChevron ?? onTap != null;
    final Widget card = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Spacing.xxl + Spacing.s),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.palette.bgSecondary,
          borderRadius: theme.radii.cardRadius,
          border: Border.all(color: theme.palette.borderSubtle),
        ),
        child: Padding(
          padding: AppInsets.symmetric(
            horizontal: Spacing.m,
            vertical: Spacing.s,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) => Row(
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  SizedBox.square(
                    dimension: IconSizes.chipContainer,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.palette.accentDim,
                        borderRadius: theme.radii.chipRadius,
                      ),
                      child: Center(
                        child: AppIcon(
                          leading!,
                          role: AppIconRole.rowLeading,
                          color: theme.palette.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.m),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: theme.text.title2.copyWith(
                          color: theme.palette.textPrimary,
                        ),
                      ),
                      if (value != null)
                        Text(
                          value!,
                          style: theme.text.footnote.copyWith(
                            color: theme.palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: Spacing.s),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: box.maxWidth * 0.5),
                    child: trailing!,
                  ),
                ],
                if (chevron) ...<Widget>[
                  const SizedBox(width: Spacing.s),
                  AppIcon(
                    AppIcons.chevron,
                    role: AppIconRole.rowTrailing,
                    color: theme.palette.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (onTap == null) {
      return card;
    }
    return Pressable(onTap: onTap, semanticLabel: semanticLabel, child: card);
  }
}
