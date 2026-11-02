/// Small persistent values. Every call fails soft: when storage is not
/// available the implementation keeps the value in memory and reports it
/// through [hasFailed].
abstract interface class KeyValueStore {
  /// True once any storage call has failed.
  bool get hasFailed;

  Future<String?> getString(String key);
  Future<void> setString(String key, String value);

  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);

  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);

  /// A JSON object, or null when missing or unreadable.
  Future<Map<String, Object?>?> getJson(String key);
  Future<void> setJson(String key, Map<String, Object?> value);

  Future<void> remove(String key);
}
