import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/contracts/browser_engine.dart';
import '../../core/contracts/external_launcher.dart';
import '../../core/error/error_taxonomy.dart';
import '../../core/theme/theme_builder.dart';
import '../../core/utils/url_utils.dart';

/// The error a failed page load becomes.
AppError errorForLoad(WebResourceError error) {
  if (error.type == WebResourceErrorType.NOT_CONNECTED_TO_INTERNET) {
    return const NetworkError.offline();
  }
  if (error.type == WebResourceErrorType.TIMEOUT) {
    return const NetworkError.timeout();
  }
  return WebViewError.loadFailed(detail: error.description);
}

/// True when the load stopped because another one started or the person
/// pressed stop. That is not an error to show.
bool isCancelledLoad(WebResourceError error) =>
    error.type == WebResourceErrorType.CANCELLED;

/// What the web view should do for each policy decision.
NavigationActionPolicy policyFor(NavigationDecision decision) {
  return decision is AllowNavigation
      ? NavigationActionPolicy.ALLOW
      : NavigationActionPolicy.CANCEL;
}

/// The contract request for a plugin navigation action.
NavigationRequest requestFor(String tabId, NavigationAction action) {
  return NavigationRequest(
    tabId: tabId,
    uri: action.request.url ?? Uri(),
    isMainFrame: action.isForMainFrame,
    hasGesture: action.hasGesture ?? false,
  );
}

/// [BrowserEngine] over `flutter_inappwebview`, shared by both platforms.
/// The platform engines only adjust settings.
abstract class InAppWebViewEngineBase implements BrowserEngine {
  InAppWebViewEngineBase({
    required ExternalLauncher launcher,
    bool safeBrowsingEnabled = true,
  }) : _launcher = launcher,
       _safeBrowsing = safeBrowsingEnabled;

  final ExternalLauncher _launcher;
  final bool _safeBrowsing;
  final Map<String, InAppWebViewController> _controllers =
      <String, InAppWebViewController>{};
  NavigationPolicy? _policy;

  /// Platform-specific changes to the settings of a tab.
  @protected
  void configureSettings(InAppWebViewSettings settings, TabViewConfig config) {}

  /// The user agent of a tab, or null for the web view's own.
  @protected
  String? userAgentFor(TabViewConfig config) => null;

  /// The settings a tab is created with.
  ///
  /// `incognito` is never set: on Android it clears the cookies of every web
  /// view, so private tabs are handled by host-scoped cleanup instead.
  @visibleForTesting
  InAppWebViewSettings settingsFor(TabViewConfig config) {
    final InAppWebViewSettings settings = InAppWebViewSettings(
      javaScriptEnabled: true,
      supportMultipleWindows: true,
      javaScriptCanOpenWindowsAutomatically: false,
      allowsInlineMediaPlayback: true,
      mediaPlaybackRequiresUserGesture: true,
      useHybridComposition: true,
      useShouldOverrideUrlLoading: true,
      safeBrowsingEnabled: _safeBrowsing,
      isFraudulentWebsiteWarningEnabled: _safeBrowsing,
      transparentBackground: false,
      supportZoom: true,
      builtInZoomControls: false,
      displayZoomControls: false,
      allowFileAccess: false,
      userAgent: userAgentFor(config),
      isInspectable: kDebugMode,
    );
    configureSettings(settings, config);
    return settings;
  }

  @override
  void setNavigationPolicy(NavigationPolicy policy) => _policy = policy;

  /// Decides a navigation. A policy that throws never blocks browsing.
  @visibleForTesting
  Future<NavigationActionPolicy> decide(
    String tabId,
    NavigationAction action,
  ) async {
    final NavigationPolicy? policy = _policy;
    if (policy == null) {
      return NavigationActionPolicy.ALLOW;
    }
    final NavigationRequest request = requestFor(tabId, action);
    final NavigationDecision decision;
    try {
      decision = policy(request);
    } on Exception {
      return NavigationActionPolicy.ALLOW;
    }
    switch (decision) {
      case AllowNavigation():
      case BlockNavigation():
        break;
      case OpenExternally(:final Uri uri):
        unawaited(_openExternally(tabId, uri));
      case RedirectNavigation(:final Uri uri):
        final InAppWebViewController? controller = _controllers[tabId];
        if (controller != null) {
          unawaited(
            controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri))),
          );
        }
    }
    return policyFor(decision);
  }

  Future<void> _openExternally(String tabId, Uri uri) async {
    final bool opened = await _launcher.openExternalApp(uri);
    if (opened || uri.scheme != 'intent') {
      return;
    }
    // No app could handle the link: use the page it names, if any.
    final Uri? fallback = parseIntentUri(uri.toString())?.fallbackUrl;
    final InAppWebViewController? controller = _controllers[tabId];
    if (fallback != null && controller != null) {
      await controller.loadUrl(
        urlRequest: URLRequest(url: WebUri.uri(fallback)),
      );
    }
  }

  @override
  Widget buildTab(TabViewConfig config, TabEventSink sink) {
    return _WebTab(
      key: ValueKey<String>(config.tabId),
      engine: this,
      config: config,
      sink: sink,
    );
  }

  @override
  Future<void> load(String tabId, Uri uri) async {
    await _controllers[tabId]?.loadUrl(
      urlRequest: URLRequest(url: WebUri.uri(uri)),
    );
  }

  @override
  Future<void> goBack(String tabId) async => _controllers[tabId]?.goBack();

  @override
  Future<void> goForward(String tabId) async =>
      _controllers[tabId]?.goForward();

  @override
  Future<void> reload(String tabId) async => _controllers[tabId]?.reload();

  @override
  Future<void> stop(String tabId) async => _controllers[tabId]?.stopLoading();

  @override
  Future<void> dispose(String tabId) async {
    _controllers.remove(tabId);
  }
}

class _WebTab extends StatefulWidget {
  const _WebTab({
    super.key,
    required this.engine,
    required this.config,
    required this.sink,
  });

  final InAppWebViewEngineBase engine;
  final TabViewConfig config;
  final TabEventSink sink;

  @override
  State<_WebTab> createState() => _WebTabState();
}

class _WebTabState extends State<_WebTab> {
  PullToRefreshController? _pull;
  InAppWebViewController? _controller;

  String get _tabId => widget.config.tabId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = AppTheme.of(context);
    _pull ??= PullToRefreshController(
      settings: PullToRefreshSettings(
        color: theme.palette.accent,
        backgroundColor: theme.palette.bgSecondary,
      ),
      onRefresh: () async => _controller?.reload(),
    );
  }

  @override
  void dispose() {
    final InAppWebViewController? mine = _controller;
    if (mine != null && identical(widget.engine._controllers[_tabId], mine)) {
      widget.engine._controllers.remove(_tabId);
    }
    super.dispose();
  }

  Future<void> _emitNavigationState(
    InAppWebViewController controller,
    Uri? url,
  ) async {
    try {
      final bool back = await controller.canGoBack();
      final bool forward = await controller.canGoForward();
      widget.sink(
        NavigationStateChanged(
          _tabId,
          canGoBack: back,
          canGoForward: forward,
          url: url,
        ),
      );
    } on Exception {
      // The web view went away while we asked; nothing to report.
    }
  }

  Future<void> _emitFavicon(InAppWebViewController controller) async {
    try {
      final List<Favicon> icons = await controller.getFavicons();
      widget.sink(
        FaviconChanged(
          _tabId,
          icons.isEmpty ? null : icons.first.url.toString(),
        ),
      );
    } on Exception {
      // Not every page has an icon.
    }
  }

  @override
  Widget build(BuildContext context) {
    final Uri? initial = widget.config.initialUrl;
    return InAppWebView(
      initialUrlRequest: initial == null
          ? null
          : URLRequest(url: WebUri.uri(initial)),
      initialSettings: widget.engine.settingsFor(widget.config),
      pullToRefreshController: _pull,
      onWebViewCreated: (InAppWebViewController controller) {
        _controller = controller;
        widget.engine._controllers[_tabId] = controller;
      },
      onLoadStart: (InAppWebViewController controller, WebUri? url) {
        if (url != null) {
          widget.sink(PageStarted(_tabId, url));
        }
      },
      onLoadStop: (InAppWebViewController controller, WebUri? url) async {
        await _pull?.endRefreshing();
        if (url != null) {
          widget.sink(PageFinished(_tabId, url));
        }
        await _emitNavigationState(controller, url);
        await _emitFavicon(controller);
      },
      onProgressChanged: (InAppWebViewController controller, int progress) {
        widget.sink(ProgressChanged(_tabId, progress / 100));
        if (progress >= 100) {
          unawaited(_pull?.endRefreshing());
        }
      },
      onTitleChanged: (InAppWebViewController controller, String? title) {
        widget.sink(TitleChanged(_tabId, title));
      },
      onUpdateVisitedHistory:
          (InAppWebViewController controller, WebUri? url, bool? isReload) {
            unawaited(_emitNavigationState(controller, url));
          },
      shouldOverrideUrlLoading: (
        InAppWebViewController controller,
        NavigationAction action,
      ) => widget.engine.decide(_tabId, action),
      onReceivedError:
          (
            InAppWebViewController controller,
            WebResourceRequest request,
            WebResourceError error,
          ) {
            if (request.isForMainFrame != true || isCancelledLoad(error)) {
              return;
            }
            unawaited(_pull?.endRefreshing());
            widget.sink(ErrorOccurred(_tabId, errorForLoad(error)));
          },
    );
  }
}
