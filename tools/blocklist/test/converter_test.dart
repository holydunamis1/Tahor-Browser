import 'package:tahor_blocklist_tools/abp_converter.dart';
import 'package:test/test.dart';

ConvertResult run(List<String> lines) => convert(lines);

void main() {
  const String hostPrefix = r'^[^:]+://+([^:/]+\.)?';

  group('network rules', () {
    test('a host anchor becomes a host block', () {
      expect(run(<String>['||ads.example.com^']).rules, <String>[
        'block|$hostPrefix'
            r'ads\.example\.com[/:?]|*|*|*|*',
      ]);
    });

    test('third-party and resource types are kept', () {
      expect(
        run(<String>[r'||tracker.net^$third-party,script,image']).rules,
        <String>[
          'block|$hostPrefix'
              r'tracker\.net[/:?]|image,script|third|*|*',
        ],
      );
    });

    test('a path pattern with a wildcard keeps its literal characters', () {
      expect(run(<String>[r'/banner/ads/*$image']).rules, <String>[
        'block|/banner/ads/.*|image|*|*|*',
      ]);
    });

    test('an exception rule becomes allow, with its domain list', () {
      expect(
        run(<String>[r'@@||good.com^$script,domain=site.com|other.org']).rules,
        <String>[
          'allow|$hostPrefix'
              r'good\.com[/:?]|script|*|site.com,other.org|*',
        ],
      );
    });

    test('excluded domains go to the unless list', () {
      expect(
        run(<String>[r'||x.com^$domain=~a.com|~b.com']).rules.single,
        endsWith('|*|*|a.com,b.com'),
      );
    });

    test('start and end anchors are kept', () {
      expect(run(<String>['|http://ads.example.com/|']).rules, <String>[
        r'block|^http://ads\.example\.com/$|*|*|*|*',
      ]);
    });

    test('a separator in the middle matches any non-word character', () {
      expect(
        run(<String>['||a.com^b']).rules.single,
        contains(r'[^a-zA-Z0-9_.%-]b'),
      );
    });

    test('regex special characters in the pattern are escaped', () {
      expect(
        run(<String>['/a+b(c)?d=e']).rules.single,
        startsWith(r'block|/a\+b\(c\)\?d=e|'),
      );
    });

    test('the same rule twice is kept once', () {
      expect(run(<String>['||ads.com^', '||ads.com^']).rules.length, 1);
    });

    test('the canonical fields never contain the separator inside a regex', () {
      for (final String rule in run(<String>[
        '||a.com^',
        '/x/y/z*',
        '|http://q.com/|',
      ]).rules) {
        expect(rule.split('|').length, 6, reason: rule);
      }
    });
  });

  group('what is dropped, and why', () {
    Map<String, int> dropped(String line) => run(<String>[line]).dropped;

    test('regular expressions', () {
      expect(dropped(r'/ads\d+/'), <String, int>{'regular expression': 1});
    });

    test('options the app cannot honour', () {
      expect(dropped(r'||x.com^$csp=default-src'), <String, int>{
        'option: csp': 1,
      });
      expect(dropped(r'||x.com^$redirect=noop.js'), <String, int>{
        'option: redirect': 1,
      });
      expect(dropped(r'||x.com^$removeparam=utm'), <String, int>{
        'option: removeparam': 1,
      });
    });

    test('negated resource types', () {
      expect(dropped(r'||x.com^$~script'), <String, int>{
        'negated resource type': 1,
      });
    });

    test('rules with both a domain list and an exclusion list', () {
      expect(dropped(r'||x.com^$domain=a.com|~b.com'), <String, int>{
        'both domain lists': 1,
      });
    });

    test('patterns too generic to block safely', () {
      expect(dropped('ad'), <String, int>{'pattern too generic': 1});
      expect(dropped('/ad'), <String, int>{'pattern too generic': 1});
      // Slashes at both ends make it a regular expression in this syntax.
      expect(dropped('/ad/'), <String, int>{'regular expression': 1});
    });

    test('non-ASCII patterns', () {
      expect(dropped('||bücher.de^'), <String, int>{
        'non-ASCII or whitespace in pattern': 1,
      });
    });

    test('a pipe inside the pattern, which would break the format', () {
      expect(dropped('/a|b/cdef'), <String, int>{'pipe inside pattern': 1});
    });

    test('comments, headers and blank lines are not counted', () {
      final ConvertResult r = run(<String>[
        '! comment',
        '[Adblock Plus 2.0]',
        '',
        '   ',
      ]);
      expect(r.rules, isEmpty);
      expect(r.dropped, isEmpty);
    });
  });

  group('element hiding', () {
    test('a generic and a domain rule', () {
      expect(
        run(<String>['##.sponsor', 'a.com,b.org##.ad-banner']).rules,
        <String>['hide|*|.sponsor', 'hide|a.com,b.org|.ad-banner'],
      );
    });

    test('extended selectors, exceptions and scriptlets are dropped', () {
      final ConvertResult r = run(<String>[
        'a.com##.x:has-text(Ad)',
        'a.com#@#.x',
        'a.com#?#.x',
        'a.com##+js(abort-on-property-read, x)',
        '~a.com##.x',
        'a.com##.x|y',
      ]);
      expect(r.rules, isEmpty);
      expect(r.dropped.values.fold(0, (int a, int b) => a + b), 6);
    });
  });
}
