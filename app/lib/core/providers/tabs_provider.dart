import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import '../contracts/browser_engine.dart';
import '../error/error_taxonomy.dart';
import '../models/session_snapshot.dart';
import '../models/tab_model.dart';
import '../utils/url_utils.dart';

const Object _keep = Object();

/// What is happening in a tab right now. It is not saved.
@immutable
class TabRuntime {
  const TabRuntime({
    this.progress = 0,
    this.isLoading = false,
    this.canGoBack = false,
    this.canGoForward = false,
    this.error,
  });

  /// Load progress from 0 to 1.
  final double progress;
  final bool isLoading;
  final bool canGoBack;
  final bool canGoForward;

  /// The error that stopped the page from loading, if any.
  final AppError? error;

  TabRuntime copyWith({
    double? progress,
    bool? isLoading,
    bool? canGoBack,
    bool? canGoForward,
    Object? error = _keep,
  }) {
    return TabRuntime(
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      error: identical(error, _keep) ? this.error : error as AppError?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TabRuntime &&
      other.progress == progress &&
      other.isLoading == isLoading &&
      other.canGoBack == canGoBack &&
      other.canGoForward == canGoForward &&
      other.error == error;

  @override
  int get hashCode =>
      Object.hash(progress, isLoading, canGoBack, canGoForward, error);
}

/// The open tabs, which one is showing, and what each is doing.
@immutable
class TabsState {
  const TabsState({
    required this.tabs,
    required this.activeIndex,
    this.runtime = const <String, TabRuntime>{},
    this.live = const <String>[],
  });

  final List<TabModel> tabs;
  final int activeIndex;
  final Map<String, TabRuntime> runtime;

  /// The tabs that have a web view right now, least recently used first. The
  /// rest are hibernated: saved to disk and released.
  final List<String> live;

  bool isLive(String tabId) => live.contains(tabId);

  TabsState copyWith({
    List<TabModel>? tabs,
    int? activeIndex,
    Map<String, TabRuntime>? runtime,
    List<String>? live,
  }) => TabsState(
    tabs: tabs ?? this.tabs,
    activeIndex: activeIndex ?? this.activeIndex,
    runtime: runtime ?? this.runtime,
    live: live ?? this.live,
  );

  TabModel get activeTab => tabs[activeIndex];

  TabRuntime runtimeOf(String tabId) => runtime[tabId] ?? const TabRuntime();

  TabRuntime get activeRuntime => runtimeOf(activeTab.id);

  @override
  bool operator ==(Object other) =>
      other is TabsState &&
      other.activeIndex == activeIndex &&
      listEquals(other.tabs, tabs) &&
      listEquals(other.live, live) &&
      mapEquals(other.runtime, runtime);

  @override
  int get hashCode => Object.hash(
    activeIndex,
    Object.hashAll(tabs),
    Object.hashAll(live),
    Object.hashAll(runtime.entries.map((e) => Object.hash(e.key, e.value))),
  );
}

typedef TabIdGenerator = String Function();

/// Owns the tab list and the active index. The engine owns the live web
/// views and reports what happens in them as events, which this consumes.
/// There is always at least one tab.
class TabsProvider extends ValueNotifier<TabsState> {
  TabsProvider({
    required this._engine,
    required this._searchEngine,
    TabIdGenerator? idGenerator,
  }) : _newId = idGenerator ?? _sequentialIds(),
       super(const TabsState(tabs: <TabModel>[], activeIndex: 0)) {
    final TabModel first = TabModel(id: _newId());
    value = TabsState(
      tabs: <TabModel>[first],
      activeIndex: 0,
      live: <String>[first.id],
    );
  }

  final BrowserEngine _engine;
  final SearchEngine Function() _searchEngine;
  final TabIdGenerator _newId;

  /// Tabs closed this session, newest last, for Reopen closed tab. Private
  /// tabs are never kept.
  final List<TabModel> _closed = <TabModel>[];

  /// How many closed tabs are remembered.
  static const int closedTabLimit = 10;

  bool get canReopenClosed => _closed.isNotEmpty;

  /// Saved state waiting for a tab's view to be built; each is used once.
  final Map<String, Uint8List> _pendingRestore = <String, Uint8List>{};

  static TabIdGenerator _sequentialIds() {
    final String base = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    int next = 0;
    return () => '$base-${next++}';
  }

  TabModel get activeTab => value.activeTab;

  /// Opens a tab and returns its id, or null when [AppConstants.maxTabs] tabs
  /// are already open.
  String? openTab({Uri? url, bool isIncognito = false, bool select = true}) {
    if (value.tabs.length >= AppConstants.maxTabs) {
      return null;
    }
    final TabModel tab = TabModel(
      id: _newId(),
      url: url?.toString() ?? '',
      isIncognito: isIncognito,
    );
    final List<TabModel> tabs = <TabModel>[...value.tabs, tab];
    value = value.copyWith(
      tabs: tabs,
      activeIndex: select ? tabs.length - 1 : value.activeIndex,
      live: <String>[...value.live, tab.id],
    );
    return tab.id;
  }

  /// Closes a tab. Closing the last one leaves a new blank tab. Closing the
  /// showing tab shows the one that takes its place.
  void closeTab(String id) {
    final int index = value.tabs.indexWhere((TabModel t) => t.id == id);
    if (index < 0) {
      return;
    }
    unawaited(_engine.dispose(id));
    _pendingRestore.remove(id);
    _remember(value.tabs[index]);
    final List<String> live = <String>[...value.live]..remove(id);
    final List<TabModel> tabs = <TabModel>[...value.tabs]..removeAt(index);
    final Map<String, TabRuntime> runtime = <String, TabRuntime>{
      ...value.runtime,
    }..remove(id);
    if (tabs.isEmpty) {
      final TabModel fresh = TabModel(id: _newId());
      value = TabsState(
        tabs: <TabModel>[fresh],
        activeIndex: 0,
        runtime: runtime,
        live: <String>[fresh.id],
      );
      return;
    }
    int active = value.activeIndex;
    if (index < active) {
      active -= 1;
    } else if (index == active) {
      active = math.min(active, tabs.length - 1);
    }
    value = TabsState(
      tabs: tabs,
      activeIndex: active,
      runtime: runtime,
      live: live,
    );
  }

  void _remember(TabModel tab) {
    if (tab.isIncognito || tab.isBlank) {
      return;
    }
    _closed.add(tab);
    while (_closed.length > closedTabLimit) {
      _closed.removeAt(0);
    }
  }

  /// Closes every tab and leaves one new blank tab. The tabs closed are
  /// remembered for [reopenClosedTab], newest last.
  void closeAllTabs() {
    for (final TabModel tab in value.tabs) {
      unawaited(_engine.dispose(tab.id));
      _remember(tab);
    }
    _pendingRestore.clear();
    final TabModel fresh = TabModel(id: _newId());
    value = TabsState(
      tabs: <TabModel>[fresh],
      activeIndex: 0,
      live: <String>[fresh.id],
    );
  }

  /// Brings back the tab closed last and shows it. Returns its id, or null when
  /// there is none or [AppConstants.maxTabs] tabs are open.
  String? reopenClosedTab() {
    if (_closed.isEmpty || value.tabs.length >= AppConstants.maxTabs) {
      return null;
    }
    final TabModel tab = _closed.removeLast();
    // A tab that is the only blank one is replaced, so reopening after Close
    // all does not leave an empty tab behind.
    final bool replaceBlank =
        value.tabs.length == 1 && value.tabs.first.isBlank;
    final List<TabModel> tabs = replaceBlank
        ? <TabModel>[tab]
        : <TabModel>[...value.tabs, tab];
    if (replaceBlank) {
      unawaited(_engine.dispose(value.tabs.first.id));
    }
    value = TabsState(
      tabs: tabs,
      activeIndex: tabs.length - 1,
      runtime: replaceBlank ? const <String, TabRuntime>{} : value.runtime,
      live: <String>[if (!replaceBlank) ...value.live, tab.id],
    );
    return tab.id;
  }

  void selectTab(String id) {
    final int index = value.tabs.indexWhere((TabModel t) => t.id == id);
    if (index < 0 || index == value.activeIndex) {
      return;
    }
    final String chosen = value.tabs[index].id;
    value = value.copyWith(
      activeIndex: index,
      // A tab that is already live becomes the most recently used. A
      // hibernated one is woken by the lifecycle service, which then calls
      // [markLive], so its view is never built without its saved state.
      live: value.isLive(chosen)
          ? <String>[...value.live.where((String t) => t != chosen), chosen]
          : value.live,
    );
  }

  /// Opens what was typed in the showing tab: a page, or a search. Returns
  /// the decision so the caller can explain a refusal.
  ResolvedInput navigate(String text) {
    final ResolvedInput resolved = resolveInput(text, _searchEngine());
    final Uri? uri = resolved.uri;
    if (resolved.kind == InputKind.refused || uri == null) {
      return resolved;
    }
    final TabModel tab = value.activeTab;
    if (tab.isBlank) {
      // No web view exists yet; it is built with this address.
      _apply(tab.id, tab: (TabModel t) => t.copyWith(url: uri.toString()));
    } else {
      unawaited(_engine.load(tab.id, uri));
    }
    return resolved;
  }

  void goBack() => unawaited(_engine.goBack(value.activeTab.id));
  void goForward() => unawaited(_engine.goForward(value.activeTab.id));
  void reload() => unawaited(_engine.reload(value.activeTab.id));
  void stop() => unawaited(_engine.stop(value.activeTab.id));

  /// What a tab's web view is created from. Saved state given to [markLive]
  /// stays available until the view reports its first event, so a build that
  /// is thrown away before the view exists cannot lose it.
  TabViewConfig configFor(TabModel tab) {
    return TabViewConfig(
      tabId: tab.id,
      initialUrl: tab.isBlank ? null : Uri.tryParse(tab.url),
      isIncognito: tab.isIncognito,
      viewMode: tab.viewMode,
      restoredState: _pendingRestore[tab.id],
      restoreScrollY: tab.scrollY,
    );
  }

  /// Gives a tab a web view, optionally restored from [restoredState]. Ignored
  /// for unknown tabs.
  void markLive(String tabId, {Uint8List? restoredState}) {
    if (!value.tabs.any((TabModel t) => t.id == tabId)) {
      return;
    }
    if (restoredState != null) {
      _pendingRestore[tabId] = restoredState;
    }
    if (value.isLive(tabId)) {
      return;
    }
    value = value.copyWith(live: <String>[...value.live, tabId]);
  }

  /// Releases a tab's view; its saved state stays on disk. The showing tab
  /// cannot be hibernated.
  void markHibernated(String tabId) {
    if (!value.isLive(tabId) || value.activeTab.id == tabId) {
      return;
    }
    _pendingRestore.remove(tabId);
    value = value.copyWith(live: <String>[...value.live]..remove(tabId));
  }

  /// Records where a tab was scrolled to, and the key of its saved state.
  void recordSaved(String tabId, {double? scrollY, String? stateKey}) {
    _apply(
      tabId,
      tab: (TabModel t) =>
          t.copyWith(scrollY: scrollY, stateKey: stateKey ?? t.stateKey),
    );
  }

  /// Replaces every tab with the ones in [snapshot]. Only the showing tab gets
  /// a view; the rest wake when selected. An empty snapshot changes nothing.
  void restore(SessionSnapshot snapshot) {
    if (snapshot.isEmpty) {
      return;
    }
    for (final TabModel old in value.tabs) {
      unawaited(_engine.dispose(old.id));
    }
    _pendingRestore.clear();
    final List<TabModel> tabs = snapshot.tabs.length > AppConstants.maxTabs
        ? snapshot.tabs.sublist(0, AppConstants.maxTabs)
        : snapshot.tabs;
    final int active = math.min(snapshot.activeIndex, tabs.length - 1);
    value = TabsState(
      tabs: tabs,
      activeIndex: active,
      live: <String>[tabs[active].id],
    );
  }

  /// The widget that shows [tab], reporting back to this provider.
  Widget buildView(TabModel tab) =>
      _engine.buildTab(configFor(tab), handleEvent);

  /// Applies something that happened in a tab. Unknown tabs are ignored.
  void handleEvent(TabEvent event) {
    // The view exists, so it has used any saved state it was given.
    _pendingRestore.remove(event.tabId);
    switch (event) {
      case PageStarted(:final Uri url):
        _apply(
          event.tabId,
          tab: (TabModel t) => t.copyWith(url: url.toString()),
          runtime: (TabRuntime r) =>
              r.copyWith(isLoading: true, progress: 0, error: null),
        );
      case ProgressChanged(:final double progress):
        _apply(
          event.tabId,
          runtime: (TabRuntime r) =>
              r.copyWith(progress: progress.clamp(0.0, 1.0).toDouble()),
        );
      case PageFinished(:final Uri url):
        _apply(
          event.tabId,
          tab: (TabModel t) => t.copyWith(url: url.toString()),
          runtime: (TabRuntime r) => r.copyWith(isLoading: false, progress: 1),
        );
      case TitleChanged(:final String? title):
        _apply(event.tabId, tab: (TabModel t) => t.copyWith(title: title));
      case FaviconChanged(:final String? faviconUrl):
        _apply(
          event.tabId,
          tab: (TabModel t) => t.copyWith(faviconUrl: faviconUrl),
        );
      case NavigationStateChanged(
        :final bool canGoBack,
        :final bool canGoForward,
        :final Uri? url,
      ):
        _apply(
          event.tabId,
          tab: url == null
              ? null
              : (TabModel t) => t.copyWith(url: url.toString()),
          runtime: (TabRuntime r) =>
              r.copyWith(canGoBack: canGoBack, canGoForward: canGoForward),
        );
      case ErrorOccurred(:final AppError error, :final bool isMainFrame):
        if (isMainFrame) {
          _apply(
            event.tabId,
            runtime: (TabRuntime r) =>
                r.copyWith(isLoading: false, error: error),
          );
        }
    }
  }

  /// Changes one tab and its runtime state in a single notification.
  void _apply(
    String tabId, {
    TabModel Function(TabModel)? tab,
    TabRuntime Function(TabRuntime)? runtime,
  }) {
    final int index = value.tabs.indexWhere((TabModel t) => t.id == tabId);
    if (index < 0) {
      return;
    }
    List<TabModel> tabs = value.tabs;
    if (tab != null) {
      final TabModel changed = tab(value.tabs[index]);
      if (changed != value.tabs[index]) {
        tabs = <TabModel>[...value.tabs]..[index] = changed;
      }
    }
    Map<String, TabRuntime> states = value.runtime;
    if (runtime != null) {
      final TabRuntime before = value.runtimeOf(tabId);
      final TabRuntime after = runtime(before);
      if (after != before) {
        states = <String, TabRuntime>{...value.runtime, tabId: after};
      }
    }
    if (identical(tabs, value.tabs) && identical(states, value.runtime)) {
      return;
    }
    value = value.copyWith(tabs: tabs, runtime: states);
  }
}
