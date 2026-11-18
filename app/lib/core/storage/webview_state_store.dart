import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../contracts/file_store.dart';
import 'schema_version.dart';
import 'storage_keys.dart';

/// Saved web view state per tab, kept within a size budget.
///
/// Each blob is capped, and when the total passes the budget the least
/// recently used blobs are deleted first. An index file remembers the order;
/// if it is missing or damaged it is rebuilt from the files, so a bad index
/// loses the order, never the data.
class WebViewStateStore {
  WebViewStateStore(
    this._files, {
    this.maxBlobBytes = defaultMaxBlobBytes,
    this.maxTotalBytes = defaultMaxTotalBytes,
  }) : assert(
         maxBlobBytes <= maxTotalBytes,
         'A blob larger than the whole budget could never be kept.',
       );

  static const int defaultMaxBlobBytes = 2 * 1024 * 1024;
  static const int defaultMaxTotalBytes = 16 * 1024 * 1024;

  static const String _indexKey = 'index';

  final FileStore _files;
  final int maxBlobBytes;
  final int maxTotalBytes;

  /// Oldest first; the last entry is the most recently used.
  final List<FileEntry> _order = <FileEntry>[];
  bool _loaded = false;
  Future<void>? _tail;

  /// Saves [bytes] under [key]. Returns false, and keeps nothing new, when the
  /// blob is larger than [maxBlobBytes].
  Future<bool> put(String key, Uint8List bytes) => _locked(() async {
    if (bytes.length > maxBlobBytes) {
      return false;
    }
    await _load();
    await _files.write(StorageKeys.webViewStateNamespace, key, bytes);
    _order.removeWhere((FileEntry e) => e.key == key);
    _order.add(FileEntry(key, bytes.length));
    int total = _order.fold(0, (int sum, FileEntry e) => sum + e.sizeBytes);
    while (total > maxTotalBytes && _order.length > 1) {
      final FileEntry oldest = _order.removeAt(0);
      total -= oldest.sizeBytes;
      await _files.delete(StorageKeys.webViewStateNamespace, oldest.key);
    }
    await _saveIndex();
    return true;
  });

  /// The saved bytes, or null. Reading marks the blob as recently used.
  Future<Uint8List?> get(String key) => _locked(() async {
    await _load();
    final Uint8List? bytes = await _files.read(
      StorageKeys.webViewStateNamespace,
      key,
    );
    final int at = _order.indexWhere((FileEntry e) => e.key == key);
    if (bytes == null) {
      if (at >= 0) {
        _order.removeAt(at);
        await _saveIndex();
      }
      return null;
    }
    if (at >= 0) {
      _order.removeAt(at);
    }
    _order.add(FileEntry(key, bytes.length));
    await _saveIndex();
    return bytes;
  });

  Future<void> remove(String key) => _locked(() async {
    await _load();
    await _files.delete(StorageKeys.webViewStateNamespace, key);
    _order.removeWhere((FileEntry e) => e.key == key);
    await _saveIndex();
  });

  /// Deletes every saved state.
  Future<void> clear() => _locked(() async {
    await _files.clear(StorageKeys.webViewStateNamespace);
    await _files.clear(StorageKeys.webViewStateIndexNamespace);
    _order.clear();
    _loaded = true;
  });

  /// The saved keys, least recently used first.
  Future<List<String>> keys() => _locked(() async {
    await _load();
    return <String>[for (final FileEntry e in _order) e.key];
  });

  /// Runs one operation at a time, so two saves never race over the index. The
  /// chain starts from a future made here, in the caller's zone.
  Future<T> _locked<T>(Future<T> Function() action) {
    final Completer<T> done = Completer<T>();
    _tail = (_tail ?? Future<void>.value()).then((_) async {
      try {
        done.complete(await action());
      } on Object catch (error, stack) {
        done.completeError(error, stack);
      }
    });
    return done.future;
  }

  /// Reads the index once and reconciles it with the files that exist.
  Future<void> _load() async {
    if (_loaded) {
      return;
    }
    final Map<String, int> onDisk = <String, int>{
      for (final FileEntry e in await _files.list(
        StorageKeys.webViewStateNamespace,
      ))
        e.key: e.sizeBytes,
    };
    final List<String> ordered = await _readIndex();
    _order.clear();
    // Files the index does not know come first, so they are evicted first.
    for (final String key in onDisk.keys) {
      if (!ordered.contains(key)) {
        _order.add(FileEntry(key, onDisk[key]!));
      }
    }
    for (final String key in ordered) {
      final int? size = onDisk[key];
      if (size != null) {
        _order.add(FileEntry(key, size));
      }
    }
    _loaded = true;
  }

  Future<List<String>> _readIndex() async {
    try {
      final Uint8List? raw = await _files.read(
        StorageKeys.webViewStateIndexNamespace,
        _indexKey,
      );
      if (raw == null) {
        return const <String>[];
      }
      final Object? decoded = jsonDecode(utf8.decode(raw));
      if (decoded is Map<String, Object?> &&
          decoded['v'] == SchemaVersions.webViewStateIndex &&
          decoded['order'] is List<Object?>) {
        return <String>[
          for (final Object? k in decoded['order']! as List<Object?>)
            if (k is String) k,
        ];
      }
    } on FormatException {
      // A damaged index is rebuilt from the files.
    }
    return const <String>[];
  }

  Future<void> _saveIndex() => _files.write(
    StorageKeys.webViewStateIndexNamespace,
    _indexKey,
    Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'v': SchemaVersions.webViewStateIndex,
          'order': <String>[for (final FileEntry e in _order) e.key],
        }),
      ),
    ),
  );
}
