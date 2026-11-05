import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/motion.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../icons/semantic_icons.dart';
import 'icon_wrapper.dart';

/// A transparent row for lists: an optional leading icon, a title with an
/// optional second line, an optional trailing widget and a chevron. Pressing
/// tints the row instead of fading it.
class PremiumRow extends StatefulWidget {
  const PremiumRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.showChevron,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final AppIconGlyph? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Defaults to true when the row can be tapped.
  final bool? showChevron;
  final String? semanticLabel;

  @override
  State<PremiumRow> createState() => _PremiumRowState();
}

class _PremiumRowState extends State<PremiumRow> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) {
      setState(() => _pressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final Motion motion = Motion.of(context);
    final bool chevron = widget.showChevron ?? widget.onTap != null;
    return Semantics(
      button: _enabled,
      enabled: _enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _set(true) : null,
        onTapUp: _enabled ? (_) => _set(false) : null,
        onTapCancel: _enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: motion.press,
          curve: motion.curve,
          color: _pressed ? theme.palette.bgTertiary : const Color(0x00000000),
          constraints: const BoxConstraints(minHeight: Spacing.xxl + Spacing.s),
          padding: AppInsets.symmetric(
            horizontal: Spacing.m,
            vertical: Spacing.s,
          ),
          child: Row(
            children: <Widget>[
              if (widget.leading != null) ...<Widget>[
                SizedBox.square(
                  dimension: IconSizes.chipContainer,
                  child: Center(
                    child: AppIcon(
                      widget.leading!,
                      role: AppIconRole.rowLeading,
                      color: theme.palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.s),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text.callout.copyWith(
                        color: theme.palette.textPrimary,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text.footnote.copyWith(
                          color: theme.palette.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.trailing != null) ...<Widget>[
                const SizedBox(width: Spacing.s),
                widget.trailing!,
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
    );
  }
}
