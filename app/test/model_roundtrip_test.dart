import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/app_constants.dart';
import 'package:tahorbrowser/core/models/app_settings.dart';
import 'package:tahorbrowser/core/models/tab_model.dart';

Map<String, Object?> viaJson(Map<String, Object?> map) =>
    (jsonDecode(jsonEncode(map)) as Map<String, dynamic>)
        .cast<String, Object?>();

void main() {
  group('AppSettings', () {
    test('defaults', () {
      const AppSettings s = AppSettings();
      expect(s.themeMode, AppThemeMode.system);
      expect(s.searchEngineId, AppConstants.defaultSearchEngineId);
      expect(s.localeCode, isNull);
    });

    test('toJson writes the schema version and every field', () {
      expect(const AppSettings().toJson(), <String, Object?>{
        'v': 1,
        'themeMode': 'system',
        'searchEngineId': 'duckduckgo',
        'localeCode': null,
      });
    });

    test('round-trips through JSON text', () {
      const AppSettings s = AppSettings(
        themeMode: AppThemeMode.dark,
        searchEngineId: 'brave',
        localeCode: 'de',
      );
      final AppSettings back = AppSettings.fromJson(viaJson(s.toJson()));
      expect(back, s);
      expect(back.hashCode, s.hashCode);
    });

    test('unknown fields are ignored and missing fields take defaults', () {
      final AppSettings s = AppSettings.fromJson(<String, Object?>{
        'themeMode': 'light',
        'somethingFromTheFuture': 42,
      });
      expect(s.themeMode, AppThemeMode.light);
      expect(s.searchEngineId, AppConstants.defaultSearchEngineId);
      expect(s.localeCode, isNull);
    });

    test('values of the wrong type or unknown names fall back to defaults', () {
      final AppSettings s = AppSettings.fromJson(<String, Object?>{
        'themeMode': 7,
        'searchEngineId': '',
        'localeCode': 12,
      });
      expect(s, const AppSettings());
      expect(
        AppSettings.fromJson(<String, Object?>{'themeMode': 'neon'}).themeMode,
        AppThemeMode.system,
      );
    });

    test('an empty map is the defaults', () {
      expect(AppSettings.fromJson(<String, Object?>{}), const AppSettings());
    });

    test('versionOf reads the saved version', () {
      expect(AppSettings.versionOf(<String, Object?>{'v': 1}), 1);
      expect(AppSettings.versionOf(<String, Object?>{'v': 'x'}), isNull);
      expect(AppSettings.versionOf(<String, Object?>{}), isNull);
    });

    test('copyWith changes only what is given', () {
      const AppSettings s = AppSettings(localeCode: 'fr');
      expect(s.copyWith(themeMode: AppThemeMode.dark).localeCode, 'fr');
      expect(s.copyWith(searchEngineId: 'bing').themeMode, AppThemeMode.system);
    });

    test('copyWith can clear the locale', () {
      const AppSettings s = AppSettings(localeCode: 'fr');
      expect(s.copyWith(localeCode: null).localeCode, isNull);
      expect(s.copyWith().localeCode, 'fr');
    });

    test('equality compares every field', () {
      expect(const AppSettings(), const AppSettings());
      expect(const AppSettings(), isNot(const AppSettings(localeCode: 'de')));
      expect(
        const AppSettings(),
        isNot(const AppSettings(themeMode: AppThemeMode.light)),
      );
    });
  });

  group('TabModel', () {
    const TabModel full = TabModel(
      id: 't1',
      url: 'https://example.com/a',
      title: 'Example',
      faviconUrl: 'https://example.com/icon.png',
      isIncognito: true,
      viewMode: TabViewMode.desktop,
      scrollY: 812.5,
      stateKey: 'state-t1',
    );

    test('defaults describe a blank mobile tab', () {
      const TabModel t = TabModel(id: 'x');
      expect(t.isBlank, isTrue);
      expect(t.url, '');
      expect(t.isIncognito, isFalse);
      expect(t.viewMode, TabViewMode.mobile);
      expect(t.scrollY, 0);
      expect(t.title, isNull);
      expect(t.stateKey, isNull);
    });

    test('round-trips through JSON text', () {
      final TabModel? back = TabModel.tryFromJson(viaJson(full.toJson()));
      expect(back, full);
      expect(back.hashCode, full.hashCode);
    });

    test('a tab without a usable id cannot be read', () {
      expect(TabModel.tryFromJson(<String, Object?>{'url': 'x'}), isNull);
      expect(TabModel.tryFromJson(<String, Object?>{'id': ''}), isNull);
      expect(TabModel.tryFromJson(<String, Object?>{'id': 5}), isNull);
      expect(TabModel.tryFromJson('not a map'), isNull);
      expect(TabModel.tryFromJson(null), isNull);
    });

    test('bad fields become defaults and the tab is kept', () {
      final TabModel? t = TabModel.tryFromJson(<String, Object?>{
        'id': 't2',
        'url': 9,
        'title': <Object?>[],
        'isIncognito': 'yes',
        'viewMode': 'tablet',
        'scrollY': -4,
        'stateKey': 3,
        'extra': true,
      });
      expect(t, const TabModel(id: 't2'));
    });

    test('scroll positions that are not finite numbers are dropped', () {
      expect(
        TabModel.tryFromJson(<String, Object?>{
          'id': 'a',
          'scrollY': double.nan,
        })!.scrollY,
        0,
      );
      expect(
        TabModel.tryFromJson(<String, Object?>{'id': 'a', 'scrollY': 12})!
            .scrollY,
        12,
      );
    });

    test('copyWith keeps the id and changes only what is given', () {
      final TabModel t = full.copyWith(url: 'https://example.com/b');
      expect(t.id, 't1');
      expect(t.url, 'https://example.com/b');
      expect(t.title, 'Example');
      expect(t.isIncognito, isTrue);
    });

    test('copyWith can clear the optional fields', () {
      final TabModel t = full.copyWith(
        title: null,
        faviconUrl: null,
        stateKey: null,
      );
      expect(t.title, isNull);
      expect(t.faviconUrl, isNull);
      expect(t.stateKey, isNull);
      expect(t.url, full.url);
    });

    test('equality compares every field', () {
      expect(full, full.copyWith());
      expect(full, isNot(full.copyWith(scrollY: 1)));
      expect(full, isNot(full.copyWith(viewMode: TabViewMode.mobile)));
      expect(full, isNot(full.copyWith(isIncognito: false)));
    });
  });
}
