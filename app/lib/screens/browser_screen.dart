import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/app_scope.dart';
import '../core/constants/route_names.dart';
import '../core/constants/spacing.dart';
import '../core/models/tab_model.dart';
import '../core/providers/tabs_provider.dart';
import '../core/theme/theme_builder.dart';
import '../l10n/l10n_extensions.dart';
import '../widgets/browser/address_bar.dart';
import '../widgets/browser/browser_menu_sheet.dart';
import '../widgets/browser/browser_nav_bar.dart';
import '../widgets/browser/page_progress_bar.dart';
import '../widgets/core/app_scaffold.dart';
import '../widgets/core/error_state.dart';
import '../widgets/icons/semantic_icons.dart';

/// The browser: the address bar and progress bar on top, the page in the
/// middle, the navigation bar below. Chrome is fixed; only the page moves.
class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key});

  List<MenuAction> _menuActions(
    BuildContext context,
    AppDependencies deps,
    TabModel tab,
    TabRuntime runtime,
  ) {
    final l10n = context.l10n;
    final bool hasPage = !tab.isBlank;
    return <MenuAction>[
      if (hasPage)
        MenuAction(
          id: runtime.isLoading ? 'stop' : 'reload',
          label: runtime.isLoading ? l10n.menuStop : l10n.menuReload,
          glyph: runtime.isLoading ? AppIcons.close : AppIcons.reload,
          group: MenuGroup.quick,
          onSelected: runtime.isLoading ? deps.tabs.stop : deps.tabs.reload,
        ),
      if (hasPage)
        MenuAction(
          id: 'share',
          label: l10n.menuShare,
          glyph: AppIcons.share,
          group: MenuGroup.quick,
          onSelected: () {
            final Uri? uri = Uri.tryParse(tab.url);
            if (uri != null) {
              unawaited(deps.share.shareUrl(uri, title: tab.title));
            }
          },
        ),
      if (hasPage)
        MenuAction(
          id: 'open-external',
          label: l10n.menuOpenInBrowser,
          glyph: AppIcons.openExternal,
          group: MenuGroup.page,
          onSelected: () {
            final Uri? uri = Uri.tryParse(tab.url);
            if (uri != null) {
              unawaited(deps.launcher.openInSystemBrowser(uri));
            }
          },
        ),
      MenuAction(
        id: 'settings',
        label: l10n.menuSettings,
        glyph: AppIcons.settings,
        group: MenuGroup.app,
        onSelected: () => unawaited(
          Navigator.of(context).pushNamed<void>(RouteNames.settings),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppDependencies deps = AppScope.of(context);
    return ValueListenableBuilder<TabsState>(
      valueListenable: deps.tabs,
      builder: (BuildContext context, TabsState state, Widget? _) {
        final TabModel tab = state.activeTab;
        final TabRuntime runtime = state.activeRuntime;
        return PopScope(
          // With history, Back goes back in the page; at the start of the
          // history it leaves the app.
          canPop: !runtime.canGoBack,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) {
              deps.tabs.goBack();
            }
          },
          child: AppScaffold(
            top: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: AppInsets.symmetric(
                    horizontal: Spacing.m,
                    vertical: Spacing.s,
                  ),
                  child: AddressBar(
                    url: tab.url,
                    onSubmitted: (String text) {
                      deps.tabs.navigate(text);
                    },
                  ),
                ),
                PageProgressBar(
                  progress: runtime.progress,
                  isLoading: runtime.isLoading,
                ),
              ],
            ),
            body: _PageArea(tab: tab, runtime: runtime, deps: deps),
            bottom: BrowserNavBar(
              canGoBack: runtime.canGoBack,
              canGoForward: runtime.canGoForward,
              isLoading: runtime.isLoading,
              onBack: deps.tabs.goBack,
              onForward: deps.tabs.goForward,
              onReload: deps.tabs.reload,
              onStop: deps.tabs.stop,
              onMenu: () => unawaited(
                showBrowserMenu(
                  context: context,
                  actions: _menuActions(context, deps, tab, runtime),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageArea extends StatelessWidget {
  const _PageArea({
    required this.tab,
    required this.runtime,
    required this.deps,
  });

  final TabModel tab;
  final TabRuntime runtime;
  final AppDependencies deps;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: tab.isBlank ? const _BlankPage() : deps.tabs.buildView(tab),
        ),
        if (runtime.error != null)
          Positioned.fill(
            child: ColoredBox(
              color: theme.palette.bgPrimary,
              child: ErrorState(
                error: runtime.error!,
                onRetry: deps.tabs.reload,
              ),
            ),
          ),
      ],
    );
  }
}

/// What an empty tab shows until the start page arrives with the tab
/// batch: the name, once.
class _BlankPage extends StatelessWidget {
  const _BlankPage();

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Center(
      child: Padding(
        padding: AppInsets.all(Spacing.l),
        child: Text(
          context.l10n.appName,
          textAlign: TextAlign.center,
          style: theme.text.display.copyWith(color: theme.palette.textPrimary),
        ),
      ),
    );
  }
}
