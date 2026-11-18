import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:tahorbrowser/core/contracts/app_info.dart';
import 'package:tahorbrowser/core/contracts/browser_engine.dart';
import 'package:tahorbrowser/core/contracts/external_launcher.dart';
import 'package:tahorbrowser/core/contracts/file_store.dart';
import 'package:tahorbrowser/core/contracts/key_value_store.dart';
import 'package:tahorbrowser/core/contracts/local_database.dart';
import 'package:tahorbrowser/core/contracts/share.dart';

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
    if (value is! String) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(value);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Like the real store, JSON is kept as text.
  @override
  Future<void> setJson(String key, Map<String, Object?> value) async =>
      data[key] = jsonEncode(value);

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

/// An [ExternalLauncher] that records what it is asked to open.
class FakeLauncher implements ExternalLauncher {
  final List<Uri> systemBrowser = <Uri>[];
  final List<Uri> apps = <Uri>[];

  @override
  Future<bool> openInSystemBrowser(Uri uri) async {
    systemBrowser.add(uri);
    return true;
  }

  @override
  Future<bool> openExternalApp(Uri uri) async {
    apps.add(uri);
    return true;
  }
}

/// A [Share] that records what it is asked to share.
class FakeShare implements Share {
  final List<(Uri, String?)> shared = <(Uri, String?)>[];

  @override
  Future<void> shareUrl(Uri url, {String? title}) async =>
      shared.add((url, title));
}

class FakeAppInfo implements AppInfo {
  @override
  String get version => '0.1.0';

  @override
  String get buildNumber => '1';
}

/// A [FileStore] in memory. Set [failWrites] or [failReads] to make it throw.
class FakeFileStore implements FileStore {
  final Map<String, Map<String, Uint8List>> data =
      <String, Map<String, Uint8List>>{};
  bool failWrites = false;
  bool failReads = false;

  @override
  Future<void> write(String namespace, String key, Uint8List bytes) async {
    if (failWrites) {
      throw StateError('write failed');
    }
    data.putIfAbsent(namespace, () => <String, Uint8List>{})[key] = bytes;
  }

  @override
  Future<Uint8List?> read(String namespace, String key) async {
    if (failReads) {
      throw StateError('read failed');
    }
    return data[namespace]?[key];
  }

  @override
  Future<bool> delete(String namespace, String key) async =>
      data[namespace]?.remove(key) != null;

  @override
  Future<List<FileEntry>> list(String namespace) async => <FileEntry>[
    for (final MapEntry<String, Uint8List> e
        in (data[namespace] ?? <String, Uint8List>{}).entries)
      FileEntry(e.key, e.value.length),
  ];

  @override
  Future<void> clear(String namespace) async => data.remove(namespace);
}

/// A [LocalDatabase] that records what it is asked to run and answers every
/// query with no rows. Real SQL is exercised by the integration tests.
class FakeLocalDatabase implements LocalDatabase {
  final List<String> statements = <String>[];
  DatabaseSchema? schema;
  bool opened = false;

  @override
  bool get isOpen => opened;

  @override
  Future<void> open(DatabaseSchema schema) async {
    this.schema = schema;
    opened = true;
  }

  @override
  Future<void> execute(
    String sql, [
    List<Object?> arguments = const <Object?>[],
  ]) async => statements.add(sql);

  @override
  Future<List<DbRow>> query(
    String sql, [
    List<Object?> arguments = const <Object?>[],
  ]) async => const <DbRow>[];

  @override
  Future<T> transaction<T>(Future<T> Function(SqlExecutor txn) action) =>
      action(this);

  @override
  Future<void> close() async => opened = false;
}
