import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/scripts/scroll_capture_script.dart';

void main() {
  test('the read script is a self-contained expression', () {
    expect(ScrollScripts.read, startsWith('(function(){'));
    expect(ScrollScripts.read, endsWith('})()'));
    expect(ScrollScripts.read, contains('pageYOffset'));
  });

  test('the restore script scrolls to the rounded target', () {
    expect(ScrollScripts.restore(1234.6), contains('var t=1235,'));
    expect(ScrollScripts.restore(0), contains('var t=0,'));
  });

  test('the restore script never carries a bad number into the page', () {
    for (final double bad in <double>[
      double.nan,
      double.infinity,
      double.negativeInfinity,
      -50,
    ]) {
      final String script = ScrollScripts.restore(bad);
      expect(script, contains('var t=0,'), reason: '$bad');
      expect(script, isNot(contains('NaN')));
      expect(script, isNot(contains('Infinity')));
    }
  });

  test('a huge position is written as plain digits, not exponent notation', () {
    expect(ScrollScripts.restore(1e12), contains('var t=1000000000000,'));
  });

  test(
    'the restore script retries five times before scrolling as far as it can',
    () {
      final String script = ScrollScripts.restore(500);
      expect(script, contains('n>=5'));
      expect(script, contains('setTimeout(go,300)'));
    },
  );

  test('a read result is accepted only when it is a sane position', () {
    expect(ScrollScripts.parse(120), 120);
    expect(ScrollScripts.parse(12.5), 12.5);
    expect(ScrollScripts.parse(null), 0);
    expect(ScrollScripts.parse('120'), 0);
    expect(ScrollScripts.parse(-3), 0);
    expect(ScrollScripts.parse(double.nan), 0);
    expect(ScrollScripts.parse(double.infinity), 0);
  });
}
