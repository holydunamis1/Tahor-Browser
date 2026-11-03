import 'package:flutter/widgets.dart';
import 'package:tahorbrowser/core/theme/app_theme_data.dart';
import 'package:tahorbrowser/core/theme/light_theme.dart';
import 'package:tahorbrowser/core/theme/theme_builder.dart';
import 'package:tahorbrowser/l10n/gen/app_localizations.dart';

const MediaQueryData defaultMedia = MediaQueryData(size: Size(800, 600));

/// The theme the helpers use unless a test asks for another.
const AppThemeData routeHostDefaultTheme = lightTheme;

Widget _frame({
  required Widget child,
  required AppThemeData theme,
  required TextDirection direction,
  required MediaQueryData media,
}) {
  // Localizations sets its own text direction, so ours goes below it.
  return MediaQuery(
    data: media,
    child: Localizations(
      locale: const Locale('en'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Directionality(
        textDirection: direction,
        child: AppTheme(data: theme, child: child),
      ),
    ),
  );
}

/// A widget under test inside text direction, media, localizations, theme and
/// an overlay (text fields and menus need one).
Widget testHost(
  Widget child, {
  AppThemeData theme = lightTheme,
  TextDirection direction = TextDirection.ltr,
  MediaQueryData media = defaultMedia,
}) {
  return _frame(
    theme: theme,
    direction: direction,
    media: media,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(builder: (BuildContext context) => child),
      ],
    ),
  );
}

/// A navigator whose first page is built by [home], for route tests.
Widget routeHost(
  GlobalKey<NavigatorState> key,
  WidgetBuilder home, {
  AppThemeData theme = lightTheme,
  TextDirection direction = TextDirection.ltr,
  MediaQueryData media = defaultMedia,
  RouteFactory? onGenerateRoute,
}) {
  return _frame(
    theme: theme,
    direction: direction,
    media: media,
    child: Navigator(
      key: key,
      onGenerateRoute:
          onGenerateRoute ??
          (RouteSettings settings) => PageRouteBuilder<void>(
            settings: settings,
            pageBuilder: (BuildContext context, _, _) => home(context),
          ),
    ),
  );
}
