import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../../core/contracts/external_launcher.dart';

/// Starts [uri] outside the app and says whether anything handled it.
typedef UrlLaunchFunction = Future<bool> Function(Uri uri);

/// [ExternalLauncher] over `url_launcher`.
class UrlLauncherExternalLauncher implements ExternalLauncher {
  UrlLauncherExternalLauncher({UrlLaunchFunction? launch})
    : _launch = launch ?? _systemLaunch;

  final UrlLaunchFunction _launch;

  static Future<bool> _systemLaunch(Uri uri) =>
      launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);

  /// Schemes that must never be handed to another app: they run code in the
  /// browser or reach local files.
  static const Set<String> blockedSchemes = <String>{
    'javascript',
    'vbscript',
    'file',
    'data',
    'blob',
    'content',
    'filesystem',
    'about',
  };

  /// Launches [uri], turning any platform failure into `false`.
  @protected
  Future<bool> launch(Uri uri) async {
    try {
      return await _launch(uri);
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> openInSystemBrowser(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return Future<bool>.value(false);
    }
    return launch(uri);
  }

  @override
  Future<bool> openExternalApp(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();
    if (scheme.isEmpty || blockedSchemes.contains(scheme)) {
      return Future<bool>.value(false);
    }
    return launch(uri);
  }
}
