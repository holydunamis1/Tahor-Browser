import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/models/app_settings.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/models/session_snapshot.dart';
import 'package:tahorbrowser/core/providers/feedback_provider.dart';
import 'package:tahorbrowser/core/models/tab_model.dart';
import 'package:tahorbrowser/core/storage/storage_keys.dart';
import 'package:tahorbrowser/widgets/browser/tab_card.dart';
import 'package:tahorbrowser/widgets/browser/tab_count_button.dart';
import 'package:tahorbrowser/widgets/core/icon_chip.dart';
import 'package:tahorbrowser/widgets/core/premium_card.dart';
import 'package:tahorbrowser/widgets/core/primary_button.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

void main() {
  Finder chip(String label) => find.byWidgetPredicate(
    (Widget w) => w is IconChip && w.semanticLabel == label,
  );

  Future<void> openTabs(WidgetTester tester) async {
    await tester.tap(find.byType(TabCountButton));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(EditableText), text);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
  }

  group('the start page', () {
    appTest('a blank tab shows the start page and the tab count', (
      WidgetTester tester,
    ) async {
      await TestApp.pump(tester);
      expect(find.text('Fast, private browsing'), findsOneWidget);
      expect(find.text('Search or enter address'), findsWidgets);
      expect(find.text('1'), findsOneWidget);
    });

    appTest('tapping the search field opens the address bar', (
      WidgetTester tester,
    ) async {
      await TestApp.pump(tester);
      await tester.tap(find.byType(PremiumCard));
      await tester.pumpAndSettle();
      final EditableText field = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(field.focusNode.hasFocus, isTrue);
    });

    appTest('once a page is open the start page is gone', (
      WidgetTester tester,
    ) async {
      await TestApp.pump(tester);
      await submit(tester, 'example.com');
      expect(find.text('Fast, private browsing'), findsNothing);
    });
  });

  group('tab count button', () {
    test('shows 99+ above ninety-nine', () {
      expect(TabCountButton.labelFor(1), '1');
      expect(TabCountButton.labelFor(99), '99');
      expect(TabCountButton.labelFor(100), '99+');
    });

    appTest('speaks the count and opens the tab list', (
      WidgetTester tester,
    ) async {
      await TestApp.pump(tester);
      expect(find.bySemanticsLabel('1 tab open'), findsOneWidget);
      await openTabs(tester);
      expect(find.text('Tabs'), findsOneWidget);
    });
  });

  group('the tab list', () {
    appTest('every tab is a card and the showing one is marked', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      app.deps.tabs.openTab(url: Uri.parse('https://b.example'));
      await tester.pumpAndSettle();
      await openTabs(tester);
      expect(find.byType(TabCard), findsNWidgets(2));
      final List<TabCard> cards = tester
          .widgetList<TabCard>(find.byType(TabCard))
          .toList();
      expect(cards.where((TabCard c) => c.isActive).length, 1);
      expect(cards.last.isActive, isTrue);
    });

    appTest('a card shows the page title, and New tab when there is no page', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      app.deps.tabs.openTab(url: Uri.parse('https://b.example'));
      app.deps.tabs.handleEvent(
        TitleChanged(app.deps.tabs.activeTab.id, 'Page B'),
      );
      await tester.pumpAndSettle();
      await openTabs(tester);
      expect(
        find.descendant(
          of: find.byType(TabCard),
          matching: find.text('New tab'),
        ),
        findsOneWidget,
      );
      expect(find.text('Page B'), findsOneWidget);
      expect(find.text('b.example'), findsOneWidget);
    });

    appTest('a page with no title shows its host', (WidgetTester tester) async {
      final TestApp app = await TestApp.pump(tester);
      app.deps.tabs.openTab(url: Uri.parse('https://b.example'));
      await tester.pumpAndSettle();
      await openTabs(tester);
      expect(find.text('b.example'), findsOneWidget);
    });

    appTest('tapping a card shows that tab and returns to the page', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      final String first = app.deps.tabs.activeTab.id;
      app.deps.tabs.openTab(url: Uri.parse('https://b.example'));
      await tester.pumpAndSettle();
      await openTabs(tester);
      await tester.tap(find.byKey(ValueKey<String>('tab-$first')));
      await tester.pumpAndSettle();
      expect(app.deps.tabs.activeTab.id, first);
      expect(find.text('Tabs'), findsNothing);
    });

    appTest('the close button closes one tab', (WidgetTester tester) async {
      final TestApp app = await TestApp.pump(tester);
      final String first = app.deps.tabs.activeTab.id;
      app.deps.tabs.openTab(url: Uri.parse('https://b.example'));
      await tester.pumpAndSettle();
      await openTabs(tester);
      await tester.tap(find.byKey(ValueKey<String>('close-$first')));
      await tester.pumpAndSettle();
      expect(find.byType(TabCard), findsOneWidget);
      expect(app.deps.tabs.value.tabs.length, 1);
    });

    appTest('New tab opens an empty tab and returns to the page', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await openTabs(tester);
      await tester.tap(find.widgetWithText(PrimaryButton, 'New tab'));
      await tester.pumpAndSettle();
      expect(app.deps.tabs.value.tabs.length, 2);
      expect(app.deps.tabs.activeTab.isBlank, isTrue);
      expect(find.text('Tabs'), findsNothing);
    });

    appTest('Close all asks first, and Cancel keeps every tab', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      app.deps.tabs.openTab(url: Uri.parse('https://b.example'));
      await tester.pumpAndSettle();
      await openTabs(tester);
      await tester.tap(chip('Close all'));
      await tester.pumpAndSettle();
      expect(find.text('Close all tabs?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(app.deps.tabs.value.tabs.length, 2);
    });

    appTest('confirming Close all leaves one empty tab', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      app.deps.tabs.openTab(url: Uri.parse('https://b.example'));
      await tester.pumpAndSettle();
      await openTabs(tester);
      await tester.tap(chip('Close all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close all').last);
      await tester.pumpAndSettle();
      expect(app.deps.tabs.value.tabs.length, 1);
      expect(app.deps.tabs.activeTab.isBlank, isTrue);
    });

    appTest('Reopen closed tab is offered only when there is one', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      app.deps.tabs.openTab(url: Uri.parse('https://b.example'));
      await tester.pumpAndSettle();
      await openTabs(tester);
      expect(find.text('Reopen closed tab'), findsNothing);

      final String closing = app.deps.tabs.activeTab.id;
      await tester.tap(find.byKey(ValueKey<String>('close-$closing')));
      await tester.pumpAndSettle();
      expect(find.text('Reopen closed tab'), findsOneWidget);

      await tester.tap(find.text('Reopen closed tab'));
      await tester.pumpAndSettle();
      expect(app.deps.tabs.activeTab.url, 'https://b.example');
    });
  });

  group('the browser menu', () {
    String? copied;

    setUp(() => copied = null);

    void mockClipboard(WidgetTester tester) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    appTest('New tab is always offered; page items only with a page', (
      WidgetTester tester,
    ) async {
      await TestApp.pump(tester);
      await tester.tap(chip('Menu'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('menu-new-tab')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('menu-copy-link')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('menu-reopen-tab')),
        findsNothing,
      );
    });

    appTest('Copy link copies the address and says so', (
      WidgetTester tester,
    ) async {
      mockClipboard(tester);
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      await tester.tap(chip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('menu-copy-link')));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(copied, 'https://example.com');
      // First the provider, so a failure says which half is broken.
      expect(app.deps.feedback.value, const FeedbackMessage('Link copied'));
      expect(find.text('Link copied'), findsOneWidget);
      // The message goes away by itself.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Link copied'), findsNothing);
    });

    appTest('Reopen closed tab appears after a tab was closed', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      final String id = app.deps.tabs.openTab(
        url: Uri.parse('https://b.example'),
      )!;
      app.deps.tabs.closeTab(id);
      await tester.pumpAndSettle();
      await tester.tap(chip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('menu-reopen-tab')));
      await tester.pumpAndSettle();
      expect(app.deps.tabs.activeTab.url, 'https://b.example');
    });
  });

  group('start-up', () {
    FakeKeyValueStore saved(StartupMode mode) {
      final FakeKeyValueStore store = FakeKeyValueStore();
      store.data[StorageKeys.settings] = jsonEncode(
        AppSettings(startupMode: mode).toJson(),
      );
      store.data[StorageKeys.sessionSnapshot] = jsonEncode(
        SessionSnapshot.capture(
          tabs: const <TabModel>[
            TabModel(id: 'a', url: 'https://a.example'),
            TabModel(id: 'b', url: 'https://b.example'),
          ],
          activeTabId: 'b',
          savedAt: DateTime.utc(2026, 11, 17),
        ).toJson(),
      );
      return store;
    }

    appTest('continue where I left off brings the tabs back', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(
        tester,
        store: saved(StartupMode.continueSession),
      );
      expect(app.deps.tabs.value.tabs.length, 2);
      expect(app.deps.tabs.activeTab.url, 'https://b.example');
    });

    appTest('the start page choice opens one empty tab', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(
        tester,
        store: saved(StartupMode.startPage),
      );
      expect(app.deps.tabs.value.tabs.length, 1);
      expect(app.deps.tabs.activeTab.isBlank, isTrue);
    });
  });
}
