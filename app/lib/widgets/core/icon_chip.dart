import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/theme/theme_builder.dart';
import '../icons/semantic_icons.dart';
import 'icon_wrapper.dart';
import 'pressable.dart';

/// An icon in a 40 x 40 container with a 48 x 48 hit area. Every icon in
/// browser chrome is one of these; a bare icon never floats in a toolbar.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.glyph,
    required this.semanticLabel,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.filled = false,
    this.color,
  });

  final AppIconGlyph glyph;

  /// Required: an icon button has no text for a screen reader to read.
  final String semanticLabel;

  /// Null disables the chip.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Draws the chip in the accent tint.
  final bool selected;
  final bool filled;

  /// Overrides the icon colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      child: SizedBox.square(
        dimension: IconSizes.minHitTarget,
        child: Center(
          child: SizedBox.square(
            dimension: IconSizes.chipContainer,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? theme.palette.accentDim
                    : theme.palette.bgSecondary,
                borderRadius: theme.radii.buttonRadius,
              ),
              child: Center(
                child: AppIcon(
                  glyph,
                  filled: filled,
                  color:
                      color ??
                      (selected
                          ? theme.palette.accent
                          : theme.palette.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
