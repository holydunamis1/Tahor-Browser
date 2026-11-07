import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart' as plus;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahorbrowser/platform/android/android_browser_engine.dart';
import 'package:tahorbrowser/platform/android/android_external_launcher.dart';
import 'package:tahorbrowser/platform/common/package_info_app_info.dart';
import 'package:tahorbrowser/platform/common/share_plus_share.dart';
import 'package:tahorbrowser/platform/common/url_launcher_external_launcher.dart';
import 'package:tahorbrowser/platform/ios/ios_browser_engine.dart';
import 'package:tahorbrowser/platform/platform_factory.dart';
import 'package:tahorbrowser/platform/platform_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharePlusShare', () {
    test('shares the address with the title', () async {
      plus.ShareParams? seen;
      final SharePlusShare share = SharePlusShare(
        share: (plus.ShareParams p) async => seen = p,
      );
      await share.shareUrl(
        Uri.parse('https://example.com/a'),
        title: 'Example',
      );
      expect(seen!.uri, Uri.parse('https://example.com/a'));
      expect(seen!.title, 'Example');
      expect(seen!.subject, 'Example');
    });

    test('a failing share sheet does not throw', () async {
      final SharePlusShare share = SharePlusShare(
        share: (plus.ShareParams p) => throw Exception('closed'),
      );
      await share.shareUrl(Uri.parse('https://example.com'));
    });
  });

  group('PackageInfoAppInfo', () {
    test('reads the installed version', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Tahor',
        packageName: 'com.zdmgold.tahorbrowser',
        version: '1.2.3',
        buildNumber: '45',
        buildSignature: '',
      );
      final PackageInfoAppInfo info = await PackageInfoAppInfo.load();
      expect(info.version, '1.2.3');
      expect(info.buildNumber, '45');
    });
  });

  group('createPlatformServices', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      PackageInfo.setMockInitialValues(
        appName: 'Tahor',
        packageName: 'com.zdmgold.tahorbrowser',
        version: '0.1.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    test('Android gets its own engine and launcher', () async {
      final PlatformServices s = await createPlatformServices(
        const PlatformInfo(isAndroid: true, isIOS: false),
      );
      expect(s.engine, isA<AndroidBrowserEngine>());
      expect(s.launcher, isA<AndroidExternalLauncher>());
      expect(s.appInfo.version, '0.1.0');
    });

    test('iOS gets its own engine and the common launcher', () async {
      final PlatformServices s = await createPlatformServices(
        const PlatformInfo(isAndroid: false, isIOS: true),
      );
      expect(s.engine, isA<IosBrowserEngine>());
      expect(s.launcher, isA<UrlLauncherExternalLauncher>());
      expect(s.launcher, isNot(isA<AndroidExternalLauncher>()));
    });

    test('anything else is refused', () async {
      expect(
        createPlatformServices(
          const PlatformInfo(isAndroid: false, isIOS: false),
        ),
        throwsUnsupportedError,
      );
    });

    test('the key-value store works', () async {
      final PlatformServices s = await createPlatformServices(
        const PlatformInfo(isAndroid: true, isIOS: false),
      );
      await s.keyValueStore.setString('k', 'v');
      expect(await s.keyValueStore.getString('k'), 'v');
    });
  });

  test('PlatformInfo.current describes the test host as neither phone OS', () {
    final PlatformInfo info = PlatformInfo.current();
    expect(info.isAndroid && info.isIOS, isFalse);
  });
}
