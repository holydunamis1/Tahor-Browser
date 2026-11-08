import 'package:flutter/widgets.dart';

import '../models/app_settings.dart';
import '../theme/app_theme_data.dart';
import '../theme/theme_builder.dart';
import 'settings_provider.dart';

/// The theme in force: the person's choice, or the phone's when they chose
/// to follow it. Notifies only when the choice changes.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._settings) : _mode = _settings.value.themeMode {
    _settings.addListener(_onSettings);
  }

  final SettingsProvider _settings;
  AppThemeMode _mode;

  AppThemeMode get mode => _mode;

  /// The theme to draw with, given the phone's current brightness.
  AppThemeData themeFor(Brightness platformBrightness) {
    switch (_mode) {
      case AppThemeMode.light:
        return AppThemeBuilder.forBrightness(Brightness.light);
      case AppThemeMode.dark:
        return AppThemeBuilder.forBrightness(Brightness.dark);
      case AppThemeMode.system:
        return AppThemeBuilder.forBrightness(platformBrightness);
    }
  }

  void _onSettings() {
    final AppThemeMode next = _settings.value.themeMode;
    if (next != _mode) {
      _mode = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettings);
    super.dispose();
  }
}
