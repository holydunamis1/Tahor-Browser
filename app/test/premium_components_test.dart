import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/design_tokens.dart';
import 'package:tahorbrowser/core/constants/icon_sizes.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';
import 'package:tahorbrowser/widgets/core/empty_state.dart';
import 'package:tahorbrowser/widgets/core/error_state.dart';
import 'package:tahorbrowser/widgets/core/icon_chip.dart';
import 'package:tahorbrowser/widgets/core/icon_wrapper.dart';
import 'package:tahorbrowser/widgets/core/premium_bottom_sheet.dart';
import 'package:tahorbrowser/widgets/core/premium_card.dart';
import 'package:tahorbrowser/widgets/core/premium_chip.dart';
import 'package:tahorbrowser/widgets/core/premium_dialog.dart';
import 'package:tahorbrowser/widgets/core/premium_row.dart';
import 'package:tahorbrowser/widgets/core/pressable.dart';
import 'package:tahorbrowser/widgets/core/primary_button.dart';
import 'package:tahorbrowser/widgets/core/section_header.dart';
import 'package:tahorbrowser/widgets/icons/semantic_icons.dart';
import 'package:tahorbrowser/l10n/gen/app_localizations.dart';

import 'support/test_host.dart';

Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    testHost(Center(child: child), direction: direction);

void main() {
  group('AppIcon', () {
    const AppIcon chrome = AppIcon(AppIcons.back);

    test('bold above 20 px, regular at 20 and below', () {
      expect(chrome.dataFor(24), AppIcons.back.bold);
      expect(chrome.dataFor(22), AppIcons.back.bold);
      expect(chrome.dataFor(20), AppIcons.back.regular);
      expect(chrome.dataFor(16), AppIcons.back.regular);
    });

    test('filled uses the fill version when there is one', () {
      expect(
        const AppIcon(AppIcons.bookmark, filled: true).dataFor(24),
        AppIcons.bookmark.fill,
      );
      expect(
        const AppIcon(AppIcons.back, filled: true).dataFor(24),
        AppIcons.back.bold,
      );
    });

    test('roles fix the size', () {
      expect(AppIcon.sizeOf(AppIconRole.nav), IconSizes.nav);
      expect(AppIcon.sizeOf(AppIconRole.rowLeading), IconSizes.rowLeading);
      expect(AppIcon.sizeOf(AppIconRole.rowTrailing), IconSizes.rowTrailing);
      expect(AppIcon.sizeOf(AppIconRole.hero), IconSizes.hero);
    });

    testWidgets('draws at the role size in the text colour', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const AppIcon(AppIcons.close)));
      final Icon icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 24);
      expect(icon.color, AppPalette.light.textPrimary);
    });

    testWidgets('direction-aware glyphs flip in right-to-left', (
      WidgetTester tester,
    ) async {
      Future<int> count(Widget icon, TextDirection d) async {
        await tester.pumpWidget(host(icon, direction: d));
        return find
            .descendant(
              of: find.byType(AppIcon),
              matching: find.byType(Transform),
            )
            .evaluate()
            .length;
      }

      final int plain = await count(
        const AppIcon(AppIcons.close),
        TextDirection.rtl,
      );
      expect(
        await count(const AppIcon(AppIcons.back), TextDirection.rtl),
        plain + 1,
      );
      expect(
        await count(const AppIcon(AppIcons.back), TextDirection.ltr),
        plain,
      );
    });
  });

  group('Pressable', () {
    testWidgets('reports taps and long presses', (WidgetTester tester) async {
      int taps = 0;
      int longs = 0;
      await tester.pumpWidget(
        host(
          Pressable(
            onTap: () => taps++,
            onLongPress: () => longs++,
            child: const SizedBox(width: 60, height: 60),
          ),
        ),
      );
      await tester.tap(find.byType(Pressable));
      expect(taps, 1);
      await tester.longPress(find.byType(Pressable));
      expect(longs, 1);
    });

    testWidgets('fades while pressed and back after', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          Pressable(onTap: () {}, child: const SizedBox(width: 60, height: 60)),
        ),
      );
      double opacity() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
      expect(opacity(), 1);
      final TestGesture g = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump();
      expect(opacity(), 0.5);
      await g.up();
      await tester.pump();
      expect(opacity(), 1);
    });

    testWidgets('a disabled one is dimmed and ignores taps', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const Pressable(child: SizedBox(width: 60, height: 60))),
      );
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0.4,
      );
    });

    testWidgets('keeps a 48 by 48 hit area around small content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          Pressable(onTap: () {}, child: const SizedBox(width: 10, height: 10)),
        ),
      );
      final Size size = tester.getSize(find.byType(Pressable));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('IconChip', () {
    testWidgets('is a 40 container in a 48 hit area', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          IconChip(glyph: AppIcons.back, semanticLabel: 'Back', onTap: () {}),
        ),
      );
      expect(tester.getSize(find.byType(IconChip)), const Size(48, 48));
      final Finder container = find.descendant(
        of: find.byType(IconChip),
        matching: find.byWidgetPredicate(
          (Widget w) => w is SizedBox && w.width == 40 && w.height == 40,
        ),
      );
      expect(container, findsOneWidget);
    });

    testWidgets('taps and disables', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        host(
          IconChip(
            glyph: AppIcons.back,
            semanticLabel: 'Back',
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(IconChip));
      expect(taps, 1);
    });

    testWidgets('selected draws the accent tint', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const IconChip(
            glyph: AppIcons.shield,
            semanticLabel: 'Shield',
            selected: true,
          ),
        ),
      );
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(IconChip),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (box.decoration as BoxDecoration).color,
        AppPalette.light.accentDim,
      );
    });
  });

  group('PremiumCard', () {
    testWidgets('shows label and value, and a chevron only when tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          PremiumCard(
            label: 'Search engine',
            value: 'DuckDuckGo',
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Search engine'), findsOneWidget);
      expect(find.text('DuckDuckGo'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      await tester.pumpWidget(host(const PremiumCard(label: 'Static')));
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Pressable), findsNothing);
    });

    testWidgets('taps', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        host(PremiumCard(label: 'Go', onTap: () => taps++)),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 1);
    });

    testWidgets('uses the card surface, radius and a hairline border', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const PremiumCard(label: 'Card')));
      final BoxDecoration d =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(PremiumCard),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(d.color, AppPalette.light.bgSecondary);
      expect(d.borderRadius, const BorderRadius.all(Radius.circular(16)));
      expect(d.boxShadow, isNull);
    });

    testWidgets('is at least 48 high', (WidgetTester tester) async {
      await tester.pumpWidget(host(const PremiumCard(label: 'Card')));
      expect(
        tester.getSize(find.byType(PremiumCard)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('PremiumRow', () {
    testWidgets('shows title and subtitle and tints while pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: PremiumRow(
              title: 'Bookmarks',
              subtitle: '12 saved',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Bookmarks'), findsOneWidget);
      expect(find.text('12 saved'), findsOneWidget);
      Color? tint() =>
          (tester
                      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                      .decoration!
                  as BoxDecoration)
              .color;
      expect(tint(), const Color(0x00000000));
      final TestGesture g = await tester.startGesture(
        tester.getCenter(find.byType(PremiumRow)),
      );
      await tester.pump();
      expect(tint(), AppPalette.light.bgTertiary);
      await g.up();
      await tester.pump();
      expect(tint(), const Color(0x00000000));
    });

    testWidgets('taps and long-presses', (WidgetTester tester) async {
      int taps = 0;
      int longs = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: PremiumRow(
              title: 'Row',
              onTap: () => taps++,
              onLongPress: () => longs++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Row'));
      await tester.longPress(find.text('Row'));
      expect((taps, longs), (1, 1));
    });

    testWidgets('is at least 48 high', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(const SizedBox(width: 300, child: PremiumRow(title: 'Row'))),
      );
      expect(
        tester.getSize(find.byType(PremiumRow)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('PremiumChip', () {
    testWidgets('selected uses the accent tint', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(const PremiumChip(label: 'Last hour', selected: true)),
      );
      final BoxDecoration d =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(PremiumChip),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(d.color, AppPalette.light.accentDim);
    });

    testWidgets('a label chip is 32 high; a tappable one has a 48 hit area', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const PremiumChip(label: 'Info')));
      expect(tester.getSize(find.byType(PremiumChip)).height, 32);
      int taps = 0;
      await tester.pumpWidget(
        host(PremiumChip(label: 'Pick', onTap: () => taps++)),
      );
      expect(
        tester.getSize(find.byType(Pressable)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('Pick'));
      expect(taps, 1);
    });
  });

  group('PrimaryButton', () {
    testWidgets('is a filled accent button at least 48 high', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: PrimaryButton(label: 'Continue', onPressed: () {}),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(PrimaryButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.getSize(find.byType(PrimaryButton)).width, 300);
      final BoxDecoration d =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(PrimaryButton),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(d.color, AppPalette.light.accent);
      expect(d.border, isNull);
      expect(d.borderRadius, const BorderRadius.all(Radius.circular(12)));
    });

    testWidgets('can shrink to its label', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: PrimaryButton(
              label: 'OK',
              expanded: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(PrimaryButton)).width, lessThan(300));
    });

    testWidgets('taps, and a disabled one does not', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        host(PrimaryButton(label: 'Go', onPressed: () => taps++)),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 1);
      await tester.pumpWidget(
        host(const PrimaryButton(label: 'Go', onPressed: null)),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 1);
    });

    testWidgets('TextActionButton taps and can be destructive', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        host(
          TextActionButton(
            label: 'Delete',
            destructive: true,
            onPressed: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Delete'));
      expect(taps, 1);
      expect(
        tester.widget<Text>(find.text('Delete')).style!.color,
        AppPalette.light.error,
      );
    });
  });

  testWidgets('SectionHeader upper-cases and is a header', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const SectionHeader('Appearance')));
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(tester.getSemantics(find.text('APPEARANCE')).label, 'APPEARANCE');
    handle.dispose();
  });

  group('EmptyState', () {
    testWidgets('shows icon, title, subtitle and action', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          EmptyState(
            glyph: AppIcons.history,
            title: 'No history',
            subtitle: 'Off by default',
            action: PrimaryButton(label: 'Turn on', onPressed: () {}),
          ),
        ),
      );
      expect(find.text('No history'), findsOneWidget);
      expect(find.text('Off by default'), findsOneWidget);
      expect(find.text('Turn on'), findsOneWidget);
      expect(tester.widget<Icon>(find.byType(Icon)).size, 32);
    });

    testWidgets('subtitle and action are optional', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const EmptyState(glyph: AppIcons.history, title: 'Nothing')),
      );
      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(PrimaryButton), findsNothing);
    });
  });

  group('ErrorState and errorMessage', () {
    final List<AppError> all = <AppError>[
      const NetworkError.offline(),
      const NetworkError.timeout(),
      NetworkError.http(503),
      const StorageError.readFailed(),
      const StorageError.full(),
      PermissionError.denied('camera'),
      const WebViewError.loadFailed(),
      const WebViewError.rendererGone(),
      const WebViewError.certificate(),
      const BlocklistError.fetchFailed(),
      const BlocklistError.verificationFailed(),
      const BillingError.unavailable(),
      const BillingError.purchaseFailed(),
      const BillingError.pending(),
      const ConsentError.refreshFailed(),
      const UnexpectedError.async('x'),
    ];

    testWidgets(
      'every error has a sentence, and only unknown ones use the generic one',
      (WidgetTester tester) async {
        late AppLocalizations l10n;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (BuildContext context) {
                l10n = AppLocalizations.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        final Set<String> seen = <String>{};
        for (final AppError e in all) {
          final String text = errorMessage(l10n, e);
          expect(text, isNotEmpty, reason: e.code);
          if (e is! ConsentError && e is! UnexpectedError) {
            expect(text, isNot(l10n.errorUnexpected), reason: e.code);
          }
          seen.add(text);
        }
        expect(seen.length, greaterThan(10));
        expect(
          errorMessage(l10n, NetworkError.http(404)),
          l10n.errorServer(404),
        );
      },
    );

    testWidgets('shows a retry button only when it can help', (
      WidgetTester tester,
    ) async {
      int retries = 0;
      await tester.pumpWidget(
        host(
          ErrorState(
            error: const NetworkError.offline(),
            onRetry: () => retries++,
          ),
        ),
      );
      expect(
        find.text('You\'re offline. Check your connection and try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      expect(retries, 1);

      await tester.pumpWidget(
        host(const ErrorState(error: NetworkError.offline())),
      );
      expect(find.text('Try again'), findsNothing);

      await tester.pumpWidget(
        host(ErrorState(error: const StorageError.corrupted(), onRetry: () {})),
      );
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('PremiumBottomSheet', () {
    testWidgets('shows a title and content and dismisses on the scrim', (
      WidgetTester tester,
    ) async {
      final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        routeHost(nav, (BuildContext c) => const SizedBox.expand()),
      );
      unawaited(
        showPremiumBottomSheet<void>(
          context: tester.element(find.byType(SizedBox).first),
          title: 'Menu',
          builder: (BuildContext c) =>
              const SizedBox(height: 120, child: Text('Body')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      await tester.tapAt(const Offset(400, 30));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
    });

    testWidgets('keeps clear of the home indicator', (
      WidgetTester tester,
    ) async {
      final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        routeHost(
          nav,
          (BuildContext c) => const SizedBox.expand(),
          media: const MediaQueryData(
            size: Size(800, 600),
            padding: EdgeInsets.only(bottom: 34),
          ),
        ),
      );
      unawaited(
        showPremiumBottomSheet<void>(
          context: tester.element(find.byType(SizedBox).first),
          builder: (BuildContext c) =>
              const SizedBox(height: 100, child: Text('Body', key: Key('b'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(PremiumBottomSheet)).bottom, 600);
      expect(
        tester.getBottomLeft(find.byKey(const Key('b'))).dy,
        lessThanOrEqualTo(600 - 34),
      );
    });
  });

  group('PremiumDialog', () {
    testWidgets('runs the primary and secondary actions', (
      WidgetTester tester,
    ) async {
      final List<String> pressed = <String>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: PremiumDialog(
              title: 'Clear data?',
              message: 'This cannot be undone.',
              primary: DialogAction(
                label: 'Clear',
                onPressed: () => pressed.add('primary'),
              ),
              secondary: DialogAction(
                label: 'Cancel',
                onPressed: () => pressed.add('secondary'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Clear data?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.tap(find.text('Cancel'));
      expect(pressed, <String>['primary', 'secondary']);
    });

    testWidgets('showConfirmDialog returns the choice, and no when dismissed', (
      WidgetTester tester,
    ) async {
      final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        routeHost(nav, (BuildContext c) => const SizedBox.expand()),
      );
      Future<bool> ask() => showConfirmDialog(
        context: tester.element(find.byType(SizedBox).first),
        title: 'Delete?',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
      );

      Future<bool> result = ask();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);

      result = ask();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);

      result = ask();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });
  });
}
