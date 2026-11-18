import 'dart:async';
import 'dart:convert';

import '../contracts/key_value_store.dart';
import '../models/session_snapshot.dart';
import '../providers/tabs_provider.dart';
import '../storage/persistence_guard.dart';
import '../storage/storage_keys.dart';
import '../utils/debouncer.dart';
import 'tab_lifecycle_service.dart';

/// Saves the open tabs as they change and brings them back at the next start.
///
/// The saved list is written half a second after the last change, and at once
/// when the app goes to the background (where the system may end the process).
/// Private tabs are never saved. Only the showing tab gets a web view at
/// start-up; the others load when selected.
class SessionRestoreService {
  SessionRestoreService({
    required this._tabs,
    required this._store,
    required this._lifecycle,
    required this._guard,
    DateTime Function()? clock,
    Duration delay = const Duration(milliseconds: 500),
  }) : _clock = clock ?? DateTime.now,
       _debouncer = Debouncer(delay);

  final TabsProvider _tabs;
  final KeyValueStore _store;
  final TabLifecycleService _lifecycle;
  final PersistenceGuard _guard;
  final DateTime Function() _clock;
  final Debouncer _debouncer;

  bool _started = false;
  Map<String, Object?>? _lastWritten;

  /// Reads the saved tabs and opens them. Returns true when tabs were
  /// restored. Call before [start] so the restore is not saved straight back.
  Future<bool> restore() async {
    final Map<String, Object?>? json = await _guard.run<Map<String, Object?>?>(
      'tabs',
      () => _store.getJson(StorageKeys.sessionSnapshot),
      fallback: () => null,
    );
    final SessionSnapshot? snapshot = SessionSnapshot.tryFromJson(json);
    if (snapshot == null || snapshot.isEmpty) {
      return false;
    }
    _tabs.restore(snapshot);
    _lastWritten = _content(snapshot);
    return true;
  }

  /// Starts saving changes. Calling it twice does nothing.
  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _tabs.addListener(_onChange);
  }

  void _onChange() => _debouncer.run(() => unawaited(_write()));

  /// Saves each live tab's state and scroll position, then the tab list, now.
  Future<void> flush() async {
    _debouncer.cancel();
    await _lifecycle.saveLiveTabs();
    await _write();
  }

  Future<void> _write() async {
    final TabsState state = _tabs.value;
    final SessionSnapshot snapshot = SessionSnapshot.capture(
      tabs: state.tabs,
      activeTabId: state.activeTab.id,
      savedAt: _clock(),
    );
    final Map<String, Object?> content = _content(snapshot);
    if (_mapsEqual(content, _lastWritten)) {
      return;
    }
    final bool saved = await _guard.run<bool>(
      'tabs',
      () async {
        await _store.setJson(StorageKeys.sessionSnapshot, snapshot.toJson());
        return true;
      },
      fallback: () => false,
      write: true,
    );
    if (saved) {
      _lastWritten = content;
    }
  }

  /// What a snapshot says, without the time it was taken, so an unchanged tab
  /// list is not written again.
  static Map<String, Object?> _content(SessionSnapshot snapshot) {
    final Map<String, Object?> json = snapshot.toJson()..remove('savedAt');
    return json;
  }

  static bool _mapsEqual(Map<String, Object?> a, Map<String, Object?>? b) =>
      b != null && _encode(a) == _encode(b);

  static String _encode(Map<String, Object?> value) => jsonEncode(value);

  void dispose() {
    _debouncer.cancel();
    if (_started) {
      _tabs.removeListener(_onChange);
      _started = false;
    }
  }
}
