import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/app/bootstrap.dart';
import 'package:tahorbrowser/core/app_scope.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/error/global_error_handler.dart';
import 'package:tahorbrowser/core/models/app_settings.dart';
import 'package:tahorbrowser/core/services/settings_service.dart';
import 'package:tahorbrowser/platform/platform_factory.dart';

import 'support/fakes.dart';

void main() {
  PlatformServices services(
    FakeBrowserEngine engine,
    FakeKeyValueStore store,
  ) => PlatformServices(
    engine: engine,
    launcher: FakeLauncher(),
    share: FakeShare(),
    keyValueStore: store,
    appInfo: FakeAppInfo(),
  );

  test('builds the dependencies over the platform services', () async {
    final FakeBrowserEngine engine = FakeBrowserEngine();
    final GlobalErrorHandler handler = GlobalErrorHandler();
    final AppDependencies deps = await bootstrap(
      errorHandler: handler,
      platform: services(engine, FakeKeyValueStore()),
    );
    expect(deps.errorHandler, same(handler));
    expect(deps.appInfo.version, '0.1.0');
    expect(deps.tabs.value.tabs.length, 1);
    expect(deps.tabs.activeTab.isBlank, isTrue);
    expect(deps.settings.value, const AppSettings());
  });

  test('installs the navigation policy on the engine', () async {
    final FakeBrowserEngine engine = FakeBrowserEngine();
    await bootstrap(
      errorHandler: GlobalErrorHandler(),
      platform: services(engine, FakeKeyValueStore()),
    );
    expect(engine.policy, isNotNull);
    expect(
      engine.policy!(
        NavigationRequest(
          tabId: 't',
          uri: Uri.parse('https://a.com'),
          isMainFrame: true,
        ),
      ),
      isA<AllowNavigation>(),
    );
    expect(
      engine.policy!(
        NavigationRequest(
          tabId: 't',
          uri: Uri.parse('file:///x'),
          isMainFrame: true,
        ),
      ),
      isA<BlockNavigation>(),
    );
  });

  test('loads the saved settings before anything is built', () async {
    final FakeKeyValueStore store = FakeKeyValueStore(<String, Object>{
      SettingsService.storageKey: jsonEncode(<String, Object?>{
        'v': 1,
        'themeMode': 'dark',
        'searchEngineId': 'ecosia',
        'localeCode': 'de',
      }),
    });
    final AppDependencies deps = await bootstrap(
      errorHandler: GlobalErrorHandler(),
      platform: services(FakeBrowserEngine(), store),
    );
    expect(deps.settings.value.themeMode, AppThemeMode.dark);
    expect(deps.theme.mode, AppThemeMode.dark);
    expect(deps.locale.locale!.languageCode, 'de');
    expect(
      deps.tabs.navigate('cats').uri.toString(),
      'https://www.ecosia.org/search?q=cats',
    );
  });

  test('a failing store still starts the app on defaults', () async {
    final FakeKeyValueStore store = FakeKeyValueStore()..failed = true;
    final AppDependencies deps = await bootstrap(
      errorHandler: GlobalErrorHandler(),
      platform: services(FakeBrowserEngine(), store),
    );
    expect(deps.settings.value, const AppSettings());
    expect(deps.settings.persistenceFailed.value, isTrue);
  });
}
