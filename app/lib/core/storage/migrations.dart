import '../contracts/key_value_store.dart';
import '../contracts/local_database.dart';
import 'storage_keys.dart';

/// One step that brings a store from [toVersion] - 1 to [toVersion].
class Migration<T> {
  const Migration(this.toVersion, this.apply);

  final int toVersion;
  final Future<void> Function(T target) apply;
}

/// Steps must run 2, 3, 4 ... with no gap and no repeat; version 1 is the
/// baseline that exists before any step.
List<Migration<T>> _validated<T>(List<Migration<T>> steps) {
  for (int i = 0; i < steps.length; i++) {
    final int expected = i + 2;
    if (steps[i].toVersion != expected) {
      throw ArgumentError(
        'Migration ${i + 1} goes to version ${steps[i].toVersion}; '
        'expected $expected.',
      );
    }
  }
  return List<Migration<T>>.unmodifiable(steps);
}

/// The database's baseline and the ordered steps after it.
class DatabaseMigrations {
  DatabaseMigrations(List<Migration<SqlExecutor>> steps)
    : steps = _validated<SqlExecutor>(steps);

  /// The migrations the app ships. Later batches append their steps:
  /// site settings (2), downloads (3), history (4), bookmarks (5).
  static final DatabaseMigrations app = DatabaseMigrations(
    const <Migration<SqlExecutor>>[],
  );

  /// Version 1: a small table the app can use for bookkeeping.
  static const List<String> baseline = <String>[
    'CREATE TABLE IF NOT EXISTS meta ('
        'key TEXT PRIMARY KEY NOT NULL, '
        'value TEXT)',
  ];

  final List<Migration<SqlExecutor>> steps;

  int get latestVersion => steps.isEmpty ? 1 : steps.last.toVersion;

  /// Builds a new database: the baseline, then every step.
  Future<void> create(SqlExecutor db) async {
    for (final String sql in baseline) {
      await db.execute(sql);
    }
    for (final Migration<SqlExecutor> step in steps) {
      await step.apply(db);
    }
  }

  /// Runs the steps after [from] up to and including [to], in order.
  Future<void> upgrade(SqlExecutor db, int from, int to) async {
    for (final Migration<SqlExecutor> step in steps) {
      if (step.toVersion > from && step.toVersion <= to) {
        await step.apply(db);
      }
    }
  }

  DatabaseSchema toSchema({
    DowngradePolicy downgrade = DowngradePolicy.refuse,
  }) => DatabaseSchema(
    version: latestVersion,
    onCreate: create,
    onUpgrade: upgrade,
    downgrade: downgrade,
  );
}

/// What running the key-value migrations found.
enum MigrationOutcome { upToDate, migrated, newerThanApp }

/// The key-value store's migrations. The store has no version marker on
/// installs that pre-date this class, and those are version 1.
class KeyValueMigrations {
  KeyValueMigrations(List<Migration<KeyValueStore>> steps)
    : steps = _validated<KeyValueStore>(steps);

  static final KeyValueMigrations app = KeyValueMigrations(
    const <Migration<KeyValueStore>>[],
  );

  final List<Migration<KeyValueStore>> steps;

  int get latestVersion => steps.isEmpty ? 1 : steps.last.toVersion;

  /// Brings [store] up to date. When the store was written by a newer app it is
  /// left alone: every value is parsed tolerantly, so the older app still runs.
  Future<MigrationOutcome> run(KeyValueStore store) async {
    final int stored =
        await store.getInt(StorageKeys.keyValueSchemaVersion) ?? 1;
    if (stored > latestVersion) {
      return MigrationOutcome.newerThanApp;
    }
    if (stored == latestVersion) {
      await store.setInt(StorageKeys.keyValueSchemaVersion, stored);
      return MigrationOutcome.upToDate;
    }
    for (final Migration<KeyValueStore> step in steps) {
      if (step.toVersion > stored) {
        await step.apply(store);
        await store.setInt(StorageKeys.keyValueSchemaVersion, step.toVersion);
      }
    }
    return MigrationOutcome.migrated;
  }
}
