import 'package:flutter/widgets.dart';

import '../constants/design_tokens.dart';
import '../constants/motion.dart';
import '../constants/radii.dart';
import '../constants/shadows.dart';
import '../constants/typography.dart';
import 'app_theme_data.dart';

/// The dark theme. It has no shadows.
const AppThemeData darkTheme = AppThemeData(
  brightness: Brightness.dark,
  palette: AppPalette.dark,
  text: AppTextStyles.standard,
  radii: AppRadii.standard,
  shadows: AppShadows.dark,
  motion: Motion.standard,
);
