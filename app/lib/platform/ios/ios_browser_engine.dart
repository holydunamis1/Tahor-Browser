import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/contracts/browser_engine.dart';
import '../common/inappwebview_engine_base.dart';

/// The iOS web view: edge-swipe history, picture in picture, AirPlay for
/// web video, and the fraudulent-website warning (shared switch).
class IosBrowserEngine extends InAppWebViewEngineBase {
  IosBrowserEngine({required super.launcher, super.safeBrowsingEnabled});

  @override
  void configureSettings(InAppWebViewSettings settings, TabViewConfig config) {
    settings.allowsBackForwardNavigationGestures = true;
    settings.allowsPictureInPictureMediaPlayback = true;
    settings.allowsAirPlayForMediaPlayback = true;
  }
}
