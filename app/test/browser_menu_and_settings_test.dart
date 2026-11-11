import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/widgets/browser/browser_menu_sheet.dart';
import 'package:tahorbrowser/widgets/core/premium_toggle.dart';
import 'package:tahorbrowser/widgets/icons/semantic_icons.dart';
import 'package:tahorbrowser/widgets/settings/setting_choice_tile.dart';
import 'package:tahorbrowser/widgets/settings/setting_switch.dart';
import 'package:tahorbrowser/widgets/settings/setting_tile.dart';

import 'support/test_host.dart';

void main() {
  group('BrowserMenuSheet', () {
    late GlobalKey<NavigatorState> nav;
    late List<String> log;

    Future<void> open(WidgetTester tester, List<MenuAction> actions) async {
      nav = GlobalKey<NavigatorState>();
      log = <String>[];
      await tester.pumpWidget(
        routeHost(nav, (BuildContext c) => const SizedBox.expand()),
      );
      unawaited(
        showBrowserMenu(
          context: tester.element(find.byType(SizedBox).first),
          actions: actions,
        ),
      );
      await tester.pumpAndSettle();
    }

    List<MenuAction> sample() => <MenuAction>[
      MenuAction(
        id: 'reload',
        label: 'Reload',
        glyph: AppIcons.reload,
        group: MenuGroup.quick,
        onSelected: () => log.add('reload'),
      ),
      MenuAction(
        id: 'share',
        label: 'Share',
        glyph: AppIcons.share,
        group: MenuGroup.quick,
        onSelected: () => log.add('share'),
      ),
      MenuAction(
        id: 'external',
        label: 'Open in system browser',
        glyph: AppIcons.openExternal,
        group: MenuGroup.page,
        onSelected: () => log.add('external'),
      ),
      MenuAction(
        id: 'settings',
        label: 'Settings',
        glyph: AppIcons.settings,
        group: MenuGroup.app,
        onSelected: () => log.add('settings'),
      ),
    ];

    testWidgets('draws the quick row and the groups it is given, in order', (
      WidgetTester tester,
    ) async {
      await open(tester, sample());
      expect(find.text('Reload'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('THIS PAGE'), findsOneWidget);
      expect(find.text('APP'), findsOneWidget);
      expect(find.text('TABS'), findsNothing);
      expect(find.text('LIBRARY'), findsNothing);
      expect(
        tester.getTopLeft(find.text('THIS PAGE')).dy,
        lessThan(tester.getTopLeft(find.text('APP')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Reload')).dy,
        lessThan(tester.getTopLeft(find.text('THIS PAGE')).dy),
      );
    });

    testWidgets('choosing an item closes the menu and runs it once', (
      WidgetTester tester,
    ) async {
      await open(tester, sample());
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(log, <String>['settings']);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('a quick tile works too', (WidgetTester tester) async {
      await open(tester, sample());
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(log, <String>['share']);
      expect(find.text('Share'), findsNothing);
    });

    testWidgets('an in-place item leaves the menu open', (
      WidgetTester tester,
    ) async {
      await open(tester, <MenuAction>[
        MenuAction(
          id: 'desktop',
          label: 'Desktop site',
          glyph: AppIcons.desktop,
          group: MenuGroup.page,
          closesMenu: false,
          onSelected: () => log.add('desktop'),
          trailing: PremiumToggle(value: false, onChanged: (bool _) {}),
        ),
      ]);
      await tester.tap(find.text('Desktop site'));
      await tester.pumpAndSettle();
      expect(log, <String>['desktop']);
      expect(find.text('Desktop site'), findsOneWidget);
    });

    testWidgets('a disabled item does nothing and stays open', (
      WidgetTester tester,
    ) async {
      await open(tester, <MenuAction>[
        const MenuAction(
          id: 'x',
          label: 'Find in page',
          glyph: AppIcons.search,
          group: MenuGroup.page,
        ),
      ]);
      await tester.tap(find.text('Find in page'));
      await tester.pumpAndSettle();
      expect(find.text('Find in page'), findsOneWidget);
    });

    testWidgets('an empty list draws just the sheet', (
      WidgetTester tester,
    ) async {
      await open(tester, const <MenuAction>[]);
      expect(find.byType(BrowserMenuSheet), findsOneWidget);
      expect(find.textContaining('THIS'), findsNothing);
    });
  });

  group('settings rows', () {
    Widget host(Widget child) =>
        testHost(Center(child: SizedBox(width: 360, child: child)));

    testWidgets('SettingTile shows its title, subtitle and value and taps', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        host(
          SettingTile(
            title: 'Search engine',
            subtitle: 'Used in the address bar',
            value: 'DuckDuckGo',
            glyph: AppIcons.search,
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.text('Search engine'), findsOneWidget);
      expect(find.text('Used in the address bar'), findsOneWidget);
      expect(find.text('DuckDuckGo'), findsOneWidget);
      await tester.tap(find.text('Search engine'));
      expect(taps, 1);
    });

    testWidgets('a disabled SettingTile has no chevron', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const SettingTile(title: 'Locked', onTap: null)),
      );
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('SettingSwitch flips from anywhere on the row', (
      WidgetTester tester,
    ) async {
      final List<bool> changes = <bool>[];
      await tester.pumpWidget(
        host(
          SettingSwitch(
            title: 'Save history',
            value: false,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.tap(find.text('Save history'));
      expect(changes, <bool>[true]);
      await tester.tap(find.byType(PremiumToggle));
      expect(changes, <bool>[true, true]);
    });

    testWidgets('SettingSwitch reports the opposite of its current value', (
      WidgetTester tester,
    ) async {
      final List<bool> changes = <bool>[];
      await tester.pumpWidget(
        host(
          SettingSwitch(
            title: 'HTTPS only',
            value: true,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.tap(find.text('HTTPS only'));
      expect(changes, <bool>[false]);
    });

    testWidgets('a disabled SettingSwitch ignores taps', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const SettingSwitch(title: 'Off', value: false, onChanged: null)),
      );
      await tester.tap(find.text('Off'));
    });

    testWidgets('SettingSwitch exposes its state to screen readers', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          SettingSwitch(
            title: 'Save history',
            subtitle: 'Off by default',
            value: true,
            onChanged: (bool _) {},
          ),
        ),
      );
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Save history, Off by default'),
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    group('SettingChoiceTile', () {
      const List<SettingChoice<String>> choices = <SettingChoice<String>>[
        SettingChoice<String>(value: 'a', label: 'Alpha'),
        SettingChoice<String>(value: 'b', label: 'Beta'),
      ];

      testWidgets('shows the current choice', (WidgetTester tester) async {
        await tester.pumpWidget(
          host(
            SettingChoiceTile<String>(
              title: 'Letter',
              choices: choices,
              value: 'b',
              onChanged: (String _) {},
            ),
          ),
        );
        expect(find.text('Beta'), findsOneWidget);
        expect(find.text('Alpha'), findsNothing);
      });

      testWidgets('an unknown value shows the first choice', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          host(
            SettingChoiceTile<String>(
              title: 'Letter',
              choices: choices,
              value: 'zzz',
              onChanged: (String _) {},
            ),
          ),
        );
        expect(find.text('Alpha'), findsOneWidget);
      });

      testWidgets(
        'opens a sheet, marks the current choice and applies a pick',
        (WidgetTester tester) async {
          final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
          final List<String> picked = <String>[];
          await tester.pumpWidget(
            routeHost(
              nav,
              (BuildContext c) => Center(
                child: SizedBox(
                  width: 360,
                  child: SettingChoiceTile<String>(
                    title: 'Letter',
                    choices: choices,
                    value: 'a',
                    onChanged: picked.add,
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Alpha'));
          await tester.pumpAndSettle();
          // The tile's own title and the sheet's title.
          expect(find.text('Letter'), findsNWidgets(2));
          expect(
            find.byKey(const ValueKey<String>('choice-Alpha')),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byKey(const ValueKey<String>('choice-Alpha')),
              matching: find.byType(Icon),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byKey(const ValueKey<String>('choice-Beta')),
              matching: find.byType(Icon),
            ),
            findsNothing,
          );
          await tester.tap(find.byKey(const ValueKey<String>('choice-Beta')));
          await tester.pumpAndSettle();
          expect(picked, <String>['b']);
          expect(
            find.byKey(const ValueKey<String>('choice-Beta')),
            findsNothing,
          );
        },
      );
    });
  });
}
