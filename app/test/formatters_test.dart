import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahorbrowser/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('de');
  });

  group('formatBytes', () {
    test('small sizes are whole bytes', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(999), '999 B');
    });

    test('units are 1000 and decimals shrink as the number grows', () {
      expect(formatBytes(1000), '1.00 KB');
      expect(formatBytes(1500), '1.50 KB');
      expect(formatBytes(12345), '12.3 KB');
      expect(formatBytes(123456), '123 KB');
      expect(formatBytes(1500000), '1.50 MB');
      expect(formatBytes(123456789), '123 MB');
      expect(formatBytes(1500000000), '1.50 GB');
    });

    test('rounding up to 1000 moves to the next unit', () {
      expect(formatBytes(999999), '1.00 MB');
      expect(formatBytes(999999999), '1.00 GB');
    });

    test('negative sizes show as zero and huge sizes stay in terabytes', () {
      expect(formatBytes(-5), '0 B');
      expect(formatBytes(5000000000000000), '5,000 TB');
    });

    test('numbers follow the locale', () {
      expect(formatBytes(1500, locale: 'de'), '1,50 KB');
      expect(formatBytes(1500, locale: 'en'), '1.50 KB');
    });
  });

  test('formatNumber groups digits by locale', () {
    expect(formatNumber(1234567, locale: 'en'), '1,234,567');
    expect(formatNumber(1234567, locale: 'de'), '1.234.567');
  });

  group('classifyRelativeTime', () {
    final DateTime now = DateTime(2026, 11, 1, 12);

    RelativeTime at(Duration ago) =>
        classifyRelativeTime(now.subtract(ago), now: now);

    test('under a minute and the future are just now', () {
      expect(at(Duration.zero), const RelativeTime(RelativeUnit.justNow, 0));
      expect(
        at(const Duration(seconds: 59)),
        const RelativeTime(RelativeUnit.justNow, 0),
      );
      expect(
        at(const Duration(minutes: -5)),
        const RelativeTime(RelativeUnit.justNow, 0),
      );
    });

    test('minutes, hours and days', () {
      expect(
        at(const Duration(minutes: 1)),
        const RelativeTime(RelativeUnit.minutes, 1),
      );
      expect(
        at(const Duration(minutes: 59)),
        const RelativeTime(RelativeUnit.minutes, 59),
      );
      expect(
        at(const Duration(minutes: 60)),
        const RelativeTime(RelativeUnit.hours, 1),
      );
      expect(
        at(const Duration(hours: 23)),
        const RelativeTime(RelativeUnit.hours, 23),
      );
      expect(
        at(const Duration(hours: 24)),
        const RelativeTime(RelativeUnit.days, 1),
      );
      expect(
        at(const Duration(days: 6)),
        const RelativeTime(RelativeUnit.days, 6),
      );
    });

    test('a week or more is a date', () {
      expect(
        at(const Duration(days: 7)),
        const RelativeTime(RelativeUnit.date, 0),
      );
      expect(
        at(const Duration(days: 400)),
        const RelativeTime(RelativeUnit.date, 0),
      );
    });
  });

  test('formatDate follows the locale', () {
    final DateTime d = DateTime(2026, 11, 1);
    expect(formatDate(d, locale: 'en'), 'Nov 1, 2026');
    expect(formatDate(d, locale: 'de'), '1. Nov. 2026');
  });

  test('formatTime shows hours and minutes', () {
    final String t = formatTime(DateTime(2026, 11, 1, 15, 5), locale: 'en');
    expect(t, contains('3:05'));
    expect(t, contains('PM'));
  });

  test('formatDisplayHost delegates to the display host rules', () {
    expect(formatDisplayHost('https://www.example.com/a'), 'example.com');
  });
}
