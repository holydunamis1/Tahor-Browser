import '../core/contracts/app_info.dart';
import '../core/contracts/browser_engine.dart';
import '../core/contracts/external_launcher.dart';
import '../core/contracts/key_value_store.dart';
import '../core/contracts/share.dart';
import 'android/android_browser_engine.dart';
import 'android/android_external_launcher.dart';
import 'common/package_info_app_info.dart';
import 'common/share_plus_share.dart';
import 'common/shared_prefs_key_value_store.dart';
import 'common/url_launcher_external_launcher.dart';
import 'ios/ios_browser_engine.dart';
import 'platform_info.dart';

/// Everything the app needs from the platform, chosen for the running
/// system. Later batches add fields.
class PlatformServices {
  const PlatformServices({
    required this.engine,
    required this.launcher,
    required this.share,
    required this.keyValueStore,
    required this.appInfo,
  });

  final BrowserEngine engine;
  final ExternalLauncher launcher;
  final Share share;
  final KeyValueStore keyValueStore;
  final AppInfo appInfo;
}

/// Builds the platform services. Used by the app's start-up code only.
Future<PlatformServices> createPlatformServices(PlatformInfo info) async {
  if (!info.isAndroid && !info.isIOS) {
    throw UnsupportedError('Tahor runs on Android and iOS.');
  }
  final ExternalLauncher launcher = info.isAndroid
      ? AndroidExternalLauncher()
      : UrlLauncherExternalLauncher();
  final BrowserEngine engine = info.isAndroid
      ? AndroidBrowserEngine(launcher: launcher)
      : IosBrowserEngine(launcher: launcher);
  return PlatformServices(
    engine: engine,
    launcher: launcher,
    share: SharePlusShare(),
    keyValueStore: SharedPrefsKeyValueStore(),
    appInfo: await PackageInfoAppInfo.load(),
  );
}
