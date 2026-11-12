import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/design_tokens.dart';
import 'package:tahorbrowser/core/models/app_settings.dart';
import 'package:tahorbrowser/core/theme/theme_builder.dart';
import 'package:tahorbrowser/widgets/browser/address_bar.dart';
import 'package:tahorbrowser/widgets/browser/browser_nav_bar.dart';

import 'support/test_app.dart';

void main() {
  AppTheme currentTheme(WidgetTester tester) =>
      tester.widget<AppTheme>(find.byType(AppTheme).first);

  testWidgets('the app boots with its address bar and navigation bar', (
    WidgetTester tester,
  ) async {
    await TestApp.pump(tester);
    expect(find.byType(AddressBar), findsOneWidget);
    expect(find.byType(BrowserNavBar), findsOneWidget);
    expect(find.text('Tahor Fast & Private Browser'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the theme follows the phone until the person chooses', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final TestApp app = await TestApp.pump(tester);
    expect(currentTheme(tester).data.palette, AppPalette.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(currentTheme(tester).data.palette, AppPalette.light);

    await app.deps.settings.setThemeMode(AppThemeMode.dark);
    await tester.pumpAndSettle();
    expect(currentTheme(tester).data.palette, AppPalette.dark);

    await app.deps.settings.setThemeMode(AppThemeMode.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(currentTheme(tester).data.palette, AppPalette.light);
  });

  testWidgets('the theme toggle changes the theme', (
    WidgetTester tester,
  ) async {
    final TestApp app = await TestApp.pump(tester);
    final bool before = currentTheme(tester).data.isDark;
    await app.deps.settings.setThemeMode(
      before ? AppThemeMode.light : AppThemeMode.dark,
    );
    await tester.pumpAndSettle();
    expect(currentTheme(tester).data.isDark, isNot(before));
  });

  testWidgets('text never shows the framework fallback style', (
    WidgetTester tester,
  ) async {
    await TestApp.pump(tester);
    final DefaultTextStyle style = tester.widget<DefaultTextStyle>(
      find.byType(DefaultTextStyle).first,
    );
    expect(style.style.decoration, isNot(TextDecoration.underline));
    expect(style.style.fontSize, 17);
  });
}
