import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../core/app_scope.dart';
import '../core/blocklist/blocklist_service.dart';
import '../core/blocklist/blocklist_verifier.dart';
import '../core/constants/app_constants.dart';
import '../core/error/error_taxonomy.dart';
import '../core/models/app_settings.dart';
import '../core/error/global_error_handler.dart';
import '../core/providers/adblock_provider.dart';
import '../core/providers/feature_flags_provider.dart';
import '../core/providers/feedback_provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/site_settings_provider.dart';
import '../core/providers/tabs_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/services/session_restore_service.dart';
import '../core/services/settings_service.dart';
import '../core/services/site_settings_service.dart';
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
  Future<Uint8List> Function(String assetPath)? loadAssetBytes,
}) async {
  final Future<Uint8List> Function(String) assets =
      loadAssetBytes ??
      (String path) async => (await rootBundle.load(path)).buffer.asUint8List();
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

  final ThumbnailCache thumbnails = ThumbnailCache(services.fileStore);
  // The database is opened here, by the first feature that needs it. If it
  // cannot be opened the guard records it and site settings stay in memory.
  await guard.run<void>(
    'database',
    () => services.localDatabase.open(DatabaseMigrations.app.toSchema()),
    fallback: () {},
  );
  final SiteSettingsService siteService = SiteSettingsService(
    services.localDatabase,
    guard,
  );
  await siteService.load();
  final SiteSettingsProvider siteSettings = SiteSettingsProvider(
    service: siteService,
    tabs: tabs,
  );

  final Uint8List publicKey = base64Decode(
    utf8.decode(await assets('assets/blocklist/update_public_key.txt')).trim(),
  );
  final BlocklistService blocklist = BlocklistService(
    http: services.httpClient,
    files: services.fileStore,
    verifier: BlocklistVerifier(publicKey),
    loadAssetBytes: assets,
    appVersion: services.appInfo.version,
  );
  final FeatureFlagsProvider featureFlags = FeatureFlagsProvider(blocklist);
  final AdblockProvider adblock = AdblockProvider(
    blocklist: blocklist,
    settings: settings,
    sites: siteSettings,
    flags: featureFlags,
    store: services.keyValueStore,
  );
  // The blocklist loads in the background so the first screen is not delayed;
  // the weekly check follows when the person has turned it on.
  unawaited(blocklist.initialize().then((_) => adblock.autoRefreshIfDue()));

  final TabLifecycleService lifecycle = TabLifecycleService(
    tabs: tabs,
    engine: services.engine,
    states: WebViewStateStore(services.fileStore),
    thumbnails: thumbnails,
    guard: guard,
  );
  final SessionRestoreService sessionRestore = SessionRestoreService(
    tabs: tabs,
    store: services.keyValueStore,
    lifecycle: lifecycle,
    guard: guard,
  );
  // Restore before saving starts, so the restored tabs are not written back.
  if (settings.value.startupMode == StartupMode.continueSession) {
    await sessionRestore.restore();
  }
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
    thumbnails: thumbnails,
    feedback: FeedbackProvider(),
    blocklist: blocklist,
    siteSettings: siteSettings,
    featureFlags: featureFlags,
    adblock: adblock,
  );
}
