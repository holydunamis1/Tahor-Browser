import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/spacing.dart';
import '../../core/models/tab_model.dart';
import '../../core/theme/theme_builder.dart';
import '../../core/utils/url_utils.dart';
import '../../l10n/l10n_extensions.dart';
import '../core/icon_wrapper.dart';
import '../core/pressable.dart';
import '../icons/semantic_icons.dart';

/// One tab in the tab grid: its title and host, a preview of the page, and a
/// close button. The showing tab has a border in the focus colour.
class TabCard extends StatelessWidget {
  const TabCard({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    this.thumbnail,
  });

  final TabModel tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  /// A PNG of the page, when there is one.
  final Uint8List? thumbnail;

  /// The title shown: the page's, else its host, else "New tab".
  String titleFor(BuildContext context) {
    final String? title = tab.title;
    if (title != null && title.trim().isNotEmpty) {
      return title.trim();
    }
    return tab.isBlank ? context.l10n.tabBlankTitle : displayHostOf(tab.url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final String title = titleFor(context);
    final String host = tab.isBlank ? '' : displayHostOf(tab.url);
    return Pressable(
      onTap: onTap,
      semanticLabel: tab.isIncognito
          ? '${context.l10n.tabPrivateLabel}, $title'
          : title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.palette.bgSecondary,
          borderRadius: theme.radii.cardRadius,
          border: Border.all(
            color: isActive
                ? theme.palette.borderFocus
                : theme.palette.borderSubtle,
            width: isActive ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: theme.radii.cardRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: Spacing.m,
                  top: Spacing.xs,
                  bottom: Spacing.xs,
                ),
                child: Row(
                  children: <Widget>[
                    if (tab.isIncognito) ...<Widget>[
                      AppIcon(
                        AppIcons.privateTab,
                        role: AppIconRole.rowTrailing,
                        color: theme.palette.accent,
                      ),
                      const SizedBox(width: Spacing.xs),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.text.callout.copyWith(
                              color: theme.palette.textPrimary,
                            ),
                          ),
                          if (host.isNotEmpty && host != title)
                            Text(
                              host,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.text.caption.copyWith(
                                color: theme.palette.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Pressable(
                      key: ValueKey<String>('close-${tab.id}'),
                      onTap: onClose,
                      semanticLabel: context.l10n.tabsCloseTab,
                      child: SizedBox.square(
                        dimension: IconSizes.minHitTarget,
                        child: Center(
                          child: AppIcon(
                            AppIcons.close,
                            role: AppIconRole.rowTrailing,
                            color: theme.palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _Preview(thumbnail: thumbnail)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.thumbnail});

  final Uint8List? thumbnail;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final Widget placeholder = ColoredBox(
      color: theme.palette.bgTertiary,
      child: Center(
        child: AppIcon(
          AppIcons.globe,
          role: AppIconRole.hero,
          color: theme.palette.textTertiary,
        ),
      ),
    );
    final Uint8List? bytes = thumbnail;
    if (bytes == null) {
      return placeholder;
    }
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          placeholder,
    );
  }
}
