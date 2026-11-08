import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/app_constants.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';
import 'package:tahorbrowser/core/models/tab_model.dart';
import 'package:tahorbrowser/core/providers/tabs_provider.dart';
import 'package:tahorbrowser/core/utils/url_utils.dart';

import 'support/fakes.dart';

void main() {
  late FakeBrowserEngine engine;
  late TabsProvider tabs;
  int counter = 0;

  setUp(() {
    counter = 0;
    engine = FakeBrowserEngine();
    tabs = TabsProvider(
      engine: engine,
      searchEngine: () => AppConstants.engineById('duckduckgo'),
      idGenerator: () => 't${counter++}',
    );
  });

  List<String> ids() => tabs.value.tabs.map((TabModel t) => t.id).toList();

  group('opening, selecting and closing', () {
    test('starts with one blank tab showing', () {
      expect(ids(), <String>['t0']);
      expect(tabs.value.activeIndex, 0);
      expect(tabs.activeTab.isBlank, isTrue);
    });

    test('openTab adds at the end and selects it', () {
      final String? id = tabs.openTab(url: Uri.parse('https://a.com'));
      expect(id, 't1');
      expect(ids(), <String>['t0', 't1']);
      expect(tabs.value.activeIndex, 1);
      expect(tabs.activeTab.url, 'https://a.com');
    });

    test('openTab can leave the showing tab alone', () {
      tabs.openTab(select: false);
      expect(tabs.value.activeIndex, 0);
      expect(ids().length, 2);
    });

    test('a private tab is marked private', () {
      tabs.openTab(isIncognito: true);
      expect(tabs.activeTab.isIncognito, isTrue);
    });

    test('no more tabs open past the limit', () {
      for (int i = 1; i < AppConstants.maxTabs; i++) {
        expect(tabs.openTab(), isNotNull);
      }
      expect(tabs.value.tabs.length, AppConstants.maxTabs);
      expect(tabs.openTab(), isNull);
      expect(tabs.value.tabs.length, AppConstants.maxTabs);
    });

    test('selectTab shows that tab, and ignores unknown ids', () {
      tabs.openTab();
      tabs.openTab();
      tabs.selectTab('t0');
      expect(tabs.value.activeIndex, 0);
      tabs.selectTab('nope');
      expect(tabs.value.activeIndex, 0);
    });

    test('selecting the showing tab does not notify', () {
      int heard = 0;
      tabs.addListener(() => heard++);
      tabs.selectTab('t0');
      expect(heard, 0);
    });

    group('closing', () {
      setUp(() {
        tabs.openTab(); // t1
        tabs.openTab(); // t2
        tabs.openTab(); // t3
      });

      test('closing the showing tab in the middle shows the one that takes its place', () {
        tabs.selectTab('t1');
        tabs.closeTab('t1');
        expect(ids(), <String>['t0', 't2', 't3']);
        expect(tabs.activeTab.id, 't2');
      });

      test('closing the showing last tab shows the new last one', () {
        tabs.closeTab('t3');
        expect(ids(), <String>['t0', 't1', 't2']);
        expect(tabs.activeTab.id, 't2');
      });

      test(
        'closing a tab before the showing one keeps the same tab showing',
        () {
          expect(tabs.activeTab.id, 't3');
          tabs.closeTab('t0');
          expect(tabs.activeTab.id, 't3');
          expect(tabs.value.activeIndex, 2);
        },
      );

      test(
        'closing a tab after the showing one keeps the same tab showing',
        () {
          tabs.selectTab('t1');
          tabs.closeTab('t3');
          expect(tabs.activeTab.id, 't1');
        },
      );

      test('closing the first showing tab shows the next', () {
        tabs.selectTab('t0');
        tabs.closeTab('t0');
        expect(tabs.activeTab.id, 't1');
        expect(tabs.value.activeIndex, 0);
      });

      test('an unknown id is ignored', () {
        tabs.closeTab('nope');
        expect(ids().length, 4);
        expect(
          engine.calls.where((String c) => c.startsWith('dispose')),
          isEmpty,
        );
      });

      test('the engine releases the closed tab', () {
        tabs.closeTab('t2');
        expect(engine.calls, contains('dispose t2'));
      });

      test('closing every tab leaves one new blank tab', () {
        for (final String id in ids()) {
          tabs.closeTab(id);
        }
        expect(tabs.value.tabs.length, 1);
        expect(tabs.activeTab.isBlank, isTrue);
        expect(tabs.activeTab.id, 't4');
        expect(tabs.value.activeIndex, 0);
      });

      test('closing the only tab replaces it with a blank one', () {
        final TabsProvider solo = TabsProvider(
          engine: engine,
          searchEngine: () => AppConstants.engineById('duckduckgo'),
          idGenerator: () => 's${counter++}',
        );
        final String first = solo.activeTab.id;
        solo.closeTab(first);
        expect(solo.value.tabs.length, 1);
        expect(solo.activeTab.id, isNot(first));
      });

      test('closing forgets the tab\'s runtime state', () {
        tabs.handleEvent(const ProgressChanged('t2', 0.4));
        expect(tabs.value.runtime.containsKey('t2'), isTrue);
        tabs.closeTab('t2');
        expect(tabs.value.runtime.containsKey('t2'), isFalse);
      });
    });
  });

  group('navigate', () {
    test('an address on a blank tab sets the tab address for its web view', () {
      final ResolvedInput r = tabs.navigate('example.com');
      expect(r.kind, InputKind.navigation);
      expect(tabs.activeTab.url, 'https://example.com');
      expect(engine.calls, isEmpty);
    });

    test('text on a blank tab becomes a search address', () {
      tabs.navigate('hello world');
      expect(tabs.activeTab.url, 'https://duckduckgo.com/?q=hello+world');
    });

    test('on a tab with a page, the engine loads it', () {
      tabs.navigate('example.com');
      tabs.navigate('other.org/page');
      expect(engine.calls, <String>['load t0 https://other.org/page']);
    });

    test('a refused address changes nothing', () {
      final ResolvedInput r = tabs.navigate('javascript:alert(1)');
      expect(r.kind, InputKind.refused);
      expect(tabs.activeTab.isBlank, isTrue);
      expect(engine.calls, isEmpty);
    });

    test('the chosen search engine is used', () {
      final TabsProvider bing = TabsProvider(
        engine: engine,
        searchEngine: () => AppConstants.engineById('bing'),
      );
      bing.navigate('cats');
      expect(bing.activeTab.url, 'https://www.bing.com/search?q=cats');
    });
  });

  group('commands go to the showing tab', () {
    test('back, forward, reload and stop', () {
      tabs.openTab();
      tabs.goBack();
      tabs.goForward();
      tabs.reload();
      tabs.stop();
      expect(engine.calls, <String>[
        'back t1',
        'forward t1',
        'reload t1',
        'stop t1',
      ]);
    });
  });

  group('events', () {
    final Uri page = Uri.parse('https://example.com/page');

    test('starting a load sets the address and clears the last error', () {
      tabs.handleEvent(const ErrorOccurred('t0', WebViewError.loadFailed()));
      expect(tabs.value.runtimeOf('t0').error, isNotNull);
      tabs.handleEvent(PageStarted('t0', page));
      expect(tabs.activeTab.url, 'https://example.com/page');
      final TabRuntime r = tabs.value.runtimeOf('t0');
      expect(r.isLoading, isTrue);
      expect(r.progress, 0);
      expect(r.error, isNull);
    });

    test('progress is kept between zero and one', () {
      tabs.handleEvent(const ProgressChanged('t0', 0.5));
      expect(tabs.value.runtimeOf('t0').progress, 0.5);
      tabs.handleEvent(const ProgressChanged('t0', 7));
      expect(tabs.value.runtimeOf('t0').progress, 1);
      tabs.handleEvent(const ProgressChanged('t0', -1));
      expect(tabs.value.runtimeOf('t0').progress, 0);
    });

    test('finishing a load ends loading', () {
      tabs.handleEvent(PageStarted('t0', page));
      tabs.handleEvent(PageFinished('t0', page));
      final TabRuntime r = tabs.value.runtimeOf('t0');
      expect(r.isLoading, isFalse);
      expect(r.progress, 1);
    });

    test('title and icon are stored and can be cleared', () {
      tabs.handleEvent(const TitleChanged('t0', 'Example'));
      tabs.handleEvent(const FaviconChanged('t0', 'https://example.com/i.png'));
      expect(tabs.activeTab.title, 'Example');
      expect(tabs.activeTab.faviconUrl, 'https://example.com/i.png');
      tabs.handleEvent(const TitleChanged('t0', null));
      expect(tabs.activeTab.title, isNull);
    });

    test('navigation state sets the buttons and the address when given', () {
      tabs.handleEvent(
        NavigationStateChanged(
          't0',
          canGoBack: true,
          canGoForward: false,
          url: page,
        ),
      );
      expect(tabs.value.runtimeOf('t0').canGoBack, isTrue);
      expect(tabs.value.runtimeOf('t0').canGoForward, isFalse);
      expect(tabs.activeTab.url, 'https://example.com/page');
      tabs.handleEvent(
        const NavigationStateChanged(
          't0',
          canGoBack: false,
          canGoForward: true,
        ),
      );
      expect(tabs.activeTab.url, 'https://example.com/page');
      expect(tabs.value.runtimeOf('t0').canGoForward, isTrue);
    });

    test('a main-frame error is kept and stops loading', () {
      tabs.handleEvent(PageStarted('t0', page));
      tabs.handleEvent(const ErrorOccurred('t0', NetworkError.offline()));
      final TabRuntime r = tabs.value.runtimeOf('t0');
      expect(r.isLoading, isFalse);
      expect(r.error!.code, 'network.offline');
    });

    test('an error in a sub-frame is ignored', () {
      tabs.handleEvent(
        const ErrorOccurred(
          't0',
          WebViewError.loadFailed(),
          isMainFrame: false,
        ),
      );
      expect(tabs.value.runtimeOf('t0').error, isNull);
    });

    test('events for a tab that does not exist are ignored', () {
      int heard = 0;
      tabs.addListener(() => heard++);
      tabs.handleEvent(const TitleChanged('ghost', 'x'));
      tabs.handleEvent(const ProgressChanged('ghost', 0.5));
      expect(heard, 0);
      expect(tabs.value.runtime, isEmpty);
    });

    test('an event that changes nothing does not notify', () {
      tabs.handleEvent(const TitleChanged('t0', 'Same'));
      int heard = 0;
      tabs.addListener(() => heard++);
      tabs.handleEvent(const TitleChanged('t0', 'Same'));
      expect(heard, 0);
    });

    test('one event is one notification', () {
      int heard = 0;
      tabs.addListener(() => heard++);
      tabs.handleEvent(PageStarted('t0', page));
      expect(heard, 1);
    });

    test('events change only their own tab', () {
      tabs.openTab();
      tabs.handleEvent(const TitleChanged('t1', 'Second'));
      expect(tabs.value.tabs[0].title, isNull);
      expect(tabs.value.tabs[1].title, 'Second');
    });
  });

  group('web views', () {
    test('a blank tab builds with no address', () {
      expect(tabs.configFor(tabs.activeTab).initialUrl, isNull);
    });

    test('a tab with a page builds with it, and keeps privacy and mode', () {
      tabs.openTab(url: Uri.parse('https://a.com/x'), isIncognito: true);
      final TabViewConfig c = tabs.configFor(tabs.activeTab);
      expect(c.tabId, 't1');
      expect(c.initialUrl, Uri.parse('https://a.com/x'));
      expect(c.isIncognito, isTrue);
    });

    test('buildView asks the engine and wires events back', () {
      tabs.openTab(url: Uri.parse('https://a.com'));
      final Widget view = tabs.buildView(tabs.activeTab);
      expect(view.key, const ValueKey<String>('view-t1'));
      expect(engine.builtConfigs.single.tabId, 't1');
      engine.lastSink!(const TitleChanged('t1', 'Heard'));
      expect(tabs.activeTab.title, 'Heard');
    });
  });

  group('state', () {
    test('states compare by content', () {
      final TabsState a = TabsState(
        tabs: const <TabModel>[TabModel(id: 'x')],
        activeIndex: 0,
        runtime: const <String, TabRuntime>{'x': TabRuntime(progress: 0.5)},
      );
      final TabsState b = TabsState(
        tabs: const <TabModel>[TabModel(id: 'x')],
        activeIndex: 0,
        runtime: const <String, TabRuntime>{'x': TabRuntime(progress: 0.5)},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(TabsState(tabs: a.tabs, activeIndex: 0)));
    });

    test('runtime copyWith can clear the error', () {
      const TabRuntime r = TabRuntime(error: NetworkError.offline());
      expect(r.copyWith(error: null).error, isNull);
      expect(r.copyWith(progress: 0.2).error, isNotNull);
    });

    test('an unknown tab has a default runtime', () {
      expect(tabs.value.runtimeOf('zzz'), const TabRuntime());
    });
  });
}
