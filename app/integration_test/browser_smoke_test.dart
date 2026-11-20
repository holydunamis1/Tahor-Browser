import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tahorbrowser/core/models/tab_model.dart';
import 'package:tahorbrowser/core/providers/tabs_provider.dart';
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

  testWidgets('a page loads, shows its title, and Back and Forward work', (
    WidgetTester tester,
  ) async {
    final LiveApp app = await LiveApp.launch(tester, platform: platform);
    final TabsProvider tabs = app.deps.tabs;

    tabs.navigate(server.uri('/a').toString());
    await pumpUntil(
      tester,
      () => tabs.activeTab.title == 'Page A',
      what: 'Page A to load',
    );

    tabs.navigate(server.uri('/b').toString());
    await pumpUntil(
      tester,
      () => tabs.activeTab.title == 'Page B',
      what: 'Page B to load',
    );
    expect(tabs.value.activeRuntime.canGoBack, isTrue);

    tabs.goBack();
    await pumpUntil(
      tester,
      () => tabs.activeTab.title == 'Page A',
      what: 'Back to Page A',
    );
    expect(tabs.value.activeRuntime.canGoForward, isTrue);

    tabs.goForward();
    await pumpUntil(
      tester,
      () => tabs.activeTab.title == 'Page B',
      what: 'Forward to Page B',
    );

    await app.shutDown(tester);
  });

  testWidgets('tabs open, switch and close, each keeping its own page', (
    WidgetTester tester,
  ) async {
    final LiveApp app = await LiveApp.launch(tester, platform: platform);
    final TabsProvider tabs = app.deps.tabs;
    final String first = tabs.activeTab.id;

    tabs.navigate(server.uri('/a').toString());
    await pumpUntil(
      tester,
      () => titleOf(tabs, first) == 'Page A',
      what: 'Page A to load',
    );

    final String second = tabs.openTab(url: server.uri('/b'))!;
    await pumpUntil(
      tester,
      () => titleOf(tabs, second) == 'Page B',
      what: 'Page B to load in a second tab',
    );
    expect(tabs.value.tabs.length, 2);

    tabs.selectTab(first);
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(tabs.activeTab.id, first);
    expect(titleOf(tabs, first), 'Page A');
    expect(titleOf(tabs, second), 'Page B');

    tabs.closeTab(second);
    await pumpFor(tester, const Duration(milliseconds: 500));
    expect(tabs.value.tabs.length, 1);
    expect(tabs.canReopenClosed, isTrue);

    final String? back = tabs.reopenClosedTab();
    expect(back, second);
    await pumpUntil(
      tester,
      () => titleOf(tabs, second) == 'Page B',
      what: 'the reopened tab to load again',
    );

    await app.shutDown(tester);
  });
}
