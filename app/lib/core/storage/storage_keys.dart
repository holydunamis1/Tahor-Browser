/// Every key and namespace the app stores under, in one place.
abstract final class StorageKeys {
  // Key-value store.
  static const String settings = 'app_settings';
  static const String keyValueSchemaVersion = 'schema.key_value';
  static const String sessionSnapshot = 'session_snapshot';

  // File store namespaces.
  static const String webViewStateNamespace = 'webview_state';
  static const String webViewStateIndexNamespace = 'webview_state_index';
  static const String thumbnailNamespace = 'thumbnails';
  static const String blocklistNamespace = 'blocklist';
  static const String pdfCacheNamespace = 'pdf_cache';

  // Database file.
  static const String databaseFileName = 'tahor.db';

  static final RegExp _valid = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$');

  /// Whether [value] may be used as a file-store namespace or key: letters,
  /// digits, dot, dash and underscore, starting with a letter or digit, at
  /// most 128 characters, and not ending in `.tmp` (reserved for atomic
  /// writes).
  static bool isValidKey(String value) =>
      _valid.hasMatch(value) && !value.endsWith('.tmp');
}
