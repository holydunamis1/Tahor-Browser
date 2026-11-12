import 'package:flutter/widgets.dart';

import 'contracts/app_info.dart';
import 'contracts/external_launcher.dart';
import 'contracts/share.dart';
import 'error/global_error_handler.dart';
import 'providers/locale_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/tabs_provider.dart';
import 'providers/theme_provider.dart';

/// Everything the screens need, built once at start-up. It holds contracts
/// and providers only; the platform code that implements them is never
/// visible here.
class AppDependencies {
  const AppDependencies({
    required this.settings,
    required this.theme,
    required this.locale,
    required this.tabs,
    required this.errorHandler,
    required this.launcher,
    required this.share,
    required this.appInfo,
  });

  final SettingsProvider settings;
  final ThemeProvider theme;
  final LocaleProvider locale;
  final TabsProvider tabs;
  final GlobalErrorHandler errorHandler;
  final ExternalLauncher launcher;
  final Share share;
  final AppInfo appInfo;
}

/// Makes [AppDependencies] available to every screen below it.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  /// The dependencies above [context]. Throws when there are none.
  static AppDependencies of(BuildContext context) {
    final AppScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw FlutterError(
        'AppScope.of() was called with a context that has no AppScope above it.',
      );
    }
    return scope.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
