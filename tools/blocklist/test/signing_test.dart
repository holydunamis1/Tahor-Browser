import 'dart:convert';
import 'dart:typed_data';

import 'package:tahor_blocklist_tools/signing.dart';
import 'package:test/test.dart';

Uint8List hex(String s) => Uint8List.fromList(<int>[
  for (int i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16),
]);

String toHex(List<int> b) =>
    b.map((int x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // RFC 8032, section 7.1, TEST 1.
  final Uint8List seed = hex(
    '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60',
  );

  test('the public key for the RFC 8032 test seed matches the standard', () async {
    expect(
      toHex(await publicKeyFor(seed)),
      'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
    );
  });

  test('SHA-256 matches the standard answer for "abc"', () async {
    expect(
      await sha256Hex(utf8.encode('abc')),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  group('a signed manifest', () {
    final Uint8List list = Uint8List.fromList(utf8.encode('block|x|*|*|*|*\nhide|*|.a\n'));

    Future<SignedManifest> sign({int version = 3}) => signList(
      list: list,
      seed: seed,
      version: version,
      minAppVersion: '0.1.0',
      ruleCounts: const <String, int>{'block': 1, 'allow': 0, 'hide': 1},
      flags: const <String, bool>{'cast': true},
    );

    test('names the version, the hash and the size of the list', () async {
      final Map<String, Object?> m =
          jsonDecode((await sign()).manifestJson) as Map<String, Object?>;
      expect(m['version'], 3);
      expect(m['sha256'], await sha256Hex(list));
      expect(m['size'], list.length);
      expect(m['minAppVersion'], '0.1.0');
    });

    test('verifies with the matching public key', () async {
      final SignedManifest s = await sign();
      expect(await verifyManifest(s.manifestJson, s.signature, s.publicKey), isTrue);
    });

    test('is rejected when the manifest text is changed', () async {
      final SignedManifest s = await sign();
      final String tampered = s.manifestJson.replaceFirst('"version":3', '"version":4');
      expect(await verifyManifest(tampered, s.signature, s.publicKey), isFalse);
    });

    test('is rejected when the signature is changed', () async {
      final SignedManifest s = await sign();
      final Uint8List bad = Uint8List.fromList(s.signature)..[0] ^= 0xff;
      expect(await verifyManifest(s.manifestJson, bad, s.publicKey), isFalse);
    });

    test('is rejected under another key', () async {
      final SignedManifest s = await sign();
      final Uint8List other = await publicKeyFor(Uint8List(32)..[0] = 7);
      expect(await verifyManifest(s.manifestJson, s.signature, other), isFalse);
    });

    test('signing twice gives the same signature (Ed25519 is deterministic)', () async {
      expect((await sign()).signature, (await sign()).signature);
    });
  });
}
