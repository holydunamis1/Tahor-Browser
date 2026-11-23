import 'dart:io';

import 'package:tahor_blocklist_tools/abp_converter.dart';

/// Usage:
///   dart run convert_abp_to_canonical.dart --out-full full.txt
///       [--max-rules 400000] list1.txt list2.txt ...
///
/// Prints a JSON summary of what was kept and what was dropped, and why.
void main(List<String> args) {
  String? outFull;
  int maxRules = 400000;
  final List<String> inputs = <String>[];
  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--out-full':
        outFull = args[++i];
      case '--max-rules':
        maxRules = int.parse(args[++i]);
      default:
        inputs.add(args[i]);
    }
  }
  if (outFull == null || inputs.isEmpty) {
    stderr.writeln('Usage: convert_abp_to_canonical.dart --out-full F list...');
    exit(64);
  }

  final ConvertResult result = ConvertResult();
  for (final String path in inputs) {
    convert(File(path).readAsLinesSync(), into: result);
  }
  int overCap = 0;
  if (result.rules.length > maxRules) {
    overCap = result.rules.length - maxRules;
    result.rules.removeRange(maxRules, result.rules.length);
  }
  String header(String kind, int count) =>
      '# Tahor canonical blocklist ($kind)\n'
      '# Converted from EasyList and EasyPrivacy; see SOURCES.md for licences.\n'
      '# Rules: $count\n';
  File(outFull).writeAsStringSync(
    '${header('full', result.rules.length)}${result.rules.join('\n')}\n',
  );
  File(outSeed)
      .writeAsStringSync('${header('seed', seed.length)}${seed.join('\n')}\n');

  stdout.writeln(
    '{"kept":${result.rules.length},"block":${result.blockCount},'
    '"allow":${result.allowCount},"hide":${result.hideCount},'
    '"overCap":$overCap,'
    '"dropped":${_json(result.dropped)}}',
  );
}

String _json(Map<String, int> m) =>
    '{${m.entries.map((MapEntry<String, int> e) => '"${e.key}":${e.value}').join(',')}}';
