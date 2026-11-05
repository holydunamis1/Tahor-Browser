import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/theme/app_theme_data.dart';
import 'package:tahorbrowser/core/theme/light_theme.dart';

import 'test_host.dart';

/// The variants every golden is taken in.
enum GoldenVariant {
  light('light', TextDirection.ltr, 1),
  dark('dark', TextDirection.ltr, 1),
  rtl('rtl', TextDirection.rtl, 1),
  largeText('text2x', TextDirection.ltr, 2);

  const GoldenVariant(this.name, this.direction, this.textScale);

  final String name;
  final TextDirection direction;
  final double textScale;
}

const Key goldenBoundary = Key('golden-boundary');

/// Pumps [child] on a 400 x 1100 surface in the given theme, direction and
/// text scale, wrapped in a boundary the golden compares.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  required AppThemeData theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(400, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    testHost(
      RepaintBoundary(
        key: goldenBoundary,
        child: ColoredBox(color: theme.palette.bgPrimary, child: child),
      ),
      theme: theme,
      direction: direction,
      media: MediaQueryData(
        size: const Size(400, 1100),
        textScaler: TextScaler.linear(textScale),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The light theme, for tests that do not care.
AppThemeData get defaultTheme => lightTheme;
