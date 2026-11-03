import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/design_tokens.dart';
import 'package:tahorbrowser/core/theme/dark_theme.dart';
import 'package:tahorbrowser/widgets/core/premium_toggle.dart';

import 'support/test_host.dart';

void main() {
  Widget toggle({
    bool value = false,
    ValueChanged<bool>? onChanged,
    String? label,
    MediaQueryData media = defaultMedia,
  }) => testHost(
    Center(
      child: PremiumToggle(
        value: value,
        onChanged: onChanged,
        semanticLabel: label,
      ),
    ),
    media: media,
  );

  testWidgets('tapping reports the opposite value', (
    WidgetTester tester,
  ) async {
    final List<bool> changes = <bool>[];
    await tester.pumpWidget(toggle(onChanged: changes.add));
    await tester.tap(find.byType(PremiumToggle));
    expect(changes, <bool>[true]);

    changes.clear();
    await tester.pumpWidget(toggle(value: true, onChanged: changes.add));
    await tester.tap(find.byType(PremiumToggle));
    expect(changes, <bool>[false]);
  });

  testWidgets('a disabled toggle does nothing', (WidgetTester tester) async {
    await tester.pumpWidget(toggle());
    await tester.tap(find.byType(PremiumToggle));
    final Opacity opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(PremiumToggle),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, lessThan(1));
  });

  testWidgets('the hit area is at least 48 by 48', (WidgetTester tester) async {
    await tester.pumpWidget(toggle(onChanged: (bool _) {}));
    final Size size = tester.getSize(find.byType(PremiumToggle));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });

  testWidgets('a tap just outside the track but inside the hit area counts', (
    WidgetTester tester,
  ) async {
    final List<bool> changes = <bool>[];
    await tester.pumpWidget(toggle(onChanged: changes.add));
    final Offset top = tester.getTopLeft(find.byType(PremiumToggle));
    await tester.tapAt(top + const Offset(25, 3));
    expect(changes, <bool>[true]);
  });

  testWidgets('the thumb moves when the value changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(toggle(onChanged: (bool _) {}));
    await tester.pumpWidget(toggle(value: true, onChanged: (bool _) {}));
    await tester.pump(const Duration(milliseconds: 75));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduce-motion removes the animation', (
    WidgetTester tester,
  ) async {
    const MediaQueryData reduced = MediaQueryData(
      size: Size(800, 600),
      disableAnimations: true,
    );
    await tester.pumpWidget(toggle(onChanged: (bool _) {}, media: reduced));
    await tester.pumpWidget(
      toggle(value: true, onChanged: (bool _) {}, media: reduced),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('exposes its label and a tap action to screen readers', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      toggle(label: 'Wi-Fi only', onChanged: (bool _) {}),
    );
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Wi-Fi only'),
    );
    expect(node.label, 'Wi-Fi only');
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('works in dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      testHost(
        Center(child: PremiumToggle(value: true, onChanged: (bool _) {})),
        theme: darkTheme,
      ),
    );
    expect(find.byType(PremiumToggle), findsOneWidget);
    expect(AppPalette.dark.accent, isNot(AppPalette.light.accent));
  });
}
