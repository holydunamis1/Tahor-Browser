/// Converts Adblock Plus syntax filter lists (EasyList, EasyPrivacy) into the
/// canonical blocklist format of docs/BLUEPRINT.md section 4:
///
///     block|<url-filter regex>|<types csv or *>|<party>|<if-domain>|<unless-domain>
///     allow|<same fields>
///     hide|<domain csv or *>|<css selector>
///
/// Only the subset that Android and iPhone can both express is kept. Every
/// other rule is dropped and counted by reason, so the loss is visible.
library;

/// The outcome of converting one or more lists.
class ConvertResult {
  ConvertResult();

  /// Canonical lines in input order, without duplicates.
  final List<String> rules = <String>[];

  /// Why rules were dropped, with the number dropped for each reason.
  final Map<String, int> dropped = <String, int>{};

  int get blockCount => _count('block|');
  int get allowCount => _count('allow|');
  int get hideCount => _count('hide|');

  int _count(String prefix) =>
      rules.where((String r) => r.startsWith(prefix)).length;

  void _drop(String reason) => dropped[reason] = (dropped[reason] ?? 0) + 1;
}

/// The canonical resource types. `popup` is kept for completeness.
const Set<String> canonicalTypes = <String>{
  'document',
  'image',
  'style-sheet',
  'script',
  'font',
  'raw',
  'media',
  'svg-document',
  'popup',
};

const Map<String, String> _typeAliases = <String, String>{
  'script': 'script',
  'image': 'image',
  'stylesheet': 'style-sheet',
  'font': 'font',
  'media': 'media',
  'object': 'raw',
  'xmlhttprequest': 'raw',
  'xhr': 'raw',
  'ping': 'raw',
  'websocket': 'raw',
  'other': 'raw',
  'subdocument': 'document',
  'popup': 'popup',
};

/// Options that change nothing for blocking and are ignored.
const Set<String> _ignoredOptions = <String>{
  'important',
  'first-party-ignored',
};

/// Selector parts that need an engine this app does not have.
final RegExp _extendedSelector = RegExp(
  r':has-text|:-abp-|:xpath|:matches-css|:matches-path|:style\(|:remove\(|'
  r':upward|:min-text-length|:watch-attr|:others\(|:not\(:',
);

/// Converts [lines] and appends to [into] (or a new result).
ConvertResult convert(Iterable<String> lines, {ConvertResult? into}) {
  final ConvertResult result = into ?? ConvertResult();
  final Set<String> seen = result.rules.toSet();
  for (final String raw in lines) {
    final String line = raw.trim();
    if (line.isEmpty || line.startsWith('!') || line.startsWith('[')) {
      continue;
    }
    final String? rule = _convertLine(line, result);
    if (rule != null && seen.add(rule)) {
      result.rules.add(rule);
    }
  }
  return result;
}

String? _convertLine(String line, ConvertResult result) {
  if (line.contains('#@#')) {
    result._drop('cosmetic exception');
    return null;
  }
  if (line.contains('#?#') ||
      line.contains('#\$#') ||
      line.contains('##+js(') ||
      line.contains('#%#')) {
    result._drop('extended or scriptlet cosmetic');
    return null;
  }
  final int cosmetic = line.indexOf('##');
  if (cosmetic >= 0) {
    return _convertHide(
      line.substring(0, cosmetic),
      line.substring(cosmetic + 2),
      result,
    );
  }
  return _convertNetwork(line, result);
}

String? _convertHide(String domains, String selector, ConvertResult result) {
  if (selector.isEmpty) {
    result._drop('empty selector');
    return null;
  }
  if (_extendedSelector.hasMatch(selector)) {
    result._drop('extended selector');
    return null;
  }
  if (selector.contains('|')) {
    result._drop('selector contains the field separator');
    return null;
  }
  if (domains.contains('~')) {
    result._drop('cosmetic domain exclusion');
    return null;
  }
  final String scope = domains.isEmpty ? '*' : domains.toLowerCase();
  if (scope != '*' && !RegExp(r'^[a-z0-9.,-]+$').hasMatch(scope)) {
    result._drop('cosmetic domain not plain');
    return null;
  }
  return 'hide|$scope|$selector';
}

String? _convertNetwork(String original, ConvertResult result) {
  String line = original;
  final bool allow = line.startsWith('@@');
  if (allow) {
    line = line.substring(2);
  }
  String pattern = line;
  String options = '';
  final int dollar = line.lastIndexOf(r'$');
  if (dollar >= 0 && !line.substring(dollar).contains('/')) {
    pattern = line.substring(0, dollar);
    options = line.substring(dollar + 1);
  }
  if (pattern.length > 2 && pattern.startsWith('/') && pattern.endsWith('/')) {
    result._drop('regular expression');
    return null;
  }
  if (pattern.contains('|') && !_pipeOnlyAtAnchors(pattern)) {
    result._drop('pipe inside pattern');
    return null;
  }
  if (pattern.runes.any((int c) => c > 126 || c < 33)) {
    result._drop('non-ASCII or whitespace in pattern');
    return null;
  }

  final _Options? parsed = _parseOptions(options, result);
  if (parsed == null) {
    return null;
  }
  final String? regex = _toRegex(pattern, result);
  if (regex == null) {
    return null;
  }
  final String types = parsed.types.isEmpty
      ? '*'
      : (parsed.types.toList()..sort()).join(',');
  final String ifDomain = parsed.ifDomains.isEmpty
      ? '*'
      : parsed.ifDomains.join(',');
  final String unless = parsed.unlessDomains.isEmpty
      ? '*'
      : parsed.unlessDomains.join(',');
  return '${allow ? 'allow' : 'block'}|$regex|$types|${parsed.party}|$ifDomain|$unless';
}

bool _pipeOnlyAtAnchors(String p) {
  String body = p;
  if (body.startsWith('||')) {
    body = body.substring(2);
  } else if (body.startsWith('|')) {
    body = body.substring(1);
  }
  if (body.endsWith('|')) {
    body = body.substring(0, body.length - 1);
  }
  return !body.contains('|');
}

class _Options {
  final Set<String> types = <String>{};
  final List<String> ifDomains = <String>[];
  final List<String> unlessDomains = <String>[];
  String party = '*';
}

_Options? _parseOptions(String text, ConvertResult result) {
  final _Options out = _Options();
  if (text.isEmpty) {
    return out;
  }
  for (final String option in text.split(',')) {
    final String o = option.trim().toLowerCase();
    if (o.isEmpty || _ignoredOptions.contains(o)) {
      continue;
    }
    if (o == 'third-party' || o == '3p') {
      out.party = 'third';
    } else if (o == '~third-party' || o == 'first-party' || o == '1p') {
      out.party = 'first';
    } else if (o.startsWith('domain=')) {
      for (final String d in o.substring(7).split('|')) {
        final bool negative = d.startsWith('~');
        final String host = negative ? d.substring(1) : d;
        if (!RegExp(r'^[a-z0-9.-]+$').hasMatch(host)) {
          result._drop('domain option not plain');
          return null;
        }
        (negative ? out.unlessDomains : out.ifDomains).add(host);
      }
    } else if (_typeAliases.containsKey(o)) {
      out.types.add(_typeAliases[o]!);
    } else if (o.startsWith('~') && _typeAliases.containsKey(o.substring(1))) {
      result._drop('negated resource type');
      return null;
    } else {
      final String name = o.contains('=') ? o.substring(0, o.indexOf('=')) : o;
      result._drop('option: $name');
      return null;
    }
  }
  if (out.ifDomains.isNotEmpty && out.unlessDomains.isNotEmpty) {
    result._drop('both domain lists');
    return null;
  }
  return out;
}

/// Turns an ABP pattern into the regex subset WebKit accepts: literals,
/// `.`, `.*`, character classes, `?`, `^`, `$` and one optional group.
String? _toRegex(String pattern, ConvertResult result) {
  String p = pattern;
  final StringBuffer out = StringBuffer();
  bool hostAnchored = false;
  if (p.startsWith('||')) {
    hostAnchored = true;
    p = p.substring(2);
    out.write(r'^[^:]+://+([^:/]+\.)?');
  } else if (p.startsWith('|')) {
    p = p.substring(1);
    out.write('^');
  }
  bool endAnchor = false;
  if (p.endsWith('|')) {
    endAnchor = true;
    p = p.substring(0, p.length - 1);
  }
  if (p.isEmpty) {
    result._drop('empty pattern');
    return null;
  }
  final String literalCheck = p.replaceAll('*', '').replaceAll('^', '');
  if (!hostAnchored && !pattern.startsWith('|') && literalCheck.length < 4) {
    result._drop('pattern too generic');
    return null;
  }
  for (int i = 0; i < p.length; i++) {
    final String c = p[i];
    final bool last = i == p.length - 1;
    switch (c) {
      case '*':
        out.write('.*');
      case '^':
        out.write(last && !endAnchor ? r'[/:?]' : r'[^a-zA-Z0-9_.%-]');
      case '.' ||
          '+' ||
          '?' ||
          '(' ||
          ')' ||
          '[' ||
          ']' ||
          '{' ||
          '}' ||
          r'\' ||
          r'$' ||
          '|':
        out.write('\\$c');
      default:
        out.write(c);
    }
  }
  if (endAnchor) {
    out.write(r'$');
  }
  final String regex = out.toString();
  if (regex.contains('|')) {
    result._drop('pipe inside pattern');
    return null;
  }
  return regex;
}

/// Picks a compact starter list from [all]: first the pure host blocks (rules
/// that block a whole third-party host and nothing else), then generic hide
/// rules, up to the given caps. The order of the input is kept.
List<String> selectSeed(
  List<String> all, {
  required int maxBlocks,
  required int maxHides,
}) {
  final RegExp hostOnly = RegExp(
    r'^block\|\^\[\^:\]\+://\+\(\[\^:/\]\+\\\.\)\?[a-z0-9\\.-]+\[/:\?\]\|\*\|(third|\*)\|\*\|\*$',
  );
  final List<String> blocks = <String>[];
  final List<String> hides = <String>[];
  for (final String rule in all) {
    if (blocks.length < maxBlocks && hostOnly.hasMatch(rule)) {
      blocks.add(rule);
    } else if (hides.length < maxHides && rule.startsWith('hide|*|')) {
      hides.add(rule);
    }
  }
  return <String>[...blocks, ...hides];
}
