import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/design_tokens.dart';

double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double lighter = la > lb ? la : lb;
  final double darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  final Map<String, AppPalette> palettes = <String, AppPalette>{
    'light': AppPalette.light,
    'dark': AppPalette.dark,
  };

  palettes.forEach((String mode, AppPalette p) {
    group('$mode palette', () {
      test('every text colour reaches 4.5:1 on every background', () {
        final Map<String, Color> texts = <String, Color>{
          'textPrimary': p.textPrimary,
          'textSecondary': p.textSecondary,
          'textTertiary': p.textTertiary,
        };
        final Map<String, Color> backgrounds = <String, Color>{
          'bgPrimary': p.bgPrimary,
          'bgSecondary': p.bgSecondary,
          'bgTertiary': p.bgTertiary,
        };
        texts.forEach((String tn, Color t) {
          backgrounds.forEach((String bn, Color b) {
            expect(
              contrast(t, b),
              greaterThanOrEqualTo(4.5),
              reason: '$tn on $bn in $mode',
            );
          });
        });
      });

      test('accent and status colours reach 4.5:1 as text', () {
        final Map<String, Color> colours = <String, Color>{
          'accent': p.accent,
          'error': p.error,
          'success': p.success,
          'warning': p.warning,
        };
        colours.forEach((String name, Color c) {
          expect(
            contrast(c, p.bgPrimary),
            greaterThanOrEqualTo(4.5),
            reason: '$name on bgPrimary in $mode',
          );
          expect(
            contrast(c, p.bgSecondary),
            greaterThanOrEqualTo(4.5),
            reason: '$name on bgSecondary in $mode',
          );
        });
      });

      test('text on the accent fill and on the accent tint is readable', () {
        expect(contrast(p.onAccent, p.accent), greaterThanOrEqualTo(4.5));
        expect(contrast(p.accent, p.accentDim), greaterThanOrEqualTo(4.5));
        expect(contrast(p.textPrimary, p.accentDim), greaterThanOrEqualTo(4.5));
      });

      test('surfaces and text colours are opaque', () {
        final List<Color> opaque = <Color>[
          p.bgPrimary,
          p.bgSecondary,
          p.bgTertiary,
          p.accent,
          p.accentDim,
          p.onAccent,
          p.textPrimary,
          p.textSecondary,
          p.textTertiary,
          p.error,
          p.success,
          p.warning,
        ];
        for (final Color c in opaque) {
          expect(c.a, 1.0);
        }
      });

      test('the focus border is the accent', () {
        expect(p.borderFocus, p.accent);
      });
    });
  });

  test('light and dark palettes differ', () {
    expect(AppPalette.light.bgPrimary, isNot(AppPalette.dark.bgPrimary));
    expect(AppPalette.light.textPrimary, isNot(AppPalette.dark.textPrimary));
  });
}
