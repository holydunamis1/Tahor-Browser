import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/widgets/core/app_page_route.dart';

import 'support/test_host.dart';

void main() {
  late GlobalKey<NavigatorState> navKey;

  Future<void> pumpApp(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
    MediaQueryData media = defaultMedia,
  }) async {
    navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      routeHost(
        navKey,
        (BuildContext context) => const Center(child: Text('Home')),
        direction: direction,
        media: media,
      ),
    );
  }

  Future<void> pushSecond(WidgetTester tester) async {
    unawaited(
      navKey.currentState!.push<void>(
        AppPageRoute<void>(
          builder: (BuildContext context) =>
              const Center(child: Text('Second')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a pushed page appears', (WidgetTester tester) async {
    await pumpApp(tester);
    await pushSecond(tester);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('the page fades in while it slides', (WidgetTester tester) async {
    await pumpApp(tester);
    unawaited(
      navKey.currentState!.push<void>(
        AppPageRoute<void>(
          builder: (BuildContext context) =>
              const Center(child: Text('Second')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final FadeTransition fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Second'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    final FadeTransition done = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Second'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(done.opacity.value, 1);
  });

  testWidgets('durations follow the specification', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await pushSecond(tester);
    final AppPageRoute<void> route =
        ModalRoute.of(tester.element(find.text('Second')))!
            as AppPageRoute<void>;
    expect(route.transitionDuration, const Duration(milliseconds: 350));
    expect(route.reverseTransitionDuration, const Duration(milliseconds: 280));
  });

  testWidgets('reduce-motion makes the transition instant', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      media: const MediaQueryData(
        size: Size(800, 600),
        disableAnimations: true,
      ),
    );
    await pushSecond(tester);
    final AppPageRoute<void> route =
        ModalRoute.of(tester.element(find.text('Second')))!
            as AppPageRoute<void>;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
  });

  testWidgets('a long swipe from the start edge goes back', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await pushSecond(tester);
    await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a short swipe snaps back and stays', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await pushSecond(tester);
    await tester.dragFrom(const Offset(4, 300), const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
    expect(navKey.currentState!.userGestureInProgress, isFalse);
  });

  testWidgets('in right-to-left layouts the swipe starts at the right edge', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, direction: TextDirection.rtl);
    await pushSecond(tester);
    await tester.dragFrom(const Offset(796, 300), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('a swipe from the middle of the page does not go back', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await pushSecond(tester);
    await tester.dragFrom(const Offset(400, 300), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('the first page cannot be swiped away', (
    WidgetTester tester,
  ) async {
    navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      routeHost(
        navKey,
        (BuildContext context) => const Center(child: Text('Home')),
        onGenerateRoute: (RouteSettings s) => AppPageRoute<void>(
          settings: s,
          builder: (BuildContext context) => const Center(child: Text('Home')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
