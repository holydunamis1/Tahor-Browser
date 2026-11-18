import 'dart:async';
import 'dart:typed_data';

import '../contracts/browser_engine.dart';
import '../models/tab_model.dart';
import '../providers/tabs_provider.dart';
import '../scripts/scroll_capture_script.dart';
import '../storage/persistence_guard.dart';
import '../storage/webview_state_store.dart';
import 'thumbnail_cache.dart';

/// Keeps at most [maxLive] web views alive. The least recently used tab that
/// is not showing is hibernated: its state, scroll position and a preview are
/// saved, and its view is released. A hibernated tab is woken when selected,
/// with its saved state, so its history is back exactly as it was.
class TabLifecycleService {
  TabLifecycleService({
    required this._tabs,
    required this._engine,
    required this._states,
    required this._thumbnails,
    required this._guard,
    this.maxLive = defaultMaxLive,
  }) : assert(maxLive >= 1, 'The showing tab must always be live.');

  static const int defaultMaxLive = 3;

  final TabsProvider _tabs;
  final BrowserEngine _engine;
  final WebViewStateStore _states;
  final ThumbnailCache _thumbnails;
  final PersistenceGuard _guard;
  final int maxLive;

  bool _started = false;
  bool _working = false;
  bool _again = false;

  /// Starts reacting to tab changes. Calling it twice does nothing.
  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _tabs.addListener(_onChange);
    _onChange();
  }

  void dispose() {
    if (_started) {
      _tabs.removeListener(_onChange);
      _started = false;
    }
  }

  void _onChange() {
    if (_working) {
      _again = true;
      return;
    }
    unawaited(_settle());
  }

  /// Wakes the showing tab if it is hibernated, then hibernates tabs until no
  /// more than [maxLive] are live. Changes that arrive meanwhile run once more.
  Future<void> _settle() async {
    _working = true;
    try {
      do {
        _again = false;
        await _wakeActive();
        await _enforceLimit();
      } while (_again);
    } finally {
      _working = false;
    }
  }

  Future<void> _wakeActive() async {
    final TabsState state = _tabs.value;
    final TabModel tab = state.activeTab;
    if (state.isLive(tab.id)) {
      return;
    }
    final Uint8List? saved = tab.isBlank
        ? null
        : await _guard.run<Uint8List?>(
            'tab state',
            () => _states.get(tab.stateKey ?? tab.id),
            fallback: () => null,
          );
    _tabs.markLive(tab.id, restoredState: saved);
  }

  Future<void> _enforceLimit() async {
    while (_tabs.value.live.length > maxLive) {
      final TabsState state = _tabs.value;
      String? victim;
      for (final String id in state.live) {
        if (id != state.activeTab.id) {
          victim = id;
          break;
        }
      }
      if (victim == null) {
        return;
      }
      await hibernate(victim);
      if (_tabs.value.isLive(victim)) {
        // It could not be hibernated; stop rather than loop forever.
        return;
      }
    }
  }

  /// Saves a tab's state, scroll position and preview, then releases its view.
  /// A tab whose state cannot be saved is still released: it reloads its
  /// address when woken, which is better than keeping too many views.
  Future<void> hibernate(String tabId) async {
    final TabsState state = _tabs.value;
    if (state.activeTab.id == tabId || !state.isLive(tabId)) {
      return;
    }
    final TabModel tab = state.tabs.firstWhere((TabModel t) => t.id == tabId);
    if (!tab.isBlank && !tab.isIncognito) {
      await _saveTab(tab);
      final Uint8List? thumb = await _engine.takeThumbnail(tabId);
      if (thumb != null) {
        await _guard.run<void>(
          'thumbnails',
          () => _thumbnails.put(tabId, thumb),
          fallback: () {},
          write: true,
        );
      }
    }
    _tabs.markHibernated(tabId);
    await _engine.dispose(tabId);
  }

  /// Saves a live tab's web view state and scroll position and records them
  /// on the tab. Returns true when the state itself was saved.
  Future<bool> _saveTab(TabModel tab) async {
    final Uint8List? bytes = await _guard.run<Uint8List?>(
      'tab state',
      () async {
        final Uint8List? saved = await _engine.saveState(tab.id);
        if (saved != null && await _states.put(tab.id, saved)) {
          return saved;
        }
        return null;
      },
      fallback: () => null,
      write: true,
    );
    final double scroll = ScrollScripts.parse(
      await _engine.evaluate(tab.id, ScrollScripts.read),
    );
    _tabs.recordSaved(
      tab.id,
      scrollY: scroll,
      stateKey: bytes == null ? null : tab.id,
    );
    return bytes != null;
  }

  /// Saves the state of every live tab that can be saved, without releasing
  /// anything. Called when the app goes to the background, because the system
  /// may end the process there.
  Future<void> saveLiveTabs() async {
    for (final String id in List<String>.of(_tabs.value.live)) {
      for (final TabModel tab in _tabs.value.tabs) {
        if (tab.id == id && !tab.isBlank && !tab.isIncognito) {
          await _saveTab(tab);
        }
      }
    }
  }
}
