import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/contracts/key_value_store.dart';
import 'package:tahorbrowser/core/contracts/local_database.dart';
import 'package:tahorbrowser/core/storage/migrations.dart';
import 'package:tahorbrowser/core/storage/storage_keys.dart';

import 'support/fakes.dart';

void main() {
  Migration<SqlExecutor> sqlStep(int to) =>
      Migration<SqlExecutor>(to, (SqlExecutor db) => db.execute('STEP $to'));

  group('DatabaseMigrations', () {
    test('steps must be numbered 2, 3, 4 with no gap or repeat', () {
      expect(
        () => DatabaseMigrations(<Migration<SqlExecutor>>[sqlStep(3)]),
        throwsArgumentError,
      );
      expect(
        () => DatabaseMigrations(<Migration<SqlExecutor>>[
          sqlStep(2),
          sqlStep(2),
        ]),
        throwsArgumentError,
      );
      expect(
        () => DatabaseMigrations(<Migration<SqlExecutor>>[
          sqlStep(2),
          sqlStep(3),
        ]),
        returnsNormally,
      );
    });

    test('with no steps the latest version is the baseline, 1', () {
      expect(DatabaseMigrations.app.latestVersion, 1);
      expect(
        DatabaseMigrations(const <Migration<SqlExecutor>>[]).latestVersion,
        1,
      );
    });

    test('the latest version is the last step', () {
      final DatabaseMigrations m = DatabaseMigrations(<Migration<SqlExecutor>>[
        sqlStep(2),
        sqlStep(3),
      ]);
      expect(m.latestVersion, 3);
      expect(m.toSchema().version, 3);
    });

    test('creating a database runs the baseline and then every step', () async {
      final FakeLocalDatabase db = FakeLocalDatabase();
      final DatabaseMigrations m = DatabaseMigrations(<Migration<SqlExecutor>>[
        sqlStep(2),
        sqlStep(3),
      ]);
      await m.create(db);
      expect(db.statements.first, DatabaseMigrations.baseline.first);
      expect(db.statements.skip(DatabaseMigrations.baseline.length), <String>[
        'STEP 2',
        'STEP 3',
      ]);
    });

    test(
      'upgrading runs only the steps after the old version, in order',
      () async {
        final FakeLocalDatabase db = FakeLocalDatabase();
        final DatabaseMigrations m = DatabaseMigrations(
          <Migration<SqlExecutor>>[sqlStep(2), sqlStep(3), sqlStep(4)],
        );
        await m.upgrade(db, 2, 4);
        expect(db.statements, <String>['STEP 3', 'STEP 4']);
      },
    );

    test('upgrading stops at the requested version', () async {
      final FakeLocalDatabase db = FakeLocalDatabase();
      final DatabaseMigrations m = DatabaseMigrations(<Migration<SqlExecutor>>[
        sqlStep(2),
        sqlStep(3),
      ]);
      await m.upgrade(db, 1, 2);
      expect(db.statements, <String>['STEP 2']);
    });

    test('the schema refuses a downgrade unless told otherwise', () {
      final DatabaseMigrations m = DatabaseMigrations(
        const <Migration<SqlExecutor>>[],
      );
      expect(m.toSchema().downgrade, DowngradePolicy.refuse);
      expect(
        m.toSchema(downgrade: DowngradePolicy.recoverToEmpty).downgrade,
        DowngradePolicy.recoverToEmpty,
      );
    });
  });

  group('KeyValueMigrations', () {
    final List<int> ran = <int>[];

    Migration<KeyValueStore> step(int to) => Migration<KeyValueStore>(
      to,
      (KeyValueStore store) async => ran.add(to),
    );

    KeyValueMigrations two() =>
        KeyValueMigrations(<Migration<KeyValueStore>>[step(2), step(3)]);

    setUp(ran.clear);

    test('a store with no marker is version 1 and gets the marker', () async {
      final FakeKeyValueStore store = FakeKeyValueStore();
      final MigrationOutcome outcome = await KeyValueMigrations.app.run(store);
      expect(outcome, MigrationOutcome.upToDate);
      expect(store.data[StorageKeys.keyValueSchemaVersion], 1);
    });

    test(
      'an old store is migrated step by step and the marker follows',
      () async {
        final FakeKeyValueStore store = FakeKeyValueStore();
        final MigrationOutcome outcome = await two().run(store);
        expect(outcome, MigrationOutcome.migrated);
        expect(ran, <int>[2, 3]);
        expect(store.data[StorageKeys.keyValueSchemaVersion], 3);
      },
    );

    test('running twice migrates once', () async {
      final FakeKeyValueStore store = FakeKeyValueStore();
      final KeyValueMigrations m = two();
      await m.run(store);
      final MigrationOutcome second = await m.run(store);
      expect(second, MigrationOutcome.upToDate);
      expect(ran, <int>[2, 3]);
    });

    test('a store already at version 2 only gets step 3', () async {
      final FakeKeyValueStore store = FakeKeyValueStore()
        ..data[StorageKeys.keyValueSchemaVersion] = 2;
      await two().run(store);
      expect(ran, <int>[3]);
    });

    test('a store from a newer app is left untouched', () async {
      final FakeKeyValueStore store = FakeKeyValueStore()
        ..data[StorageKeys.keyValueSchemaVersion] = 9
        ..data['keep'] = 'me';
      final MigrationOutcome outcome = await two().run(store);
      expect(outcome, MigrationOutcome.newerThanApp);
      expect(ran, isEmpty);
      expect(store.data[StorageKeys.keyValueSchemaVersion], 9);
      expect(store.data['keep'], 'me');
    });

    test(
      'a step that fails keeps the marker at the last good version',
      () async {
        final FakeKeyValueStore store = FakeKeyValueStore();
        final KeyValueMigrations m = KeyValueMigrations(
          <Migration<KeyValueStore>>[
            step(2),
            Migration<KeyValueStore>(
              3,
              (KeyValueStore s) async => throw StateError('boom'),
            ),
          ],
        );
        await expectLater(m.run(store), throwsStateError);
        expect(store.data[StorageKeys.keyValueSchemaVersion], 2);
      },
    );
  });
}
