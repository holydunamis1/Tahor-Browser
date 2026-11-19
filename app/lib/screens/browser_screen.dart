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
import '../widgets/browser/new_tab_page.dart';
import '../widgets/browser/page_progress_bar.dart';
import '../widgets/browser/tab_count_button.dart';
import '../widgets/core/app_scaffold.dart';
import '../widgets/core/clipboard_action.dart';
import '../widgets/core/error_state.dart';
import '../widgets/core/persistence_warning_banner.dart';
import '../widgets/icons/semantic_icons.dart';

/// The browser: the address bar and progress bar on top, the page in the
/// middle, the navigation bar below. Chrome is fixed; only the page moves.
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  /// The address bar's focus, so the start page's search field can open it.
  final FocusNode _addressFocus = FocusNode(debugLabel: 'address-bar');

  @override
  void dispose() {
    _addressFocus.dispose();
    super.dispose();
  }

  /// Opens the tab list with a fresh preview of the page showing.
  Future<void> _openTabs(AppDependencies deps) async {
    await deps.tabLifecycle.captureActiveThumbnail();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushNamed<void>(RouteNames.tabs);
  }

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
          id: 'copy-link',
          label: l10n.menuCopyLink,
          glyph: AppIcons.copy,
          group: MenuGroup.page,
          onSelected: () => unawaited(_copyLink(deps, tab.url)),
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
        id: 'new-tab',
        label: l10n.menuNewTab,
        glyph: AppIcons.add,
        group: MenuGroup.tabs,
        onSelected: deps.tabs.openTab,
      ),
      if (deps.tabs.canReopenClosed)
        MenuAction(
          id: 'reopen-tab',
          label: l10n.menuReopenTab,
          glyph: AppIcons.history,
          group: MenuGroup.tabs,
          onSelected: deps.tabs.reopenClosedTab,
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

  Future<void> _copyLink(AppDependencies deps, String url) async {
    // Read before the await: the context may not be usable afterwards.
    final l10n = context.l10n;
    final bool copied = await copyToClipboard(url);
    deps.feedback.show(
      copied ? l10n.feedbackLinkCopied : l10n.feedbackCopyFailed,
      isError: !copied,
    );
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
                    focusNode: _addressFocus,
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
                PersistenceWarningBanner(guard: deps.persistenceGuard),
              ],
            ),
            body: _PageArea(
              state: state,
              tab: tab,
              runtime: runtime,
              deps: deps,
              onSearchTap: _addressFocus.requestFocus,
            ),
            bottom: BrowserNavBar(
              tabsButton: TabCountButton(
                count: state.tabs.length,
                onTap: () => unawaited(_openTabs(deps)),
              ),
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
    required this.state,
    required this.tab,
    required this.runtime,
    required this.deps,
    required this.onSearchTap,
  });

  final VoidCallback onSearchTap;
  final TabsState state;
  final TabModel tab;
  final TabRuntime runtime;
  final AppDependencies deps;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    // Every live tab keeps its view mounted, so switching tabs keeps each
    // page's history and scroll. Hibernated tabs have no view at all; the
    // showing one is woken by the lifecycle service, which restores its state
    // before the view is built. Until then the page area is plain.
    return Stack(
      children: <Widget>[
        Positioned.fill(child: ColoredBox(color: theme.palette.bgPrimary)),
        for (final TabModel t in state.tabs)
          if (state.isLive(t.id) && !t.isBlank)
            Positioned.fill(
              key: ValueKey<String>('page-${t.id}'),
              child: Offstage(
                offstage: t.id != tab.id,
                child: TickerMode(
                  enabled: t.id == tab.id,
                  child: deps.tabs.buildView(t),
                ),
              ),
            ),
        if (tab.isBlank)
          Positioned.fill(child: NewTabPage(onSearchTap: onSearchTap)),
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
