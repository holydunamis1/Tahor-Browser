/// Opens things outside the app.
abstract interface class ExternalLauncher {
  /// Opens [uri] in the system browser. False when nothing could open it.
  Future<bool> openInSystemBrowser(Uri uri);

  /// Opens [uri] in the app that handles it (phone, mail, a store, another
  /// app). False when no app can.
  Future<bool> openExternalApp(Uri uri);
}
