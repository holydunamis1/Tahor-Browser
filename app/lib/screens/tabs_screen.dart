import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../core/app_scope.dart';
import '../core/constants/spacing.dart';
import '../core/models/tab_model.dart';
import '../core/providers/tabs_provider.dart';
import '../l10n/l10n_extensions.dart';
import '../widgets/browser/tab_card.dart';
import '../widgets/core/app_scaffold.dart';
import '../widgets/core/icon_chip.dart';
import '../widgets/core/premium_card.dart';
import '../widgets/core/premium_dialog.dart';
import '../widgets/core/primary_button.dart';
import '../widgets/core/screen_nav_bar.dart';
import '../widgets/icons/semantic_icons.dart';

/// Every open tab as a card in a grid. Tapping one shows it; New tab opens an
/// empty one; Close all asks first; Reopen brings back the tab closed last.
class TabsScreen extends StatelessWidget {
  const TabsScreen({super.key});

  Future<void> _closeAll(BuildContext context, AppDependencies deps) async {
    final l10n = context.l10n;
    final bool confirmed = await showConfirmDialog(
      context: context,
      title: l10n.tabsCloseAllTitle,
      message: l10n.tabsCloseAllBody,
      confirmLabel: l10n.tabsCloseAll,
      cancelLabel: l10n.dialogCancel,
      destructive: true,
    );
    if (confirmed) {
      deps.tabs.closeAllTabs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppDependencies deps = AppScope.of(context);
    final l10n = context.l10n;
    return ValueListenableBuilder<TabsState>(
      valueListenable: deps.tabs,
      builder: (BuildContext context, TabsState state, Widget? _) {
        return AppScaffold(
          top: ScreenNavBar(
            title: l10n.tabsTitle,
            onBack: () => Navigator.of(context).pop(),
            actions: <Widget>[
              IconChip(
                glyph: AppIcons.delete,
                semanticLabel: l10n.tabsCloseAll,
                onTap: () => unawaited(_closeAll(context, deps)),
              ),
            ],
          ),
          body: GridView.builder(
            padding: AppInsets.all(Spacing.m),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: Spacing.m,
              crossAxisSpacing: Spacing.m,
              childAspectRatio: 0.78,
            ),
            itemCount: state.tabs.length,
            itemBuilder: (BuildContext context, int index) {
              final TabModel tab = state.tabs[index];
              return _TabCell(
                key: ValueKey<String>('tab-${tab.id}'),
                tab: tab,
                isActive: index == state.activeIndex,
                deps: deps,
              );
            },
          ),
          bottom: DecoratedBox(
            decoration: const BoxDecoration(),
            child: Padding(
              padding: AppInsets.all(Spacing.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (deps.tabs.canReopenClosed) ...<Widget>[
                    PremiumCard(
                      label: l10n.tabsReopen,
                      leading: AppIcons.history,
                      showChevron: false,
                      onTap: () {
                        if (deps.tabs.reopenClosedTab() != null) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(height: Spacing.s),
                  ],
                  PrimaryButton(
                    label: l10n.tabsNew,
                    glyph: AppIcons.add,
                    onPressed: () {
                      if (deps.tabs.openTab() != null) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One cell of the grid. It loads its own preview so a slow disk never delays
/// the grid.
class _TabCell extends StatefulWidget {
  const _TabCell({
    super.key,
    required this.tab,
    required this.isActive,
    required this.deps,
  });

  final TabModel tab;
  final bool isActive;
  final AppDependencies deps;

  @override
  State<_TabCell> createState() => _TabCellState();
}

class _TabCellState extends State<_TabCell> {
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_TabCell old) {
    super.didUpdateWidget(old);
    if (old.tab.url != widget.tab.url) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    Uint8List? bytes;
    try {
      bytes = await widget.deps.thumbnails.get(widget.tab.id);
    } on Exception {
      bytes = null;
    }
    if (mounted && bytes != null) {
      setState(() => _thumbnail = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TabsProvider tabs = widget.deps.tabs;
    return TabCard(
      tab: widget.tab,
      isActive: widget.isActive,
      thumbnail: _thumbnail,
      onTap: () {
        tabs.selectTab(widget.tab.id);
        Navigator.of(context).pop();
      },
      onClose: () => tabs.closeTab(widget.tab.id),
    );
  }
}
