import 'package:flutter/widgets.dart';

/// The spacing scale. Every gap in the interface is one of these values.
abstract final class Spacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  static const List<double> scale = <double>[xxs, xs, s, m, l, xl, xxl, xxxl];

  /// True for zero and for every value of the scale.
  static bool isOnScale(double value) => value == 0 || scale.contains(value);
}

/// Directional inset helpers, so layouts mirror in right-to-left languages.
/// Debug builds reject values outside the spacing scale.
abstract final class AppInsets {
  static EdgeInsetsDirectional all(double value) {
    assert(Spacing.isOnScale(value), 'Spacing $value is not on the scale');
    return EdgeInsetsDirectional.all(value);
  }

  static EdgeInsetsDirectional symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) {
    assert(
      Spacing.isOnScale(horizontal),
      'Spacing $horizontal is not on the scale',
    );
    assert(
      Spacing.isOnScale(vertical),
      'Spacing $vertical is not on the scale',
    );
    return EdgeInsetsDirectional.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  static EdgeInsetsDirectional horizontal(double value) =>
      symmetric(horizontal: value);

  static EdgeInsetsDirectional vertical(double value) =>
      symmetric(vertical: value);

  static EdgeInsetsDirectional only({
    double start = 0,
    double top = 0,
    double end = 0,
    double bottom = 0,
  }) {
    assert(Spacing.isOnScale(start), 'Spacing $start is not on the scale');
    assert(Spacing.isOnScale(top), 'Spacing $top is not on the scale');
    assert(Spacing.isOnScale(end), 'Spacing $end is not on the scale');
    assert(Spacing.isOnScale(bottom), 'Spacing $bottom is not on the scale');
    return EdgeInsetsDirectional.only(
      start: start,
      top: top,
      end: end,
      bottom: bottom,
    );
  }
}
