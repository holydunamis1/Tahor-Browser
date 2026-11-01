import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_theme_data.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

/// Picks the theme for a brightness.
abstract final class AppThemeBuilder {
  static AppThemeData forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? darkTheme : lightTheme;
}

/// Exposes the current [AppThemeData] to the widget tree. Every widget reads
/// colours, text styles, radii and shadows through [AppTheme.of].
class AppTheme extends InheritedWidget {
  const AppTheme({super.key, required this.data, required super.child});

  final AppThemeData data;

  /// The theme above [context]. Throws when there is none.
  static AppThemeData of(BuildContext context) {
    final AppThemeData? theme = maybeOf(context);
    if (theme == null) {
      throw FlutterError(
        'AppTheme.of() was called with a context that has no AppTheme above it.\n'
        'Wrap the app in AppTheme (app_shell does this).',
      );
    }
    return theme;
  }

  static AppThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTheme>()?.data;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => data != oldWidget.data;
}
