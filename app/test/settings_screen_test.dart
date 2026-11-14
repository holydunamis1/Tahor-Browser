import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/models/app_settings.dart';
import 'package:tahorbrowser/core/services/settings_service.dart';
import 'package:tahorbrowser/core/theme/theme_builder.dart';
import 'package:tahorbrowser/screens/settings_screen.dart';
import 'package:tahorbrowser/widgets/core/icon_chip.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

void main() {
  Finder chip(String label) => find.byWidgetPredicate(
    (Widget w) => w is IconChip && w.semanticLabel == label,
  );

  /// What is stored, after letting the background save finish.
  Future<AppSettings> savedSettings(
    WidgetTester tester,
    FakeKeyValueStore store,
  ) async {
    for (int i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    return (await tester.runAsync(() => SettingsService(store).load()))!;
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(chip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
  }

  appTest('opens from the menu and shows its sections', (
    WidgetTester tester,
  ) async {
    await TestApp.pump(tester);
    await openSettings(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('SEARCH'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Search engine'), findsOneWidget);
    expect(find.text('DuckDuckGo'), findsOneWidget);
  });

  appTest('the Back chip returns to the browser', (WidgetTester tester) async {
    await TestApp.pump(tester);
    await openSettings(tester);
    await tester.tap(chip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
  });

  appTest('choosing a theme applies it at once and saves it', (
    WidgetTester tester,
  ) async {
    final TestApp app = await TestApp.pump(tester);
    await openSettings(tester);
    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('choice-Dark')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AppTheme>(find.byType(AppTheme).first).data.isDark,
      isTrue,
    );
    expect(find.text('Dark'), findsOneWidget);
    final AppSettings saved = await tester.runAsync(
      () => SettingsService(app.store).load(),
    ) as AppSettings;
    expect(saved.themeMode, AppThemeMode.dark);
  });

  appTest('choosing a search engine changes where searches go', (
    WidgetTester tester,
  ) async {
    final TestApp app = await TestApp.pump(tester);
    await openSettings(tester);
    await tester.tap(find.text('DuckDuckGo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('choice-Brave Search')));
    await tester.pumpAndSettle();
    expect(find.text('Brave Search'), findsOneWidget);
    expect(app.deps.settings.value.searchEngineId, 'brave');

    await tester.tap(chip('Back'));
    await tester.pumpAndSettle();
    expect(
      app.deps.tabs.navigate('cats').uri.toString(),
      'https://search.brave.com/search?q=cats',
    );
  });

  appTest('the chosen settings are there after a restart', (
    WidgetTester tester,
  ) async {
    final TestApp first = await TestApp.pump(tester);
    await first.deps.settings.setThemeMode(AppThemeMode.dark);
    await first.deps.settings.setSearchEngine('bing');
    await tester.pumpWidget(const SizedBox());
    final TestApp second = await TestApp.pump(tester, store: first.store);
    expect(second.deps.settings.value.themeMode, AppThemeMode.dark);
    expect(second.deps.settings.value.searchEngineId, 'bing');
    expect(
      tester.widget<AppTheme>(find.byType(AppTheme).first).data.isDark,
      isTrue,
    );
  });
}
