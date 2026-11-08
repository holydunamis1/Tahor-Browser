import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/services/url_policy_service.dart';

void main() {
  const UrlPolicyService service = UrlPolicyService();

  NavigationDecision decide(
    String url, {
    bool main = true,
    bool gesture = false,
  }) => service.decide(
    NavigationRequest(
      tabId: 't',
      uri: Uri.parse(url),
      isMainFrame: main,
      hasGesture: gesture,
    ),
  );

  void expectAllow(NavigationDecision d, [String? reason]) =>
      expect(d, isA<AllowNavigation>(), reason: reason);
  void expectBlock(NavigationDecision d, [String? reason]) =>
      expect(d, isA<BlockNavigation>(), reason: reason);

  group('web pages', () {
    test('http and https load, with or without a tap, in any frame', () {
      for (final String url in <String>[
        'http://a.com',
        'https://a.com/x?y=1',
        'HTTPS://A.COM',
      ]) {
        expectAllow(decide(url), url);
        expectAllow(decide(url, gesture: true), url);
        expectAllow(decide(url, main: false), url);
      }
    });

    test('a blank page and blob addresses load', () {
      expectAllow(decide('about:blank'));
      expectAllow(decide('blob:https://a.com/uuid'));
      expectAllow(decide('blob:https://a.com/uuid', main: false));
    });
  });

  group('blocked', () {
    test('code, local files and other risky addresses never load', () {
      for (final String url in <String>[
        'javascript:alert(1)',
        'vbscript:x',
        'file:///etc/passwd',
        'content://media/1',
        'filesystem:https://a.com/f',
        'view-source:https://a.com',
        'ftp://files.example.com',
      ]) {
        expectBlock(decide(url, gesture: true), url);
        expectBlock(decide(url), url);
      }
    });

    test('about pages other than blank are blocked', () {
      expectBlock(decide('about:config', gesture: true));
      expectBlock(decide('about:srcdoc'));
    });

    test(
      'a data address cannot be the page itself, but frames may use one',
      () {
        expectBlock(decide('data:text/html,<h1>x</h1>', gesture: true));
        expectAllow(decide('data:image/png;base64,AAAA', main: false));
      },
    );

    test('an address without a scheme is blocked', () {
      expectBlock(decide('/relative/path'));
    });
  });

  group('links to other apps', () {
    test('a tap hands the address to the other app', () {
      for (final String url in <String>[
        'tel:+123',
        'mailto:a@b.co',
        'sms:+123',
        'market://details?id=com.x',
        'intent://scan/#Intent;scheme=zxing;end',
        'geo:0,0?q=cafe',
        'spotify:track:1',
        'whatsapp://send?text=hi',
      ]) {
        final NavigationDecision d = decide(url, gesture: true);
        expect(d, isA<OpenExternally>(), reason: url);
        expect((d as OpenExternally).uri, Uri.parse(url), reason: url);
      }
    });

    test('without a tap, a page cannot launch another app', () {
      for (final String url in <String>[
        'tel:+123',
        'intent://x#Intent;end',
        'spotify:track:1',
      ]) {
        expectBlock(decide(url), url);
        expectBlock(decide(url, main: false), url);
      }
    });
  });

  test('the scheme lists do not overlap', () {
    final Set<String> all = <String>{
      ...UrlPolicyService.webSchemes,
      ...UrlPolicyService.appSchemes,
      ...UrlPolicyService.blockedSchemes,
    };
    expect(
      all.length,
      UrlPolicyService.webSchemes.length +
          UrlPolicyService.appSchemes.length +
          UrlPolicyService.blockedSchemes.length,
    );
  });
}
