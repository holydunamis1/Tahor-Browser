import '../models/blocklist_rule.dart';

/// A line that could not be read, and why.
class ParseIssue {
  const ParseIssue(this.line, this.reason);

  /// 1-based line number.
  final int line;
  final String reason;

  @override
  String toString() => 'line $line: $reason';
}

/// What a parse found. A bad line costs only that line.
class ParseResult {
  const ParseResult(this.rules, this.issues, {this.truncated = false});

  final List<BlocklistRule> rules;
  final List<ParseIssue> issues;

  /// True when the list had more rules than the limit and the rest were left
  /// out.
  final bool truncated;
}

final RegExp _domain = RegExp(r'^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$');

/// Reads canonical blocklist text:
///
///     block|<url-filter>|<types csv or *>|<party>|<if-domain csv or *>|<unless-domain csv or *>
///     allow|<same fields>
///     hide|<domain csv or *>|<css selector>
///
/// Blank lines and lines starting with `#` are skipped. A line that is
/// malformed is reported in [ParseResult.issues] and skipped; the rest of the
/// list is still used.
ParseResult parseCanonical(
  String text, {
  int maxRules = 400000,
  int maxLineLength = 2048,
}) {
  final List<BlocklistRule> rules = <BlocklistRule>[];
  final List<ParseIssue> issues = <ParseIssue>[];
  bool truncated = false;
  int lineNumber = 0;
  for (final String raw in text.split('\n')) {
    lineNumber++;
    final String line = raw.endsWith('\r')
        ? raw.substring(0, raw.length - 1)
        : raw;
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    if (rules.length >= maxRules) {
      truncated = true;
      break;
    }
    if (line.length > maxLineLength) {
      issues.add(ParseIssue(lineNumber, 'line too long'));
      continue;
    }
    final Object result = _parseLine(line);
    if (result is BlocklistRule) {
      rules.add(result);
    } else {
      issues.add(ParseIssue(lineNumber, result as String));
    }
  }
  return ParseResult(
    List<BlocklistRule>.unmodifiable(rules),
    List<ParseIssue>.unmodifiable(issues),
    truncated: truncated,
  );
}

/// A [BlocklistRule] or a reason string.
Object _parseLine(String line) {
  final List<String> f = line.split('|');
  switch (f[0]) {
    case 'block' || 'allow':
      if (f.length != 6) {
        return 'expected 6 fields, found ${f.length}';
      }
      if (f[1].isEmpty || f[1].length > 1024) {
        return 'url filter is empty or too long';
      }
      final List<String>? types = _types(f[2]);
      if (types == null) {
        return 'unknown resource type';
      }
      final RuleParty? party = RuleParty.parse(f[3]);
      if (party == null) {
        return 'unknown party';
      }
      final List<String>? ifDomains = _domains(f[4]);
      final List<String>? unless = _domains(f[5]);
      if (ifDomains == null || unless == null) {
        return 'bad domain list';
      }
      return f[0] == 'block'
          ? BlockRule(
              urlFilter: f[1],
              types: types,
              party: party,
              ifDomains: ifDomains,
              unlessDomains: unless,
            )
          : AllowRule(
              urlFilter: f[1],
              types: types,
              party: party,
              ifDomains: ifDomains,
              unlessDomains: unless,
            );
    case 'hide':
      if (f.length != 3) {
        return 'expected 3 fields, found ${f.length}';
      }
      final List<String>? domains = _domains(f[1]);
      if (domains == null) {
        return 'bad domain list';
      }
      if (f[2].isEmpty || f[2].length > 1024) {
        return 'selector is empty or too long';
      }
      return HideRule(selector: f[2], domains: domains);
    default:
      return 'unknown rule kind';
  }
}

/// `*` is every type (an empty list); otherwise each must be a known type.
List<String>? _types(String field) {
  if (field == '*') {
    return const <String>[];
  }
  final List<String> types = field.split(',');
  for (final String t in types) {
    if (!ruleResourceTypes.contains(t)) {
      return null;
    }
  }
  return List<String>.unmodifiable(types);
}

/// `*` is no condition (an empty list); otherwise plain lower-case hosts.
List<String>? _domains(String field) {
  if (field == '*') {
    return const <String>[];
  }
  final List<String> domains = field.split(',');
  for (final String d in domains) {
    if (!_domain.hasMatch(d)) {
      return null;
    }
  }
  return List<String>.unmodifiable(domains);
}
