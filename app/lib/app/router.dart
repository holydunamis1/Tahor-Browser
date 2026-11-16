import 'package:flutter/widgets.dart';

import '../core/constants/route_names.dart';
import '../screens/browser_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/core/app_page_route.dart';

/// Named routes. The first screen appears at once; every other screen uses
/// the app's page transition.
abstract final class AppRoutes {
  static Route<dynamic>? generate(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.browser:
        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (BuildContext context, _, _) => const BrowserScreen(),
        );
      case RouteNames.settings:
        return AppPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const SettingsScreen(),
        );
    }
    return null;
  }
}
