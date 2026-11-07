import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/contracts/key_value_store.dart';

/// [KeyValueStore] over `shared_preferences`.
///
/// Every call is guarded. When storage is not available, values are kept in
/// memory for the rest of the session and [hasFailed] turns true so the app
/// can warn that changes may be lost.
class SharedPrefsKeyValueStore implements KeyValueStore {
  SharedPrefsKeyValueStore({Future<SharedPreferences> Function()? loader})
    : _loader = loader ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _loader;
  final Map<String, Object> _memory = <String, Object>{};
  SharedPreferences? _prefs;
  bool _failed = false;

  @override
  bool get hasFailed => _failed;

  Future<SharedPreferences?> _open() async {
    if (_prefs != null) {
      return _prefs;
    }
    try {
      _prefs = await _loader();
    } on Exception {
      _failed = true;
    }
    return _prefs;
  }

  Future<T?> _read<T extends Object>(
    String key,
    T? Function(SharedPreferences prefs) read,
  ) async {
    final Object? remembered = _memory[key];
    if (remembered is T) {
      return remembered;
    }
    final SharedPreferences? prefs = await _open();
    if (prefs == null) {
      return null;
    }
    try {
      return read(prefs);
    } on TypeError {
      // The key holds a value of another type: treat it as missing.
      return null;
    } on Exception {
      _failed = true;
      return null;
    }
  }

  Future<void> _write(
    String key,
    Object value,
    Future<bool> Function(SharedPreferences prefs) write,
  ) async {
    final SharedPreferences? prefs = await _open();
    if (prefs != null) {
      try {
        if (await write(prefs)) {
          _memory.remove(key);
          return;
        }
      } on Exception {
        // Falls through to the in-memory copy below.
      }
    }
    _failed = true;
    _memory[key] = value;
  }

  @override
  Future<String?> getString(String key) =>
      _read<String>(key, (SharedPreferences p) => p.getString(key));

  @override
  Future<void> setString(String key, String value) =>
      _write(key, value, (SharedPreferences p) => p.setString(key, value));

  @override
  Future<int?> getInt(String key) =>
      _read<int>(key, (SharedPreferences p) => p.getInt(key));

  @override
  Future<void> setInt(String key, int value) =>
      _write(key, value, (SharedPreferences p) => p.setInt(key, value));

  @override
  Future<bool?> getBool(String key) =>
      _read<bool>(key, (SharedPreferences p) => p.getBool(key));

  @override
  Future<void> setBool(String key, bool value) =>
      _write(key, value, (SharedPreferences p) => p.setBool(key, value));

  @override
  Future<Map<String, Object?>?> getJson(String key) async {
    final String? text = await getString(key);
    if (text == null) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(text);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      if (decoded is Map<Object?, Object?>) {
        return decoded.cast<String, Object?>();
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  @override
  Future<void> setJson(String key, Map<String, Object?> value) =>
      setString(key, jsonEncode(value));

  @override
  Future<void> remove(String key) async {
    _memory.remove(key);
    final SharedPreferences? prefs = await _open();
    if (prefs == null) {
      return;
    }
    try {
      await prefs.remove(key);
    } on Exception {
      _failed = true;
    }
  }
}
