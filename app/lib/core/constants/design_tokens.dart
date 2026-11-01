import 'package:flutter/widgets.dart';

/// Colour tokens, frozen before any widget exists. Additions only; each one is
/// recorded in docs/DECISIONS.md.
///
/// Every text colour is verified against every background it can sit on at a
/// contrast ratio of at least 4.5:1 by test/design_tokens_test.dart.
@immutable
class AppPalette {
  const AppPalette({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.accent,
    required this.accentDim,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderSubtle,
    required this.borderFocus,
    required this.error,
    required this.success,
    required this.warning,
  });

  /// Page background.
  final Color bgPrimary;

  /// Cards, inputs and grouped surfaces.
  final Color bgSecondary;

  /// Pressed states, chips and nested surfaces.
  final Color bgTertiary;

  /// Brand colour: filled primary actions, links and active states.
  final Color accent;

  /// A solid tint of the accent for selected rows and quiet badges.
  final Color accentDim;

  /// Text and icons drawn on top of [accent].
  final Color onAccent;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Hairline borders on cards and dividers.
  final Color borderSubtle;

  /// The border of a focused input; equal to [accent].
  final Color borderFocus;

  final Color error;
  final Color success;
  final Color warning;

  /// The light palette: clean white surfaces, a deep teal accent.
  static const AppPalette light = AppPalette(
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF4F5F7),
    bgTertiary: Color(0xFFE7E9ED),
    accent: Color(0xFF0A7487),
    accentDim: Color(0xFFDDF0F3),
    onAccent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111318),
    textSecondary: Color(0xFF474C57),
    textTertiary: Color(0xFF596070),
    borderSubtle: Color(0x1F111318),
    borderFocus: Color(0xFF0A7487),
    error: Color(0xFFC42B2B),
    success: Color(0xFF1B7A38),
    warning: Color(0xFF8A5600),
  );

  /// The dark palette: true black for OLED, a lighter teal accent.
  static const AppPalette dark = AppPalette(
    bgPrimary: Color(0xFF000000),
    bgSecondary: Color(0xFF15171B),
    bgTertiary: Color(0xFF23262C),
    accent: Color(0xFF45C2D3),
    accentDim: Color(0xFF0E2D33),
    onAccent: Color(0xFF03181C),
    textPrimary: Color(0xFFF5F6F8),
    textSecondary: Color(0xFFB7BCC7),
    textTertiary: Color(0xFF9BA2AF),
    borderSubtle: Color(0x29F5F6F8),
    borderFocus: Color(0xFF45C2D3),
    error: Color(0xFFFF7A72),
    success: Color(0xFF55D483),
    warning: Color(0xFFFFC656),
  );
}
