import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/blocklist/blocklist_service.dart';
import 'package:tahorbrowser/core/blocklist/blocklist_verifier.dart';
import 'package:tahorbrowser/core/constants/app_constants.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';
import 'package:tahorbrowser/core/models/blocklist_rule.dart';
import 'package:tahorbrowser/core/storage/storage_keys.dart';

import 'support/blocklist_support.dart';
import 'support/fakes.dart';

void main() {
  late TestSigner signer;
  late FakeHttpClient http;
  late FakeFileStore files;
  late BlocklistService service;

  const String seedText =
      'block|seed\\.one|*|*|*|*\nblock|seed\\.two|*|*|*|*\n';
  late Map<String, Uint8List> assets;

  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  const String newList =
      'block|new\\.one|*|*|*|*\nblock|new\\.two|*|*|*|*\nhide|*|.sponsor\n';

  Future<void> publish({
    String list = newList,
    int version = 2,
    String minApp = '0.1.0',
    TestSigner? by,
    String? listServed,
  }) async {
    final Uint8List listBytes = bytes(list);
    final m = await (by ?? signer).manifestFor(
      listBytes,
      version: version,
      minAppVersion: minApp,
    );
    http.answer(AppUrls.blocklistManifest, utf8.encode(m.json));
    http.answer(AppUrls.blocklistSignature, utf8.encode(m.signature));
    http.answer(AppUrls.blocklistLatest, bytes(listServed ?? list));
  }

  BlocklistService make({FakeFileStore? store}) => BlocklistService(
    http: http,
    files: store ?? files,
    verifier: BlocklistVerifier(signer.publicKey),
    loadAssetBytes: (String path) async {
      final Uint8List? asset = assets[path];
      if (asset == null) {
        throw StateError('no asset $path');
      }
      return asset;
    },
    appVersion: '0.1.0',
    clock: () => DateTime.utc(2026, 11, 22),
  );

  setUp(() async {
    signer = await TestSigner.create();
    http = FakeHttpClient();
    files = FakeFileStore();
    final bundled = await signer.manifestFor(bytes(seedText), version: 1);
    assets = <String, Uint8List>{
      BlocklistService.bundledListAsset: bytes(seedText),
      BlocklistService.bundledManifestAsset: bytes(bundled.json),
      BlocklistService.bundledSignatureAsset: bytes(bundled.signature),
    };
    service = make();
  });

  group('starting up', () {
    test('with nothing saved the list bundled in the app is used', () async {
      await service.initialize();
      expect(service.value.source, BlocklistSource.bundled);
      expect(service.value.version, 1);
      expect(service.value.lastError, isNull);
      expect(service.rules.length, 2);
      expect(service.manifest, isNotNull);
      expect(service.flags['cast'], isTrue);
    });

    test('a missing bundled list leaves no blocklist and says why', () async {
      assets.remove(BlocklistService.bundledListAsset);
      await service.initialize();
      expect(service.value.source, BlocklistSource.none);
      expect(service.rules, isEmpty);
      expect(service.value.lastError!.code, 'blocklist.invalid');
    });

    test('a bundled list that fails its checks is not used', () async {
      assets[BlocklistService.bundledListAsset] = bytes(
        'block|tampered\\.one|*|*|*|*\n',
      );
      await service.initialize();
      expect(service.value.source, BlocklistSource.none);
      expect(service.rules, isEmpty);
      expect(service.value.lastError!.code, 'blocklist.verification');
    });

    test('a bundled signature from another key is not trusted', () async {
      final other = await (await TestSigner.create(9))
          .manifestFor(bytes(seedText), version: 1);
      assets[BlocklistService.bundledManifestAsset] = bytes(other.json);
      assets[BlocklistService.bundledSignatureAsset] = bytes(other.signature);
      await service.initialize();
      expect(service.value.source, BlocklistSource.none);
      expect(service.value.lastError!.code, 'blocklist.verification');
    });
  });

  group('refreshing', () {
    test('a newer signed list is downloaded, checked and put to use', () async {
      await service.initialize();
      await publish();

      expect(await service.refresh(), RefreshOutcome.updated);

      expect(service.value.source, BlocklistSource.downloaded);
      expect(service.value.version, 2);
      expect(service.value.ruleCount, 3);
      expect(service.value.checkedAt, DateTime.utc(2026, 11, 22));
      expect(service.value.lastError, isNull);
      expect(service.rules.whereType<HideRule>().length, 1);
      expect(service.flags['cast'], isTrue);
    });

    test('the new list is saved and used again after a restart', () async {
      await service.initialize();
      await publish();
      await service.refresh();

      final BlocklistService restarted = make();
      await restarted.initialize();
      expect(restarted.value.source, BlocklistSource.downloaded);
      expect(restarted.value.version, 2);
      expect(restarted.rules.length, 3);
    });

    test('the list is not downloaded when the manifest is not newer', () async {
      await service.initialize();
      await publish(version: 1);
      expect(await service.refresh(), RefreshOutcome.upToDate);
      expect(http.requested, isNot(contains(AppUrls.blocklistLatest)));
      expect(service.value.version, 1);
      expect(service.value.checkedAt, isNotNull);
    });

    test('an older manifest is ignored, never applied', () async {
      await service.initialize();
      await publish(version: 5);
      await service.refresh();
      await publish(version: 3, list: 'block|old\\.list|*|*|*|*\n');
      expect(await service.refresh(), RefreshOutcome.upToDate);
      expect(service.value.version, 5);
      expect(service.rules.length, 3);
    });

    test(
      'a list changed in transit is refused and the old list stays',
      () async {
        await service.initialize();
        await publish(listServed: 'block|evil\\.list|*|*|*|*\n');
        expect(await service.refresh(), RefreshOutcome.failed);
        expect(service.value.source, BlocklistSource.bundled);
        expect(service.rules.length, 2);
        expect(service.value.lastError!.code, 'blocklist.verification');
        expect(files.data[StorageKeys.blocklistNamespace], isNull);
      },
    );

    test('a manifest signed by another key is refused', () async {
      await service.initialize();
      await publish(by: await TestSigner.create(9));
      expect(await service.refresh(), RefreshOutcome.failed);
      expect(service.value.lastError!.code, 'blocklist.verification');
      expect(service.value.version, 1);
    });

    test('a list that needs a newer app is refused', () async {
      await service.initialize();
      await publish(minApp: '9.0.0');
      expect(await service.refresh(), RefreshOutcome.failed);
      expect(service.value.version, 1);
    });

    test(
      'a server error keeps the old list and reports a fetch failure',
      () async {
        await service.initialize();
        expect(await service.refresh(), RefreshOutcome.failed);
        expect(service.value.lastError!.code, 'blocklist.fetch');
        expect(service.rules.length, 2);
      },
    );

    test('a network exception is handled the same way', () async {
      await service.initialize();
      http.failWith = Exception('offline');
      expect(await service.refresh(background: true), RefreshOutcome.failed);
      expect(service.value.lastError!.code, 'blocklist.fetch');
      expect(service.value.lastError!.treatment, ErrorTreatment.silentLog);
      expect(service.rules.length, 2);
    });

    test('a list with no readable rules is refused', () async {
      await service.initialize();
      await publish(list: '# only a comment\n');
      expect(await service.refresh(), RefreshOutcome.failed);
      expect(service.value.lastError!.code, 'blocklist.invalid');
    });

    test('a later success clears the earlier error', () async {
      await service.initialize();
      await service.refresh();
      expect(service.value.lastError, isNotNull);
      await publish();
      await service.refresh();
      expect(service.value.lastError, isNull);
    });

    test(
      'a failure to save still lets this session use the new list',
      () async {
        await service.initialize();
        await publish();
        files.failWrites = true;
        expect(await service.refresh(), RefreshOutcome.updated);
        expect(service.value.version, 2);
      },
    );
  });

  group('the saved list is checked again at start-up', () {
    Future<void> saveGood() async {
      await service.initialize();
      await publish();
      await service.refresh();
    }

    test('changed list bytes fall back to the starter list', () async {
      await saveGood();
      files.data[StorageKeys.blocklistNamespace]!['list.txt'] = bytes(
        'block|tampered|*|*|*|*\n',
      );
      final BlocklistService restarted = make();
      await restarted.initialize();
      expect(restarted.value.source, BlocklistSource.bundled);
    });

    test('a changed signature falls back to the starter list', () async {
      await saveGood();
      files.data[StorageKeys.blocklistNamespace]!['manifest.sig'] = bytes(
        base64Encode(Uint8List(64)),
      );
      final BlocklistService restarted = make();
      await restarted.initialize();
      expect(restarted.value.source, BlocklistSource.bundled);
    });

    test('an unreadable store falls back to the starter list', () async {
      await saveGood();
      files.failReads = true;
      final BlocklistService restarted = make();
      await restarted.initialize();
      expect(restarted.value.source, BlocklistSource.bundled);
    });
  });
}
