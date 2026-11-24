import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/blocklist/blocklist_service.dart';
import 'package:tahorbrowser/core/blocklist/blocklist_verifier.dart';
import 'package:tahorbrowser/core/blocklist/canonical_parser.dart';
import 'package:tahorbrowser/core/models/blocklist_rule.dart';

import 'support/blocklist_support.dart';
import 'support/fakes.dart';

/// The files that ship inside the app, checked with the key that ships inside
/// the app. If the publish workflow ever produces a list the app would refuse,
/// this fails before a release can.
void main() {
  // Tests run with the app directory as the working directory.
  final Uint8List list = File('assets/blocklist/canonical_blocklist.txt')
      .readAsBytesSync();
  final String manifestJson = File('assets/blocklist/manifest.json')
      .readAsStringSync();
  final Uint8List signature = base64Decode(
    File('assets/blocklist/manifest.sig').readAsStringSync().trim(),
  );
  final Uint8List publicKey = base64Decode(
    File('assets/blocklist/update_public_key.txt').readAsStringSync().trim(),
  );

  test('the bundled manifest is signed by the key in the app', () async {
    final VerificationResult r = await BlocklistVerifier(publicKey)
        .verifyManifest(
          manifestJson: manifestJson,
          signature: signature,
          currentVersion: 0,
          appVersion: '0.1.0',
        );
    expect(r.failure, isNull);
    expect(r.manifest!.version, greaterThanOrEqualTo(1));
  });

  test('the bundled list is the one the manifest describes', () async {
    final BlocklistManifest manifest = BlocklistManifest.tryParse(
      manifestJson,
    )!;
    final VerificationResult r = await BlocklistVerifier(publicKey)
        .verifyList(manifest, list);
    expect(r.failure, isNull);
  });

  test('every line of the bundled list is readable and matches the counts', () {
    final BlocklistManifest manifest = BlocklistManifest.tryParse(
      manifestJson,
    )!;
    final ParseResult parsed = parseCanonical(utf8.decode(list));
    expect(parsed.issues, isEmpty);
    expect(parsed.truncated, isFalse);
    expect(
      parsed.rules.whereType<BlockRule>().length,
      manifest.ruleCounts['block'],
    );
    expect(
      parsed.rules.whereType<AllowRule>().length,
      manifest.ruleCounts['allow'],
    );
    expect(
      parsed.rules.whereType<HideRule>().length,
      manifest.ruleCounts['hide'],
    );
  });

  test(
    'the service starts from it, complete, on first launch with no network',
    () async {
      final Map<String, Uint8List> assets = <String, Uint8List>{
        BlocklistService.bundledListAsset: list,
        BlocklistService.bundledManifestAsset: Uint8List.fromList(
          utf8.encode(manifestJson),
        ),
        BlocklistService.bundledSignatureAsset: Uint8List.fromList(
          utf8.encode(base64Encode(signature)),
        ),
      };
      final FakeHttpClient http = FakeHttpClient()
        ..failWith = Exception('offline');
      final BlocklistService service = BlocklistService(
        http: http,
        files: FakeFileStore(),
        verifier: BlocklistVerifier(publicKey),
        loadAssetBytes: (String path) async => assets[path]!,
        appVersion: '0.1.0',
      );
      await service.initialize();
      expect(service.value.source, BlocklistSource.bundled);
      expect(service.value.lastError, isNull);
      expect(service.value.ruleCount, greaterThan(100000));
      expect(
        http.requested,
        isEmpty,
        reason: 'starting up must not use the network',
      );
    },
  );
}
