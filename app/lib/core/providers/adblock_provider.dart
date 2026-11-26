import 'package:flutter/foundation.dart';

import '../blocklist/blocklist_service.dart';
import '../blocklist/content_rule_compiler.dart';
import '../blocklist/cosmetic_filter.dart';
import '../contracts/key_value_store.dart';
import '../models/blocklist_rule.dart';
import '../storage/storage_keys.dart';
import 'feature_flags_provider.dart';
import 'settings_provider.dart';
import 'site_settings_provider.dart';

/// Runs compile work. The default runs it right here; the app can pass a runner
/// that uses another isolate.
typedef CompileRunner = Future<R> Function<R>(R Function() job);

Future<R> _runHere<R>(R Function() job) async => job();

/// Everything about ad blocking in one place: whether it is on, for which
/// sites, which list is in use, and the compiled rules for the engine. It
/// notifies whenever any of that changes, which is the engine's cue to apply
/// the rules again.
class AdblockProvider extends ChangeNotifier {
  AdblockProvider({
    required this.blocklist,
    required this.settings,
    required this.sites,
    required this.flags,
    required this._store,
    DateTime Function()? clock,
    CompileRunner? runner,
  }) : _clock = clock ?? DateTime.now,
       _runner = runner ?? _runHere {
    blocklist.addListener(_changed);
    settings.addListener(_changed);
    sites.addListener(_changed);
    flags.addListener(_changed);
  }

  /// How long after a check the weekly refresh waits.
  static const Duration autoRefreshInterval = Duration(days: 7);

  final BlocklistService blocklist;
  final SettingsProvider settings;
  final SiteSettingsProvider sites;
  final FeatureFlagsProvider flags;
  final KeyValueStore _store;
  final DateTime Function() _clock;
  final CompileRunner _runner;

  CosmeticFilter? _cosmetic;
  int _cosmeticVersion = -1;
  String? _iosKey;
  IosRuleLists? _ios;
  String? _androidKey;
  AndroidRuleSet? _android;

  void _changed() => notifyListeners();

  /// The global switch.
  bool get enabled => settings.value.adblockEnabled;

  /// Whether ads are blocked on [host]: the global switch and the site's own.
  bool enabledFor(String host) => enabled && sites.forHost(host).adblockEnabled;

  /// Sites with ad blocking turned off.
  List<String> get exceptionHosts => sites.adblockExceptions;

  /// Identifies the rules compiled right now.
  String get cacheKey =>
      ContentRuleCompiler.cacheKey(blocklist.value.version, exceptionHosts);

  List<BlocklistRule> get rules => blocklist.rules;

  /// Selectors to hide on [host]; none when ad blocking is off there.
  List<String> selectorsFor(String host) {
    if (!enabledFor(host)) {
      return const <String>[];
    }
    if (_cosmetic == null || _cosmeticVersion != blocklist.value.version) {
      _cosmetic = CosmeticFilter(blocklist.rules);
      _cosmeticVersion = blocklist.value.version;
    }
    return _cosmetic!.selectorsFor(host);
  }

  /// WebKit lists for the current list and exceptions; compiled once per
  /// [cacheKey].
  Future<IosRuleLists> iosLists() async {
    final String key = cacheKey;
    if (_ios != null && _iosKey == key) {
      return _ios!;
    }
    final List<BlocklistRule> source = blocklist.rules;
    final List<String> hosts = exceptionHosts;
    final IosRuleLists out = await _runner<IosRuleLists>(
      () => ContentRuleCompiler.compileIos(source, exceptionHosts: hosts),
    );
    _iosKey = key;
    _ios = out;
    return out;
  }

  /// Android content blockers for the current list; compiled once per list
  /// version, since per-site exceptions are applied by the engine.
  Future<AndroidRuleSet> androidSet() async {
    final String key = 'v${blocklist.value.version}';
    if (_android != null && _androidKey == key) {
      return _android!;
    }
    final List<BlocklistRule> source = blocklist.rules;
    final AndroidRuleSet out = await _runner<AndroidRuleSet>(
      () => ContentRuleCompiler.compileAndroid(source),
    );
    _androidKey = key;
    _android = out;
    return out;
  }

  /// Whether the manifest in use allows refreshing the list.
  bool get canRefresh => flags.isEnabled(FeatureFlag.blocklistRefresh);

  /// Checks the website now. Remembers when, so the weekly check can tell.
  Future<RefreshOutcome> refreshNow() async {
    final RefreshOutcome outcome = await blocklist.refresh();
    await _remember();
    return outcome;
  }

  /// The weekly check: runs only when the person turned it on, refreshing is
  /// allowed, and a week has passed since the last check. Quiet on failure.
  Future<void> autoRefreshIfDue() async {
    if (!settings.value.blocklistAutoUpdate || !canRefresh) {
      return;
    }
    final int? last = await _lastCheckMillis();
    if (last != null &&
        _clock().difference(DateTime.fromMillisecondsSinceEpoch(last)) <
            autoRefreshInterval) {
      return;
    }
    await blocklist.refresh(background: true);
    await _remember();
  }

  Future<int?> _lastCheckMillis() async {
    try {
      return await _store.getInt(StorageKeys.blocklistLastCheck);
    } on Object {
      return null;
    }
  }

  Future<void> _remember() async {
    try {
      await _store.setInt(
        StorageKeys.blocklistLastCheck,
        _clock().millisecondsSinceEpoch,
      );
    } on Object {
      // Not remembering only means the next start checks again.
    }
  }

  @override
  void dispose() {
    blocklist.removeListener(_changed);
    settings.removeListener(_changed);
    sites.removeListener(_changed);
    flags.removeListener(_changed);
    super.dispose();
  }
}
