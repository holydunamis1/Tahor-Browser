import 'package:flutter/widgets.dart';

import '../constants/design_tokens.dart';
import '../constants/motion.dart';
import '../constants/radii.dart';
import '../constants/shadows.dart';
import '../constants/typography.dart';

/// Everything a widget needs to draw itself: palette, text styles, radii,
/// shadows and motion. Plain immutable Dart; there is no Material ThemeData.
///
/// Only two instances exist (the light and dark compile-time constants), so
/// equality is identity.
@immutable
class AppThemeData {
  const AppThemeData({
    required this.brightness,
    required this.palette,
    required this.text,
    required this.radii,
    required this.shadows,
    required this.motion,
  });

  final Brightness brightness;
  final AppPalette palette;
  final AppTextStyles text;
  final AppRadii radii;
  final AppShadows shadows;
  final Motion motion;

  bool get isDark => brightness == Brightness.dark;
}
