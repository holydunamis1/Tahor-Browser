import 'package:sqflite/sqflite.dart' as sql;

import '../../core/contracts/local_database.dart';
import '../../core/error/error_taxonomy.dart';
import '../../core/storage/storage_keys.dart';

/// [LocalDatabase] over `sqflite`.
///
/// Every failure leaves here as a `StorageError`. A file that SQLite reports
/// as corrupt is deleted and recreated once; any other failure leaves the file
/// alone, because it may be a passing problem and the data may still be good.
class SqfliteLocalDatabase implements LocalDatabase {
  SqfliteLocalDatabase({Future<String> Function()? pathProvider})
    : _pathProvider = pathProvider ?? _defaultPath;

  final Future<String> Function() _pathProvider;
  sql.Database? _db;

  static Future<String> _defaultPath() async =>
      '${await sql.getDatabasesPath()}/${StorageKeys.databaseFileName}';

  static bool _looksCorrupt(Object error) {
    final String text = error.toString().toLowerCase();
    return text.contains('malformed') ||
        text.contains('not a database') ||
        text.contains('corrupt');
  }

  @override
  bool get isOpen => _db?.isOpen ?? false;

  @override
  Future<void> open(DatabaseSchema schema) async {
    final String path = await _pathProvider();
    try {
      _db = await _openAt(path, schema);
    } on StorageError {
      rethrow;
    } on sql.DatabaseException catch (error) {
      if (!_looksCorrupt(error)) {
        throw StorageError.readFailed(detail: 'database open: $error');
      }
      try {
        await sql.deleteDatabase(path);
        _db = await _openAt(path, schema);
      } on sql.DatabaseException catch (second) {
        throw StorageError.corrupted(detail: 'database recreate: $second');
      }
    }
  }

  Future<sql.Database> _openAt(String path, DatabaseSchema schema) {
    return sql.openDatabase(
      path,
      version: schema.version,
      onCreate: (sql.Database db, int version) => schema.onCreate(_Exec(db)),
      onUpgrade: (sql.Database db, int from, int to) =>
          schema.onUpgrade(_Exec(db), from, to),
      onDowngrade: schema.downgrade == DowngradePolicy.refuse
          ? (sql.Database db, int from, int to) async {
              throw const StorageError.readFailed(
                detail:
                    'the database was written by a newer version of the app',
              );
            }
          : sql.onDatabaseDowngradeDelete,
    );
  }

  sql.Database get _open {
    final sql.Database? db = _db;
    if (db == null || !db.isOpen) {
      throw const StorageError.readFailed(detail: 'database is not open');
    }
    return db;
  }

  @override
  Future<void> execute(
    String statement, [
    List<Object?> arguments = const <Object?>[],
  ]) => _Exec(_open).execute(statement, arguments);

  @override
  Future<List<DbRow>> query(
    String statement, [
    List<Object?> arguments = const <Object?>[],
  ]) => _Exec(_open).query(statement, arguments);

  @override
  Future<T> transaction<T>(Future<T> Function(SqlExecutor txn) action) async {
    try {
      return await _open.transaction<T>(
        (sql.Transaction txn) => action(_Exec(txn)),
      );
    } on sql.DatabaseException catch (error) {
      throw StorageError.writeFailed(detail: 'transaction: $error');
    }
  }

  @override
  Future<void> close() async {
    final sql.Database? db = _db;
    _db = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}

/// [SqlExecutor] over a sqflite database or transaction.
class _Exec implements SqlExecutor {
  const _Exec(this._target);

  final sql.DatabaseExecutor _target;

  @override
  Future<void> execute(
    String statement, [
    List<Object?> arguments = const <Object?>[],
  ]) async {
    try {
      await _target.execute(statement, arguments);
    } on sql.DatabaseException catch (error) {
      throw StorageError.writeFailed(detail: 'execute: $error');
    }
  }

  @override
  Future<List<DbRow>> query(
    String statement, [
    List<Object?> arguments = const <Object?>[],
  ]) async {
    try {
      final List<Map<String, Object?>> rows = await _target.rawQuery(
        statement,
        arguments,
      );
      return <DbRow>[
        for (final Map<String, Object?> row in rows) <String, Object?>{...row},
      ];
    } on sql.DatabaseException catch (error) {
      throw StorageError.readFailed(detail: 'query: $error');
    }
  }
}
