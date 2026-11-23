import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Why a downloaded list was refused.
enum VerificationFailure {
  malformedManifest,
  badSignature,
  hashMismatch,
  sizeMismatch,
  rollback,
  appTooOld,
}

/// What a signed manifest says about a list.
class BlocklistManifest {
  const BlocklistManifest({
    required this.version,
    required this.sha256,
    required this.size,
    required this.minAppVersion,
    required this.flags,
    required this.ruleCounts,
  });

  final int version;
  final String sha256;
  final int size;
  final String minAppVersion;

  /// Kill switches: a feature the manifest turns off is off for everyone.
  final Map<String, bool> flags;
  final Map<String, int> ruleCounts;

  /// Reads manifest JSON, or null when it is not a manifest.
  static BlocklistManifest? tryParse(String json) {
    try {
      final Object? decoded = jsonDecode(json);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      final Object? version = decoded['version'];
      final Object? sha = decoded['sha256'];
      final Object? size = decoded['size'];
      final Object? min = decoded['minAppVersion'];
      if (version is! int ||
          version < 1 ||
          sha is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(sha) ||
          size is! int ||
          size < 0 ||
          min is! String) {
        return null;
      }
      final Object? flags = decoded['flags'];
      final Object? counts = decoded['rules'];
      return BlocklistManifest(
        version: version,
        sha256: sha,
        size: size,
        minAppVersion: min,
        flags: flags is Map<String, Object?>
            ? <String, bool>{
                for (final MapEntry<String, Object?> e in flags.entries)
                  if (e.value is bool) e.key: e.value! as bool,
              }
            : const <String, bool>{},
        ruleCounts: counts is Map<String, Object?>
            ? <String, int>{
                for (final MapEntry<String, Object?> e in counts.entries)
                  if (e.value is int) e.key: e.value! as int,
              }
            : const <String, int>{},
      );
    } on FormatException {
      return null;
    }
  }
}

/// The outcome of checking a manifest or a list: a manifest, or a failure.
class VerificationResult {
  const VerificationResult.ok(BlocklistManifest this.manifest) : failure = null;
  const VerificationResult.failed(VerificationFailure this.failure)
    : manifest = null;

  final BlocklistManifest? manifest;
  final VerificationFailure? failure;

  bool get isOk => manifest != null;
}

/// Compares dotted version numbers such as `0.1.0`. Missing parts are 0.
int compareVersions(String a, String b) {
  List<int> parts(String v) => <int>[
    for (final String p in v.split('.')) int.tryParse(p) ?? 0,
  ];
  final List<int> x = parts(a);
  final List<int> y = parts(b);
  for (int i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
    final int xi = i < x.length ? x[i] : 0;
    final int yi = i < y.length ? y[i] : 0;
    if (xi != yi) {
      return xi < yi ? -1 : 1;
    }
  }
  return 0;
}

/// Checks that a downloaded blocklist is the one we published: the manifest is
/// signed by the key built into the app, the list matches the manifest's hash
/// and size, the version is newer than the one in use, and the app is new
/// enough to read it.
class BlocklistVerifier {
  BlocklistVerifier(this._publicKey);

  final Uint8List _publicKey;
  final Ed25519 _ed25519 = Ed25519();

  /// Step one, before the list is downloaded: signature, shape, version and
  /// app version. [currentVersion] is the version in use; a manifest that is
  /// not strictly newer is a rollback.
  Future<VerificationResult> verifyManifest({
    required String manifestJson,
    required Uint8List signature,
    required int currentVersion,
    required String appVersion,
  }) async {
    bool signed;
    try {
      signed = await _ed25519.verify(
        utf8.encode(manifestJson),
        signature: Signature(
          signature,
          publicKey: SimplePublicKey(_publicKey, type: KeyPairType.ed25519),
        ),
      );
    } on Object {
      // A malformed signature makes the crypto library throw an Error, not an
      // Exception; either way the manifest is not signed.
      signed = false;
    }
    if (!signed) {
      return const VerificationResult.failed(VerificationFailure.badSignature);
    }
    final BlocklistManifest? manifest = BlocklistManifest.tryParse(
      manifestJson,
    );
    if (manifest == null) {
      return const VerificationResult.failed(
        VerificationFailure.malformedManifest,
      );
    }
    if (manifest.version <= currentVersion) {
      return const VerificationResult.failed(VerificationFailure.rollback);
    }
    if (compareVersions(manifest.minAppVersion, appVersion) > 0) {
      return const VerificationResult.failed(VerificationFailure.appTooOld);
    }
    return VerificationResult.ok(manifest);
  }

  /// Step two: the downloaded bytes are the list the manifest describes.
  Future<VerificationResult> verifyList(
    BlocklistManifest manifest,
    Uint8List listBytes,
  ) async {
    if (listBytes.length != manifest.size) {
      return const VerificationResult.failed(VerificationFailure.sizeMismatch);
    }
    final Hash hash = await Sha256().hash(listBytes);
    final String hex = hash.bytes
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    if (hex != manifest.sha256) {
      return const VerificationResult.failed(VerificationFailure.hashMismatch);
    }
    return VerificationResult.ok(manifest);
  }
}
