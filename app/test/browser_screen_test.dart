import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';
import 'package:tahorbrowser/widgets/browser/address_bar.dart';
import 'package:tahorbrowser/widgets/browser/browser_nav_bar.dart';
import 'package:tahorbrowser/widgets/browser/page_progress_bar.dart';
import 'package:tahorbrowser/widgets/core/icon_chip.dart';

import 'support/test_app.dart';

void main() {
  Finder chip(String label) => find.byWidgetPredicate(
    (Widget w) => w is IconChip && w.semanticLabel == label,
  );

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(EditableText), text);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
  }

  group('opening pages', () {
    testWidgets(
      'a typed address opens in the showing tab and builds its web view',
      (WidgetTester tester) async {
        final TestApp app = await TestApp.pump(tester);
        await submit(tester, 'example.com');
        expect(app.deps.tabs.activeTab.url, 'https://example.com');
        expect(
          app.engine.builtConfigs.last.initialUrl,
          Uri.parse('https://example.com'),
        );
        expect(
          find.byKey(ValueKey<String>('view-${app.deps.tabs.activeTab.id}')),
          findsOneWidget,
        );
        expect(find.text('Tahor Fast & Private Browser'), findsNothing);
      },
    );

    testWidgets('typed words become a search with the chosen engine', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'cats and dogs');
      expect(
        app.deps.tabs.activeTab.url,
        'https://duckduckgo.com/?q=cats+and+dogs',
      );
    });

    testWidgets('a refused address does nothing', (WidgetTester tester) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'javascript:alert(1)');
      expect(app.deps.tabs.activeTab.isBlank, isTrue);
    });

    testWidgets('the engine got the app navigation policy', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      final NavigationDecision blocked = app.engine.policy!(
        NavigationRequest(
          tabId: 't',
          uri: Uri.parse('javascript:alert(1)'),
          isMainFrame: true,
        ),
      );
      expect(blocked, isA<BlockNavigation>());
    });
  });

  group('page state', () {
    testWidgets('loading shows the progress bar and a Stop button', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      final String id = app.deps.tabs.activeTab.id;
      expect(tester.getSize(find.byType(PageProgressBar)).height, 0);
      expect(chip('Reload'), findsOneWidget);

      app.engine.lastSink!(PageStarted(id, Uri.parse('https://example.com')));
      app.engine.lastSink!(ProgressChanged(id, 0.5));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(PageProgressBar)).height, 2);
      expect(chip('Stop'), findsOneWidget);
      expect(chip('Reload'), findsNothing);

      app.engine.lastSink!(PageFinished(id, Uri.parse('https://example.com')));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(PageProgressBar)).height, 0);
      expect(chip('Reload'), findsOneWidget);
    });

    testWidgets('Back and Forward follow the page history', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      final String id = app.deps.tabs.activeTab.id;
      expect(tester.widget<IconChip>(chip('Back')).onTap, isNull);
      app.engine.lastSink!(
        NavigationStateChanged(id, canGoBack: true, canGoForward: true),
      );
      await tester.pump();
      await tester.tap(chip('Back'));
      await tester.tap(chip('Forward'));
      await tester.tap(chip('Reload'));
      expect(app.engine.calls, <String>[
        'back $id',
        'forward $id',
        'reload $id',
      ]);
    });

    testWidgets('the address bar shows the page host', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      final String id = app.deps.tabs.activeTab.id;
      app.engine.lastSink!(
        PageFinished(id, Uri.parse('https://www.news.org/story')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'news.org',
      );
    });
  });

  group('errors', () {
    testWidgets(
      'a failed load shows the error with Try again, and a new load clears it',
      (WidgetTester tester) async {
        final TestApp app = await TestApp.pump(tester);
        await submit(tester, 'example.com');
        final String id = app.deps.tabs.activeTab.id;
        app.engine.lastSink!(ErrorOccurred(id, const NetworkError.offline()));
        await tester.pumpAndSettle();
        expect(
          find.text("You're offline. Check your connection and try again."),
          findsOneWidget,
        );
        await tester.tap(find.text('Try again'));
        expect(app.engine.calls, contains('reload $id'));

        app.engine.lastSink!(PageStarted(id, Uri.parse('https://example.com')));
        await tester.pumpAndSettle();
        expect(find.text('Try again'), findsNothing);
      },
    );

    testWidgets('an error in a sub-frame shows nothing', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      final String id = app.deps.tabs.activeTab.id;
      app.engine.lastSink!(
        ErrorOccurred(id, const WebViewError.loadFailed(), isMainFrame: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('the Back button', () {
    testWidgets('goes back in the page when there is history', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      final String id = app.deps.tabs.activeTab.id;
      app.engine.lastSink!(
        NavigationStateChanged(id, canGoBack: true, canGoForward: false),
      );
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(app.engine.calls, contains('back $id'));
    });

    testWidgets('leaves the app when there is no history', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        app.engine.calls.where((String c) => c.startsWith('back')),
        isEmpty,
      );
    });
  });

  group('the menu', () {
    testWidgets('a blank tab offers only Settings', (
      WidgetTester tester,
    ) async {
      await TestApp.pump(tester);
      await tester.tap(chip('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Share'), findsNothing);
      expect(find.text('Open in system browser'), findsNothing);
    });

    testWidgets('a page adds Reload, Share and Open in system browser', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      await tester.tap(chip('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Reload'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Open in system browser'), findsOneWidget);

      await tester.tap(find.text('Open in system browser'));
      await tester.pumpAndSettle();
      expect(app.launcher.systemBrowser, <Uri>[
        Uri.parse('https://example.com'),
      ]);
    });

    testWidgets('Share hands the address and title to the share sheet', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      app.engine.lastSink!(TitleChanged(app.deps.tabs.activeTab.id, 'Example'));
      await tester.pump();
      await tester.tap(chip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(app.share.shared, <(Uri, String?)>[
        (Uri.parse('https://example.com'), 'Example'),
      ]);
    });

    testWidgets('Reload reloads the page', (WidgetTester tester) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      await tester.tap(chip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reload'));
      await tester.pumpAndSettle();
      expect(app.engine.calls, <String>[
        'reload ${app.deps.tabs.activeTab.id}',
      ]);
    });

    testWidgets('while loading the menu offers Stop', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      app.engine.lastSink!(
        PageStarted(
          app.deps.tabs.activeTab.id,
          Uri.parse('https://example.com'),
        ),
      );
      await tester.pump();
      await tester.tap(chip('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Reload'), findsNothing);
      expect(find.text('Stop'), findsWidgets);
    });
  });

  testWidgets('an open keyboard takes the navigation bar out of the layout', (
    WidgetTester tester,
  ) async {
    await TestApp.pump(tester);
    expect(find.byType(BrowserNavBar), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byType(BrowserNavBar), findsNothing);
    expect(find.byType(AddressBar), findsOneWidget);
  });

  testWidgets('chrome stays in place while only the page area changes', (
    WidgetTester tester,
  ) async {
    final TestApp app = await TestApp.pump(tester);
    final Offset addressBefore = tester.getTopLeft(find.byType(AddressBar));
    final Offset navBefore = tester.getTopLeft(find.byType(BrowserNavBar));
    await submit(tester, 'example.com');
    app.engine.lastSink!(
      PageStarted(app.deps.tabs.activeTab.id, Uri.parse('https://example.com')),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(AddressBar)), addressBefore);
    expect(tester.getTopLeft(find.byType(BrowserNavBar)), navBefore);
  });
}
