import 'package:flutter/widgets.dart';

import 'contracts/app_info.dart';
import 'contracts/external_launcher.dart';
import 'contracts/share.dart';
import 'error/global_error_handler.dart';
import 'blocklist/blocklist_service.dart';
import 'providers/adblock_provider.dart';
import 'providers/feature_flags_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/site_settings_provider.dart';
import 'providers/tabs_provider.dart';
import 'providers/theme_provider.dart';
import 'services/session_restore_service.dart';
import 'services/tab_lifecycle_service.dart';
import 'services/thumbnail_cache.dart';
import 'storage/persistence_guard.dart';

/// Everything the screens need, built once at start-up. It holds contracts
/// and providers only; the platform code that implements them is never
/// visible here.
class AppDependencies {
  const AppDependencies({
    required this.settings,
    required this.theme,
    required this.locale,
    required this.tabs,
    required this.errorHandler,
    required this.launcher,
    required this.share,
    required this.appInfo,
    required this.sessionRestore,
    required this.tabLifecycle,
    required this.persistenceGuard,
    required this.thumbnails,
    required this.feedback,
    required this.blocklist,
    required this.siteSettings,
    required this.featureFlags,
    required this.adblock,
  });

  final SettingsProvider settings;
  final ThemeProvider theme;
  final LocaleProvider locale;
  final TabsProvider tabs;
  final GlobalErrorHandler errorHandler;
  final ExternalLauncher launcher;
  final Share share;
  final AppInfo appInfo;
  final SessionRestoreService sessionRestore;
  final TabLifecycleService tabLifecycle;
  final PersistenceGuard persistenceGuard;
  final ThumbnailCache thumbnails;
  final FeedbackProvider feedback;
  final BlocklistService blocklist;
  final SiteSettingsProvider siteSettings;
  final FeatureFlagsProvider featureFlags;
  final AdblockProvider adblock;

  /// Stops the background work. Called when the app goes away.
  void dispose() {
    sessionRestore.dispose();
    tabLifecycle.dispose();
    feedback.dispose();
    adblock.dispose();
    featureFlags.dispose();
    siteSettings.dispose();
    blocklist.dispose();
  }
}

/// Makes [AppDependencies] available to every screen below it.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  /// The dependencies above [context]. Throws when there are none.
  static AppDependencies of(BuildContext context) {
    final AppScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw FlutterError(
        'AppScope.of() was called with a context that has no AppScope above it.',
      );
    }
    return scope.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
