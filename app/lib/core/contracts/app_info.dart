/// The installed version of the app.
abstract interface class AppInfo {
  /// For example `0.1.0`.
  String get version;

  /// For example `1`.
  String get buildNumber;
}
