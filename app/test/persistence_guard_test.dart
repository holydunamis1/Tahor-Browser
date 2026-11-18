import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';
import 'package:tahorbrowser/core/storage/persistence_guard.dart';

void main() {
  late List<AppError> errors;
  late PersistenceGuard guard;

  setUp(() {
    errors = <AppError>[];
    guard = PersistenceGuard(onError: errors.add);
  });

  test(
    'a successful action passes its value through and flags nothing',
    () async {
      final int value = await guard.run<int>(
        'settings',
        () async => 7,
        fallback: () => 0,
      );
      expect(value, 7);
      expect(guard.isDegraded, isFalse);
      expect(errors, isEmpty);
    },
  );

  test('an exception gives the fallback and flags the area', () async {
    final int value = await guard.run<int>(
      'history',
      () async => throw const FormatException('bad'),
      fallback: () => 42,
    );
    expect(value, 42);
    expect(guard.isDegraded, isTrue);
    expect(guard.failedAreas.value, <String>{'history'});
    expect(errors.single.code, 'storage.read');
  });

  test('a failed save is reported as a write failure', () async {
    await guard.run<void>(
      'tabs',
      () async => throw StateError('disk'),
      fallback: () {},
      write: true,
    );
    expect(errors.single.code, 'storage.write');
  });

  test('a TypeError from a plugin is handled like any other failure', () async {
    final String value = await guard.run<String>(
      'settings',
      () async => throw TypeError(),
      fallback: () => 'default',
    );
    expect(value, 'default');
    expect(guard.failedAreas.value, contains('settings'));
  });

  test('an error that is already an AppError keeps its own code', () async {
    await guard.run<void>(
      'downloads',
      () async => throw const StorageError.full(),
      fallback: () {},
      write: true,
    );
    expect(errors.single.code, 'storage.full');
  });

  test('the listener hears about each new area once', () async {
    int heard = 0;
    guard.failedAreas.addListener(() => heard++);
    for (int i = 0; i < 3; i++) {
      await guard.run<void>(
        'history',
        () async => throw StateError('x'),
        fallback: () {},
      );
    }
    await guard.run<void>(
      'tabs',
      () async => throw StateError('x'),
      fallback: () {},
    );
    expect(heard, 2);
    expect(guard.failedAreas.value, <String>{'history', 'tabs'});
  });

  test('the reported set cannot be changed from outside', () async {
    await guard.run<void>(
      'tabs',
      () async => throw StateError('x'),
      fallback: () {},
    );
    expect(() => guard.failedAreas.value.add('x'), throwsUnsupportedError);
  });

  test('reset clears the warning', () async {
    await guard.run<void>(
      'tabs',
      () async => throw StateError('x'),
      fallback: () {},
    );
    guard.reset();
    expect(guard.isDegraded, isFalse);
  });

  test('a programming error is not swallowed', () async {
    await expectLater(
      guard.run<void>(
        'tabs',
        () async => throw ArgumentError('a bug'),
        fallback: () {},
      ),
      throwsArgumentError,
    );
    expect(guard.isDegraded, isFalse);
  });
}
