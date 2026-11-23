import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/blocklist/content_rule_compiler.dart';
import 'package:tahorbrowser/core/models/blocklist_rule.dart';

List<Map<String, Object?>> decode(String list) =>
    (jsonDecode(list) as List<Object?>).cast<Map<String, Object?>>();

BlockRule block(String filter, {RuleParty party = RuleParty.any}) =>
    BlockRule(urlFilter: filter, party: party);

String hostRule(String host) =>
    '^[^:]+://+([^:/]+\\.)?${host.replaceAll('.', '\\.')}[/:?]';

void main() {
  group('cache key', () {
    test('is the same for the same inputs in any order', () {
      expect(
        ContentRuleCompiler.cacheKey(3, <String>['b.com', 'a.com']),
        ContentRuleCompiler.cacheKey(3, <String>['a.com', 'b.com', 'a.com']),
      );
    });

    test('changes with the version and with the exceptions', () {
      final String base = ContentRuleCompiler.cacheKey(3, <String>['a.com']);
      expect(ContentRuleCompiler.cacheKey(4, <String>['a.com']), isNot(base));
      expect(ContentRuleCompiler.cacheKey(3, <String>['b.com']), isNot(base));
      expect(ContentRuleCompiler.cacheKey(3, <String>[]), isNot(base));
    });
  });

  group('iPhone', () {
    test('a block rule keeps its conditions in WebKit spelling', () {
      final IosRuleLists out = ContentRuleCompiler.compileIos(<BlocklistRule>[
        const BlockRule(
          urlFilter: r'ads\.x',
          types: <String>['script', 'image'],
          party: RuleParty.third,
          ifDomains: <String>['a.com'],
        ),
      ]);
      expect(decode(out.lists.single), <Map<String, Object?>>[
        <String, Object?>{
          'trigger': <String, Object?>{
            'url-filter': r'ads\.x',
            'resource-type': <String>['script', 'image'],
            'load-type': <String>['third-party'],
            'if-domain': <String>['*a.com'],
          },
          'action': <String, Object?>{'type': 'block'},
        },
      ]);
      expect(out.ruleCount, 1);
    });

    test('a first-party rule and an unless-domain rule', () {
      final List<Map<String, Object?>> rules = decode(
        ContentRuleCompiler.compileIos(<BlocklistRule>[
          const BlockRule(
            urlFilter: 'x.y',
            party: RuleParty.first,
            unlessDomains: <String>['ok.com'],
          ),
        ]).lists.single,
      );
      final Map<String, Object?> trigger =
          rules.single['trigger']! as Map<String, Object?>;
      expect(trigger['load-type'], <String>['first-party']);
      expect(trigger['unless-domain'], <String>['*ok.com']);
      expect(trigger.containsKey('if-domain'), isFalse);
    });

    test('exceptions follow the blocks in the same list', () {
      final List<Map<String, Object?>> rules = decode(
        ContentRuleCompiler.compileIos(<BlocklistRule>[
          block('a.b'),
          const AllowRule(urlFilter: 'good.b'),
          block('c.d'),
        ]).lists.single,
      );
      expect(
        rules.map((Map<String, Object?> r) => (r['action']! as Map)['type']),
        <Object?>['block', 'block', 'ignore-previous-rules'],
      );
    });

    test(
      'element hiding is a css-display-none rule, scoped when it has domains',
      () {
        final List<Map<String, Object?>> rules = decode(
          ContentRuleCompiler.compileIos(<BlocklistRule>[
            const HideRule(selector: '.ad'),
            const HideRule(selector: '.promo', domains: <String>['a.com']),
          ]).lists.single,
        );
        expect(rules[0]['action'], <String, Object?>{
          'type': 'css-display-none',
          'selector': '.ad',
        });
        expect(rules[0]['trigger'], <String, Object?>{'url-filter': '.*'});
        expect(
          (rules[1]['trigger']! as Map<String, Object?>)['if-domain'],
          <String>['*a.com'],
        );
      },
    );

    test('per-site exceptions are appended to every list', () {
      final IosRuleLists out = ContentRuleCompiler.compileIos(
        <BlocklistRule>[block('a.b'), const HideRule(selector: '.x')],
        exceptionHosts: <String>['site.com'],
      );
      expect(out.lists.length, 2);
      for (final String list in out.lists) {
        final Map<String, Object?> last = decode(list).last;
        expect(last['action'], <String, Object?>{
          'type': 'ignore-previous-rules',
        });
        expect(
          (last['trigger']! as Map<String, Object?>)['if-domain'],
          <String>['*site.com'],
        );
      }
    });

    test('a rule with both domain lists is left out and counted', () {
      final IosRuleLists out = ContentRuleCompiler.compileIos(<BlocklistRule>[
        const BlockRule(
          urlFilter: 'x.y',
          ifDomains: <String>['a.com'],
          unlessDomains: <String>['b.com'],
        ),
        block('ok.ok'),
      ]);
      expect(out.skipped, 1);
      expect(out.ruleCount, 1);
    });

    test('lists never exceed the limit, and exceptions stay in each', () {
      final List<BlocklistRule> rules = <BlocklistRule>[
        for (int i = 0; i < 5; i++) block('b$i.x'),
        const AllowRule(urlFilter: 'good.x'),
      ];
      final IosRuleLists out = ContentRuleCompiler.compileIos(
        rules,
        listLimit: 3,
      );
      expect(out.lists.length, 3);
      for (final String list in out.lists) {
        final List<Map<String, Object?>> l = decode(list);
        expect(l.length, lessThanOrEqualTo(3));
        expect((l.last['action']! as Map)['type'], 'ignore-previous-rules');
      }
      expect(out.ruleCount, 5);
    });

    test('allow rules beyond a quarter of a list are dropped', () {
      final IosRuleLists out = ContentRuleCompiler.compileIos(<BlocklistRule>[
        block('a.b'),
        for (int i = 0; i < 6; i++) AllowRule(urlFilter: 'g$i.x'),
      ], listLimit: 8);
      expect(out.skipped, 4);
      expect(decode(out.lists.single).length, 3);
    });

    test('the output is the same every time', () {
      final List<BlocklistRule> rules = <BlocklistRule>[
        block('a.b'),
        block('c.d'),
      ];
      expect(
        ContentRuleCompiler.compileIos(rules).lists,
        ContentRuleCompiler.compileIos(rules).lists,
      );
    });

    test('no rules give no lists', () {
      expect(ContentRuleCompiler.compileIos(<BlocklistRule>[]).lists, isEmpty);
    });
  });

  group('Android', () {
    test('host blocks with the same conditions become one pattern', () {
      final AndroidRuleSet out = ContentRuleCompiler.compileAndroid(
        <BlocklistRule>[
          block(hostRule('a.com')),
          block(hostRule('b.org')),
          block(hostRule('c.net')),
        ],
      );
      expect(out.entries.length, 1);
      final String filter =
          (out.entries.single['trigger']!
                  as Map<String, Object?>)['url-filter']!
              as String;
      expect(filter, contains(r'(a\.com|b\.org|c\.net)'));
    });

    test('the merged pattern matches the hosts and their subdomains only', () {
      final String filter =
          (ContentRuleCompiler.compileAndroid(<BlocklistRule>[
                    block(hostRule('a.com')),
                    block(hostRule('b.org')),
                  ]).entries.single['trigger']!
                  as Map<String, Object?>)['url-filter']!
              as String;
      final RegExp re = RegExp(filter);
      expect(re.hasMatch('https://a.com/x'), isTrue);
      expect(re.hasMatch('https://sub.b.org/x?y=1'), isTrue);
      expect(re.hasMatch('https://a.com.evil.net/x'), isFalse);
      expect(re.hasMatch('https://nota.com/x'), isFalse);
      expect(re.hasMatch('https://c.com/x'), isFalse);
    });

    test('different conditions are kept apart', () {
      final AndroidRuleSet out = ContentRuleCompiler.compileAndroid(
        <BlocklistRule>[
          block(hostRule('a.com')),
          block(hostRule('b.org'), party: RuleParty.third),
        ],
      );
      expect(out.entries.length, 2);
    });

    test('a long group is split into entries of the given size', () {
      final AndroidRuleSet out = ContentRuleCompiler.compileAndroid(
        <BlocklistRule>[for (int i = 0; i < 5; i++) block(hostRule('h$i.com'))],
        hostsPerEntry: 2,
      );
      expect(out.entries.length, 3);
    });

    test('other rules stay as they are', () {
      final AndroidRuleSet out = ContentRuleCompiler.compileAndroid(
        <BlocklistRule>[block('/banner/ads/.*')],
      );
      expect(
        (out.entries.single['trigger']! as Map<String, Object?>)['url-filter'],
        '/banner/ads/.*',
      );
    });

    test('exceptions are dropped and counted; hiding is left to the cosmetic filter', () {
      final AndroidRuleSet out = ContentRuleCompiler.compileAndroid(
        <BlocklistRule>[
          block(hostRule('a.com')),
          const AllowRule(urlFilter: 'good.x'),
          const AllowRule(urlFilter: 'good2.x'),
          const HideRule(selector: '.x'),
        ],
      );
      expect(out.droppedAllows, 2);
      expect(out.entries.length, 1);
    });

    test('the entry cap is a hard limit and the excess is counted', () {
      final AndroidRuleSet out = ContentRuleCompiler.compileAndroid(
        <BlocklistRule>[for (int i = 0; i < 10; i++) block('/p$i/xyz')],
        maxEntries: 4,
      );
      expect(out.entries.length, 4);
      expect(out.truncated, 6);
    });

    test('a rule with both domain lists is skipped', () {
      final AndroidRuleSet out = ContentRuleCompiler.compileAndroid(
        <BlocklistRule>[
          const BlockRule(
            urlFilter: 'x.y',
            ifDomains: <String>['a.com'],
            unlessDomains: <String>['b.com'],
          ),
        ],
      );
      expect(out.skipped, 1);
      expect(out.entries, isEmpty);
    });
  });
}
