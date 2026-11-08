import '../contracts/key_value_store.dart';
import '../models/app_settings.dart';

/// Loads and saves [AppSettings] as one JSON value.
class SettingsService {
  const SettingsService(this._store);

  static const String storageKey = 'app_settings';

  final KeyValueStore _store;

  /// True once the store has failed and values are only kept in memory.
  bool get persistenceFailed => _store.hasFailed;

  /// The saved settings, or the defaults when there are none or the saved
  /// value cannot be read (which is then discarded).
  Future<AppSettings> load() async {
    final String? raw = await _store.getString(storageKey);
    if (raw == null) {
      return const AppSettings();
    }
    final Map<String, Object?>? json = await _store.getJson(storageKey);
    if (json == null) {
      await _store.remove(storageKey);
      return const AppSettings();
    }
    return AppSettings.fromJson(json);
  }

  Future<void> save(AppSettings settings) =>
      _store.setJson(storageKey, settings.toJson());
}
