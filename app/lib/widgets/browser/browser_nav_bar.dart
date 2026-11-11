import 'package:flutter/widgets.dart';

import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import '../core/icon_chip.dart';
import '../icons/semantic_icons.dart';

/// The bottom bar: Back, Forward, an optional tabs button, Reload (Stop while
/// a page loads) and Menu, each an icon chip. Back and Forward are disabled
/// when there is nowhere to go.
class BrowserNavBar extends StatelessWidget {
  const BrowserNavBar({
    super.key,
    required this.canGoBack,
    required this.canGoForward,
    required this.isLoading,
    required this.onBack,
    required this.onForward,
    required this.onReload,
    required this.onStop,
    required this.onMenu,
    this.tabsButton,
  });

  final bool canGoBack;
  final bool canGoForward;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onReload;
  final VoidCallback onStop;
  final VoidCallback onMenu;

  /// The tab count button, added in the tab batch.
  final Widget? tabsButton;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.palette.bgPrimary,
        border: Border(top: BorderSide(color: theme.palette.borderSubtle)),
      ),
      child: Padding(
        padding: AppInsets.symmetric(
          horizontal: Spacing.s,
          vertical: Spacing.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconChip(
              glyph: AppIcons.back,
              semanticLabel: l10n.navBack,
              onTap: canGoBack ? onBack : null,
            ),
            IconChip(
              glyph: AppIcons.forward,
              semanticLabel: l10n.navForward,
              onTap: canGoForward ? onForward : null,
            ),
            ?tabsButton,
            if (isLoading)
              IconChip(
                glyph: AppIcons.close,
                semanticLabel: l10n.navStop,
                onTap: onStop,
              )
            else
              IconChip(
                glyph: AppIcons.reload,
                semanticLabel: l10n.navReload,
                onTap: onReload,
              ),
            IconChip(
              glyph: AppIcons.menu,
              semanticLabel: l10n.navMenu,
              onTap: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}
