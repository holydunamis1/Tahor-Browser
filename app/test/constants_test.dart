import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/app_constants.dart';
import 'package:tahorbrowser/core/constants/icon_sizes.dart';
import 'package:tahorbrowser/core/constants/radii.dart';
import 'package:tahorbrowser/core/constants/spacing.dart';
import 'package:tahorbrowser/core/constants/typography.dart';

void main() {
  group('spacing', () {
    test('the scale is 2, 4, 8, 16, 24, 32, 48, 64', () {
      expect(Spacing.scale, <double>[2, 4, 8, 16, 24, 32, 48, 64]);
    });

    test('isOnScale accepts zero and scale values only', () {
      expect(Spacing.isOnScale(0), isTrue);
      expect(Spacing.isOnScale(16), isTrue);
      expect(Spacing.isOnScale(10), isFalse);
    });

    test('insets are directional', () {
      expect(AppInsets.all(8), const EdgeInsetsDirectional.all(8));
      expect(
        AppInsets.only(start: 16, bottom: 8),
        const EdgeInsetsDirectional.only(start: 16, bottom: 8),
      );
      expect(
        AppInsets.horizontal(24),
        const EdgeInsetsDirectional.symmetric(horizontal: 24),
      );
    });

    test('off-scale insets are rejected in debug builds', () {
      expect(() => AppInsets.all(10), throwsAssertionError);
    });
  });

  group('radii', () {
    const AppRadii r = AppRadii.standard;

    test('values match the specification', () {
      expect(r.card, 16);
      expect(r.hero, 20);
      expect(r.chip, 8);
      expect(r.button, 12);
      expect(r.input, 12);
      expect(r.sheet, 20);
      expect(r.dialog, 16);
    });

    test('sheets round the top corners only', () {
      expect(r.sheetRadius.topLeft, const Radius.circular(20));
      expect(r.sheetRadius.topRight, const Radius.circular(20));
      expect(r.sheetRadius.bottomLeft, Radius.zero);
      expect(r.sheetRadius.bottomRight, Radius.zero);
    });

    test('a pill is half its height', () {
      expect(r.pill(48).topLeft, const Radius.circular(24));
    });
  });

  group('icons', () {
    test('sizes match the specification', () {
      expect(IconSizes.nav, 24);
      expect(IconSizes.rowLeading, 22);
      expect(IconSizes.rowTrailing, 20);
      expect(IconSizes.hero, 32);
      expect(IconSizes.chipContainer, 40);
      expect(IconSizes.minHitTarget, 48);
    });

    test('regular weight at 20 px and below, bold above', () {
      expect(IconSizes.weightFor(20), AppIconWeight.regular);
      expect(IconSizes.weightFor(16), AppIconWeight.regular);
      expect(IconSizes.weightFor(22), AppIconWeight.bold);
      expect(IconSizes.weightFor(24), AppIconWeight.bold);
    });
  });

  group('typography', () {
    const AppTextStyles t = AppTextStyles.standard;

    test('sizes and weights match the specification', () {
      expect(t.display.fontSize, 34);
      expect(t.display.fontWeight, FontWeight.w700);
      expect(t.headline.fontSize, 28);
      expect(t.headline.fontWeight, FontWeight.w600);
      expect(t.title1.fontSize, 22);
      expect(t.title1.fontWeight, FontWeight.w600);
      expect(t.title2.fontSize, 17);
      expect(t.title2.fontWeight, FontWeight.w600);
      expect(t.body.fontSize, 17);
      expect(t.body.fontWeight, FontWeight.w400);
      expect(t.callout.fontSize, 16);
      expect(t.callout.fontWeight, FontWeight.w500);
      expect(t.footnote.fontSize, 13);
      expect(t.footnote.fontWeight, FontWeight.w400);
      expect(t.caption.fontSize, 12);
      expect(t.caption.fontWeight, FontWeight.w400);
    });

    test('each role maps to a style', () {
      expect(t.forRole(AppTextRole.display), t.display);
      expect(t.forRole(AppTextRole.chrome), t.callout);
      expect(t.forRole(AppTextRole.body), t.body);
      expect(t.forRole(AppTextRole.mono), t.mono);
    });

    test('only the mono role names a font family', () {
      expect(t.body.fontFamily, isNull);
      expect(t.callout.fontFamily, isNull);
      expect(t.mono.fontFamily, 'monospace');
    });
  });

  group('app constants', () {
    test('the blob ceiling is 20 MB', () {
      expect(AppConstants.blobCeilingBytes, 20 * 1024 * 1024);
    });

    test('the default engine exists in the list', () {
      expect(
        AppConstants.searchEngines.map((SearchEngine e) => e.id),
        contains(AppConstants.defaultSearchEngineId),
      );
    });

    test('engine ids are unique and templates carry the placeholder', () {
      final Set<String> ids = <String>{};
      for (final SearchEngine e in AppConstants.searchEngines) {
        expect(ids.add(e.id), isTrue, reason: 'duplicate id ${e.id}');
        expect(e.urlTemplate, contains('{query}'));
        expect(e.urlTemplate, startsWith('https://'));
      }
    });

    test('urlFor encodes the query', () {
      final SearchEngine ddg = AppConstants.engineById('duckduckgo');
      expect(
        ddg.urlFor('hello world'),
        'https://duckduckgo.com/?q=hello+world',
      );
      expect(ddg.urlFor('a&b=c'), 'https://duckduckgo.com/?q=a%26b%3Dc');
    });

    test('an unknown engine id falls back to the default', () {
      expect(
        AppConstants.engineById('nope').id,
        AppConstants.defaultSearchEngineId,
      );
    });

    test('site addresses are https and share one origin', () {
      expect(AppUrls.privacy, startsWith('${AppUrls.site}/'));
      expect(AppUrls.support, startsWith('${AppUrls.site}/'));
      expect(AppUrls.blocklistLatest, startsWith('${AppUrls.site}/blocklist/'));
      expect(AppUrls.site, startsWith('https://'));
    });
  });
}
