/// One row of a query result.
typedef Row = Map<String, Object?>;

/// Runs SQL. Implemented by the open database and by each transaction.
abstract interface class SqlExecutor {
  Future<void> execute(
    String sql, [
    List<Object?> arguments = const <Object?>[],
  ]);

  Future<List<Row>> query(
    String sql, [
    List<Object?> arguments = const <Object?>[],
  ]);
}

/// What to do when the file on disk was written by a newer version of the app.
enum DowngradePolicy {
  /// Leave the file untouched and raise a recoverable storage error, so the app
  /// carries on in memory and the data is still there after the next update.
  refuse,

  /// Delete the file and start empty. Only for data that can be rebuilt.
  recoverToEmpty,
}

/// The shape of the database: its version and how to build or upgrade it.
class DatabaseSchema {
  const DatabaseSchema({
    required this.version,
    required this.onCreate,
    required this.onUpgrade,
    this.downgrade = DowngradePolicy.refuse,
  });

  final int version;

  /// Builds a new database at [version].
  final Future<void> Function(SqlExecutor db) onCreate;

  /// Moves an existing database from [from] to [to] (`from < to`).
  final Future<void> Function(SqlExecutor db, int from, int to) onUpgrade;

  final DowngradePolicy downgrade;
}

/// The app's SQLite database (history, bookmarks, site settings, downloads).
///
/// Implementations raise `StorageError` and nothing else.
abstract interface class LocalDatabase implements SqlExecutor {
  bool get isOpen;

  /// Opens the database, creating or upgrading it as [schema] says. A file that
  /// is corrupt is deleted and recreated once.
  Future<void> open(DatabaseSchema schema);

  /// Runs [action] atomically: everything it does is kept, or none of it is.
  Future<T> transaction<T>(Future<T> Function(SqlExecutor txn) action);

  Future<void> close();
}
