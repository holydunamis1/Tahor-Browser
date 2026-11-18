import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/app_constants.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/models/tab_model.dart';
import 'package:tahorbrowser/core/providers/tabs_provider.dart';
import 'package:tahorbrowser/core/services/tab_lifecycle_service.dart';
import 'package:tahorbrowser/core/services/thumbnail_cache.dart';
import 'package:tahorbrowser/core/storage/persistence_guard.dart';
import 'package:tahorbrowser/core/storage/storage_keys.dart';
import 'package:tahorbrowser/core/storage/webview_state_store.dart';

import 'support/fakes.dart';

void main() {
  late FakeBrowserEngine engine;
  late FakeFileStore files;
  late WebViewStateStore states;
  late ThumbnailCache thumbnails;
  late PersistenceGuard guard;
  late TabsProvider tabs;
  late TabLifecycleService service;
  int counter = 0;

  Uint8List bytes(int v) => Uint8List.fromList(<int>[v, v, v]);

  TabLifecycleService make({int maxLive = 2}) => TabLifecycleService(
    tabs: tabs,
    engine: engine,
    states: states,
    thumbnails: thumbnails,
    guard: guard,
    maxLive: maxLive,
  );

  setUp(() {
    counter = 0;
    engine = FakeBrowserEngine();
    files = FakeFileStore();
    states = WebViewStateStore(files);
    thumbnails = ThumbnailCache(files);
    guard = PersistenceGuard();
    tabs = TabsProvider(
      engine: engine,
      searchEngine: () => AppConstants.engineById('duckduckgo'),
      idGenerator: () => 't${counter++}',
    );
    service = make();
    // t0 is the first tab and shows a page, like a real session.
    tabs.navigate('example.com');
    engine.states['t0'] = bytes(10);
    engine.evaluated['t0'] = 250;
    engine.thumbnails['t0'] = bytes(99);
  });

  tearDown(() => service.dispose());

  TabModel tab(String id) =>
      tabs.value.tabs.firstWhere((TabModel t) => t.id == id);

  test('starting with the limit not exceeded releases nothing', () async {
    service.start();
    await pumpEventQueue();
    expect(tabs.value.live, <String>['t0']);
    expect(engine.calls.where((String c) => c.startsWith('dispose')), isEmpty);
  });

  test('a third live tab hibernates the least recently used one', () async {
    service.start();
    tabs.openTab(url: Uri.parse('https://b.example'));
    tabs.openTab(url: Uri.parse('https://c.example'));
    await pumpEventQueue();

    expect(tabs.value.live, <String>['t1', 't2']);
    expect(engine.calls, contains('dispose t0'));
    // Its state, scroll position and preview were saved before it went.
    expect(await states.get('t0'), bytes(10));
    expect(tab('t0').scrollY, 250);
    expect(tab('t0').stateKey, 't0');
    expect(await thumbnails.get('t0'), bytes(99));
  });

  test('the showing tab is never hibernated', () async {
    final TabLifecycleService one = make(maxLive: 1);
    one.start();
    tabs.openTab(url: Uri.parse('https://b.example'));
    await pumpEventQueue();
    expect(tabs.value.live, <String>['t1']);
    expect(tabs.activeTab.id, 't1');
    one.dispose();
  });

  test('selecting a hibernated tab wakes it with its saved state', () async {
    service.start();
    tabs.openTab(url: Uri.parse('https://b.example'));
    tabs.openTab(url: Uri.parse('https://c.example'));
    await pumpEventQueue();

    tabs.selectTab('t0');
    await pumpEventQueue();

    expect(tabs.value.isLive('t0'), isTrue);
    expect(tabs.configFor(tab('t0')).restoredState, bytes(10));
    // Waking one tab hibernated the next least recently used.
    expect(tabs.value.live.length, 2);
    expect(tabs.value.isLive('t0'), isTrue);
  });

  test(
    'a woken tab with no saved state reloads its address and scroll',
    () async {
      engine.states.remove('t0');
      service.start();
      tabs.openTab(url: Uri.parse('https://b.example'));
      tabs.openTab(url: Uri.parse('https://c.example'));
      await pumpEventQueue();
      expect(tab('t0').stateKey, isNull);

      tabs.selectTab('t0');
      await pumpEventQueue();

      final TabViewConfig config = tabs.configFor(tab('t0'));
      expect(config.restoredState, isNull);
      expect(config.initialUrl, Uri.parse(tab('t0').url));
      expect(config.initialUrl, isNotNull);
      expect(config.restoreScrollY, 250);
    },
  );

  test(
    'a plugin that fails to save still lets the tab go, and flags it',
    () async {
      engine.failSaveState = true;
      service.start();
      tabs.openTab(url: Uri.parse('https://b.example'));
      tabs.openTab(url: Uri.parse('https://c.example'));
      await pumpEventQueue();

      expect(tabs.value.live, <String>['t1', 't2']);
      expect(tab('t0').stateKey, isNull);
      expect(guard.failedAreas.value, contains('tab state'));
    },
  );

  test(
    'a state too large for the store is dropped but the tab is released',
    () async {
      states = WebViewStateStore(files, maxBlobBytes: 2, maxTotalBytes: 10);
      service = make();
      service.start();
      tabs.openTab(url: Uri.parse('https://b.example'));
      tabs.openTab(url: Uri.parse('https://c.example'));
      await pumpEventQueue();

      expect(tabs.value.isLive('t0'), isFalse);
      expect(tab('t0').stateKey, isNull);
      expect(files.data[StorageKeys.webViewStateNamespace], isNull);
    },
  );

  test('a private tab is released without saving anything', () async {
    service.start();
    final String? secret = tabs.openTab(
      url: Uri.parse('https://p.example'),
      isIncognito: true,
    );
    tabs.openTab(url: Uri.parse('https://c.example'));
    tabs.selectTab('t0');
    await pumpEventQueue();
    tabs.openTab(url: Uri.parse('https://d.example'));
    await pumpEventQueue();

    expect(engine.calls, isNot(contains('saveState $secret')));
    expect(
      files.data[StorageKeys.webViewStateNamespace]?.containsKey(secret),
      isNot(true),
    );
  });

  test('a blank tab is released without saving anything', () async {
    service.start();
    tabs.openTab(); // t1, blank
    tabs.openTab(url: Uri.parse('https://c.example'));
    await pumpEventQueue();
    expect(engine.calls, isNot(contains('saveState t1')));
  });

  test('saveLiveTabs saves every live page and releases nothing', () async {
    engine.states['t1'] = bytes(11);
    service.start();
    tabs.openTab(url: Uri.parse('https://b.example'));
    await pumpEventQueue();

    await service.saveLiveTabs();

    expect(engine.calls, containsAll(<String>['saveState t0', 'saveState t1']));
    expect(await states.get('t0'), bytes(10));
    expect(await states.get('t1'), bytes(11));
    expect(tabs.value.live, <String>['t0', 't1']);
    expect(engine.calls.where((String c) => c.startsWith('dispose')), isEmpty);
  });

  test('after dispose the service no longer reacts to changes', () async {
    service.start();
    service.dispose();
    tabs.openTab(url: Uri.parse('https://b.example'));
    tabs.openTab(url: Uri.parse('https://c.example'));
    await pumpEventQueue();
    expect(tabs.value.live.length, 3);
  });

  test('starting twice does not double the work', () async {
    service.start();
    service.start();
    tabs.openTab(url: Uri.parse('https://b.example'));
    tabs.openTab(url: Uri.parse('https://c.example'));
    await pumpEventQueue();
    expect(engine.calls.where((String c) => c == 'saveState t0').length, 1);
  });
}
