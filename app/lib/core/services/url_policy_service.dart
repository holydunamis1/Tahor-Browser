import '../contracts/browser_engine.dart';

/// Decides what happens to every navigation a web view is about to make.
///
/// Web pages load; links to other apps open them, but only when the person
/// tapped (a page must never launch apps by itself); and anything that could
/// run code or read local files is blocked. Later batches add the HTTPS
/// upgrade, PDF handling and sign-in handoff here.
class UrlPolicyService {
  const UrlPolicyService();

  /// Schemes that load in the web view.
  static const Set<String> webSchemes = <String>{'http', 'https'};

  /// Schemes handed to another app when the person tapped a link.
  static const Set<String> appSchemes = <String>{
    'tel',
    'mailto',
    'sms',
    'market',
    'intent',
    'geo',
  };

  /// Schemes that are never loaded or opened.
  static const Set<String> blockedSchemes = <String>{
    'javascript',
    'vbscript',
    'file',
    'content',
    'filesystem',
    'view-source',
    'ftp',
  };

  /// The decision for [request]. Never throws.
  NavigationDecision decide(NavigationRequest request) {
    final String scheme = request.uri.scheme.toLowerCase();

    if (scheme.isEmpty) {
      return const BlockNavigation();
    }
    if (webSchemes.contains(scheme)) {
      return const AllowNavigation();
    }
    if (blockedSchemes.contains(scheme)) {
      return const BlockNavigation();
    }
    if (scheme == 'about') {
      return request.uri.toString().toLowerCase() == 'about:blank'
          ? const AllowNavigation()
          : const BlockNavigation();
    }
    if (scheme == 'blob') {
      return const AllowNavigation();
    }
    if (scheme == 'data') {
      // Pages use data addresses inside frames and images. Opening one as
      // the page itself is a phishing trick, so only frames may.
      return request.isMainFrame
          ? const BlockNavigation()
          : const AllowNavigation();
    }
    // A link to another app (a store, a phone number, an app's own scheme).
    // Without a tap it is a script or a redirect: block it.
    return request.hasGesture
        ? OpenExternally(request.uri)
        : const BlockNavigation();
  }
}
