import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/motion.dart';

Future<Motion> motionWith(WidgetTester tester, {required bool reduce}) async {
  late Motion captured;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: Builder(
        builder: (BuildContext context) {
          captured = Motion.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('reduce-motion returns zero durations', (
    WidgetTester tester,
  ) async {
    final Motion m = await motionWith(tester, reduce: true);
    expect(m.push, Duration.zero);
    expect(m.pop, Duration.zero);
    expect(m.sheet, Duration.zero);
    expect(m.press, Duration.zero);
    expect(m.success, Duration.zero);
    expect(m.theme, Duration.zero);
  });

  testWidgets('normal motion follows the specification', (
    WidgetTester tester,
  ) async {
    final Motion m = await motionWith(tester, reduce: false);
    expect(m.push, const Duration(milliseconds: 350));
    expect(m.pop, const Duration(milliseconds: 280));
    expect(m.sheet, const Duration(milliseconds: 400));
    expect(m.press, const Duration(milliseconds: 150));
    expect(m.success, const Duration(milliseconds: 300));
    expect(m.theme, const Duration(milliseconds: 200));
  });

  testWidgets('without a MediaQuery the standard motion is used', (
    WidgetTester tester,
  ) async {
    late Motion captured;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          captured = Motion.of(context);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(captured, Motion.standard);
  });
}
