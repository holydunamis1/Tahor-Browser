import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/blocklist/blocklist_service.dart';
import 'package:tahorbrowser/core/blocklist/blocklist_verifier.dart';
import 'package:tahorbrowser/core/blocklist/content_rule_compiler.dart';
import 'package:tahorbrowser/core/constants/app_constants.dart';
import 'package:tahorbrowser/core/models/app_settings.dart';
import 'package:tahorbrowser/core/providers/adblock_provider.dart';
import 'package:tahorbrowser/core/providers/feature_flags_provider.dart';
import 'package:tahorbrowser/core/providers/settings_provider.dart';
import 'package:tahorbrowser/core/providers/site_settings_provider.dart';
import 'package:tahorbrowser/core/providers/tabs_provider.dart';
import 'package:tahorbrowser/core/services/settings_service.dart';
import 'package:tahorbrowser/core/services/site_settings_service.dart';
import 'package:tahorbrowser/core/storage/persistence_guard.dart';
import 'package:tahorbrowser/core/storage/storage_keys.dart';

import 'support/blocklist_support.dart';
import 'support/fakes.dart';

void main() {
  late TestSigner signer;
  late FakeHttpClient http;
  late FakeKeyValueStore store;
  late BlocklistService blocklist;
  late SettingsProvider settings;
  late SiteSettingsProvider sites;
  late FeatureFlagsProvider flags;
  late AdblockProvider adblock;
  late DateTime now;
  int counter = 0;

  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  Future<void> publish({int version = 2, Map<String, bool>? flagMap}) async {
    final Uint8List list = bytes('block|new\\.one|*|*|*|*\nhide|*|.promo\n');
    final m = await signer.manifestFor(
      list,
      version: version,
      flags: flagMap ?? const <String, bool>{},
    );
    http.answer(AppUrls.blocklistManifest, utf8.encode(m.json));
    http.answer(AppUrls.blocklistSignature, utf8.encode(m.signature));
    http.answer(AppUrls.blocklistLatest, list);
  }

  setUp(() async {
    counter = 0;
    now = DateTime.utc(2026, 11, 23, 12);
    signer = await TestSigner.create();
    http = FakeHttpClient();
    store = FakeKeyValueStore();
    final Future<Uint8List> Function(String) assets = await tinyBlocklistAssets(
      signer: signer,
    );
    blocklist = BlocklistService(
      http: http,
      files: FakeFileStore(),
      verifier: BlocklistVerifier(signer.publicKey),
      loadAssetBytes: assets,
      appVersion: '0.1.0',
    );
    await blocklist.initialize();
    settings = SettingsProvider(service: SettingsService(store));
    await settings.load();
    final TabsProvider tabs = TabsProvider(
      engine: FakeBrowserEngine(),
      searchEngine: () => AppConstants.engineById('duckduckgo'),
      idGenerator: () => 't${counter++}',
    );
    sites = SiteSettingsProvider(
      service: SiteSettingsService(FakeSiteDatabase(), PersistenceGuard()),
      tabs: tabs,
    );
    flags = FeatureFlagsProvider(blocklist);
    adblock = AdblockProvider(
      blocklist: blocklist,
      settings: settings,
      sites: sites,
      flags: flags,
      store: store,
      clock: () => now,
    );
  });

  tearDown(() {
    adblock.dispose();
    flags.dispose();
    sites.dispose();
  });

  group('switches', () {
    test(
      'ad blocking is on by default and follows the global switch',
      () async {
        expect(adblock.enabled, isTrue);
        expect(adblock.enabledFor('a.com'), isTrue);
        await settings.setAdblockEnabled(false);
        expect(adblock.enabled, isFalse);
        expect(adblock.enabledFor('a.com'), isFalse);
      },
    );

    test('a site can be switched off while the rest stay on', () async {
      await sites.setAdblock('a.com', enabled: false);
      expect(adblock.enabledFor('a.com'), isFalse);
      expect(adblock.enabledFor('WWW.a.com'), isFalse);
      expect(adblock.enabledFor('b.com'), isTrue);
      expect(adblock.exceptionHosts, <String>['a.com']);
    });

    test(
      'a change in any input notifies, which is the engine\'s cue',
      () async {
        int heard = 0;
        adblock.addListener(() => heard++);
        await settings.setAdblockEnabled(false);
        await sites.setAdblock('a.com', enabled: false);
        await publish();
        await blocklist.refresh();
        expect(heard, greaterThanOrEqualTo(3));
      },
    );
  });

  group('element hiding', () {
    test('selectors come from the list while blocking is on for the site', () {
      expect(adblock.selectorsFor('a.com'), <String>['.promo']);
    });

    test('none when blocking is off globally or for that site', () async {
      await sites.setAdblock('a.com', enabled: false);
      expect(adblock.selectorsFor('a.com'), isEmpty);
      expect(adblock.selectorsFor('b.com'), isNotEmpty);
      await settings.setAdblockEnabled(false);
      expect(adblock.selectorsFor('b.com'), isEmpty);
    });
  });

  group('compiled rules', () {
    test(
      'the cache key changes with the list and with the exceptions',
      () async {
        final String base = adblock.cacheKey;
        await sites.setAdblock('a.com', enabled: false);
        final String withException = adblock.cacheKey;
        expect(withException, isNot(base));
        await sites.setAdblock('a.com', enabled: true);
        expect(adblock.cacheKey, base);
        await publish();
        await blocklist.refresh();
        expect(adblock.cacheKey, isNot(base));
      },
    );

    test('iPhone lists are compiled once for the same key', () async {
      final IosRuleLists first = await adblock.iosLists();
      expect(identical(await adblock.iosLists(), first), isTrue);
      await sites.setAdblock('a.com', enabled: false);
      final IosRuleLists second = await adblock.iosLists();
      expect(identical(second, first), isFalse);
      expect(second.lists.any((String l) => l.contains('*a.com')), isTrue);
    });

    test('Android rules are compiled once per list version', () async {
      final AndroidRuleSet first = await adblock.androidSet();
      await sites.setAdblock('a.com', enabled: false);
      expect(identical(await adblock.androidSet(), first), isTrue);
      await publish();
      await blocklist.refresh();
      expect(identical(await adblock.androidSet(), first), isFalse);
    });

    test('compiling can be handed to another runner', () async {
      int ran = 0;
      final AdblockProvider custom = AdblockProvider(
        blocklist: blocklist,
        settings: settings,
        sites: sites,
        flags: flags,
        store: store,
        runner: <R>(R Function() job) async {
          ran++;
          return job();
        },
      );
      await custom.iosLists();
      await custom.androidSet();
      expect(ran, 2);
      custom.dispose();
    });
  });

  group('refreshing', () {
    test('Update now asks the website and remembers when', () async {
      await publish();
      expect(await adblock.refreshNow(), RefreshOutcome.updated);
      expect(
        await store.getInt(StorageKeys.blocklistLastCheck),
        now.millisecondsSinceEpoch,
      );
    });

    test('the weekly check does nothing unless it was turned on', () async {
      await adblock.autoRefreshIfDue();
      expect(http.requested, isEmpty);
    });

    test('turned on and never checked: it checks and remembers', () async {
      await settings.setBlocklistAutoUpdate(true);
      await publish();
      await adblock.autoRefreshIfDue();
      expect(http.requested, isNotEmpty);
      expect(blocklist.value.version, 2);
      expect(await store.getInt(StorageKeys.blocklistLastCheck), isNotNull);
    });

    test('checked a day ago: it waits', () async {
      await settings.setBlocklistAutoUpdate(true);
      await store.setInt(
        StorageKeys.blocklistLastCheck,
        now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      await adblock.autoRefreshIfDue();
      expect(http.requested, isEmpty);
    });

    test('checked eight days ago: it checks', () async {
      await settings.setBlocklistAutoUpdate(true);
      await store.setInt(
        StorageKeys.blocklistLastCheck,
        now.subtract(const Duration(days: 8)).millisecondsSinceEpoch,
      );
      await adblock.autoRefreshIfDue();
      expect(http.requested, isNotEmpty);
    });

    test('a failed weekly check is quiet', () async {
      await settings.setBlocklistAutoUpdate(true);
      http.failWith = Exception('offline');
      await adblock.autoRefreshIfDue();
      expect(blocklist.value.lastError, isNotNull);
      expect(blocklist.value.version, 1);
    });
  });

  group('kill switches', () {
    test('every feature is on until a verified manifest says otherwise', () {
      for (final FeatureFlag f in FeatureFlag.values) {
        expect(flags.isEnabled(f), isTrue, reason: f.name);
      }
    });

    test('a manifest can switch a feature off for everyone', () async {
      await publish(flagMap: <String, bool>{'cast': false, 'reader': true});
      int heard = 0;
      flags.addListener(() => heard++);
      await blocklist.refresh();
      expect(flags.isEnabled(FeatureFlag.cast), isFalse);
      expect(flags.isEnabled(FeatureFlag.reader), isTrue);
      expect(flags.isEnabled(FeatureFlag.translation), isTrue);
      expect(heard, greaterThan(0));
    });

    test(
      'switching the blocklist refresh off stops both manual and weekly checks',
      () async {
        await publish(flagMap: <String, bool>{'blocklistRefresh': false});
        await blocklist.refresh();
        expect(adblock.canRefresh, isFalse);
        await settings.setBlocklistAutoUpdate(true);
        http.requested.clear();
        await adblock.autoRefreshIfDue();
        expect(http.requested, isEmpty);
      },
    );
  });

  test('the global settings round-trip the new fields', () {
    const AppSettings s = AppSettings(
      adblockEnabled: false,
      blocklistAutoUpdate: true,
    );
    final AppSettings back = AppSettings.fromJson(s.toJson());
    expect(back.adblockEnabled, isFalse);
    expect(back.blocklistAutoUpdate, isTrue);
    expect(AppSettings.fromJson(<String, Object?>{}).adblockEnabled, isTrue);
    expect(
      AppSettings.fromJson(<String, Object?>{}).blocklistAutoUpdate,
      isFalse,
    );
  });
}
