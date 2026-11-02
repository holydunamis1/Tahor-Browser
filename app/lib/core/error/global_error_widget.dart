import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import '../constants/icon_sizes.dart';
import '../constants/spacing.dart';
import '../theme/app_theme_data.dart';
import '../theme/theme_builder.dart';
import 'error_taxonomy.dart';

/// The words on the fallback screen. They default to English because this
/// view must work even when localizations are not available.
@immutable
class GlobalErrorStrings {
  const GlobalErrorStrings({
    required this.title,
    required this.message,
    required this.retry,
    required this.report,
    required this.codeLabel,
  });

  static const GlobalErrorStrings english = GlobalErrorStrings(
    title: 'Something went wrong',
    message: 'Tahor ran into a problem. You can try again or send us the error code.',
    retry: 'Try again',
    report: 'Send error code',
    codeLabel: 'Error code',
  );

  final String title;
  final String message;
  final String retry;
  final String report;
  final String codeLabel;
}

/// The full-screen fallback that replaces a widget that failed to build.
///
/// It is deliberately self-contained: it uses no app widgets, because the
/// thing that failed may be one of them.
class GlobalErrorView extends StatelessWidget {
  const GlobalErrorView({
    super.key,
    required this.code,
    required this.onRetry,
    required this.onReport,
    this.strings = GlobalErrorStrings.english,
  });

  final String code;
  final VoidCallback onRetry;
  final void Function(String code) onReport;
  final GlobalErrorStrings strings;

  /// A `mailto:` address carrying only the error code. Spaces are encoded as
  /// %20 because mail apps show a plus sign literally.
  static Uri reportUri(String code) {
    final String subject = Uri.encodeComponent('Tahor error report');
    final String body = Uri.encodeComponent('Error code: $code');
    return Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      query: 'subject=$subject&body=$body',
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme =
        AppTheme.maybeOf(context) ??
        AppThemeBuilder.forBrightness(
          MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light,
        );
    final TextDirection direction =
        Directionality.maybeOf(context) ?? TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: ColoredBox(
        color: theme.palette.bgPrimary,
        child: DefaultTextStyle(
          style: theme.text.body.copyWith(color: theme.palette.textPrimary),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(Spacing.l),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        strings.title,
                        textAlign: TextAlign.center,
                        style: theme.text.title1,
                      ),
                    ),
                    const SizedBox(height: Spacing.s),
                    Text(
                      strings.message,
                      textAlign: TextAlign.center,
                      style: theme.text.body.copyWith(
                        color: theme.palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.l),
                    _ErrorButton(
                      label: strings.retry,
                      theme: theme,
                      filled: true,
                      onTap: onRetry,
                    ),
                    const SizedBox(height: Spacing.s),
                    _ErrorButton(
                      label: strings.report,
                      theme: theme,
                      filled: false,
                      onTap: () => onReport(code),
                    ),
                    const SizedBox(height: Spacing.m),
                    Text(
                      '${strings.codeLabel}: $code',
                      textAlign: TextAlign.center,
                      style: theme.text.mono.copyWith(
                        color: theme.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorButton extends StatelessWidget {
  const _ErrorButton({
    required this.label,
    required this.theme,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final AppThemeData theme;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: IconSizes.minHitTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: filled ? theme.palette.accent : null,
              borderRadius: theme.radii.buttonRadius,
            ),
            child: Center(
              child: Text(
                label,
                style: theme.text.title2.copyWith(
                  color: filled ? theme.palette.onAccent : theme.palette.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Replaces the framework's default red error screen with [GlobalErrorView].
void installErrorWidget({
  required VoidCallback onRetry,
  required void Function(String code) onReport,
  GlobalErrorStrings strings = GlobalErrorStrings.english,
}) {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final AppError error = AppError.classify(
      details.exception,
      fromBuild: true,
    );
    return GlobalErrorView(
      code: error.code,
      onRetry: onRetry,
      onReport: onReport,
      strings: strings,
    );
  };
}
