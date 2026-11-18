import 'dart:typed_data';

/// One stored file.
class FileEntry {
  const FileEntry(this.key, this.sizeBytes);

  final String key;
  final int sizeBytes;
}

/// Files by namespace and key (saved web view state, thumbnails, cached
/// blocklists). Keys and namespaces follow `StorageKeys.isValidKey`; anything
/// else throws an `ArgumentError`. Everything else fails with `StorageError`.
abstract interface class FileStore {
  /// Replaces the file atomically: a reader sees the old bytes or the new
  /// bytes, never half of each.
  Future<void> write(String namespace, String key, Uint8List bytes);

  /// The bytes, or null when there is no such file.
  Future<Uint8List?> read(String namespace, String key);

  /// True when a file was removed.
  Future<bool> delete(String namespace, String key);

  Future<List<FileEntry>> list(String namespace);

  /// Removes every file of [namespace].
  Future<void> clear(String namespace);
}
