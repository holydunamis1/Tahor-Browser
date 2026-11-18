import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/app_constants.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/models/session_snapshot.dart';
import 'package:tahorbrowser/core/models/tab_model.dart';
import 'package:tahorbrowser/core/providers/tabs_provider.dart';
import 'package:tahorbrowser/core/services/session_restore_service.dart';
import 'package:tahorbrowser/core/services/tab_lifecycle_service.dart';
import 'package:tahorbrowser/core/services/thumbnail_cache.dart';
import 'package:tahorbrowser/core/storage/persistence_guard.dart';
import 'package:tahorbrowser/core/storage/storage_keys.dart';
import 'package:tahorbrowser/core/storage/webview_state_store.dart';

import 'support/fakes.dart';

/// Counts how often the tab list is written.
class CountingStore extends FakeKeyValueStore {
  int writes = 0;
  bool failWrites = false;

  @override
  Future<void> setJson(String key, Map<String, Object?> value) async {
    if (failWrites) {
      throw StateError('disk full');
    }
    if (key == StorageKeys.sessionSnapshot) {
      writes++;
    }
    await super.setJson(key, value);
  }
}

void main() {
  late FakeBrowserEngine engine;
  late CountingStore store;
  late PersistenceGuard guard;
  late TabsProvider tabs;
  late TabLifecycleService lifecycle;
  late SessionRestoreService service;
  int counter = 0;

  const Duration quiet = Duration(milliseconds: 20);
  Future<void> waitForDebounce() =>
      Future<void>.delayed(const Duration(milliseconds: 80));

  Map<String, Object?> saved() =>
      jsonDecode(store.data[StorageKeys.sessionSnapshot]! as String)
          as Map<String, Object?>;

  setUp(() {
    counter = 0;
    engine = FakeBrowserEngine();
    store = CountingStore();
    guard = PersistenceGuard();
    final FakeFileStore files = FakeFileStore();
    tabs = TabsProvider(
      engine: engine,
      searchEngine: () => AppConstants.engineById('duckduckgo'),
      idGenerator: () => 't${counter++}',
    );
    lifecycle = TabLifecycleService(
      tabs: tabs,
      engine: engine,
      states: WebViewStateStore(files),
      thumbnails: ThumbnailCache(files),
      guard: guard,
    );
    service = SessionRestoreService(
      tabs: tabs,
      store: store,
      lifecycle: lifecycle,
      guard: guard,
      clock: () => DateTime.utc(2026, 11, 18),
      delay: quiet,
    );
  });

  tearDown(() {
    service.dispose();
    lifecycle.dispose();
  });

  group('restoring', () {
    test('with nothing saved nothing changes', () async {
      expect(await service.restore(), isFalse);
      expect(tabs.value.tabs.length, 1);
      expect(tabs.activeTab.isBlank, isTrue);
    });

    test('saved tabs come back in order with the same one showing', () async {
      final SessionSnapshot snapshot = SessionSnapshot.capture(
        tabs: const <TabModel>[
          TabModel(id: 'a', url: 'https://a.example', scrollY: 40),
          TabModel(id: 'b', url: 'https://b.example', stateKey: 'b'),
          TabModel(id: 'c', url: 'https://c.example'),
        ],
        activeTabId: 'b',
        savedAt: DateTime.utc(2026, 11, 17),
      );
      store.data[StorageKeys.sessionSnapshot] = jsonEncode(snapshot.toJson());

      expect(await service.restore(), isTrue);

      expect(tabs.value.tabs.map((TabModel t) => t.id), <String>[
        'a',
        'b',
        'c',
      ]);
      expect(tabs.activeTab.id, 'b');
      // Only the showing tab gets a web view; the others wake when selected.
      expect(tabs.value.live, <String>['b']);
    });

    test('unreadable data is ignored', () async {
      store.data[StorageKeys.sessionSnapshot] = '{not json';
      expect(await service.restore(), isFalse);
      store.data[StorageKeys.sessionSnapshot] = jsonEncode(<String, Object?>{
        'v': 99,
        'tabs': <Object?>[],
      });
      expect(await service.restore(), isFalse);
      expect(tabs.value.tabs.length, 1);
    });

    test('a snapshot with no tabs is not restored', () async {
      store.data[StorageKeys.sessionSnapshot] = jsonEncode(
        SessionSnapshot.capture(
          tabs: const <TabModel>[],
          activeTabId: null,
          savedAt: DateTime.utc(2026),
        ).toJson(),
      );
      expect(await service.restore(), isFalse);
    });

    test('restored tabs are not written straight back', () async {
      store.data[StorageKeys.sessionSnapshot] = jsonEncode(
        SessionSnapshot.capture(
          tabs: const <TabModel>[TabModel(id: 'a', url: 'https://a.example')],
          activeTabId: 'a',
          savedAt: DateTime.utc(2026, 11, 17),
        ).toJson(),
      );
      await service.restore();
      service.start();
      tabs.handleEvent(ProgressChanged('a', 0.5));
      await waitForDebounce();
      expect(store.writes, 0);
    });
  });

  group('saving', () {
    test('a change is saved after a quiet moment, once', () async {
      service.start();
      tabs.navigate('example.com');
      tabs.openTab(url: Uri.parse('https://b.example'));
      tabs.openTab(url: Uri.parse('https://c.example'));
      await waitForDebounce();
      expect(store.writes, 1);
      final List<Object?> savedTabs = saved()['tabs']! as List<Object?>;
      expect(savedTabs.length, 3);
      expect(saved()['active'], 2);
    });

    test('private tabs are never written', () async {
      service.start();
      tabs.navigate('example.com');
      tabs.openTab(url: Uri.parse('https://p.example'), isIncognito: true);
      await waitForDebounce();
      final List<Object?> savedTabs = saved()['tabs']! as List<Object?>;
      expect(savedTabs.length, 1);
      expect(jsonEncode(saved()), isNot(contains('p.example')));
    });

    test('a change that is not about the tab list is not written', () async {
      service.start();
      tabs.navigate('example.com');
      await waitForDebounce();
      final int before = store.writes;
      tabs.handleEvent(ProgressChanged('t0', 0.4));
      tabs.handleEvent(ProgressChanged('t0', 0.9));
      await waitForDebounce();
      expect(store.writes, before);
    });

    test(
      'flush saves the state of the open pages and the list at once',
      () async {
        engine.states['t0'] = Uint8List.fromList(<int>[1, 2]);
        engine.evaluated['t0'] = 77;
        service.start();
        tabs.navigate('example.com');

        await service.flush();

        expect(engine.calls, contains('saveState t0'));
        expect(saved()['tabs'], isNotEmpty);
        final Map<String, Object?> first =
            (saved()['tabs']! as List<Object?>).first! as Map<String, Object?>;
        expect(first['scrollY'], 77);
        expect(first['stateKey'], 't0');
      },
    );

    test('a failing store flags the problem and does not throw', () async {
      store.failWrites = true;
      service.start();
      tabs.navigate('example.com');
      await waitForDebounce();
      expect(guard.failedAreas.value, contains('tabs'));
    });

    test('after a failed write the next change is tried again', () async {
      store.failWrites = true;
      service.start();
      tabs.navigate('example.com');
      await waitForDebounce();
      store.failWrites = false;
      tabs.openTab(url: Uri.parse('https://b.example'));
      await waitForDebounce();
      expect(store.writes, 1);
    });

    test('disposing stops saving', () async {
      service.start();
      service.dispose();
      tabs.navigate('example.com');
      await waitForDebounce();
      expect(store.writes, 0);
    });
  });
}
