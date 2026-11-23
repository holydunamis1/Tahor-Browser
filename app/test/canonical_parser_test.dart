import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/blocklist/canonical_parser.dart';
import 'package:tahorbrowser/core/models/blocklist_rule.dart';

void main() {
  test('each kind of line becomes the matching rule', () {
    final ParseResult r = parseCanonical(
      'block|ads\\.x|script,image|third|a.com,b.org|*\n'
      'allow|good\\.x|*|*|*|c.com\n'
      'hide|*|.sponsor\n'
      'hide|a.com,b.org|.ad\n',
    );
    expect(r.issues, isEmpty);
    expect(r.rules, <BlocklistRule>[
      const BlockRule(
        urlFilter: r'ads\.x',
        types: <String>['script', 'image'],
        party: RuleParty.third,
        ifDomains: <String>['a.com', 'b.org'],
      ),
      const AllowRule(urlFilter: r'good\.x', unlessDomains: <String>['c.com']),
      const HideRule(selector: '.sponsor'),
      const HideRule(selector: '.ad', domains: <String>['a.com', 'b.org']),
    ]);
  });

  test('comments, blank lines and CRLF endings are handled', () {
    final ParseResult r = parseCanonical(
      '# header\r\n\r\nblock|x.y|*|*|*|*\r\n',
    );
    expect(r.issues, isEmpty);
    expect(r.rules.length, 1);
  });

  group('a bad line costs only that line', () {
    String reasonOf(String line) =>
        parseCanonical('$line\nblock|ok.ok|*|*|*|*').issues.single.reason;

    test('the good line after it is still read', () {
      final ParseResult r = parseCanonical('nonsense\nblock|ok.ok|*|*|*|*');
      expect(r.rules.length, 1);
      expect(r.issues.single.line, 1);
    });

    test('reasons', () {
      expect(reasonOf('wat|x'), 'unknown rule kind');
      expect(reasonOf('block|x|*|*|*'), contains('expected 6 fields'));
      expect(reasonOf('hide|*'), contains('expected 3 fields'));
      expect(reasonOf('block||*|*|*|*'), 'url filter is empty or too long');
      expect(reasonOf('block|x|flash|*|*|*'), 'unknown resource type');
      expect(reasonOf('block|x|*|mine|*|*'), 'unknown party');
      expect(reasonOf('block|x|*|*|A.com|*'), 'bad domain list');
      expect(reasonOf('block|x|*|*|a b|*'), 'bad domain list');
      expect(reasonOf('hide|*|'), 'selector is empty or too long');
    });

    test('a very long line is refused', () {
      final String long = 'block|${'a' * 3000}|*|*|*|*';
      expect(reasonOf(long), 'line too long');
    });
  });

  test('a list over the limit is cut and says so', () {
    final ParseResult r = parseCanonical(
      List<String>.generate(10, (int i) => 'block|x$i.y|*|*|*|*').join('\n'),
      maxRules: 4,
    );
    expect(r.rules.length, 4);
    expect(r.truncated, isTrue);
  });
}
