import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/app_constants.dart';
import 'package:tahorbrowser/core/utils/url_utils.dart';

void main() {
  final SearchEngine ddg = AppConstants.engineById('duckduckgo');

  ResolvedInput resolve(String text) => resolveInput(text, ddg);

  void expectNavigation(String text, String url) {
    final ResolvedInput r = resolve(text);
    expect(r.kind, InputKind.navigation, reason: text);
    expect(r.uri.toString(), url, reason: text);
  }

  void expectSearch(String text, String url) {
    final ResolvedInput r = resolve(text);
    expect(r.kind, InputKind.search, reason: text);
    expect(r.uri.toString(), url, reason: text);
  }

  void expectRefused(String text, String reason) {
    final ResolvedInput r = resolve(text);
    expect(r.kind, InputKind.refused, reason: text);
    expect(r.uri, isNull);
    expect(r.reason, reason);
  }

  group('resolveInput', () {
    test('a bare host opens over https', () {
      expectNavigation('example.com', 'https://example.com');
      expectNavigation('  example.org  ', 'https://example.org');
      expectNavigation('EXAMPLE.COM', 'https://example.com');
      expectNavigation(
        'example.com/path?q=a+b',
        'https://example.com/path?q=a+b',
      );
      expectNavigation(
        'a.b.c.d.example.co.uk/x#y',
        'https://a.b.c.d.example.co.uk/x#y',
      );
    });

    test('an explicit http or https address is kept', () {
      expectNavigation('http://x', 'http://x');
      expectNavigation('https://example.com/a', 'https://example.com/a');
    });

    test('text with spaces is a search', () {
      expectSearch('foo bar', 'https://duckduckgo.com/?q=foo+bar');
      expectSearch('what is 3.5', 'https://duckduckgo.com/?q=what+is+3.5');
    });

    test('single words and version numbers are searches', () {
      expectSearch('intranet', 'https://duckduckgo.com/?q=intranet');
      expectSearch('3.5', 'https://duckduckgo.com/?q=3.5');
      expectSearch('e.g', 'https://duckduckgo.com/?q=e.g');
      expectSearch('c++', 'https://duckduckgo.com/?q=c%2B%2B');
    });

    test('local addresses open over http', () {
      expectNavigation('localhost:3000', 'http://localhost:3000');
      expectNavigation('localhost', 'http://localhost');
      expectNavigation('192.168.1.1:8080', 'http://192.168.1.1:8080');
      expectNavigation('[::1]:8080', 'http://[::1]:8080');
      expectNavigation('myhost.local', 'http://myhost.local');
      expectNavigation('my.printer.lan:631/x', 'http://my.printer.lan:631/x');
    });

    test('javascript: and file: are refused, in any case', () {
      expectRefused('javascript:alert(1)', 'scheme.javascript');
      expectRefused('JavaScript:alert(1)', 'scheme.javascript');
      expectRefused('file:///etc/passwd', 'scheme.file');
    });

    test('other dangerous schemes are refused', () {
      expectRefused('data:text/html,hi', 'scheme.data');
      expectRefused('vbscript:x', 'scheme.vbscript');
      expectRefused('blob:https://a.com/1', 'scheme.blob');
      expectRefused('intent://x#Intent;scheme=a;end', 'scheme.intent');
    });

    test('empty input is refused', () {
      expectRefused('', 'empty');
      expectRefused('   ', 'empty');
    });

    test('mail, phone and blank pages navigate', () {
      expectNavigation('mailto:a@b.co', 'mailto:a@b.co');
      expectNavigation('tel:+123', 'tel:+123');
      expectNavigation('about:blank', 'about:blank');
    });

    test('unknown schemes and malformed web addresses are searches', () {
      expectSearch('note:this', 'https://duckduckgo.com/?q=note%3Athis');
      expectSearch(
        'python:tutorial',
        'https://duckduckgo.com/?q=python%3Atutorial',
      );
      expectSearch(
        'ftp://files.example.com',
        'https://duckduckgo.com/?q=ftp%3A%2F%2Ffiles.example.com',
      );
      expectSearch(
        'http:example.com',
        'https://duckduckgo.com/?q=http%3Aexample.com',
      );
      expectSearch(
        'example.com:99999x',
        'https://duckduckgo.com/?q=example.com%3A99999x',
      );
    });

    test('a pasted address with spaces after the host is a page', () {
      expectNavigation('https://example.com/a b', 'https://example.com/a%20b');
    });

    test('a space inside the host makes it a search', () {
      expect(resolve('https://exa mple.com/x').kind, InputKind.search);
    });

    test('Unicode hosts become punycode', () {
      expectNavigation('münchen.de', 'https://xn--mnchen-3ya.de');
      expectNavigation('MÜNCHEN.DE', 'https://xn--mnchen-3ya.de');
      expectNavigation('https://münchen.de/x', 'https://xn--mnchen-3ya.de/x');
      expectNavigation('日本語.jp', 'https://xn--wgv71a119e.jp');
      expectNavigation('xn--mnchen-3ya.de', 'https://xn--mnchen-3ya.de');
    });

    test('credentials in an address are not hidden', () {
      final ResolvedInput r = resolve('https://google.com@evil.com');
      expect(r.kind, InputKind.navigation);
      expect(r.uri!.host, 'evil.com');
    });

    test('the chosen engine builds the search address', () {
      final SearchEngine bing = AppConstants.engineById('bing');
      expect(
        resolveInput('hello world', bing).uri.toString(),
        'https://www.bing.com/search?q=hello+world',
      );
    });
  });

  group('toAsciiHost', () {
    test('converts only labels with non-ASCII letters', () {
      expect(toAsciiHost('münchen.de'), 'xn--mnchen-3ya.de');
      expect(toAsciiHost('bücher.example'), 'xn--bcher-kva.example');
      expect(toAsciiHost('日本語.jp'), 'xn--wgv71a119e.jp');
      expect(toAsciiHost('ドメイン名例.jp'), 'xn--eckwd4c7cu47r2wf.jp');
      expect(toAsciiHost('example.com'), 'example.com');
      expect(toAsciiHost('xn--mnchen-3ya.de'), 'xn--mnchen-3ya.de');
    });
  });

  group('displayHost', () {
    String show(String url) => displayHost(Uri.parse(url));

    test('drops www and lowercases', () {
      expect(show('https://www.example.com/a'), 'example.com');
      expect(show('https://EXAMPLE.org'), 'example.org');
    });

    test('keeps www when nothing else would remain', () {
      expect(show('https://www.com'), 'www.com');
    });

    test('never converts punycode to Unicode', () {
      expect(show('https://xn--mnchen-3ya.de/'), 'xn--mnchen-3ya.de');
      expect(show('https://münchen.de'), 'xn--mnchen-3ya.de');
    });

    test('brackets IPv6 hosts and passes hostless addresses through', () {
      expect(show('http://[::1]:8080/'), '[::1]');
      expect(show('mailto:a@b.co'), 'mailto:a@b.co');
      expect(show('about:blank'), 'about:blank');
    });

    test('displayHostOf accepts text without a scheme', () {
      expect(displayHostOf('www.example.com/path'), 'example.com');
      expect(displayHostOf('https://www.example.com'), 'example.com');
      expect(displayHostOf('not a url'), 'not a url');
    });
  });

  group('small predicates', () {
    test('isPdfUrl looks at the path only', () {
      expect(isPdfUrl(Uri.parse('https://a.com/x.PDF?dl=1')), isTrue);
      expect(isPdfUrl(Uri.parse('https://a.com/x.pdf#page=2')), isTrue);
      expect(isPdfUrl(Uri.parse('https://a.com/x.pdf.html')), isFalse);
      expect(isPdfUrl(Uri.parse('https://a.com/?f=x.pdf')), isFalse);
    });

    test('isSecureScheme', () {
      expect(isSecureScheme(Uri.parse('HTTPS://a.com')), isTrue);
      expect(isSecureScheme(Uri.parse('http://a.com')), isFalse);
    });
  });

  group('parseIntentUri', () {
    test('reads scheme, package and fallback', () {
      final IntentLink? link = parseIntentUri(
        'intent://scan/#Intent;scheme=zxing;'
        'package=com.google.zxing.client.android;'
        'S.browser_fallback_url=https%3A%2F%2Fexample.com%2Fdl;end',
      );
      expect(link, isNotNull);
      expect(link!.launchUri.toString(), 'zxing://scan/');
      expect(link.package, 'com.google.zxing.client.android');
      expect(link.fallbackUrl.toString(), 'https://example.com/dl');
      expect(
        link.marketUri.toString(),
        'market://details?id=com.google.zxing.client.android',
      );
    });

    test('keeps path, query and action', () {
      final IntentLink? link = parseIntentUri(
        'intent://maps.example.com/place?id=1#Intent;scheme=https;'
        'package=com.example.maps;action=android.intent.action.VIEW;end',
      );
      expect(link!.launchUri.toString(), 'https://maps.example.com/place?id=1');
      expect(link.action, 'android.intent.action.VIEW');
      expect(link.fallbackUrl, isNull);
    });

    test('rejects a non-web fallback', () {
      expect(
        parseIntentUri(
          'intent://x#Intent;S.browser_fallback_url=javascript%3Aalert(1);end',
        ),
        isNull,
      );
    });

    test('ignores an invalid package name', () {
      final IntentLink? link = parseIntentUri(
        'intent://x#Intent;scheme=a;package=bad package;end',
      );
      expect(link!.package, isNull);
      expect(link.launchUri.toString(), 'a://x');
    });

    test('survives a broken percent escape in the fallback', () {
      final IntentLink? link = parseIntentUri(
        'intent://x#Intent;scheme=a;S.browser_fallback_url=%E0%A4%A;end',
      );
      expect(link!.fallbackUrl, isNull);
      expect(link.launchUri.toString(), 'a://x');
    });

    test('returns null for text that is not a usable intent link', () {
      expect(parseIntentUri('https://a.com'), isNull);
      expect(parseIntentUri('intent://x'), isNull);
      expect(parseIntentUri('intent://x#Intent;end'), isNull);
      expect(parseIntentUri('intent:#Intent;scheme=a;end'), isNull);
    });
  });
}
