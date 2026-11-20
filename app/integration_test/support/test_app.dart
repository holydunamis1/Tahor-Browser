import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/app/app_shell.dart';
import 'package:tahorbrowser/app/bootstrap.dart';
import 'package:tahorbrowser/core/app_scope.dart';
import 'package:tahorbrowser/core/error/global_error_handler.dart';
import 'package:tahorbrowser/core/storage/storage_keys.dart';
import 'package:tahorbrowser/platform/platform_factory.dart';
import 'package:tahorbrowser/platform/platform_info.dart';

/// The real app, with the real web view engine and the real stores of the
/// device. A test starts it, drives it, and can stop it and start it again to
/// act out a restart.
class LiveApp {
  LiveApp._(this.deps, this.platform);

  final AppDependencies deps;
  final PlatformServices platform;

  static Future<PlatformServices> platformServices() =>
      createPlatformServices(PlatformInfo.current());

  /// Removes everything the app saved, so each test starts from a clean
  /// install.
  static Future<void> resetStorage(PlatformServices platform) async {
    for (final String key in <String>[
      StorageKeys.sessionSnapshot,
      StorageKeys.settings,
      StorageKeys.keyValueSchemaVersion,
    ]) {
      await platform.keyValueStore.remove(key);
    }
    for (final String namespace in <String>[
      StorageKeys.webViewStateNamespace,
      StorageKeys.webViewStateIndexNamespace,
      StorageKeys.thumbnailNamespace,
    ]) {
      await platform.fileStore.clear(namespace);
    }
  }

  /// Builds the app from [platform] and shows it.
  static Future<LiveApp> launch(
    WidgetTester tester, {
    required PlatformServices platform,
  }) async {
    final AppDependencies deps = await bootstrap(
      errorHandler: GlobalErrorHandler(),
      platform: platform,
    );
    await tester.pumpWidget(
      AppScope(dependencies: deps, child: const AppShell()),
    );
    await pumpFor(tester, const Duration(milliseconds: 500));
    return LiveApp._(deps, platform);
  }

  /// What the app does when it leaves the screen: it saves every open page and
  /// the tab list at once.
  Future<void> goToBackground() => deps.sessionRestore.flush();

  /// Removes the app from the screen, as when its process ends.
  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFor(tester, const Duration(milliseconds: 200));
  }
}

/// Lets the app run for [duration] of real time. `pumpAndSettle` is not used:
/// a loading page never stops asking for frames.
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  final DateTime end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Runs the app until [condition] holds. Fails, naming [what], when it does not
/// within [timeout].
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String what,
  Duration timeout = const Duration(seconds: 45),
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw TestFailure('Timed out after $timeout waiting for $what.');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
