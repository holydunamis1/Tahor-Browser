import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tahorbrowser/core/models/tab_model.dart';
import 'package:tahorbrowser/core/providers/tabs_provider.dart';
import 'package:tahorbrowser/core/scripts/scroll_capture_script.dart';
import 'package:tahorbrowser/platform/platform_factory.dart';

import 'support/fixtures.dart';
import 'support/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FixtureServer server;
  late PlatformServices platform;

  setUpAll(() async {
    server = await FixtureServer.start();
    platform = await LiveApp.platformServices();
  });

  tearDownAll(() => server.close());

  setUp(() => LiveApp.resetStorage(platform));

  String titleOf(TabsProvider tabs, String id) =>
      tabs.value.tabs.firstWhere((TabModel t) => t.id == id).title ?? '';

  Future<double> scrollOf(PlatformServices p, String tabId) async =>
      ScrollScripts.parse(await p.engine.evaluate(tabId, ScrollScripts.read));

  testWidgets(
    'three tabs, scrolled, come back after a restart with their order, the '
    'showing tab and their scroll positions',
    (WidgetTester tester) async {
      final LiveApp app = await LiveApp.launch(tester, platform: platform);
      final TabsProvider tabs = app.deps.tabs;

      final String one = tabs.activeTab.id;
      tabs.navigate(server.uri('/tall1').toString());
      await pumpUntil(
        tester,
        () => titleOf(tabs, one) == 'Tall 1',
        what: 'the first page to load',
      );
      final String two = tabs.openTab(url: server.uri('/tall2'))!;
      await pumpUntil(
        tester,
        () => titleOf(tabs, two) == 'Tall 2',
        what: 'the second page to load',
      );
      final String three = tabs.openTab(url: server.uri('/tall3'))!;
      await pumpUntil(
        tester,
        () => titleOf(tabs, three) == 'Tall 3',
        what: 'the third page to load',
      );

      // All three views are live (the limit is three), so each can be scrolled.
      for (final MapEntry<String, int> e in <String, int>{
        one: 300,
        two: 600,
        three: 900,
      }.entries) {
        await platform.engine.evaluate(e.key, 'window.scrollTo(0, ${e.value})');
      }
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(await scrollOf(platform, two), closeTo(600, 40));

      // Show the second tab, then leave the app.
      tabs.selectTab(two);
      await pumpFor(tester, const Duration(milliseconds: 500));
      await app.goToBackground();
      await app.shutDown(tester);

      // A new start of the app over the same saved data.
      final LiveApp again = await LiveApp.launch(tester, platform: platform);
      final TabsProvider restored = again.deps.tabs;

      expect(restored.value.tabs.map((TabModel t) => t.id), <String>[
        one,
        two,
        three,
      ]);
      expect(restored.activeTab.id, two);
      // Only the showing tab has a view until another is selected.
      expect(restored.value.live, <String>[two]);

      await pumpUntil(
        tester,
        () => titleOf(restored, two) == 'Tall 2',
        what: 'the showing tab to load again',
      );
      await pumpUntil(
        tester,
        () => platform.engine.isLive(two),
        what: 'the showing tab to have a view',
      );
      await pumpFor(tester, const Duration(seconds: 2));
      expect(await scrollOf(platform, two), closeTo(600, 80));

      // Selecting another tab wakes it from its saved state.
      restored.selectTab(one);
      await pumpUntil(
        tester,
        () => restored.value.isLive(one) && platform.engine.isLive(one),
        what: 'the first tab to wake',
      );
      await pumpUntil(
        tester,
        () => titleOf(restored, one) == 'Tall 1',
        what: 'the first tab to show its page',
      );
      await pumpFor(tester, const Duration(seconds: 2));
      expect(await scrollOf(platform, one), closeTo(300, 80));

      await again.shutDown(tester);
    },
  );
}
