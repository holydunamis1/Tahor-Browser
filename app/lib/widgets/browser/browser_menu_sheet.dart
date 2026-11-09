import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import '../core/icon_wrapper.dart';
import '../core/premium_bottom_sheet.dart';
import '../core/premium_row.dart';
import '../core/pressable.dart';
import '../core/section_header.dart';
import '../icons/semantic_icons.dart';

/// Where an item sits in the browser menu.
enum MenuGroup {
  /// The row of icons at the top.
  quick,
  page,
  tabs,
  library,
  app,
}

/// One item of the browser menu. Items that do not apply are simply left
/// out of the list; the sheet draws what it is given.
@immutable
class MenuAction {
  const MenuAction({
    required this.id,
    required this.label,
    required this.glyph,
    required this.group,
    this.onSelected,
    this.trailing,
    this.closesMenu = true,
  });

  /// A stable name, such as `reload` or `share`.
  final String id;
  final String label;
  final AppIconGlyph glyph;
  final MenuGroup group;

  /// Null draws the item disabled.
  final VoidCallback? onSelected;

  /// A control at the end of the row, such as a switch.
  final Widget? trailing;

  /// False for items that change something in place (a switch).
  final bool closesMenu;
}

/// The browser menu: a quick row of icons, then grouped rows.
class BrowserMenuSheet extends StatelessWidget {
  const BrowserMenuSheet({super.key, required this.actions});

  final List<MenuAction> actions;

  List<MenuAction> _in(MenuGroup group) =>
      actions.where((MenuAction a) => a.group == group).toList();

  void _select(BuildContext context, MenuAction action) {
    if (action.closesMenu) {
      Navigator.of(context).pop();
    }
    action.onSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<MenuAction> quick = _in(MenuGroup.quick);
    final Map<MenuGroup, String> titles = <MenuGroup, String>{
      MenuGroup.page: l10n.menuGroupThisPage,
      MenuGroup.tabs: l10n.menuGroupTabs,
      MenuGroup.library: l10n.menuGroupLibrary,
      MenuGroup.app: l10n.menuGroupApp,
    };
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (quick.isNotEmpty)
            Padding(
              padding: AppInsets.symmetric(
                horizontal: Spacing.m,
                vertical: Spacing.s,
              ),
              child: Row(
                children: <Widget>[
                  for (final MenuAction a in quick)
                    Expanded(
                      child: _QuickTile(
                        action: a,
                        onTap: a.onSelected == null
                            ? null
                            : () => _select(context, a),
                      ),
                    ),
                ],
              ),
            ),
          for (final MapEntry<MenuGroup, String> group in titles.entries)
            if (_in(group.key).isNotEmpty) ...<Widget>[
              SectionHeader(group.value),
              for (final MenuAction a in _in(group.key))
                PremiumRow(
                  key: ValueKey<String>('menu-${a.id}'),
                  leading: a.glyph,
                  title: a.label,
                  trailing: a.trailing,
                  showChevron: false,
                  onTap: a.onSelected == null
                      ? null
                      : () => _select(context, a),
                ),
            ],
          const SizedBox(height: Spacing.s),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.action, required this.onTap});

  final MenuAction action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Pressable(
      key: ValueKey<String>('menu-${action.id}'),
      onTap: onTap,
      semanticLabel: action.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox.square(
            dimension: IconSizes.chipContainer,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.palette.bgSecondary,
                borderRadius: theme.radii.buttonRadius,
              ),
              child: Center(
                child: AppIcon(action.glyph, color: theme.palette.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.text.caption.copyWith(
              color: theme.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the browser menu above everything else.
Future<void> showBrowserMenu({
  required BuildContext context,
  required List<MenuAction> actions,
}) {
  return showPremiumBottomSheet<void>(
    context: context,
    builder: (BuildContext context) => BrowserMenuSheet(actions: actions),
  );
}
