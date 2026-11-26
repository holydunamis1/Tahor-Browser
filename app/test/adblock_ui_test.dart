import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/app_constants.dart';
import 'package:tahorbrowser/widgets/browser/shield_button.dart';
import 'package:tahorbrowser/widgets/core/icon_chip.dart';
import 'package:tahorbrowser/widgets/core/premium_toggle.dart';
import 'package:tahorbrowser/widgets/core/primary_button.dart';

import 'support/blocklist_support.dart';
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

  Future<void> openAdBlockingScreen(WidgetTester tester) async {
    await tester.tap(chip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ad blocking'));
    await tester.pumpAndSettle();
  }

  Future<void> publishNewer(TestApp app) async {
    final TestSigner signer = await TestSigner.create();
    final Uint8List list = Uint8List.fromList(
      utf8.encode('block|new\\.one|*|*|*|*\nblock|new\\.two|*|*|*|*\n'),
    );
    final m = await signer.manifestFor(list, version: 2);
    app.http.answer(AppUrls.blocklistManifest, utf8.encode(m.json));
    app.http.answer(AppUrls.blocklistSignature, utf8.encode(m.signature));
    app.http.answer(AppUrls.blocklistLatest, list);
  }

  group('the shield', () {
    appTest('is not shown on the start page', (WidgetTester tester) async {
      await TestApp.pump(tester);
      expect(find.byType(ShieldButton), findsNothing);
    });

    appTest('appears with a page and says blocking is on', (
      WidgetTester tester,
    ) async {
      await TestApp.pump(tester);
      await submit(tester, 'example.com');
      expect(find.byType(ShieldButton), findsOneWidget);
      expect(chip('Ad blocking is on for this site'), findsOneWidget);
    });

    appTest('the sheet switches blocking off for this site only', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      await tester.tap(find.byType(ShieldButton));
      await tester.pumpAndSettle();
      expect(find.text('example.com'), findsWidgets);
      expect(find.text('Block ads on this site'), findsOneWidget);

      await tester.tap(find.byType(PremiumToggle));
      await tester.pumpAndSettle();

      expect(app.deps.siteSettings.adblockExceptions, <String>['example.com']);
      expect(app.deps.adblock.enabledFor('example.com'), isFalse);
      expect(app.deps.adblock.enabledFor('other.com'), isTrue);
    });

    appTest('the shield shows when a site is an exception', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      await app.deps.siteSettings.setAdblock('example.com', enabled: false);
      await tester.pumpAndSettle();
      expect(chip('Ad blocking is off for this site'), findsOneWidget);
    });

    appTest('the shield shows when blocking is off everywhere', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await submit(tester, 'example.com');
      await app.deps.settings.setAdblockEnabled(false);
      await tester.pumpAndSettle();
      expect(chip('Ad blocking is off'), findsOneWidget);
    });
  });

  group('the Ad blocking screen', () {
    appTest('shows the list that is in use', (WidgetTester tester) async {
      await TestApp.pump(tester);
      await openAdBlockingScreen(tester);
      expect(find.text('Filter list'), findsOneWidget);
      expect(find.text('Built into the app'), findsOneWidget);
      expect(find.text('Not checked yet'), findsOneWidget);
      expect(find.text('Update lists now'), findsOneWidget);
      expect(find.textContaining('video streams'), findsOneWidget);
    });

    appTest('the global switch turns blocking off', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await openAdBlockingScreen(tester);
      await tester.tap(find.byType(PremiumToggle).first);
      await tester.pumpAndSettle();
      expect(app.deps.settings.value.adblockEnabled, isFalse);
    });

    appTest('the weekly check is off until switched on', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await openAdBlockingScreen(tester);
      expect(app.deps.settings.value.blocklistAutoUpdate, isFalse);
      await tester.tap(find.byType(PremiumToggle).at(1));
      await tester.pumpAndSettle();
      expect(app.deps.settings.value.blocklistAutoUpdate, isTrue);
    });

    appTest('Update now installs a newer list and says so', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await publishNewer(app);
      await openAdBlockingScreen(tester);
      await tester.tap(find.widgetWithText(PrimaryButton, 'Update lists now'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('The list was updated'), findsOneWidget);
      expect(app.deps.blocklist.value.version, 2);
      expect(find.text('Downloaded update'), findsOneWidget);
    });

    appTest('Update now says plainly when it could not', (
      WidgetTester tester,
    ) async {
      await TestApp.pump(tester);
      await openAdBlockingScreen(tester);
      await tester.tap(find.widgetWithText(PrimaryButton, 'Update lists now'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining("Couldn't update the list"), findsOneWidget);
    });

    appTest('sites with blocking off are listed and can be restored', (
      WidgetTester tester,
    ) async {
      final TestApp app = await TestApp.pump(tester);
      await app.deps.siteSettings.setAdblock('a.com', enabled: false);
      await openAdBlockingScreen(tester);
      expect(find.text('a.com'), findsOneWidget);
      await tester.tap(chip('Turn ad blocking back on for a.com'));
      await tester.pumpAndSettle();
      expect(find.text('a.com'), findsNothing);
      expect(find.textContaining('No sites'), findsOneWidget);
      expect(app.deps.siteSettings.adblockExceptions, isEmpty);
    });
  });
}
