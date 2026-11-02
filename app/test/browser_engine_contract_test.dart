import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';

/// Compiles only while every [TabEvent] subclass is handled.
String describeEvent(TabEvent e) => switch (e) {
  PageStarted() => 'started',
  ProgressChanged() => 'progress',
  PageFinished() => 'finished',
  TitleChanged() => 'title',
  FaviconChanged() => 'favicon',
  NavigationStateChanged() => 'navigation',
  ErrorOccurred() => 'error',
};

/// Compiles only while every [NavigationDecision] subclass is handled.
String describeDecision(NavigationDecision d) => switch (d) {
  AllowNavigation() => 'allow',
  BlockNavigation() => 'block',
  OpenExternally() => 'external',
  RedirectNavigation() => 'redirect',
};

void main() {
  final Uri url = Uri.parse('https://example.com');

  test('every event carries its tab id', () {
    final List<TabEvent> events = <TabEvent>[
      PageStarted('t', url),
      const ProgressChanged('t', 0.5),
      PageFinished('t', url),
      const TitleChanged('t', 'x'),
      const FaviconChanged('t', null),
      const NavigationStateChanged('t', canGoBack: true, canGoForward: false),
      const ErrorOccurred('t', WebViewError.loadFailed()),
    ];
    expect(events.every((TabEvent e) => e.tabId == 't'), isTrue);
    expect(events.map(describeEvent).toSet().length, events.length);
  });

  test('a main-frame error is the default', () {
    expect(
      const ErrorOccurred('t', WebViewError.loadFailed()).isMainFrame,
      isTrue,
    );
    expect(
      const ErrorOccurred(
        't',
        WebViewError.loadFailed(),
        isMainFrame: false,
      ).isMainFrame,
      isFalse,
    );
  });

  test('decisions carry the address they act on', () {
    expect(describeDecision(const AllowNavigation()), 'allow');
    expect(describeDecision(const BlockNavigation()), 'block');
    expect(describeDecision(OpenExternally(url)), 'external');
    expect(describeDecision(RedirectNavigation(url)), 'redirect');
    expect(OpenExternally(url).uri, url);
    expect(RedirectNavigation(url).uri, url);
  });

  test('a policy is a plain function over a request', () {
    NavigationDecision policy(NavigationRequest r) => r.uri.scheme == 'https'
        ? const AllowNavigation()
        : RedirectNavigation(r.uri.replace(scheme: 'https'));

    final NavigationRequest http = NavigationRequest(
      tabId: 't',
      uri: Uri.parse('http://example.com/x'),
      isMainFrame: true,
    );
    expect(http.hasGesture, isFalse);
    final NavigationDecision decision = policy(http);
    expect(decision, isA<RedirectNavigation>());
    expect(
      (decision as RedirectNavigation).uri.toString(),
      'https://example.com/x',
    );
  });

  test('a view config describes a blank mobile tab by default', () {
    const TabViewConfig c = TabViewConfig(tabId: 't');
    expect(c.initialUrl, isNull);
    expect(c.isIncognito, isFalse);
  });
}
