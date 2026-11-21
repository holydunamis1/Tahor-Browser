import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// A manifest and its signature.
class SignedManifest {
  SignedManifest(this.manifestJson, this.signature, this.publicKey);

  /// The exact text that was signed. Publish it byte for byte.
  final String manifestJson;
  final Uint8List signature;
  final Uint8List publicKey;
}

final Ed25519 _ed25519 = Ed25519();

/// The Ed25519 public key for a 32-byte private [seed].
Future<Uint8List> publicKeyFor(Uint8List seed) async {
  final SimplePublicKey key = await (await _ed25519.newKeyPairFromSeed(seed))
      .extractPublicKey();
  return Uint8List.fromList(key.bytes);
}

/// Lower-case hex SHA-256 of [bytes].
Future<String> sha256Hex(List<int> bytes) async {
  final Hash hash = await Sha256().hash(bytes);
  return hash.bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Builds the manifest for [list] and signs its text with [seed].
///
/// The manifest names the list version, the SHA-256 of the list bytes, the
/// oldest app version that may use it, the rule counts and the feature flags
/// (kill switches). The app checks the signature, then the hash, and refuses a
/// version that is not higher than the one it has.
Future<SignedManifest> signList({
  required Uint8List list,
  required Uint8List seed,
  required int version,
  required String minAppVersion,
  required Map<String, int> ruleCounts,
  required Map<String, bool> flags,
}) async {
  final String json = jsonEncode(<String, Object?>{
    'version': version,
    'sha256': await sha256Hex(list),
    'size': list.length,
    'minAppVersion': minAppVersion,
    'rules': ruleCounts,
    'flags': flags,
  });
  final Signature signature = await _ed25519.sign(
    utf8.encode(json),
    keyPair: await _ed25519.newKeyPairFromSeed(seed),
  );
  return SignedManifest(
    json,
    Uint8List.fromList(signature.bytes),
    await publicKeyFor(seed),
  );
}

/// Whether [signature] is a valid signature of [manifestJson] by
/// [publicKey].
Future<bool> verifyManifest(
  String manifestJson,
  Uint8List signature,
  Uint8List publicKey,
) => _ed25519.verify(
  utf8.encode(manifestJson),
  signature: Signature(
    signature,
    publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519),
  ),
);
