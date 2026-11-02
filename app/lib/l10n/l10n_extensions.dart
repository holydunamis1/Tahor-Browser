import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

/// `context.l10n` reaches the generated localizations.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
