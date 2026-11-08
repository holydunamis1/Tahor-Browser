import 'package:flutter/widgets.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/contracts/key_value_store.dart';

/// A [KeyValueStore] in memory, with switches to simulate storage trouble.
class FakeKeyValueStore implements KeyValueStore {
  FakeKeyValueStore([Map<String, Object>? initial])
    : data = <String, Object>{...?initial};

  final Map<String, Object> data;
  bool failed = false;

  @override
  bool get hasFailed => failed;

  @override
  Future<String?> getString(String key) async =>
      data[key] is String ? data[key] as String : null;

  @override
  Future<void> setString(String key, String value) async => data[key] = value;

  @override
  Future<int?> getInt(String key) async =>
      data[key] is int ? data[key] as int : null;

  @override
  Future<void> setInt(String key, int value) async => data[key] = value;

  @override
  Future<bool?> getBool(String key) async =>
      data[key] is bool ? data[key] as bool : null;

  @override
  Future<void> setBool(String key, bool value) async => data[key] = value;

  @override
  Future<Map<String, Object?>?> getJson(String key) async {
    final Object? value = data[key];
    return value is Map<String, Object?> ? value : null;
  }

  @override
  Future<void> setJson(String key, Map<String, Object?> value) async =>
      data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);
}

/// A [BrowserEngine] that records what it is asked to do.
class FakeBrowserEngine implements BrowserEngine {
  final List<String> calls = <String>[];
  final List<TabViewConfig> builtConfigs = <TabViewConfig>[];
  NavigationPolicy? policy;
  TabEventSink? lastSink;

  @override
  void setNavigationPolicy(NavigationPolicy policy) => this.policy = policy;

  @override
  Widget buildTab(TabViewConfig config, TabEventSink sink) {
    builtConfigs.add(config);
    lastSink = sink;
    return SizedBox(key: ValueKey<String>('view-${config.tabId}'));
  }

  @override
  Future<void> load(String tabId, Uri uri) async =>
      calls.add('load $tabId $uri');

  @override
  Future<void> goBack(String tabId) async => calls.add('back $tabId');

  @override
  Future<void> goForward(String tabId) async => calls.add('forward $tabId');

  @override
  Future<void> reload(String tabId) async => calls.add('reload $tabId');

  @override
  Future<void> stop(String tabId) async => calls.add('stop $tabId');

  @override
  Future<void> dispose(String tabId) async => calls.add('dispose $tabId');
}
