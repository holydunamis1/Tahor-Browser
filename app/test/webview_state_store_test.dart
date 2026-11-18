import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/storage/storage_keys.dart';
import 'package:tahorbrowser/core/storage/webview_state_store.dart';

import 'support/fakes.dart';

Uint8List blob(int size, [int fill = 1]) =>
    Uint8List.fromList(List<int>.filled(size, fill));

void main() {
  late FakeFileStore files;
  late WebViewStateStore store;

  WebViewStateStore make({int blobMax = 100, int totalMax = 250}) =>
      WebViewStateStore(files, maxBlobBytes: blobMax, maxTotalBytes: totalMax);

  setUp(() {
    files = FakeFileStore();
    store = make();
  });

  test('a saved state can be read back', () async {
    expect(await store.put('a', blob(10, 7)), isTrue);
    expect(await store.get('a'), blob(10, 7));
  });

  test('an unknown key reads as null', () async {
    expect(await store.get('missing'), isNull);
  });

  test('saving again replaces the state', () async {
    await store.put('a', blob(10, 1));
    await store.put('a', blob(20, 2));
    expect(await store.get('a'), blob(20, 2));
    expect(await store.keys(), <String>['a']);
  });

  test(
    'a blob over the per-blob cap is refused and nothing is written',
    () async {
      expect(await store.put('big', blob(101)), isFalse);
      expect(await store.get('big'), isNull);
      expect(files.data[StorageKeys.webViewStateNamespace], isNull);
    },
  );

  test('a blob exactly at the cap is kept', () async {
    expect(await store.put('edge', blob(100)), isTrue);
  });

  test(
    'going over the total budget removes the least recently used first',
    () async {
      await store.put('a', blob(100));
      await store.put('b', blob(100));
      await store.put('c', blob(100));
      expect(await store.keys(), <String>['b', 'c']);
      expect(await store.get('a'), isNull);
      expect(files.data[StorageKeys.webViewStateNamespace]!.keys, <String>{
        'b',
        'c',
      });
    },
  );

  test('reading a state protects it from eviction', () async {
    await store.put('a', blob(100));
    await store.put('b', blob(100));
    await store.get('a');
    await store.put('c', blob(100));
    expect(await store.keys(), <String>['a', 'c']);
  });

  test('several evictions happen when one large blob arrives', () async {
    await store.put('a', blob(80));
    await store.put('b', blob(80));
    await store.put('c', blob(80));
    await store.put('d', blob(100));
    expect(await store.keys(), <String>['c', 'd']);
  });

  test('the newest blob is always kept', () async {
    final WebViewStateStore tight = make(blobMax: 100, totalMax: 100);
    await tight.put('a', blob(100));
    await tight.put('b', blob(100));
    expect(await tight.keys(), <String>['b']);
  });

  test('remove deletes the state and the index entry', () async {
    await store.put('a', blob(10));
    await store.remove('a');
    expect(await store.get('a'), isNull);
    expect(await store.keys(), isEmpty);
  });

  test('clear deletes everything', () async {
    await store.put('a', blob(10));
    await store.put('b', blob(10));
    await store.clear();
    expect(await store.keys(), isEmpty);
    expect(files.data[StorageKeys.webViewStateNamespace], isNull);
  });

  test('the order survives a new store over the same files', () async {
    await store.put('a', blob(10));
    await store.put('b', blob(10));
    await store.get('a');
    final WebViewStateStore again = make();
    expect(await again.keys(), <String>['b', 'a']);
  });

  test(
    'a damaged index is rebuilt from the files and no data is lost',
    () async {
      await store.put('a', blob(10));
      await store.put('b', blob(10));
      files.data[StorageKeys.webViewStateIndexNamespace]!['index'] =
          Uint8List.fromList(<int>[0xff, 0x00, 0x7b]);
      final WebViewStateStore again = make();
      expect((await again.keys()).toSet(), <String>{'a', 'b'});
      expect(await again.get('a'), blob(10));
    },
  );

  test('a file the index does not know is adopted as the oldest', () async {
    await store.put('a', blob(10));
    files.data[StorageKeys.webViewStateNamespace]!['stray'] = blob(10);
    final WebViewStateStore again = make();
    expect(await again.keys(), <String>['stray', 'a']);
  });

  test('an index entry whose file is gone is dropped', () async {
    await store.put('a', blob(10));
    await store.put('b', blob(10));
    files.data[StorageKeys.webViewStateNamespace]!.remove('a');
    final WebViewStateStore again = make();
    expect(await again.keys(), <String>['b']);
  });

  test('concurrent saves do not lose entries', () async {
    await Future.wait(<Future<bool>>[
      for (int i = 0; i < 5; i++) store.put('k$i', blob(10)),
    ]);
    expect((await store.keys()).toSet(), <String>{
      'k0',
      'k1',
      'k2',
      'k3',
      'k4',
    });
  });

  test(
    'a failing file store surfaces the error and the next call still works',
    () async {
      files.failWrites = true;
      await expectLater(store.put('a', blob(10)), throwsStateError);
      files.failWrites = false;
      expect(await store.put('a', blob(10)), isTrue);
      expect(await store.get('a'), blob(10));
    },
  );
}
