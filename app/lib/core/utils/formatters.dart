import 'package:intl/intl.dart';

import 'url_utils.dart';

/// A file size such as `999 B`, `1.50 KB`, `12.3 MB` or `123 MB` (units of
/// 1000, as in the system file managers), with the locale's number format.
String formatBytes(int bytes, {String? locale}) {
  final int safe = bytes < 0 ? 0 : bytes;
  if (safe < 1000) {
    return '${NumberFormat.decimalPattern(locale).format(safe)} B';
  }
  const List<String> units = <String>['KB', 'MB', 'GB', 'TB'];
  double value = safe / 1000;
  int unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  int decimals = _decimalsFor(value);
  // Rounding can reach 1000 (999.999 KB); move to the next unit instead.
  if (double.parse(value.toStringAsFixed(decimals)) >= 1000 &&
      unit < units.length - 1) {
    value /= 1000;
    unit++;
    decimals = _decimalsFor(value);
  }
  final NumberFormat format = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimals,
  );
  return '${format.format(value)} ${units[unit]}';
}

int _decimalsFor(double value) => value < 10 ? 2 : (value < 100 ? 1 : 0);

/// A number with the locale's grouping and decimal marks.
String formatNumber(num value, {String? locale}) =>
    NumberFormat.decimalPattern(locale).format(value);

/// How long ago something happened, as a unit and a count. Widgets turn this
/// into words with the localized plural strings.
enum RelativeUnit { justNow, minutes, hours, days, date }

class RelativeTime {
  const RelativeTime(this.unit, this.count);

  final RelativeUnit unit;

  /// Zero for [RelativeUnit.justNow] and [RelativeUnit.date].
  final int count;

  @override
  bool operator ==(Object other) =>
      other is RelativeTime && other.unit == unit && other.count == count;

  @override
  int get hashCode => Object.hash(unit, count);

  @override
  String toString() => 'RelativeTime($unit, $count)';
}

/// Classifies the distance between [when] and [now]: under a minute is "just
/// now" (also for times in the future), then minutes, hours, days up to a
/// week, and after that a calendar date.
RelativeTime classifyRelativeTime(DateTime when, {required DateTime now}) {
  final Duration age = now.difference(when);
  if (age.inMinutes < 1) {
    return const RelativeTime(RelativeUnit.justNow, 0);
  }
  if (age.inMinutes < 60) {
    return RelativeTime(RelativeUnit.minutes, age.inMinutes);
  }
  if (age.inHours < 24) {
    return RelativeTime(RelativeUnit.hours, age.inHours);
  }
  if (age.inDays < 7) {
    return RelativeTime(RelativeUnit.days, age.inDays);
  }
  return const RelativeTime(RelativeUnit.date, 0);
}

/// A calendar date such as `Nov 1, 2026`. The locale's date data must be
/// initialized (the localization delegates do this in the app).
String formatDate(DateTime date, {String? locale}) =>
    DateFormat.yMMMd(locale).format(date);

/// A clock time in the locale's 12 or 24 hour style.
String formatTime(DateTime date, {String? locale}) =>
    DateFormat.jm(locale).format(date);

/// The host of [url] as shown in the interface (see [displayHost]).
String formatDisplayHost(String url) => displayHostOf(url);
