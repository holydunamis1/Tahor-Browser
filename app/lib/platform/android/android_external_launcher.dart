import '../../core/utils/url_utils.dart';
import '../common/url_launcher_external_launcher.dart';

/// Adds Android's `intent:` links: the target app is tried first, then its
/// store page. The web fallback inside the link is left to the caller, which
/// can open it in a tab.
class AndroidExternalLauncher extends UrlLauncherExternalLauncher {
  AndroidExternalLauncher({super.launch});

  @override
  Future<bool> openExternalApp(Uri uri) async {
    final String scheme = uri.scheme.toLowerCase();
    if (scheme == 'market') {
      return launch(uri);
    }
    if (scheme != 'intent') {
      return super.openExternalApp(uri);
    }
    final IntentLink? link = parseIntentUri(uri.toString());
    if (link == null) {
      return false;
    }
    final Uri? target = link.launchUri;
    if (target != null && await super.openExternalApp(target)) {
      return true;
    }
    final Uri? store = link.marketUri;
    if (store != null && await launch(store)) {
      return true;
    }
    return false;
  }
}
