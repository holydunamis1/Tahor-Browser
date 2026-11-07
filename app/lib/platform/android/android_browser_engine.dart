import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/contracts/browser_engine.dart';
import '../common/inappwebview_engine_base.dart';

/// The Android web view: mixed content is handled the way Chrome does, and
/// Safe Browsing (Android 8 and later) follows the shared switch.
class AndroidBrowserEngine extends InAppWebViewEngineBase {
  AndroidBrowserEngine({required super.launcher, super.safeBrowsingEnabled});

  @override
  void configureSettings(InAppWebViewSettings settings, TabViewConfig config) {
    settings.mixedContentMode =
        MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE;
    settings.domStorageEnabled = true;
  }
}
