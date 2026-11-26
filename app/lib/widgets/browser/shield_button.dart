import 'package:flutter/widgets.dart';

import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import '../core/icon_chip.dart';
import '../icons/semantic_icons.dart';

/// Whether ads are being blocked on the page showing.
enum ShieldState {
  /// Blocking is on, here and everywhere.
  on,

  /// Blocking is on, but the person turned it off for this site.
  siteOff,

  /// Blocking is off everywhere.
  off,
}

/// The ad-blocking button in the address bar. It claims nothing about how many
/// ads were blocked, because the platform does not report that.
class ShieldButton extends StatelessWidget {
  const ShieldButton({super.key, required this.state, required this.onTap});

  final ShieldState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = context.l10n;
    switch (state) {
      case ShieldState.on:
        return IconChip(
          glyph: AppIcons.shieldCheck,
          semanticLabel: l10n.shieldOn,
          color: theme.palette.accent,
          onTap: onTap,
        );
      case ShieldState.siteOff:
        return IconChip(
          glyph: AppIcons.shield,
          semanticLabel: l10n.shieldSiteOff,
          color: theme.palette.warning,
          onTap: onTap,
        );
      case ShieldState.off:
        return IconChip(
          glyph: AppIcons.shieldOff,
          semanticLabel: l10n.shieldOff,
          color: theme.palette.textTertiary,
          onTap: onTap,
        );
    }
  }
}
