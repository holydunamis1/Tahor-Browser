import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/widgets/core/icon_chip.dart';
import 'package:tahorbrowser/widgets/core/premium_card.dart';
import 'package:tahorbrowser/widgets/core/premium_row.dart';
import 'package:tahorbrowser/widgets/core/primary_button.dart';
import 'package:tahorbrowser/widgets/icons/semantic_icons.dart';

import 'support/test_host.dart';

void main() {
  Widget host(Widget child) =>
      testHost(Center(child: SizedBox(width: 320, child: child)));

  testWidgets('an icon chip announces its label as a button', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(IconChip(glyph: AppIcons.back, semanticLabel: 'Back', onTap: () {})),
    );
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Back'),
    );
    expect(node.label, 'Back');
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('cards, rows and buttons expose their text and a tap action', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PremiumCard(
              label: 'Search engine',
              value: 'DuckDuckGo',
              onTap: () {},
            ),
            PremiumRow(title: 'Bookmarks', onTap: () {}),
            PrimaryButton(label: 'Continue', onPressed: () {}),
          ],
        ),
      ),
    );
    for (final String text in <String>[
      'Search engine',
      'Bookmarks',
      'Continue',
    ]) {
      final SemanticsNode node = tester.getSemantics(find.text(text));
      expect(node.label, contains(text), reason: text);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: text,
      );
    }
    handle.dispose();
  });

  testWidgets('every control is at least 48 by 48', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconChip(glyph: AppIcons.back, semanticLabel: 'Back', onTap: () {}),
            PremiumCard(label: 'Card', onTap: () {}),
            PremiumRow(title: 'Row', onTap: () {}),
            PrimaryButton(label: 'Button', onPressed: () {}),
            TextActionButton(label: 'Text', onPressed: () {}),
          ],
        ),
      ),
    );
    for (final Type type in <Type>[
      IconChip,
      PremiumCard,
      PremiumRow,
      PrimaryButton,
      TextActionButton,
    ]) {
      final Size size = tester.getSize(find.byType(type));
      expect(size.height, greaterThanOrEqualTo(48), reason: '$type');
      expect(size.width, greaterThanOrEqualTo(48), reason: '$type');
    }
  });

  testWidgets('text scales to twice its size without overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testHost(
        Center(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PremiumCard(
                  leading: AppIcons.settings,
                  label: 'Search engine',
                  value: 'DuckDuckGo',
                  onTap: () {},
                ),
                PremiumRow(
                  title: 'Bookmarks',
                  subtitle: '12 saved',
                  onTap: () {},
                ),
                PrimaryButton(label: 'Continue', onPressed: () {}),
              ],
            ),
          ),
        ),
        media: const MediaQueryData(
          size: Size(800, 600),
          textScaler: TextScaler.linear(2),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
