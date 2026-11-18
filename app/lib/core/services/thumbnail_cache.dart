import 'dart:typed_data';

import '../contracts/file_store.dart';
import '../storage/storage_keys.dart';

/// Small PNG previews of tabs, kept for the tab grid. At most [maxEntries] are
/// kept; the oldest are deleted first. A preview is deleted with its tab.
class ThumbnailCache {
  ThumbnailCache(this._files, {this.maxEntries = 24})
    : assert(maxEntries > 0, 'The cache must keep at least one preview.');

  final FileStore _files;
  final int maxEntries;

  /// Oldest first. Previews found on disk that this session did not write are
  /// treated as older than any it did.
  final List<String> _order = <String>[];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    for (final FileEntry entry in await _files.list(
      StorageKeys.thumbnailNamespace,
    )) {
      _order.add(entry.key);
    }
  }

  Future<void> put(String tabId, Uint8List png) async {
    await _load();
    await _files.write(StorageKeys.thumbnailNamespace, tabId, png);
    _order
      ..remove(tabId)
      ..add(tabId);
    while (_order.length > maxEntries) {
      final String oldest = _order.removeAt(0);
      await _files.delete(StorageKeys.thumbnailNamespace, oldest);
    }
  }

  Future<Uint8List?> get(String tabId) =>
      _files.read(StorageKeys.thumbnailNamespace, tabId);

  Future<void> remove(String tabId) async {
    await _load();
    _order.remove(tabId);
    await _files.delete(StorageKeys.thumbnailNamespace, tabId);
  }

  /// Deletes every preview whose tab is not in [tabIds].
  Future<void> keepOnly(Set<String> tabIds) async {
    await _load();
    for (final String key in List<String>.of(_order)) {
      if (!tabIds.contains(key)) {
        _order.remove(key);
        await _files.delete(StorageKeys.thumbnailNamespace, key);
      }
    }
  }

  Future<void> clear() async {
    _order.clear();
    _loaded = true;
    await _files.clear(StorageKeys.thumbnailNamespace);
  }
}
