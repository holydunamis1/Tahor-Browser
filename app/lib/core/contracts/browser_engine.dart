import 'package:flutter/widgets.dart';

import '../error/error_taxonomy.dart';
import '../models/tab_model.dart';

/// What a tab view is built from.
@immutable
class TabViewConfig {
  const TabViewConfig({
    required this.tabId,
    this.initialUrl,
    this.isIncognito = false,
    this.viewMode = TabViewMode.mobile,
  });

  final String tabId;

  /// Loaded when the view appears; null for a blank tab.
  final Uri? initialUrl;
  final bool isIncognito;
  final TabViewMode viewMode;
}

/// A navigation the engine is about to perform.
@immutable
class NavigationRequest {
  const NavigationRequest({
    required this.tabId,
    required this.uri,
    required this.isMainFrame,
    this.hasGesture = false,
  });

  final String tabId;
  final Uri uri;
  final bool isMainFrame;

  /// True when the person caused it (a tap), false for scripts and redirects.
  final bool hasGesture;
}

/// What to do with a [NavigationRequest].
sealed class NavigationDecision {
  const NavigationDecision();
}

/// Let the web view load it.
final class AllowNavigation extends NavigationDecision {
  const AllowNavigation();
}

/// Do nothing.
final class BlockNavigation extends NavigationDecision {
  const BlockNavigation();
}

/// Hand [uri] to another app or the system browser instead.
final class OpenExternally extends NavigationDecision {
  const OpenExternally(this.uri);

  final Uri uri;
}

/// Load [uri] instead (for example the https version of an address).
final class RedirectNavigation extends NavigationDecision {
  const RedirectNavigation(this.uri);

  final Uri uri;
}

/// Asked before every navigation. Must be fast and must not throw.
typedef NavigationPolicy = NavigationDecision Function(
  NavigationRequest request,
);

/// Something that happened in a tab. The tab provider consumes these.
sealed class TabEvent {
  const TabEvent(this.tabId);

  final String tabId;
}

final class PageStarted extends TabEvent {
  const PageStarted(super.tabId, this.url);

  final Uri url;
}

/// Load progress from 0 to 1.
final class ProgressChanged extends TabEvent {
  const ProgressChanged(super.tabId, this.progress);

  final double progress;
}

final class PageFinished extends TabEvent {
  const PageFinished(super.tabId, this.url);

  final Uri url;
}

final class TitleChanged extends TabEvent {
  const TitleChanged(super.tabId, this.title);

  final String? title;
}

final class FaviconChanged extends TabEvent {
  const FaviconChanged(super.tabId, this.faviconUrl);

  final String? faviconUrl;
}

final class NavigationStateChanged extends TabEvent {
  const NavigationStateChanged(
    super.tabId, {
    required this.canGoBack,
    required this.canGoForward,
    this.url,
  });

  final bool canGoBack;
  final bool canGoForward;

  /// The address now showing, when known.
  final Uri? url;
}

final class ErrorOccurred extends TabEvent {
  const ErrorOccurred(super.tabId, this.error, {this.isMainFrame = true});

  final AppError error;

  /// False for a failed image or script; only main-frame errors replace the
  /// page with an error view.
  final bool isMainFrame;
}

/// Receives the events of one tab.
typedef TabEventSink = void Function(TabEvent event);

/// The web engine behind every tab. Screens and providers talk to this
/// contract only; the plugin lives in `platform/`.
///
/// The engine owns the live controllers, keyed by tab id. Later batches add
/// state saving, content rules, dialogs, find, print, long-press and the
/// back/forward list.
abstract interface class BrowserEngine {
  /// Sets the policy asked before every navigation.
  void setNavigationPolicy(NavigationPolicy policy);

  /// The widget that shows the tab. Events go to [sink].
  Widget buildTab(TabViewConfig config, TabEventSink sink);

  Future<void> load(String tabId, Uri uri);
  Future<void> goBack(String tabId);
  Future<void> goForward(String tabId);
  Future<void> reload(String tabId);
  Future<void> stop(String tabId);

  /// Releases the web view of a tab.
  Future<void> dispose(String tabId);
}
