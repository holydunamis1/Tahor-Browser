import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../icons/semantic_icons.dart';
import 'icon_wrapper.dart';
import 'pressable.dart';

/// The main action: a filled accent button, 48 high, never outlined.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.glyph,
    this.expanded = true,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AppIconGlyph? glyph;

  /// Fills the available width.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: IconSizes.minHitTarget),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.palette.accent,
          borderRadius: theme.radii.buttonRadius,
        ),
        child: Padding(
          padding: AppInsets.horizontal(Spacing.l),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (glyph != null) ...<Widget>[
                AppIcon(
                  glyph!,
                  role: AppIconRole.rowLeading,
                  color: theme.palette.onAccent,
                ),
                const SizedBox(width: Spacing.s),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.title2.copyWith(
                    color: theme.palette.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Pressable(onTap: onPressed, pressedOpacity: 0.8, child: content);
  }
}

/// A quiet action next to a [PrimaryButton]: accent text with no fill and no
/// border. It is the secondary choice in dialogs; it is never used alone for
/// the main action.
class TextActionButton extends StatelessWidget {
  const TextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Draws the text in the error colour.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Pressable(
      onTap: onPressed,
      child: Center(
        child: Padding(
          padding: AppInsets.horizontal(Spacing.m),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.text.title2.copyWith(
              color: destructive ? theme.palette.error : theme.palette.accent,
            ),
          ),
        ),
      ),
    );
  }
}
