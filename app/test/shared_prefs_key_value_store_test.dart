import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahorbrowser/platform/common/shared_prefs_key_value_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('strings, numbers and booleans round-trip', () async {
    final SharedPrefsKeyValueStore store = SharedPrefsKeyValueStore();
    await store.setString('s', 'hello');
    await store.setInt('i', 42);
    await store.setBool('b', true);
    expect(await store.getString('s'), 'hello');
    expect(await store.getInt('i'), 42);
    expect(await store.getBool('b'), isTrue);
    expect(store.hasFailed, isFalse);
  });

  test('a missing key reads as null', () async {
    final SharedPrefsKeyValueStore store = SharedPrefsKeyValueStore();
    expect(await store.getString('nope'), isNull);
    expect(await store.getInt('nope'), isNull);
    expect(await store.getBool('nope'), isNull);
    expect(await store.getJson('nope'), isNull);
  });

  test('values survive a new store over the same storage', () async {
    await SharedPrefsKeyValueStore().setString('k', 'kept');
    expect(await SharedPrefsKeyValueStore().getString('k'), 'kept');
  });

  test('a value of another type reads as missing, without a failure', () async {
    final SharedPrefsKeyValueStore store = SharedPrefsKeyValueStore();
    await store.setInt('k', 5);
    expect(await store.getString('k'), isNull);
    expect(store.hasFailed, isFalse);
  });

  test('remove deletes the key', () async {
    final SharedPrefsKeyValueStore store = SharedPrefsKeyValueStore();
    await store.setString('k', 'v');
    await store.remove('k');
    expect(await store.getString('k'), isNull);
  });

  group('JSON', () {
    test('an object round-trips', () async {
      final SharedPrefsKeyValueStore store = SharedPrefsKeyValueStore();
      await store.setJson('j', <String, Object?>{
        'a': 1,
        'b': 'two',
        'c': null,
      });
      expect(await store.getJson('j'), <String, Object?>{
        'a': 1,
        'b': 'two',
        'c': null,
      });
    });

    test('corrupt text reads as null', () async {
      final SharedPrefsKeyValueStore store = SharedPrefsKeyValueStore();
      await store.setString('j', '{not json');
      expect(await store.getJson('j'), isNull);
    });

    test('JSON that is not an object reads as null', () async {
      final SharedPrefsKeyValueStore store = SharedPrefsKeyValueStore();
      await store.setString('j', '[1, 2]');
      expect(await store.getJson('j'), isNull);
    });
  });

  group('when storage cannot be opened', () {
    SharedPrefsKeyValueStore broken() => SharedPrefsKeyValueStore(
      loader: () => throw Exception('storage unavailable'),
    );

    test('values live in memory and the failure is reported', () async {
      final SharedPrefsKeyValueStore store = broken();
      expect(store.hasFailed, isFalse);
      await store.setString('s', 'kept');
      await store.setInt('i', 7);
      await store.setBool('b', false);
      await store.setJson('j', <String, Object?>{'x': 1});
      expect(store.hasFailed, isTrue);
      expect(await store.getString('s'), 'kept');
      expect(await store.getInt('i'), 7);
      expect(await store.getBool('b'), isFalse);
      expect(await store.getJson('j'), <String, Object?>{'x': 1});
    });

    test('reads report the failure and return null', () async {
      final SharedPrefsKeyValueStore store = broken();
      expect(await store.getString('s'), isNull);
      expect(store.hasFailed, isTrue);
    });

    test('remove forgets the in-memory value', () async {
      final SharedPrefsKeyValueStore store = broken();
      await store.setString('s', 'x');
      await store.remove('s');
      expect(await store.getString('s'), isNull);
    });
  });
}
