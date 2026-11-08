import 'package:flutter/widgets.dart';

import 'settings_provider.dart';

/// The language override: a chosen locale, or null to follow the phone.
/// Notifies only when the choice changes.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider(this._settings) : _code = _settings.value.localeCode {
    _settings.addListener(_onSettings);
  }

  final SettingsProvider _settings;
  String? _code;

  /// The chosen locale, or null for the phone's language.
  Locale? get locale => _code == null ? null : Locale(_code!);

  void _onSettings() {
    final String? next = _settings.value.localeCode;
    if (next != _code) {
      _code = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettings);
    super.dispose();
  }
}
