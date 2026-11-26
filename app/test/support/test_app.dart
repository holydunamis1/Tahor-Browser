import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/app/app_shell.dart';
import 'package:tahorbrowser/app/bootstrap.dart';
import 'package:tahorbrowser/core/app_scope.dart';
import 'package:tahorbrowser/core/error/global_error_handler.dart';
import 'package:tahorbrowser/platform/platform_factory.dart';

import 'blocklist_support.dart';
import 'fakes.dart';

/// The real app built over fakes.
class TestApp {
  TestApp._(
    this.deps,
    this.engine,
    this.launcher,
    this.share,
    this.store,
    this.http,
  );

  final AppDependencies deps;
  final FakeBrowserEngine engine;
  final FakeLauncher launcher;
  final FakeShare share;
  final FakeKeyValueStore store;
  final FakeHttpClient http;

  Widget get widget => AppScope(dependencies: deps, child: const AppShell());

  /// Builds the app's dependencies over fakes and shows the app.
  static Future<TestApp> pump(
    WidgetTester tester, {
    FakeKeyValueStore? store,
  }) async {
    final FakeBrowserEngine engine = FakeBrowserEngine();
    final FakeLauncher launcher = FakeLauncher();
    final FakeShare share = FakeShare();
    final FakeHttpClient http = FakeHttpClient();
    final FakeKeyValueStore keyValues = store ?? FakeKeyValueStore();
    final Future<Uint8List> Function(String) assets = (await tester.runAsync(
      tinyBlocklistAssets,
    ))!;
    final AppDependencies deps = (await tester.runAsync(
      () => bootstrap(
        errorHandler: GlobalErrorHandler(),
        loadAssetBytes: assets,
        platform: PlatformServices(
          engine: engine,
          launcher: launcher,
          share: share,
          keyValueStore: keyValues,
          localDatabase: FakeLocalDatabase(),
          fileStore: FakeFileStore(),
          httpClient: http,
          appInfo: FakeAppInfo(),
        ),
      ),
    ))!;
    final TestApp app = TestApp._(
      deps,
      engine,
      launcher,
      share,
      keyValues,
      http,
    );
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    return app;
  }
}

/// A widget test for the whole app. The app is unmounted at the end, which
/// gives back the global error screen the shell replaced; Flutter checks that
/// before teardown callbacks run.
void appTest(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (WidgetTester tester) async {
    try {
      await body(tester);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
