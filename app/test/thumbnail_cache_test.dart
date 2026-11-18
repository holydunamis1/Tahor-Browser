import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/services/thumbnail_cache.dart';
import 'package:tahorbrowser/core/storage/storage_keys.dart';

import 'support/fakes.dart';

void main() {
  late FakeFileStore files;
  late ThumbnailCache cache;

  Uint8List png(int v) => Uint8List.fromList(<int>[v]);
  Iterable<String> stored() =>
      files.data[StorageKeys.thumbnailNamespace]?.keys ?? <String>[];

  setUp(() {
    files = FakeFileStore();
    cache = ThumbnailCache(files, maxEntries: 3);
  });

  test('a preview can be read back', () async {
    await cache.put('a', png(1));
    expect(await cache.get('a'), png(1));
    expect(await cache.get('missing'), isNull);
  });

  test('going over the limit deletes the oldest previews', () async {
    for (final String id in <String>['a', 'b', 'c', 'd']) {
      await cache.put(id, png(1));
    }
    expect(stored().toSet(), <String>{'b', 'c', 'd'});
  });

  test('replacing a preview makes it the newest', () async {
    await cache.put('a', png(1));
    await cache.put('b', png(1));
    await cache.put('c', png(1));
    await cache.put('a', png(2));
    await cache.put('d', png(1));
    expect(stored().toSet(), <String>{'a', 'c', 'd'});
    expect(await cache.get('a'), png(2));
  });

  test('remove deletes one preview', () async {
    await cache.put('a', png(1));
    await cache.put('b', png(1));
    await cache.remove('a');
    expect(stored().toSet(), <String>{'b'});
  });

  test('keepOnly deletes the previews of tabs that no longer exist', () async {
    for (final String id in <String>['a', 'b', 'c']) {
      await cache.put(id, png(1));
    }
    await cache.keepOnly(<String>{'b'});
    expect(stored().toSet(), <String>{'b'});
  });

  test('previews from an earlier session count as the oldest', () async {
    files.data[StorageKeys.thumbnailNamespace] = <String, Uint8List>{
      'old1': png(1),
      'old2': png(1),
    };
    final ThumbnailCache fresh = ThumbnailCache(files, maxEntries: 3);
    await fresh.put('n1', png(1));
    await fresh.put('n2', png(1));
    expect(stored().toSet(), <String>{'old2', 'n1', 'n2'});
  });

  test('clear deletes everything', () async {
    await cache.put('a', png(1));
    await cache.clear();
    expect(stored(), isEmpty);
  });
}
