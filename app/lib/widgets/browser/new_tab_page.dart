import 'package:flutter/widgets.dart';

import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import '../core/icon_wrapper.dart';
import '../core/premium_card.dart';
import '../icons/semantic_icons.dart';

/// What a tab with no page shows: the name once, a line about the browser and
/// a search field that opens the address bar. Bookmark shortcuts, a scan
/// shortcut and the banner slot arrive with their batches.
class NewTabPage extends StatelessWidget {
  const NewTabPage({super.key, required this.onSearchTap});

  /// Called when the search field is tapped; the screen focuses the address
  /// bar.
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: AppInsets.symmetric(horizontal: Spacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: SizedBox.square(
                    dimension: 72,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.palette.accentDim,
                        borderRadius: theme.radii.heroRadius,
                      ),
                      child: Center(
                        child: AppIcon(
                          AppIcons.shieldCheck,
                          role: AppIconRole.hero,
                          size: 36,
                          color: theme.palette.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.m),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.appName,
                    textAlign: TextAlign.center,
                    style: theme.text.title1.copyWith(
                      color: theme.palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  l10n.startPageTagline,
                  textAlign: TextAlign.center,
                  style: theme.text.body.copyWith(
                    color: theme.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                PremiumCard(
                  label: l10n.startPageSearch,
                  leading: AppIcons.search,
                  onTap: onSearchTap,
                  showChevron: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
