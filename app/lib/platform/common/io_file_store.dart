import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../core/contracts/file_store.dart';
import '../../core/error/error_taxonomy.dart';
import '../../core/storage/storage_keys.dart';

/// [FileStore] over a directory in the app's private storage.
///
/// Writes go to a `.tmp` file that is renamed into place, so an interrupted
/// write never leaves half a file behind.
class IoFileStore implements FileStore {
  IoFileStore({Future<Directory> Function()? rootProvider})
    : _rootProvider = rootProvider ?? _defaultRoot;

  final Future<Directory> Function() _rootProvider;

  static Future<Directory> _defaultRoot() async {
    final Directory base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}files');
  }

  static const int _noSpaceLeft = 28;

  Future<Directory> _dir(String namespace) async {
    _check(namespace, 'namespace');
    final Directory root = await _rootProvider();
    return Directory('${root.path}${Platform.pathSeparator}$namespace');
  }

  static void _check(String value, String what) {
    if (!StorageKeys.isValidKey(value)) {
      throw ArgumentError.value(value, what, 'is not a valid storage name');
    }
  }

  Future<File> _file(String namespace, String key) async {
    _check(key, 'key');
    final Directory dir = await _dir(namespace);
    return File('${dir.path}${Platform.pathSeparator}$key');
  }

  @override
  Future<void> write(String namespace, String key, Uint8List bytes) async {
    final File target = await _file(namespace, key);
    final File temp = File('${target.path}.tmp');
    try {
      await target.parent.create(recursive: true);
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(target.path);
    } on FileSystemException catch (error) {
      throw error.osError?.errorCode == _noSpaceLeft
          ? const StorageError.full()
          : StorageError.writeFailed(
              detail: '$namespace/$key: ${error.message}',
            );
    }
  }

  @override
  Future<Uint8List?> read(String namespace, String key) async {
    final File file = await _file(namespace, key);
    try {
      return await file.readAsBytes();
    } on PathNotFoundException {
      return null;
    } on FileSystemException catch (error) {
      throw StorageError.readFailed(
        detail: '$namespace/$key: ${error.message}',
      );
    }
  }

  @override
  Future<bool> delete(String namespace, String key) async {
    final File file = await _file(namespace, key);
    try {
      await file.delete();
      return true;
    } on PathNotFoundException {
      return false;
    } on FileSystemException catch (error) {
      throw StorageError.writeFailed(
        detail: '$namespace/$key: ${error.message}',
      );
    }
  }

  @override
  Future<List<FileEntry>> list(String namespace) async {
    final Directory dir = await _dir(namespace);
    final List<FileEntry> entries = <FileEntry>[];
    try {
      if (!await dir.exists()) {
        return entries;
      }
      await for (final FileSystemEntity entity in dir.list()) {
        if (entity is! File) {
          continue;
        }
        final String name = entity.uri.pathSegments.last;
        if (name.endsWith('.tmp')) {
          // Left behind by an interrupted write.
          await entity.delete();
          continue;
        }
        entries.add(FileEntry(name, await entity.length()));
      }
    } on FileSystemException catch (error) {
      throw StorageError.readFailed(detail: '$namespace: ${error.message}');
    }
    return entries;
  }

  @override
  Future<void> clear(String namespace) async {
    final Directory dir = await _dir(namespace);
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } on FileSystemException catch (error) {
      throw StorageError.writeFailed(detail: '$namespace: ${error.message}');
    }
  }
}
