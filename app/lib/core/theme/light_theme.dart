import 'package:flutter/widgets.dart';

import '../constants/design_tokens.dart';
import '../constants/motion.dart';
import '../constants/radii.dart';
import '../constants/shadows.dart';
import '../constants/typography.dart';
import 'app_theme_data.dart';

/// The light theme.
const AppThemeData lightTheme = AppThemeData(
  brightness: Brightness.light,
  palette: AppPalette.light,
  text: AppTextStyles.standard,
  radii: AppRadii.standard,
  shadows: AppShadows.light,
  motion: Motion.standard,
);
