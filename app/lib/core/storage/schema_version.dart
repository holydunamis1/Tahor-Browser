/// The current version of every stored format. A number changes only together
/// with a migration in `migrations.dart` (or tolerant parsing for the formats
/// that carry their own version).
///
/// The database version is not listed here: it is the latest step of
/// `DatabaseMigrations.app`, so it cannot disagree with the migrations.
abstract final class SchemaVersions {
  /// Key-value store layout.
  static const int keyValue = 1;

  /// The saved tab list.
  static const int sessionSnapshot = 1;

  /// The index of saved web view states.
  static const int webViewStateIndex = 1;
}
