import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/design_tokens.dart';
import 'package:tahorbrowser/core/theme/app_theme_data.dart';
import 'package:tahorbrowser/core/theme/dark_theme.dart';
import 'package:tahorbrowser/core/theme/light_theme.dart';
import 'package:tahorbrowser/core/theme/theme_builder.dart';

void main() {
  test('forBrightness returns the matching theme', () {
    expect(AppThemeBuilder.forBrightness(Brightness.light), lightTheme);
    expect(AppThemeBuilder.forBrightness(Brightness.dark), darkTheme);
  });

  test('the dark theme has no shadows and the light theme has some', () {
    expect(darkTheme.shadows.subtle, isEmpty);
    expect(darkTheme.shadows.sheet, isEmpty);
    expect(lightTheme.shadows.subtle, isNotEmpty);
    expect(darkTheme.isDark, isTrue);
    expect(lightTheme.isDark, isFalse);
  });

  testWidgets('AppTheme.of finds the theme above the context', (
    WidgetTester tester,
  ) async {
    late AppThemeData found;
    await tester.pumpWidget(
      AppTheme(
        data: darkTheme,
        child: Builder(
          builder: (BuildContext context) {
            found = AppTheme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(found.palette, AppPalette.dark);
  });

  testWidgets('dependants rebuild when the theme changes', (
    WidgetTester tester,
  ) async {
    int builds = 0;
    Widget app(AppThemeData data) => AppTheme(
      data: data,
      child: Builder(
        builder: (BuildContext context) {
          AppTheme.of(context);
          builds++;
          return const SizedBox.shrink();
        },
      ),
    );
    await tester.pumpWidget(app(lightTheme));
    await tester.pumpWidget(app(darkTheme));
    expect(builds, 2);
  });

  testWidgets('AppTheme.of throws a clear error without a theme', (
    WidgetTester tester,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(() => AppTheme.of(captured), throwsA(isA<FlutterError>()));
    expect(AppTheme.maybeOf(captured), isNull);
  });
}
