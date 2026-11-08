import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/models/app_settings.dart';
import 'package:tahorbrowser/core/services/settings_service.dart';

import 'support/fakes.dart';

void main() {
  test('with nothing saved the defaults load', () async {
    final SettingsService service = SettingsService(FakeKeyValueStore());
    expect(await service.load(), const AppSettings());
  });

  test('saved settings load back', () async {
    final FakeKeyValueStore store = FakeKeyValueStore();
    final SettingsService service = SettingsService(store);
    const AppSettings saved = AppSettings(
      themeMode: AppThemeMode.dark,
      searchEngineId: 'brave',
      localeCode: 'de',
    );
    await service.save(saved);
    expect(await service.load(), saved);
  });

  test('a corrupt value is discarded and the defaults load', () async {
    final FakeKeyValueStore store = FakeKeyValueStore(<String, Object>{
      SettingsService.storageKey: '{not json',
    });
    final SettingsService service = SettingsService(store);
    expect(await service.load(), const AppSettings());
    expect(store.data.containsKey(SettingsService.storageKey), isFalse);
  });

  test(
    'a value saved by a newer app still loads what it understands',
    () async {
      final FakeKeyValueStore store = FakeKeyValueStore(<String, Object>{
        SettingsService.storageKey: <String, Object?>{
          'v': 99,
          'themeMode': 'light',
          'fromTheFuture': true,
        },
      });
      final AppSettings s = await SettingsService(store).load();
      expect(s.themeMode, AppThemeMode.light);
    },
  );

  test('it reports when the store has failed', () {
    final FakeKeyValueStore store = FakeKeyValueStore();
    final SettingsService service = SettingsService(store);
    expect(service.persistenceFailed, isFalse);
    store.failed = true;
    expect(service.persistenceFailed, isTrue);
  });
}
