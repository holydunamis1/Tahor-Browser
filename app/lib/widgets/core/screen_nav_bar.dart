import 'package:flutter/widgets.dart';

import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import '../icons/semantic_icons.dart';
import 'icon_chip.dart';

/// The top bar of a screen: a Back chip (when there is somewhere to go
/// back to), the title, and optional action chips at the end.
class ScreenNavBar extends StatelessWidget {
  const ScreenNavBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const <Widget>[],
  });

  final String title;

  /// Null hides the Back chip (a root screen).
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Padding(
      padding: AppInsets.symmetric(horizontal: Spacing.s, vertical: Spacing.xs),
      child: Row(
        children: <Widget>[
          if (onBack != null)
            IconChip(
              glyph: AppIcons.back,
              semanticLabel: context.l10n.navBack,
              onTap: onBack,
            )
          else
            const SizedBox(width: Spacing.s),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text.title1.copyWith(
                  color: theme.palette.textPrimary,
                ),
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
