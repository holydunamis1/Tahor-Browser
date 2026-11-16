import '../core/app_scope.dart';
import '../core/constants/app_constants.dart';
import '../core/error/global_error_handler.dart';
import '../core/providers/locale_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/tabs_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/services/settings_service.dart';
import '../core/services/url_policy_service.dart';
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

  final SettingsProvider settings = SettingsProvider(
    service: SettingsService(services.keyValueStore),
  );
  await settings.load();

  final TabsProvider tabs = TabsProvider(
    engine: services.engine,
    searchEngine: () => AppConstants.engineById(settings.value.searchEngineId),
  );
  services.engine.setNavigationPolicy(const UrlPolicyService().decide);

  return AppDependencies(
    settings: settings,
    theme: ThemeProvider(settings),
    locale: LocaleProvider(settings),
    tabs: tabs,
    errorHandler: errorHandler,
    launcher: services.launcher,
    share: services.share,
    appInfo: services.appInfo,
  );
}
