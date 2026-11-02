import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/l10n/gen/app_localizations.dart';
import 'package:tahorbrowser/l10n/l10n_extensions.dart';

void main() {
  testWidgets('context.l10n reaches the generated strings', (
    WidgetTester tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Builder(
          builder: (BuildContext context) {
            l10n = context.l10n;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(l10n.appName, 'Tahor Fast & Private Browser');
    expect(l10n.errorServer(404), 'The site had a problem (error 404).');
    expect(l10n.errorFallbackRetry, 'Try again');
  });
}
