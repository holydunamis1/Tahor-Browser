import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/error/global_error_widget.dart';
import '../core/theme/app_theme_data.dart';
import '../core/theme/theme_builder.dart';
import '../l10n/gen/app_localizations.dart';
import '../widgets/core/app_page_route.dart';
import '../widgets/core/app_scroll_behavior.dart';
import '../core/app_scope.dart';
import 'router.dart';

/// The application: a `WidgetsApp` (there is no Material or Cupertino app
/// shell) with the theme, localizations, scrolling and page transition of
/// this app, and the fallback screen for errors.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Key _rootKey = UniqueKey();
  bool _errorWidgetInstalled = false;
  ErrorWidgetBuilder? _previousErrorWidget;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_errorWidgetInstalled) {
      return;
    }
    _errorWidgetInstalled = true;
    _previousErrorWidget = ErrorWidget.builder;
    final AppDependencies deps = AppScope.of(context);
    installErrorWidget(
      // Retry rebuilds everything below the root key.
      onRetry: () => setState(() => _rootKey = UniqueKey()),
      onReport: (String code) => unawaited(
        deps.launcher.openExternalApp(GlobalErrorView.reportUri(code)),
      ),
    );
  }

  @override
  void dispose() {
    // Give the framework its own error screen back when the app goes away.
    final ErrorWidgetBuilder? previous = _previousErrorWidget;
    if (previous != null) {
      ErrorWidget.builder = previous;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppDependencies deps = AppScope.of(context);
    return KeyedSubtree(
      key: _rootKey,
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[deps.theme, deps.locale]),
        builder: (BuildContext context, Widget? _) {
          return WidgetsApp(
            color: const Color(0xFF0A7487),
            locale: deps.locale.locale,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context).appName,
            onGenerateRoute: AppRoutes.generate,
            pageRouteBuilder: <T>(
              RouteSettings settings,
              WidgetBuilder builder,
            ) => AppPageRoute<T>(settings: settings, builder: builder),
            builder: (BuildContext context, Widget? child) {
              final AppThemeData theme = deps.theme.themeFor(
                MediaQuery.platformBrightnessOf(context),
              );
              return AppTheme(
                data: theme,
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: _overlayStyle(theme),
                  child: DefaultTextStyle(
                    style: theme.text.body.copyWith(
                      color: theme.palette.textPrimary,
                    ),
                    child: ScrollConfiguration(
                      behavior: const AppScrollBehavior(),
                      child: ColoredBox(
                        color: theme.palette.bgPrimary,
                        child: child!,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Transparent bars with icons that stay readable on the page colour.
  SystemUiOverlayStyle _overlayStyle(AppThemeData theme) {
    final Brightness iconBrightness = theme.isDark
        ? Brightness.light
        : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: theme.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.palette.bgPrimary,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: const Color(0x00000000),
    );
  }
}
