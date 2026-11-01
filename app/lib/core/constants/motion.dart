import 'package:flutter/widgets.dart';

/// Durations and curves. Ease curves only, no springs. When the platform asks
/// for reduced motion every duration is zero.
@immutable
class Motion {
  const Motion({
    required this.push,
    required this.pop,
    required this.sheet,
    required this.press,
    required this.success,
    required this.theme,
    required this.curve,
    required this.decelerate,
  });

  final Duration push;
  final Duration pop;
  final Duration sheet;
  final Duration press;
  final Duration success;
  final Duration theme;

  /// The default ease for movement.
  final Curve curve;

  /// The ease for things entering.
  final Curve decelerate;

  static const Motion standard = Motion(
    push: Duration(milliseconds: 350),
    pop: Duration(milliseconds: 280),
    sheet: Duration(milliseconds: 400),
    press: Duration(milliseconds: 150),
    success: Duration(milliseconds: 300),
    theme: Duration(milliseconds: 200),
    curve: Curves.easeInOut,
    decelerate: Curves.easeOut,
  );

  static const Motion reduced = Motion(
    push: Duration.zero,
    pop: Duration.zero,
    sheet: Duration.zero,
    press: Duration.zero,
    success: Duration.zero,
    theme: Duration.zero,
    curve: Curves.linear,
    decelerate: Curves.linear,
  );

  /// The motion to use here: [reduced] when the platform requests it.
  static Motion of(BuildContext context) {
    final bool disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return disabled ? reduced : standard;
  }
}
