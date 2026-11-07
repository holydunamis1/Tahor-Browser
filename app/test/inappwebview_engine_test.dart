import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/contracts/external_launcher.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';
import 'package:tahorbrowser/platform/android/android_browser_engine.dart';
import 'package:tahorbrowser/platform/common/inappwebview_engine_base.dart';
import 'package:tahorbrowser/platform/ios/ios_browser_engine.dart';

class FakeLauncher implements ExternalLauncher {
  final List<Uri> external = <Uri>[];

  @override
  Future<bool> openExternalApp(Uri uri) async {
    external.add(uri);
    return true;
  }

  @override
  Future<bool> openInSystemBrowser(Uri uri) async => true;
}

NavigationAction action(String url, {bool main = true, bool? gesture}) =>
    NavigationAction(
      request: URLRequest(url: WebUri(url)),
      isForMainFrame: main,
      hasGesture: gesture,
    );

void main() {
  const TabViewConfig config = TabViewConfig(tabId: 't1');

  group('settings', () {
    test('the shared settings suit a browser', () {
      final InAppWebViewSettings s = AndroidBrowserEngine(
        launcher: FakeLauncher(),
      ).settingsFor(config);
      expect(s.javaScriptEnabled, isTrue);
      expect(s.supportMultipleWindows, isTrue);
      expect(s.javaScriptCanOpenWindowsAutomatically, isFalse);
      expect(s.useHybridComposition, isTrue);
      expect(s.useShouldOverrideUrlLoading, isTrue);
      expect(s.allowsInlineMediaPlayback, isTrue);
      expect(s.allowFileAccess, isFalse);
      expect(s.transparentBackground, isFalse);
      expect(s.userAgent, isNull);
    });

    test('private browsing is never switched on through the plugin', () {
      for (final InAppWebViewEngineBase engine in <InAppWebViewEngineBase>[
        AndroidBrowserEngine(launcher: FakeLauncher()),
        IosBrowserEngine(launcher: FakeLauncher()),
      ]) {
        final InAppWebViewSettings s = engine.settingsFor(
          const TabViewConfig(tabId: 'p', isIncognito: true),
        );
        expect(s.incognito, anyOf(isNull, isFalse));
      }
    });

    test('Safe Browsing and the fraudulent-site warning follow one switch', () {
      final InAppWebViewSettings on = AndroidBrowserEngine(
        launcher: FakeLauncher(),
      ).settingsFor(config);
      expect(on.safeBrowsingEnabled, isTrue);
      expect(on.isFraudulentWebsiteWarningEnabled, isTrue);
      final InAppWebViewSettings off = IosBrowserEngine(
        launcher: FakeLauncher(),
        safeBrowsingEnabled: false,
      ).settingsFor(config);
      expect(off.safeBrowsingEnabled, isFalse);
      expect(off.isFraudulentWebsiteWarningEnabled, isFalse);
    });

    test('Android handles mixed content like Chrome', () {
      final InAppWebViewSettings s = AndroidBrowserEngine(
        launcher: FakeLauncher(),
      ).settingsFor(config);
      expect(
        s.mixedContentMode,
        MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
      );
      expect(s.domStorageEnabled, isTrue);
    });

    test('iOS turns on edge-swipe history, picture in picture and AirPlay', () {
      final InAppWebViewSettings s = IosBrowserEngine(launcher: FakeLauncher())
          .settingsFor(config);
      expect(s.allowsBackForwardNavigationGestures, isTrue);
      expect(s.allowsPictureInPictureMediaPlayback, isTrue);
      expect(s.allowsAirPlayForMediaPlayback, isTrue);
    });
  });

  group('load errors', () {
    test('no connection is an offline error', () {
      final AppError e = errorForLoad(
        WebResourceError(
          description: 'offline',
          type: WebResourceErrorType.NOT_CONNECTED_TO_INTERNET,
        ),
      );
      expect(e.code, 'network.offline');
    });

    test('a timeout is a timeout error', () {
      final AppError e = errorForLoad(
        WebResourceError(
          description: 'slow',
          type: WebResourceErrorType.TIMEOUT,
        ),
      );
      expect(e.code, 'network.timeout');
    });

    test('anything else is a failed load that keeps the description', () {
      final AppError e = errorForLoad(
        WebResourceError(
          description: 'bad host',
          type: WebResourceErrorType.HOST_LOOKUP,
        ),
      );
      expect(e.code, 'webview.load');
      expect(e.detail, 'bad host');
    });

    test('a cancelled load is not an error to show', () {
      expect(
        isCancelledLoad(
          WebResourceError(
            description: 'x',
            type: WebResourceErrorType.CANCELLED,
          ),
        ),
        isTrue,
      );
      expect(
        isCancelledLoad(
          WebResourceError(
            description: 'x',
            type: WebResourceErrorType.TIMEOUT,
          ),
        ),
        isFalse,
      );
    });
  });

  group('navigation', () {
    test('only an allow decision lets the web view load', () {
      expect(policyFor(const AllowNavigation()), NavigationActionPolicy.ALLOW);
      expect(policyFor(const BlockNavigation()), NavigationActionPolicy.CANCEL);
      expect(
        policyFor(OpenExternally(Uri.parse('tel:1'))),
        NavigationActionPolicy.CANCEL,
      );
      expect(
        policyFor(RedirectNavigation(Uri.parse('https://a.com'))),
        NavigationActionPolicy.CANCEL,
      );
    });

    test('a plugin action becomes a contract request', () {
      final NavigationRequest r = requestFor(
        't1',
        action('https://a.com/x', gesture: true),
      );
      expect(r.tabId, 't1');
      expect(r.uri.toString(), 'https://a.com/x');
      expect(r.isMainFrame, isTrue);
      expect(r.hasGesture, isTrue);
      expect(
        requestFor('t1', action('https://a.com', main: false)).isMainFrame,
        isFalse,
      );
      expect(requestFor('t1', action('https://a.com')).hasGesture, isFalse);
    });

    test('without a policy everything loads', () async {
      final AndroidBrowserEngine e = AndroidBrowserEngine(
        launcher: FakeLauncher(),
      );
      expect(
        await e.decide('t1', action('https://a.com')),
        NavigationActionPolicy.ALLOW,
      );
    });

    test('the policy sees the tab, the address and the frame', () async {
      final AndroidBrowserEngine e = AndroidBrowserEngine(
        launcher: FakeLauncher(),
      );
      NavigationRequest? seen;
      e.setNavigationPolicy((NavigationRequest r) {
        seen = r;
        return const AllowNavigation();
      });
      await e.decide('t9', action('https://a.com/p', main: false));
      expect(seen!.tabId, 't9');
      expect(seen!.uri.toString(), 'https://a.com/p');
      expect(seen!.isMainFrame, isFalse);
    });

    test('a block stops the load', () async {
      final AndroidBrowserEngine e = AndroidBrowserEngine(
        launcher: FakeLauncher(),
      );
      e.setNavigationPolicy((NavigationRequest r) => const BlockNavigation());
      expect(
        await e.decide('t1', action('https://a.com')),
        NavigationActionPolicy.CANCEL,
      );
    });

    test(
      'an external address is handed to the launcher and stops the load',
      () async {
        final FakeLauncher launcher = FakeLauncher();
        final AndroidBrowserEngine e = AndroidBrowserEngine(launcher: launcher);
        e.setNavigationPolicy((NavigationRequest r) => OpenExternally(r.uri));
        expect(
          await e.decide('t1', action('tel:+123')),
          NavigationActionPolicy.CANCEL,
        );
        await Future<void>.delayed(Duration.zero);
        expect(launcher.external.map((Uri u) => u.toString()), <String>[
          'tel:+123',
        ]);
      },
    );

    test('a redirect stops the original load', () async {
      final AndroidBrowserEngine e = AndroidBrowserEngine(
        launcher: FakeLauncher(),
      );
      e.setNavigationPolicy(
        (NavigationRequest r) => RedirectNavigation(Uri.parse('https://b.com')),
      );
      expect(
        await e.decide('t1', action('http://b.com')),
        NavigationActionPolicy.CANCEL,
      );
    });

    test('a policy that throws never blocks browsing', () async {
      final AndroidBrowserEngine e = AndroidBrowserEngine(
        launcher: FakeLauncher(),
      );
      e.setNavigationPolicy((NavigationRequest r) => throw Exception('bug'));
      expect(
        await e.decide('t1', action('https://a.com')),
        NavigationActionPolicy.ALLOW,
      );
    });
  });

  group('controls without a live web view', () {
    test('every command is a safe no-op', () async {
      final IosBrowserEngine e = IosBrowserEngine(launcher: FakeLauncher());
      await e.load('none', Uri.parse('https://a.com'));
      await e.goBack('none');
      await e.goForward('none');
      await e.reload('none');
      await e.stop('none');
      await e.dispose('none');
      await e.dispose('none');
    });
  });
}
