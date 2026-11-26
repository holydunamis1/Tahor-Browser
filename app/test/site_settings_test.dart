import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/models/site_setting.dart';
import 'package:tahorbrowser/core/providers/site_settings_provider.dart';
import 'package:tahorbrowser/core/providers/tabs_provider.dart';
import 'package:tahorbrowser/core/constants/app_constants.dart';
import 'package:tahorbrowser/core/services/site_settings_service.dart';
import 'package:tahorbrowser/core/storage/persistence_guard.dart';

import 'support/fakes.dart';

void main() {
  group('SiteSetting', () {
    test('hosts are lower case, without a trailing dot or www', () {
      expect(SiteSetting.normalizeHost('WWW.Example.COM.'), 'example.com');
      expect(
        SiteSetting.normalizeHost(' news.example.com '),
        'news.example.com',
      );
      expect(SiteSetting.normalizeHost('www.'), '');
    });

    test('a site with no overrides is the default', () {
      expect(SiteSetting.defaultsFor('A.com').isDefault, isTrue);
      expect(SiteSetting.defaultsFor('A.com').host, 'a.com');
      expect(
        const SiteSetting(host: 'a.com', adblockEnabled: false).isDefault,
        isFalse,
      );
      expect(
        const SiteSetting(host: 'a.com', desktopMode: false).isDefault,
        isFalse,
      );
      expect(
        const SiteSetting(host: 'a.com', camera: SitePermission.deny).isDefault,
        isFalse,
      );
    });

    test('a row survives toRow and fromRow', () {
      final SiteSetting s = SiteSetting(
        host: 'a.com',
        jsEnabled: false,
        desktopMode: true,
        adblockEnabled: false,
        camera: SitePermission.allow,
        microphone: SitePermission.deny,
        updatedAt: DateTime.utc(2026, 11, 23),
      );
      expect(SiteSetting.fromRow(s.toRow()), s);
    });

    test('desktop mode keeps three states', () {
      for (final bool? mode in <bool?>[null, true, false]) {
        final SiteSetting s = SiteSetting(host: 'a.com', desktopMode: mode);
        expect(SiteSetting.fromRow(s.toRow())!.desktopMode, mode);
      }
    });

    test('a damaged row is not a setting, and odd values fall back', () {
      expect(SiteSetting.fromRow(<String, Object?>{'js_enabled': 1}), isNull);
      expect(SiteSetting.fromRow(<String, Object?>{'host': ''}), isNull);
      final SiteSetting s = SiteSetting.fromRow(<String, Object?>{
        'host': 'a.com',
        'camera': 99,
        'js_enabled': 'x',
      })!;
      expect(s.camera, SitePermission.ask);
      expect(s.jsEnabled, isTrue);
    });

    test('copyWith can clear desktop mode', () {
      final SiteSetting s = const SiteSetting(
        host: 'a.com',
        desktopMode: true,
      ).copyWith(desktopMode: null);
      expect(s.desktopMode, isNull);
    });
  });

  group('SiteSettingsService', () {
    late FakeSiteDatabase db;
    late PersistenceGuard guard;
    late SiteSettingsService service;

    setUp(() {
      db = FakeSiteDatabase();
      guard = PersistenceGuard();
      service = SiteSettingsService(
        db,
        guard,
        clock: () => DateTime.utc(2026, 11, 23),
      );
    });

    test('an unknown site has the defaults', () async {
      await service.load();
      expect(service.get('new.com').isDefault, isTrue);
      expect(service.overrides, isEmpty);
    });

    test(
      'a saved override is stamped, stored and found under any spelling',
      () async {
        await service.save(
          SiteSetting.defaultsFor('a.com').copyWith(adblockEnabled: false),
        );
        expect(service.get('WWW.A.com').adblockEnabled, isFalse);
        expect(service.get('a.com').updatedAt, DateTime.utc(2026, 11, 23));
        expect(db.rows.keys, <String>['a.com']);
      },
    );

    test('saving the defaults removes the row instead', () async {
      await service.save(
        SiteSetting.defaultsFor('a.com').copyWith(adblockEnabled: false),
      );
      await service.save(SiteSetting.defaultsFor('a.com'));
      expect(db.rows, isEmpty);
      expect(service.overrides, isEmpty);
    });

    test('settings are read back after a restart, sorted by host', () async {
      await service.save(
        SiteSetting.defaultsFor('b.com').copyWith(jsEnabled: false),
      );
      await service.save(
        SiteSetting.defaultsFor('a.com').copyWith(adblockEnabled: false),
      );
      final SiteSettingsService again = SiteSettingsService(db, guard);
      await again.load();
      expect(again.overrides.map((SiteSetting s) => s.host), <String>[
        'a.com',
        'b.com',
      ]);
      expect(again.get('b.com').jsEnabled, isFalse);
    });

    test(
      'a stored row that equals the defaults, or is damaged, is ignored',
      () async {
        db.rows['x.com'] = SiteSetting.defaultsFor('x.com').toRow();
        db.rows['bad'] = <String, Object?>{'host': ''};
        await service.load();
        expect(service.overrides, isEmpty);
      },
    );

    test('remove and clear delete rows', () async {
      await service.save(
        SiteSetting.defaultsFor('a.com').copyWith(adblockEnabled: false),
      );
      await service.save(
        SiteSetting.defaultsFor('b.com').copyWith(adblockEnabled: false),
      );
      await service.remove('WWW.a.com');
      expect(db.rows.keys, <String>['b.com']);
      await service.clear();
      expect(db.rows, isEmpty);
      expect(service.overrides, isEmpty);
    });

    test(
      'a database that fails still lets this session work, and flags it',
      () async {
        db.failWrites = true;
        await service.save(
          SiteSetting.defaultsFor('a.com').copyWith(adblockEnabled: false),
        );
        expect(service.get('a.com').adblockEnabled, isFalse);
        expect(guard.failedAreas.value, contains('site settings'));
      },
    );

    test('an unreadable database loads as empty and flags it', () async {
      db.failReads = true;
      await service.load();
      expect(service.overrides, isEmpty);
      expect(guard.failedAreas.value, contains('site settings'));
    });
  });

  group('SiteSettingsProvider', () {
    late TabsProvider tabs;
    late SiteSettingsProvider provider;
    int counter = 0;

    setUp(() async {
      counter = 0;
      tabs = TabsProvider(
        engine: FakeBrowserEngine(),
        searchEngine: () => AppConstants.engineById('duckduckgo'),
        idGenerator: () => 't${counter++}',
      );
      provider = SiteSettingsProvider(
        service: SiteSettingsService(FakeSiteDatabase(), PersistenceGuard()),
        tabs: tabs,
      );
    });

    tearDown(() => provider.dispose());

    test('hostOf accepts web addresses only', () {
      expect(SiteSettingsProvider.hostOf('https://WWW.A.com/x'), 'a.com');
      expect(SiteSettingsProvider.hostOf('http://b.org:8080/'), 'b.org');
      expect(SiteSettingsProvider.hostOf(''), isNull);
      expect(SiteSettingsProvider.hostOf('javascript:alert(1)'), isNull);
      expect(SiteSettingsProvider.hostOf('file:///a'), isNull);
    });

    test('there are no current settings while no page is showing', () {
      expect(provider.currentHost, isNull);
      expect(provider.current, isNull);
    });

    test('the showing tab\'s site becomes the current one', () {
      int heard = 0;
      provider.addListener(() => heard++);
      tabs.navigate('https://news.example.com/a');
      expect(provider.currentHost, 'news.example.com');
      expect(provider.current!.isDefault, isTrue);
      expect(heard, 1);
    });

    test('a change to another path on the same site does not notify', () {
      tabs.navigate('https://a.com/one');
      int heard = 0;
      provider.addListener(() => heard++);
      tabs.navigate('https://a.com/two');
      expect(heard, 0);
    });

    test(
      'turning ad blocking off for a site is remembered and notifies',
      () async {
        int heard = 0;
        provider.addListener(() => heard++);
        await provider.setAdblock('a.com', enabled: false);
        expect(provider.forHost('a.com').adblockEnabled, isFalse);
        expect(provider.adblockExceptions, <String>['a.com']);
        expect(heard, 1);
        await provider.setAdblock('a.com', enabled: false);
        expect(heard, 1, reason: 'no change, no notification');
        await provider.setAdblock('a.com', enabled: true);
        expect(provider.adblockExceptions, isEmpty);
      },
    );

    test('remove and clearAll', () async {
      await provider.setAdblock('a.com', enabled: false);
      await provider.setAdblock('b.com', enabled: false);
      await provider.remove('a.com');
      expect(provider.adblockExceptions, <String>['b.com']);
      await provider.clearAll();
      expect(provider.overrides, isEmpty);
    });
  });
}
