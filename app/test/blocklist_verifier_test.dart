import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/blocklist/blocklist_verifier.dart';

import 'support/blocklist_support.dart';

void main() {
  late TestSigner signer;
  late BlocklistVerifier verifier;
  final Uint8List list = Uint8List.fromList(utf8.encode('block|x.y|*|*|*|*\n'));

  setUp(() async {
    signer = await TestSigner.create();
    verifier = BlocklistVerifier(signer.publicKey);
  });

  Future<VerificationResult> check(
    ({String json, String signature}) m, {
    int current = 1,
    String app = '0.1.0',
  }) => verifier.verifyManifest(
    manifestJson: m.json,
    signature: base64Decode(m.signature),
    currentVersion: current,
    appVersion: app,
  );

  test('a genuine, newer manifest passes and is described', () async {
    final VerificationResult r = await check(await signer.manifestFor(list));
    expect(r.isOk, isTrue);
    expect(r.manifest!.version, 2);
    expect(r.manifest!.size, list.length);
    expect(r.manifest!.flags['cast'], isTrue);
    expect(r.manifest!.ruleCounts['block'], 1);
  });

  test('a changed manifest text fails the signature', () async {
    final m = await signer.manifestFor(list);
    final VerificationResult r = await check((
      json: m.json.replaceFirst('"version":2', '"version":9'),
      signature: m.signature,
    ));
    expect(r.failure, VerificationFailure.badSignature);
  });

  test('a signature from another key fails', () async {
    final TestSigner other = await TestSigner.create(7);
    final VerificationResult r = await check(await other.manifestFor(list));
    expect(r.failure, VerificationFailure.badSignature);
  });

  test('a damaged signature fails instead of throwing', () async {
    final m = await signer.manifestFor(list);
    final VerificationResult r = await verifier.verifyManifest(
      manifestJson: m.json,
      signature: Uint8List(3),
      currentVersion: 1,
      appVersion: '0.1.0',
    );
    expect(r.failure, VerificationFailure.badSignature);
  });

  test('a validly signed text that is not a manifest is malformed', () async {
    const String text = '{"hello":1}';
    final VerificationResult r = await check((
      json: text,
      signature: await signer.signText(text),
    ));
    expect(r.failure, VerificationFailure.malformedManifest);
    const String notJson = 'nope';
    expect(
      (await check((json: notJson, signature: await signer.signText(notJson))))
          .failure,
      VerificationFailure.malformedManifest,
    );
  });

  test('an equal or older version is a rollback', () async {
    expect(
      (await check(
        await signer.manifestFor(list, version: 3),
        current: 3,
      )).failure,
      VerificationFailure.rollback,
    );
    expect(
      (await check(
        await signer.manifestFor(list, version: 2),
        current: 5,
      )).failure,
      VerificationFailure.rollback,
    );
    expect(
      (await check(
        await signer.manifestFor(list, version: 4),
        current: 3,
      )).isOk,
      isTrue,
    );
  });

  test('a list that needs a newer app is refused', () async {
    final m = await signer.manifestFor(list, minAppVersion: '2.0.0');
    expect((await check(m)).failure, VerificationFailure.appTooOld);
    expect((await check(m, app: '2.0.0')).isOk, isTrue);
  });

  group('the list itself', () {
    test('the right bytes pass', () async {
      final BlocklistManifest manifest = (await check(
        await signer.manifestFor(list),
      )).manifest!;
      expect((await verifier.verifyList(manifest, list)).isOk, isTrue);
    });

    test('changed bytes of the same length fail the hash', () async {
      final BlocklistManifest manifest = (await check(
        await signer.manifestFor(list),
      )).manifest!;
      final Uint8List other = Uint8List.fromList(list)..[0] = 0x42;
      expect(
        (await verifier.verifyList(manifest, other)).failure,
        VerificationFailure.hashMismatch,
      );
    });

    test('a different length fails the size check first', () async {
      final BlocklistManifest manifest = (await check(
        await signer.manifestFor(list),
      )).manifest!;
      expect(
        (await verifier.verifyList(manifest, Uint8List(2))).failure,
        VerificationFailure.sizeMismatch,
      );
    });
  });

  group('manifest parsing', () {
    test('rejects a bad hash, a version below 1 and missing fields', () {
      expect(BlocklistManifest.tryParse('{}'), isNull);
      expect(
        BlocklistManifest.tryParse(
          '{"version":0,"sha256":"${'a' * 64}","size":1,"minAppVersion":"0"}',
        ),
        isNull,
      );
      expect(
        BlocklistManifest.tryParse(
          '{"version":1,"sha256":"xyz","size":1,"minAppVersion":"0"}',
        ),
        isNull,
      );
    });

    test('ignores flags and counts that are not the right type', () {
      final BlocklistManifest m = BlocklistManifest.tryParse(
        '{"version":1,"sha256":"${'a' * 64}","size":1,"minAppVersion":"0",'
        '"flags":{"ok":true,"bad":"yes"},"rules":{"block":2,"x":"y"}}',
      )!;
      expect(m.flags, <String, bool>{'ok': true});
      expect(m.ruleCounts, <String, int>{'block': 2});
    });
  });

  test('version comparison', () {
    expect(compareVersions('0.1.0', '0.1.0'), 0);
    expect(compareVersions('0.1', '0.1.0'), 0);
    expect(compareVersions('0.2.0', '0.10.0'), -1);
    expect(compareVersions('1.0.0', '0.9.9'), 1);
    expect(compareVersions('1.0.0+3', '1.0.0'), 0);
  });
}
