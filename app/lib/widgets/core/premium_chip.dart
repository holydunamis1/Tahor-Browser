import 'package:flutter/widgets.dart';

import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../icons/semantic_icons.dart';
import 'icon_wrapper.dart';
import 'pressable.dart';

/// A small labelled pill for metadata and status; with [onTap] it is a
/// choice (a time range, a filter) and gets a 48 high hit area.
class PremiumChip extends StatelessWidget {
  const PremiumChip({
    super.key,
    required this.label,
    this.glyph,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final AppIconGlyph? glyph;
  final bool selected;
  final VoidCallback? onTap;

  static const double height = 32;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final Color textColor = selected
        ? theme.palette.accent
        : theme.palette.textSecondary;
    final Widget chip = DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? theme.palette.accentDim : theme.palette.bgTertiary,
        borderRadius: theme.radii.pill(height),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: height),
        child: Padding(
          padding: AppInsets.horizontal(Spacing.m),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (glyph != null) ...<Widget>[
                AppIcon(
                  glyph!,
                  role: AppIconRole.rowTrailing,
                  color: textColor,
                ),
                const SizedBox(width: Spacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.footnote.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) {
      return chip;
    }
    return Pressable(
      onTap: onTap,
      child: Center(widthFactor: 1, heightFactor: 1, child: chip),
    );
  }
}
