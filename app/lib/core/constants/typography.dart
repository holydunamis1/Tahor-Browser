import 'package:flutter/widgets.dart';

/// The four type roles. System fonts only.
enum AppTextRole {
  /// The brand wordmark and large titles.
  display,

  /// UI labels and buttons.
  chrome,

  /// Reading text.
  body,

  /// Verbatim text such as addresses and error codes.
  mono,
}

/// The type scale. Sizes follow Apple's text styles. Styles carry no colour:
/// widgets apply a palette colour with `copyWith`.
@immutable
class AppTextStyles {
  const AppTextStyles({
    required this.display,
    required this.headline,
    required this.title1,
    required this.title2,
    required this.body,
    required this.callout,
    required this.footnote,
    required this.caption,
    required this.mono,
  });

  /// 34 / 700, role display.
  final TextStyle display;

  /// 28 / 600, role display.
  final TextStyle headline;

  /// 22 / 600, role chrome (screen titles).
  final TextStyle title1;

  /// 17 / 600, role chrome (buttons and row titles).
  final TextStyle title2;

  /// 17 / 400, role body.
  final TextStyle body;

  /// 16 / 500, role chrome.
  final TextStyle callout;

  /// 13 / 400, role chrome.
  final TextStyle footnote;

  /// 12 / 400, role chrome.
  final TextStyle caption;

  /// 15 / 400, role mono.
  final TextStyle mono;

  static const AppTextStyles standard = AppTextStyles(
    display: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.12,
      letterSpacing: -0.6,
    ),
    headline: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.4,
    ),
    title1: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    title2: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.1,
    ),
    body: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.4),
    callout: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.3),
    footnote: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.3),
    caption: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.3,
      letterSpacing: 0.1,
    ),
    mono: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.35,
      fontFamily: 'monospace',
      fontFamilyFallback: <String>['Menlo', 'Courier New', 'Courier'],
    ),
  );

  /// The default style of a role.
  TextStyle forRole(AppTextRole role) {
    switch (role) {
      case AppTextRole.display:
        return display;
      case AppTextRole.chrome:
        return callout;
      case AppTextRole.body:
        return body;
      case AppTextRole.mono:
        return mono;
    }
  }
}
