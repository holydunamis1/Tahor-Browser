import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/design_tokens.dart';
import 'package:tahorbrowser/core/theme/dark_theme.dart';
import 'package:tahorbrowser/widgets/core/app_scaffold.dart';

import 'support/test_host.dart';

class Counter extends StatefulWidget {
  const Counter({super.key});

  static int created = 0;

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  @override
  void initState() {
    super.initState();
    Counter.created++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 60);
}

void main() {
  const Key topKey = Key('top');
  const Key bodyKey = Key('body');
  const Key bottomKey = Key('bottom');

  Widget scaffold({BottomChromeBehavior? behavior, Widget? bottom}) {
    return AppScaffold(
      top: const SizedBox(key: topKey, height: 50),
      body: const SizedBox.expand(key: bodyKey),
      bottom: bottom ?? const SizedBox(key: bottomKey, height: 60),
      bottomBehavior: behavior ?? BottomChromeBehavior.hideWithKeyboard,
    );
  }

  testWidgets('applies the safe area on every edge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testHost(
        scaffold(),
        media: const MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.fromLTRB(10, 24, 12, 34),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byKey(topKey)), const Offset(10, 24));
    expect(tester.getTopRight(find.byKey(topKey)).dx, 800 - 12);
    expect(tester.getBottomLeft(find.byKey(bottomKey)).dy, 600 - 34);
    expect(tester.getTopLeft(find.byKey(bodyKey)).dy, 24 + 50);
    expect(tester.getBottomLeft(find.byKey(bodyKey)).dy, 600 - 34 - 60);
  });

  testWidgets('paints the background token', (WidgetTester tester) async {
    await tester.pumpWidget(testHost(scaffold(), theme: darkTheme));
    final ColoredBox box = tester.widget<ColoredBox>(
      find.byType(ColoredBox).first,
    );
    expect(box.color, AppPalette.dark.bgPrimary);
  });

  testWidgets('a keyboard leaves the bottom chrome out of the layout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testHost(
        scaffold(),
        media: const MediaQueryData(
          size: Size(800, 600),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
      ),
    );
    expect(find.byKey(bottomKey), findsNothing);
    expect(tester.getBottomLeft(find.byKey(bodyKey)).dy, 600 - 300);
  });

  testWidgets('the bottom chrome keeps its state across the keyboard', (
    WidgetTester tester,
  ) async {
    Counter.created = 0;
    Widget build(double keyboard) => testHost(
      scaffold(bottom: const Counter()),
      media: MediaQueryData(
        size: const Size(800, 600),
        viewInsets: EdgeInsets.only(bottom: keyboard),
      ),
    );
    await tester.pumpWidget(build(0));
    await tester.pumpWidget(build(300));
    await tester.pumpWidget(build(0));
    expect(Counter.created, 1);
  });

  testWidgets('chrome can stay above the keyboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testHost(
        scaffold(behavior: BottomChromeBehavior.stayAboveKeyboard),
        media: const MediaQueryData(
          size: Size(800, 600),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
      ),
    );
    expect(find.byKey(bottomKey), findsOneWidget);
    expect(tester.getBottomLeft(find.byKey(bottomKey)).dy, 600 - 300);
  });

  testWidgets('the body gets no inset of its own', (WidgetTester tester) async {
    late EdgeInsets padding;
    late EdgeInsets insets;
    await tester.pumpWidget(
      testHost(
        AppScaffold(
          body: Builder(
            builder: (BuildContext context) {
              padding = MediaQuery.paddingOf(context);
              insets = MediaQuery.viewInsetsOf(context);
              return const SizedBox.expand();
            },
          ),
        ),
        media: const MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.only(top: 24, bottom: 34),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
      ),
    );
    expect(padding, EdgeInsets.zero);
    expect(insets, EdgeInsets.zero);
  });
}
