import '../core/app_scope.dart';
import '../core/constants/app_constants.dart';
import '../core/error/error_taxonomy.dart';
import '../core/error/global_error_handler.dart';
import '../core/providers/locale_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/tabs_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/services/session_restore_service.dart';
import '../core/services/settings_service.dart';
import '../core/services/tab_lifecycle_service.dart';
import '../core/services/thumbnail_cache.dart';
import '../core/services/url_policy_service.dart';
import '../core/storage/migrations.dart';
import '../core/storage/persistence_guard.dart';
import '../core/storage/webview_state_store.dart';
import '../platform/platform_factory.dart';
import '../platform/platform_info.dart';

/// Builds everything the app needs before the first frame. Tests pass their
/// own [platform] services.
Future<AppDependencies> bootstrap({
  required GlobalErrorHandler errorHandler,
  PlatformServices? platform,
}) async {
  final PlatformServices services =
      platform ?? await createPlatformServices(PlatformInfo.current());

  final PersistenceGuard guard = PersistenceGuard(
    onError: (AppError error) => errorHandler.report(error),
  );
  await guard.run<void>('settings', () async {
    await KeyValueMigrations.app.run(services.keyValueStore);
  }, fallback: () {});

  final SettingsProvider settings = SettingsProvider(
    service: SettingsService(services.keyValueStore),
  );
  await settings.load();

  final TabsProvider tabs = TabsProvider(
    engine: services.engine,
    searchEngine: () => AppConstants.engineById(settings.value.searchEngineId),
  );
  services.engine.setNavigationPolicy(const UrlPolicyService().decide);

  final TabLifecycleService lifecycle = TabLifecycleService(
    tabs: tabs,
    engine: services.engine,
    states: WebViewStateStore(services.fileStore),
    thumbnails: ThumbnailCache(services.fileStore),
    guard: guard,
  );
  final SessionRestoreService sessionRestore = SessionRestoreService(
    tabs: tabs,
    store: services.keyValueStore,
    lifecycle: lifecycle,
    guard: guard,
  );
  // Restore before saving starts, so the restored tabs are not written back.
  await sessionRestore.restore();
  lifecycle.start();
  sessionRestore.start();

  return AppDependencies(
    settings: settings,
    theme: ThemeProvider(settings),
    locale: LocaleProvider(settings),
    tabs: tabs,
    errorHandler: errorHandler,
    launcher: services.launcher,
    share: services.share,
    appInfo: services.appInfo,
    sessionRestore: sessionRestore,
    tabLifecycle: lifecycle,
    persistenceGuard: guard,
  );
}
