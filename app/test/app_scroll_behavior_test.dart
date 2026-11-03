import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/widgets/core/app_scroll_behavior.dart';

void main() {
  const AppScrollBehavior behavior = AppScrollBehavior();

  testWidgets('uses iOS-style bouncing physics', (WidgetTester tester) async {
    late ScrollPhysics physics;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          physics = behavior.getScrollPhysics(context);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(physics, isA<BouncingScrollPhysics>());
  });

  testWidgets('adds no glow and no scrollbar', (WidgetTester tester) async {
    const Widget child = SizedBox(key: Key('child'));
    late Widget overscroll;
    late Widget scrollbar;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          const ScrollableDetails details = ScrollableDetails.vertical();
          overscroll = behavior.buildOverscrollIndicator(
            context,
            child,
            details,
          );
          scrollbar = behavior.buildScrollbar(context, child, details);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(identical(overscroll, child), isTrue);
    expect(identical(scrollbar, child), isTrue);
  });

  test('every pointer kind can drag', () {
    expect(
      behavior.dragDevices,
      containsAll(<PointerDeviceKind>[
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
      ]),
    );
  });

  testWidgets('a list scrolls and bounces past its end', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(400, 400)),
          child: ScrollConfiguration(
            behavior: behavior,
            child: ListView(
              controller: controller,
              children: <Widget>[
                for (int i = 0; i < 20; i++)
                  SizedBox(height: 100, child: Text('row $i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pump();
    expect(
      controller.position.pixels,
      greaterThan(controller.position.maxScrollExtent),
    );
    await tester.pumpAndSettle();
    expect(controller.position.pixels, controller.position.maxScrollExtent);
  });
}
