import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:tahor_blocklist_tools/signing.dart';

/// Usage:
///   BLOCKLIST_SIGNING_KEY_B64=<32-byte seed, base64> dart run sign_blocklist.dart
///       --list latest.txt --out-manifest manifest.json --out-sig manifest.sig
///       [--previous manifest.json] [--min-app-version 0.1.0]
///
/// The version is one more than the previous manifest's, or 1 when there is
/// none, so published versions only ever increase.
Future<void> main(List<String> args) async {
  String? listPath;
  String? outManifest;
  String? outSig;
  String? previous;
  String minAppVersion = '0.1.0';
  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--list':
        listPath = args[++i];
      case '--out-manifest':
        outManifest = args[++i];
      case '--out-sig':
        outSig = args[++i];
      case '--previous':
        previous = args[++i];
      case '--min-app-version':
        minAppVersion = args[++i];
    }
  }
  final String? key = Platform.environment['BLOCKLIST_SIGNING_KEY_B64'];
  if (listPath == null || outManifest == null || outSig == null || key == null) {
    stderr.writeln('Missing arguments or BLOCKLIST_SIGNING_KEY_B64.');
    exit(64);
  }
  final Uint8List seed = base64Decode(key.trim());
  if (seed.length != 32) {
    stderr.writeln('The signing key must be a 32-byte seed.');
    exit(64);
  }

  int version = 1;
  if (previous != null && File(previous).existsSync()) {
    final Object? old = jsonDecode(File(previous).readAsStringSync());
    if (old is Map<String, Object?> && old['version'] is int) {
      version = (old['version']! as int) + 1;
    }
  }

  final Uint8List list = File(listPath).readAsBytesSync();
  final Map<String, int> counts = <String, int>{'block': 0, 'allow': 0, 'hide': 0};
  for (final String line in const LineSplitter().convert(utf8.decode(list))) {
    for (final String kind in counts.keys) {
      if (line.startsWith('$kind|')) {
        counts[kind] = counts[kind]! + 1;
      }
    }
  }
  final SignedManifest signed = await signList(
    list: list,
    seed: seed,
    version: version,
    minAppVersion: minAppVersion,
    ruleCounts: counts,
    flags: const <String, bool>{
      'blocklistRefresh': true,
      'tier3Downloads': true,
      'reader': true,
      'translation': true,
      'cast': true,
    },
  );
  File(outManifest).writeAsStringSync(signed.manifestJson);
  File(outSig).writeAsStringSync(base64Encode(signed.signature));
  stdout.writeln('version $version, ${list.length} bytes, $counts');
}
