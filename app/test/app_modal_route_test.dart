import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/design_tokens.dart';
import 'package:tahorbrowser/core/theme/dark_theme.dart';
import 'package:tahorbrowser/widgets/core/app_modal_route.dart';

import 'support/test_host.dart';

void main() {
  late GlobalKey<NavigatorState> navKey;

  Future<void> pumpApp(WidgetTester tester, {bool dark = false}) async {
    navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      routeHost(
        navKey,
        (BuildContext context) => const SizedBox.expand(),
        theme: dark ? darkTheme : routeHostDefaultTheme,
      ),
    );
  }

  BuildContext homeContext(WidgetTester tester) =>
      tester.element(find.byType(SizedBox).first);

  Future<void> openSheet(
    WidgetTester tester, {
    bool dismissible = true,
    bool drag = true,
  }) async {
    unawaited(
      showAppSheet<void>(
        context: homeContext(tester),
        isDismissible: dismissible,
        enableDrag: drag,
        dismissLabel: 'Dismiss',
        builder: (BuildContext context) => const SizedBox(
          height: 200,
          width: double.infinity,
          child: Center(child: Text('Sheet')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a sheet appears at the bottom', (WidgetTester tester) async {
    await pumpApp(tester);
    await openSheet(tester);
    expect(find.text('Sheet'), findsOneWidget);
    expect(tester.getBottomLeft(find.text('Sheet')).dy, lessThanOrEqualTo(600));
    expect(tester.getCenter(find.text('Sheet')).dy, greaterThan(450));
  });

  testWidgets('the scrim uses the theme token', (WidgetTester tester) async {
    await pumpApp(tester);
    await openSheet(tester);
    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
      AppPalette.light.scrim,
    );
  });

  testWidgets('the scrim is darker in dark mode', (WidgetTester tester) async {
    await pumpApp(tester, dark: true);
    await openSheet(tester);
    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
      AppPalette.dark.scrim,
    );
  });

  testWidgets('tapping the scrim dismisses a dismissible sheet', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openSheet(tester);
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsNothing);
  });

  testWidgets('a sheet that is not dismissible ignores the scrim', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openSheet(tester, dismissible: false);
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsOneWidget);
  });

  testWidgets('dragging a sheet down dismisses it', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openSheet(tester);
    await tester.drag(find.text('Sheet'), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsNothing);
    expect(navKey.currentState!.userGestureInProgress, isFalse);
  });

  testWidgets('a small drag settles back', (WidgetTester tester) async {
    await pumpApp(tester);
    await openSheet(tester);
    await tester.drag(find.text('Sheet'), const Offset(0, 30));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsOneWidget);
    expect(navKey.currentState!.userGestureInProgress, isFalse);
  });

  testWidgets('drag can be switched off', (WidgetTester tester) async {
    await pumpApp(tester);
    await openSheet(tester, drag: false);
    await tester.drag(find.text('Sheet'), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsOneWidget);
  });

  testWidgets('a dialog is centred and fades', (WidgetTester tester) async {
    await pumpApp(tester);
    unawaited(
      showAppDialog<void>(
        context: homeContext(tester),
        builder: (BuildContext context) => const SizedBox(
          height: 100,
          width: 200,
          child: Center(child: Text('Dialog')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final FadeTransition fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Dialog'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.text('Dialog')), const Offset(400, 300));
  });

  testWidgets('the dismiss label reaches the barrier', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await openSheet(tester);
    expect(
      tester
          .widget<ModalBarrier>(find.byType(ModalBarrier).last)
          .semanticsLabel,
      'Dismiss',
    );
  });
}
