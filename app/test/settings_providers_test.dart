import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/models/app_settings.dart';
import 'package:tahorbrowser/core/providers/locale_provider.dart';
import 'package:tahorbrowser/core/providers/settings_provider.dart';
import 'package:tahorbrowser/core/providers/theme_provider.dart';
import 'package:tahorbrowser/core/services/settings_service.dart';
import 'package:tahorbrowser/core/theme/dark_theme.dart';
import 'package:tahorbrowser/core/theme/light_theme.dart';

import 'support/fakes.dart';

class ThrowingStore extends FakeKeyValueStore {
  @override
  Future<void> setJson(String key, Map<String, Object?> value) =>
      throw Exception('disk full');
}

void main() {
  late FakeKeyValueStore store;
  late SettingsProvider settings;

  setUp(() {
    store = FakeKeyValueStore();
    settings = SettingsProvider(service: SettingsService(store));
  });

  group('SettingsProvider', () {
    test('starts with the defaults', () {
      expect(settings.value, const AppSettings());
    });

    test('a change is visible at once and then saved', () async {
      final Future<void> saved = settings.setThemeMode(AppThemeMode.dark);
      expect(settings.value.themeMode, AppThemeMode.dark);
      await saved;
      expect(
        (await SettingsService(store).load()).themeMode,
        AppThemeMode.dark,
      );
    });

    test('each setter changes only its own field', () async {
      await settings.setSearchEngine('brave');
      await settings.setLocale('fr');
      await settings.setThemeMode(AppThemeMode.light);
      expect(
        settings.value,
        const AppSettings(
          themeMode: AppThemeMode.light,
          searchEngineId: 'brave',
          localeCode: 'fr',
        ),
      );
      await settings.setLocale(null);
      expect(settings.value.localeCode, isNull);
    });

    test('listeners hear about a change once, and not about a no-op', () async {
      int heard = 0;
      settings.addListener(() => heard++);
      await settings.setThemeMode(AppThemeMode.dark);
      await settings.setThemeMode(AppThemeMode.dark);
      expect(heard, 1);
    });

    test('quick changes are saved in order, so the last one wins', () async {
      final Future<void> a = settings.setThemeMode(AppThemeMode.dark);
      final Future<void> b = settings.setThemeMode(AppThemeMode.light);
      await Future.wait<void>(<Future<void>>[a, b]);
      expect(
        (await SettingsService(store).load()).themeMode,
        AppThemeMode.light,
      );
    });

    test('load reads what was saved', () async {
      await SettingsService(store)
          .save(const AppSettings(searchEngineId: 'bing'));
      await settings.load();
      expect(settings.value.searchEngineId, 'bing');
    });

    test('a save that throws is reported, and the change stays', () async {
      final SettingsProvider broken = SettingsProvider(
        service: SettingsService(ThrowingStore()),
      );
      expect(broken.persistenceFailed.value, isFalse);
      await broken.setThemeMode(AppThemeMode.dark);
      expect(broken.persistenceFailed.value, isTrue);
      expect(broken.value.themeMode, AppThemeMode.dark);
    });

    test('a failed store is reported after a save', () async {
      store.failed = true;
      await settings.setThemeMode(AppThemeMode.dark);
      expect(settings.persistenceFailed.value, isTrue);
    });
  });

  group('ThemeProvider', () {
    test('follows the phone unless the person chose', () async {
      final ThemeProvider theme = ThemeProvider(settings);
      expect(theme.mode, AppThemeMode.system);
      expect(theme.themeFor(Brightness.light), lightTheme);
      expect(theme.themeFor(Brightness.dark), darkTheme);
      await settings.setThemeMode(AppThemeMode.dark);
      expect(theme.themeFor(Brightness.light), darkTheme);
      await settings.setThemeMode(AppThemeMode.light);
      expect(theme.themeFor(Brightness.dark), lightTheme);
    });

    test('notifies only when the theme choice changes', () async {
      final ThemeProvider theme = ThemeProvider(settings);
      int heard = 0;
      theme.addListener(() => heard++);
      await settings.setSearchEngine('bing');
      expect(heard, 0);
      await settings.setThemeMode(AppThemeMode.dark);
      expect(heard, 1);
    });

    test('stops listening when disposed', () async {
      final ThemeProvider theme = ThemeProvider(settings);
      theme.dispose();
      await settings.setThemeMode(AppThemeMode.dark);
    });
  });

  group('LocaleProvider', () {
    test('is null for the phone language and a locale once chosen', () async {
      final LocaleProvider locale = LocaleProvider(settings);
      expect(locale.locale, isNull);
      await settings.setLocale('ar');
      expect(locale.locale, const Locale('ar'));
      await settings.setLocale(null);
      expect(locale.locale, isNull);
    });

    test('notifies only when the language choice changes', () async {
      final LocaleProvider locale = LocaleProvider(settings);
      int heard = 0;
      locale.addListener(() => heard++);
      await settings.setThemeMode(AppThemeMode.dark);
      expect(heard, 0);
      await settings.setLocale('de');
      expect(heard, 1);
    });
  });
}
