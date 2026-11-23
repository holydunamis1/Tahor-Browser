import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/blocklist/cosmetic_filter.dart';
import 'package:tahorbrowser/core/models/blocklist_rule.dart';

void main() {
  final CosmeticFilter filter = CosmeticFilter(<BlocklistRule>[
    const HideRule(selector: '.ad'),
    const HideRule(selector: '.promo', domains: <String>['a.com']),
    const HideRule(selector: '.both', domains: <String>['a.com', 'b.org']),
    const BlockRule(urlFilter: 'not-a-hide-rule'),
  ]);

  test('generic selectors apply everywhere', () {
    expect(filter.selectorsFor('unrelated.net'), <String>['.ad']);
    expect(filter.genericSelectors, <String>['.ad']);
  });

  test('a domain rule applies on the domain and on its subdomains', () {
    expect(filter.selectorsFor('a.com'), <String>['.ad', '.promo', '.both']);
    expect(filter.selectorsFor('news.a.com'), <String>[
      '.ad',
      '.promo',
      '.both',
    ]);
    expect(filter.selectorsFor('x.y.a.com'), contains('.promo'));
  });

  test('a host that only ends with the same letters does not match', () {
    expect(filter.selectorsFor('nota.com'), <String>['.ad']);
  });

  test('matching ignores case', () {
    expect(filter.selectorsFor('A.COM'), contains('.promo'));
  });

  test('a rule with several domains applies on each', () {
    expect(filter.selectorsFor('b.org'), <String>['.ad', '.both']);
  });

  test('a page gets at most the cap', () {
    final CosmeticFilter big = CosmeticFilter(<BlocklistRule>[
      for (int i = 0; i < CosmeticFilter.maxSelectorsPerPage + 50; i++)
        HideRule(selector: '.s$i'),
    ]);
    expect(
      big.selectorsFor('a.com').length,
      CosmeticFilter.maxSelectorsPerPage,
    );
  });

  group('the document-start script', () {
    test('nothing to hide gives no script', () {
      expect(CosmeticFilter.styleScript(<String>[]), '');
    });

    test('each selector is its own style rule, so one bad one cannot break the rest', () {
      final String script = CosmeticFilter.styleScript(<String>['.a', '.b']);
      expect(script, contains('[".a",".b"]'));
      expect(script, contains('{display:none!important}'));
      expect(script, contains('.map('));
    });

    test('quotes in a selector cannot end the string early', () {
      final String script = CosmeticFilter.styleScript(<String>['a[href="x"]']);
      expect(script, contains(r'a[href=\"x\"]'));
    });
  });
}
