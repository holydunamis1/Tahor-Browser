import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

/// The current settings. A change is visible at once and saved in order in
/// the background.
class SettingsProvider extends ValueNotifier<AppSettings> {
  SettingsProvider({
    required this._service,
    AppSettings initial = const AppSettings(),
  }) : super(initial);

  final SettingsService _service;
  Future<void> _saving = Future<void>.value();

  /// True when settings could not be saved and may be lost on exit.
  final ValueNotifier<bool> persistenceFailed = ValueNotifier<bool>(false);

  /// Reads the saved settings into this provider.
  Future<void> load() async {
    value = await _service.load();
    persistenceFailed.value = _service.persistenceFailed;
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _change((AppSettings s) => s.copyWith(themeMode: mode));

  Future<void> setSearchEngine(String id) =>
      _change((AppSettings s) => s.copyWith(searchEngineId: id));

  /// Pass null to follow the phone's language.
  Future<void> setLocale(String? code) =>
      _change((AppSettings s) => s.copyWith(localeCode: code));

  Future<void> _change(AppSettings Function(AppSettings) change) {
    final AppSettings next = change(value);
    if (next == value) {
      return _saving;
    }
    value = next;
    _saving = _saving.then((_) => _persist(next));
    return _saving;
  }

  Future<void> _persist(AppSettings settings) async {
    try {
      await _service.save(settings);
      persistenceFailed.value = _service.persistenceFailed;
    } on Exception {
      persistenceFailed.value = true;
    }
  }

  @override
  void dispose() {
    persistenceFailed.dispose();
    super.dispose();
  }
}
