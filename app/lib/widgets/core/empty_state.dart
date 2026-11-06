import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../icons/semantic_icons.dart';
import 'icon_wrapper.dart';

/// What a list shows when it has nothing: an icon, a title, an optional
/// sentence and an optional action, centred.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.glyph,
    required this.title,
    this.subtitle,
    this.action,
  });

  final AppIconGlyph glyph;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Center(
      child: Padding(
        padding: AppInsets.all(Spacing.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: Spacing.xxxl,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.palette.accentDim,
                    borderRadius: theme.radii.pill(Spacing.xxxl),
                  ),
                  child: Center(
                    child: AppIcon(
                      glyph,
                      role: AppIconRole.hero,
                      size: IconSizes.hero,
                      color: theme.palette.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.m),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.text.title2.copyWith(
                    color: theme.palette.textPrimary,
                  ),
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: Spacing.xs),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.text.body.copyWith(
                    color: theme.palette.textSecondary,
                  ),
                ),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(height: Spacing.l),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
