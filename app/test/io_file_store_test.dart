import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/contracts/file_store.dart';
import 'package:tahorbrowser/platform/common/io_file_store.dart';

void main() {
  late Directory root;
  late IoFileStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tahor_files_');
    store = IoFileStore(rootProvider: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  Uint8List bytes(List<int> v) => Uint8List.fromList(v);

  test('write then read returns the same bytes', () async {
    await store.write('ns', 'k', bytes(<int>[1, 2, 3]));
    expect(await store.read('ns', 'k'), bytes(<int>[1, 2, 3]));
  });

  test('reading a missing file gives null', () async {
    expect(await store.read('ns', 'nope'), isNull);
  });

  test(
    'writing again replaces the file and leaves no temporary file',
    () async {
      await store.write('ns', 'k', bytes(<int>[1]));
      await store.write('ns', 'k', bytes(<int>[9, 9]));
      expect(await store.read('ns', 'k'), bytes(<int>[9, 9]));
      final List<String> names = Directory('${root.path}/ns')
          .listSync()
          .map((FileSystemEntity e) => e.uri.pathSegments.last)
          .toList();
      expect(names, <String>['k']);
    },
  );

  test('list reports keys and sizes, and ignores leftovers of an interrupted write', () async {
    await store.write('ns', 'a', bytes(<int>[1, 2]));
    await store.write('ns', 'b', bytes(<int>[1, 2, 3]));
    await File('${root.path}/ns/c.tmp').writeAsBytes(<int>[1]);
    final List<FileEntry> entries = await store.list('ns');
    expect(
      <String, int>{for (final FileEntry e in entries) e.key: e.sizeBytes},
      <String, int>{'a': 2, 'b': 3},
    );
    expect(File('${root.path}/ns/c.tmp').existsSync(), isFalse);
  });

  test('listing a namespace that does not exist gives an empty list', () async {
    expect(await store.list('empty'), isEmpty);
  });

  test('delete says whether a file was removed', () async {
    await store.write('ns', 'k', bytes(<int>[1]));
    expect(await store.delete('ns', 'k'), isTrue);
    expect(await store.delete('ns', 'k'), isFalse);
    expect(await store.read('ns', 'k'), isNull);
  });

  test(
    'clear removes every file of a namespace and only that namespace',
    () async {
      await store.write('one', 'a', bytes(<int>[1]));
      await store.write('two', 'b', bytes(<int>[2]));
      await store.clear('one');
      expect(await store.list('one'), isEmpty);
      expect(await store.read('two', 'b'), bytes(<int>[2]));
      await store.clear('never-existed');
    },
  );

  test('names that could escape the directory are refused', () async {
    for (final String bad in <String>[
      '',
      '../x',
      'a/b',
      r'a\b',
      '.hidden',
      'k.tmp',
      'x' * 129,
    ]) {
      expect(
        () => store.write('ns', bad, bytes(<int>[1])),
        throwsArgumentError,
        reason: 'key "$bad"',
      );
      expect(
        () => store.write(bad, 'k', bytes(<int>[1])),
        throwsArgumentError,
        reason: 'namespace "$bad"',
      );
    }
  });
}
