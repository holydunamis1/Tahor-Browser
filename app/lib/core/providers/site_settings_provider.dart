import 'package:flutter/foundation.dart';

import '../models/site_setting.dart';
import '../services/site_settings_service.dart';
import 'tabs_provider.dart';

/// Per-site settings for the rest of the app: the site showing now, and any
/// other by host. It notifies on every change, so ad blocking and the engine
/// can re-apply.
class SiteSettingsProvider extends ChangeNotifier {
  SiteSettingsProvider({required this.service, required this._tabs}) {
    _tabs.addListener(_onTabs);
    _host = hostOf(_tabs.value.activeTab.url);
  }

  final SiteSettingsService service;
  final TabsProvider _tabs;
  String? _host;

  /// The host of an http or https address, normalized; null for anything else.
  static String? hostOf(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return SiteSetting.normalizeHost(uri.host);
  }

  /// The host of the showing tab, or null when it shows no page.
  String? get currentHost => _host;

  /// The showing site's settings, or null when no page is showing.
  SiteSetting? get current => _host == null ? null : service.get(_host!);

  SiteSetting forHost(String host) => service.get(host);

  /// Sites that differ from the defaults.
  List<SiteSetting> get overrides => service.overrides;

  /// Sites with ad blocking turned off.
  List<String> get adblockExceptions => <String>[
    for (final SiteSetting s in service.overrides)
      if (!s.adblockEnabled) s.host,
  ];

  void _onTabs() {
    final String? host = hostOf(_tabs.value.activeTab.url);
    if (host != _host) {
      _host = host;
      notifyListeners();
    }
  }

  /// Applies [change] to [host]'s settings and saves the result.
  Future<void> update(
    String host,
    SiteSetting Function(SiteSetting current) change,
  ) async {
    final SiteSetting before = service.get(host);
    final SiteSetting after = change(before);
    if (after == before) {
      return;
    }
    await service.save(after);
    notifyListeners();
  }

  Future<void> setAdblock(String host, {required bool enabled}) =>
      update(host, (SiteSetting s) => s.copyWith(adblockEnabled: enabled));

  Future<void> remove(String host) async {
    await service.remove(host);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await service.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabs);
    super.dispose();
  }
}
