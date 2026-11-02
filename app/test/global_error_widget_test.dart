import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/design_tokens.dart';
import 'package:tahorbrowser/core/error/global_error_widget.dart';
import 'package:tahorbrowser/core/theme/dark_theme.dart';
import 'package:tahorbrowser/core/theme/theme_builder.dart';

class Boom extends StatelessWidget {
  const Boom({super.key});

  @override
  Widget build(BuildContext context) => throw StateError('broken build');
}

void main() {
  Widget view({VoidCallback? onRetry, void Function(String)? onReport}) {
    return GlobalErrorView(
      code: 'network.offline',
      onRetry: onRetry ?? () {},
      onReport: onReport ?? (String _) {},
    );
  }

  group('GlobalErrorView', () {
    testWidgets('shows the message, the buttons and the error code', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(view());
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Send error code'), findsOneWidget);
      expect(find.text('Error code: network.offline'), findsOneWidget);
    });

    testWidgets('Try again calls onRetry', (WidgetTester tester) async {
      int retries = 0;
      await tester.pumpWidget(view(onRetry: () => retries++));
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('Send error code passes only the code', (
      WidgetTester tester,
    ) async {
      final List<String> reported = <String>[];
      await tester.pumpWidget(view(onReport: reported.add));
      await tester.tap(find.text('Send error code'));
      expect(reported, <String>['network.offline']);
    });

    testWidgets('uses the surrounding theme', (WidgetTester tester) async {
      await tester.pumpWidget(AppTheme(data: darkTheme, child: view()));
      final ColoredBox box = tester.widget<ColoredBox>(
        find.byType(ColoredBox).first,
      );
      expect(box.color, AppPalette.dark.bgPrimary);
    });

    testWidgets('works with no theme at all', (WidgetTester tester) async {
      await tester.pumpWidget(view());
      final ColoredBox box = tester.widget<ColoredBox>(
        find.byType(ColoredBox).first,
      );
      expect(box.color, AppPalette.light.bgPrimary);
    });

    testWidgets('buttons are at least 48 high', (WidgetTester tester) async {
      await tester.pumpWidget(view());
      expect(tester.getSize(find.text('Try again')).height, greaterThan(0));
      final Size retry = tester.getSize(
        find
            .ancestor(
              of: find.text('Try again'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(retry.height, greaterThanOrEqualTo(48));
    });

    testWidgets('accepts translated strings', (WidgetTester tester) async {
      await tester.pumpWidget(
        GlobalErrorView(
          code: 'x.y',
          onRetry: () {},
          onReport: (String _) {},
          strings: const GlobalErrorStrings(
            title: 'Titel',
            message: 'Nachricht',
            retry: 'Erneut',
            report: 'Senden',
            codeLabel: 'Code',
          ),
        ),
      );
      expect(find.text('Titel'), findsOneWidget);
      expect(find.text('Code: x.y'), findsOneWidget);
    });
  });

  test('reportUri carries the code and encodes spaces as %20', () {
    final Uri uri = GlobalErrorView.reportUri('network.offline');
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'stmakarios@gmail.com');
    expect(uri.queryParameters['subject'], 'Tahor error report');
    expect(uri.queryParameters['body'], 'Error code: network.offline');
    expect(uri.toString(), contains('%20'));
    expect(uri.toString(), isNot(contains('+')));
  });

  testWidgets('installErrorWidget replaces a failed widget with the fallback', (
    WidgetTester tester,
  ) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    addTearDown(() => ErrorWidget.builder = original);
    installErrorWidget(onRetry: () {}, onReport: (String _) {});

    await tester.pumpWidget(const Boom());
    expect(tester.takeException(), isA<StateError>());
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Error code: unexpected.build'), findsOneWidget);
  });
}
