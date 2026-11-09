import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/design_tokens.dart';
import 'package:tahorbrowser/widgets/browser/address_bar.dart';
import 'package:tahorbrowser/widgets/browser/browser_nav_bar.dart';
import 'package:tahorbrowser/widgets/browser/page_progress_bar.dart';
import 'package:tahorbrowser/widgets/core/icon_chip.dart';

import 'support/test_host.dart';

void main() {
  String? clipboard;

  void mockClipboard(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        switch (call.method) {
          case 'Clipboard.getData':
            return clipboard == null
                ? null
                : <String, Object?>{'text': clipboard};
          case 'Clipboard.hasStrings':
            return <String, Object?>{
              'value': clipboard != null && clipboard!.isNotEmpty,
            };
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

  group('PageProgressBar', () {
    Widget bar(
      double progress, {
      bool loading = true,
      TextDirection d = TextDirection.ltr,
    }) => testHost(
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 300,
          child: PageProgressBar(progress: progress, isLoading: loading),
        ),
      ),
      direction: d,
    );

    testWidgets('takes no space when nothing is loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(bar(0.5, loading: false));
      expect(tester.getSize(find.byType(PageProgressBar)), Size.zero);
    });

    testWidgets('is 2 px high while loading and fills as it progresses', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(bar(0.5));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(PageProgressBar)).height, 2);
      final Finder fill = find.descendant(
        of: find.byType(PageProgressBar),
        matching: find.byType(ColoredBox),
      );
      expect(tester.getSize(fill).width, 150);
      expect(tester.widget<ColoredBox>(fill).color, AppPalette.light.accent);
    });

    testWidgets('always shows a sliver and never overflows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(bar(0));
      await tester.pumpAndSettle();
      final Finder fill = find.descendant(
        of: find.byType(PageProgressBar),
        matching: find.byType(ColoredBox),
      );
      expect(tester.getSize(fill).width, closeTo(6, 0.01));
      await tester.pumpWidget(bar(3));
      await tester.pumpAndSettle();
      expect(tester.getSize(fill).width, 300);
    });

    testWidgets('grows from the start side in both directions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(bar(0.5));
      await tester.pumpAndSettle();
      final Finder fill = find.descendant(
        of: find.byType(PageProgressBar),
        matching: find.byType(ColoredBox),
      );
      expect(
        tester.getTopLeft(fill).dx,
        tester.getTopLeft(find.byType(PageProgressBar)).dx,
      );
      await tester.pumpWidget(bar(0.5, d: TextDirection.rtl));
      await tester.pumpAndSettle();
      expect(
        tester.getTopRight(fill).dx,
        tester.getTopRight(find.byType(PageProgressBar)).dx,
      );
    });
  });

  group('AddressBar', () {
    const String page = 'https://www.example.com/path?q=1';

    Widget bar({
      String url = '',
      ValueChanged<String>? onSubmitted,
      FocusNode? focus,
      Widget? trailing,
    }) => testHost(
      Center(
        child: SizedBox(
          width: 360,
          child: AddressBar(
            url: url,
            onSubmitted: onSubmitted ?? (String _) {},
            focusNode: focus,
            trailing: trailing,
          ),
        ),
      ),
    );

    TextEditingController controller(WidgetTester tester) =>
        tester.widget<EditableText>(find.byType(EditableText)).controller;

    testWidgets('shows the host while unfocused', (WidgetTester tester) async {
      await tester.pumpWidget(bar(url: page));
      expect(controller(tester).text, 'example.com');
    });

    testWidgets('a blank tab shows the hint', (WidgetTester tester) async {
      await tester.pumpWidget(bar());
      expect(find.text('Search or enter address'), findsOneWidget);
    });

    testWidgets('focusing shows the whole address, selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(bar(url: page));
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(controller(tester).text, page);
      expect(
        controller(tester).selection,
        TextSelection(baseOffset: 0, extentOffset: page.length),
      );
    });

    testWidgets('losing focus goes back to the host', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(bar(url: page));
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      expect(controller(tester).text, 'example.com');
    });

    testWidgets('Go submits what was typed and gives up focus', (
      WidgetTester tester,
    ) async {
      final List<String> submitted = <String>[];
      await tester.pumpWidget(bar(url: page, onSubmitted: submitted.add));
      await tester.enterText(find.byType(EditableText), 'cats and dogs');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();
      expect(submitted, <String>['cats and dogs']);
      expect(
        FocusManager.instance.primaryFocus?.hasPrimaryFocus == true &&
            tester
                .state<EditableTextState>(find.byType(EditableText))
                .widget
                .focusNode
                .hasFocus,
        isFalse,
      );
    });

    testWidgets('a new page replaces the host while unfocused', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(bar(url: page));
      await tester.pumpWidget(bar(url: 'https://other.org/'));
      expect(controller(tester).text, 'other.org');
    });

    testWidgets('a new page does not overwrite what is being typed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(bar(url: page));
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'typing');
      await tester.pumpWidget(bar(url: 'https://other.org/'));
      expect(controller(tester).text, 'typing');
    });

    testWidgets('says Not secure for http only', (WidgetTester tester) async {
      await tester.pumpWidget(bar(url: 'http://example.com/'));
      expect(find.text('Not secure'), findsOneWidget);
      await tester.pumpWidget(bar(url: 'https://example.com/'));
      expect(find.text('Not secure'), findsNothing);
      await tester.pumpWidget(bar());
      expect(find.text('Not secure'), findsNothing);
    });

    testWidgets('is a 48 high pill', (WidgetTester tester) async {
      await tester.pumpWidget(bar(url: page));
      expect(
        tester.getSize(find.byType(AddressBar)).height,
        greaterThanOrEqualTo(48),
      );
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AddressBar),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (box.decoration as BoxDecoration).borderRadius,
        const BorderRadius.all(Radius.circular(24)),
      );
    });

    testWidgets('is set up for typing addresses', (WidgetTester tester) async {
      await tester.pumpWidget(bar());
      final EditableText e = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(e.autocorrect, isFalse);
      expect(e.keyboardType, TextInputType.url);
      expect(e.textInputAction, TextInputAction.go);
    });

    testWidgets('Paste and go submits the clipboard text', (
      WidgetTester tester,
    ) async {
      mockClipboard(tester);
      clipboard = 'example.org';
      final List<String> submitted = <String>[];
      await tester.pumpWidget(bar(onSubmitted: submitted.add));
      await tester.longPress(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paste and go'));
      await tester.pumpAndSettle();
      expect(submitted, <String>['example.org']);
    });

    testWidgets('can be focused from outside', (WidgetTester tester) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(bar(url: page, focus: focus));
      focus.requestFocus();
      await tester.pump();
      expect(controller(tester).text, page);
    });

    testWidgets('shows a trailing action', (WidgetTester tester) async {
      await tester.pumpWidget(
        bar(
          url: page,
          trailing: const SizedBox(key: Key('shield'), width: 24, height: 24),
        ),
      );
      expect(find.byKey(const Key('shield')), findsOneWidget);
    });

    testWidgets('is labelled for screen readers', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(bar(url: page));
      expect(find.bySemanticsLabel('Address or search'), findsWidgets);
      handle.dispose();
    });
  });

  group('BrowserNavBar', () {
    Widget nav({
      bool back = true,
      bool forward = true,
      bool loading = false,
      List<String>? log,
      Widget? tabs,
      TextDirection d = TextDirection.ltr,
    }) => testHost(
      Align(
        alignment: Alignment.bottomCenter,
        child: BrowserNavBar(
          canGoBack: back,
          canGoForward: forward,
          isLoading: loading,
          onBack: () => log?.add('back'),
          onForward: () => log?.add('forward'),
          onReload: () => log?.add('reload'),
          onStop: () => log?.add('stop'),
          onMenu: () => log?.add('menu'),
          tabsButton: tabs,
        ),
      ),
      direction: d,
    );

    Finder chip(String label) => find.byWidgetPredicate(
      (Widget w) => w is IconChip && w.semanticLabel == label,
    );

    testWidgets('every button calls its action', (WidgetTester tester) async {
      final List<String> log = <String>[];
      await tester.pumpWidget(nav(log: log));
      for (final String label in <String>[
        'Back',
        'Forward',
        'Reload',
        'Menu',
      ]) {
        await tester.tap(chip(label));
      }
      expect(log, <String>['back', 'forward', 'reload', 'menu']);
    });

    testWidgets('Back and Forward are disabled when there is nowhere to go', (
      WidgetTester tester,
    ) async {
      final List<String> log = <String>[];
      await tester.pumpWidget(nav(back: false, forward: false, log: log));
      await tester.tap(chip('Back'));
      await tester.tap(chip('Forward'));
      expect(log, isEmpty);
      expect(tester.widget<IconChip>(chip('Back')).onTap, isNull);
      expect(tester.widget<IconChip>(chip('Menu')).onTap, isNotNull);
    });

    testWidgets('Reload becomes Stop while a page loads', (
      WidgetTester tester,
    ) async {
      final List<String> log = <String>[];
      await tester.pumpWidget(nav(loading: true, log: log));
      expect(chip('Reload'), findsNothing);
      await tester.tap(chip('Stop'));
      expect(log, <String>['stop']);
    });

    testWidgets('the tabs button sits before Reload', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        nav(tabs: const SizedBox(key: Key('tabs'), width: 48, height: 48)),
      );
      final double back = tester.getCenter(chip('Back')).dx;
      final double forward = tester.getCenter(chip('Forward')).dx;
      final double tabs = tester.getCenter(find.byKey(const Key('tabs'))).dx;
      final double reload = tester.getCenter(chip('Reload')).dx;
      final double menu = tester.getCenter(chip('Menu')).dx;
      expect(<double>[
        back,
        forward,
        tabs,
        reload,
        menu,
      ], orderedEquals(<double>[back, forward, tabs, reload, menu]..sort()));
    });

    testWidgets('the order mirrors in right-to-left', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(nav(d: TextDirection.rtl));
      expect(
        tester.getCenter(chip('Back')).dx,
        greaterThan(tester.getCenter(chip('Menu')).dx),
      );
    });

    testWidgets('every button is at least 48 by 48', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(nav());
      for (final String label in <String>[
        'Back',
        'Forward',
        'Reload',
        'Menu',
      ]) {
        final Size s = tester.getSize(chip(label));
        expect(s.width, greaterThanOrEqualTo(48), reason: label);
        expect(s.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets('has a hairline on top and the page background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(nav());
      final BoxDecoration d =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(BrowserNavBar),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(d.color, AppPalette.light.bgPrimary);
      expect((d.border! as Border).top.color, AppPalette.light.borderSubtle);
    });
  });
}
