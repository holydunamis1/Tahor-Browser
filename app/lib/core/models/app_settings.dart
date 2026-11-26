import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// The theme the person chose. [system] follows the phone.
enum AppThemeMode { system, light, dark }

/// What the browser opens when the app starts.
enum StartupMode {
  /// The tabs that were open, each where it was left. The default.
  continueSession,

  /// One blank tab with the start page.
  startPage,
}

const Object _keep = Object();

/// Everything the person can change in Settings, persisted as one JSON value.
///
/// Later batches add fields with a default, so older saved values keep
/// loading: unknown fields are ignored and missing fields take their default.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.searchEngineId = AppConstants.defaultSearchEngineId,
    this.localeCode,
    this.startupMode = StartupMode.continueSession,
    this.adblockEnabled = true,
    this.blocklistAutoUpdate = false,
  });

  /// The version written into every saved value.
  static const int schemaVersion = 1;

  final AppThemeMode themeMode;

  /// The id of one of [AppConstants.searchEngines].
  final String searchEngineId;

  /// A language code such as `de`, or null to follow the phone.
  final String? localeCode;

  final StartupMode startupMode;

  /// The global ad-blocking switch.
  final bool adblockEnabled;

  /// Check for a newer blocklist about once a week. Off unless the person
  /// turns it on.
  final bool blocklistAutoUpdate;

  /// Reads a saved value. Never throws: anything unusable becomes a default.
  factory AppSettings.fromJson(Map<String, Object?> json) {
    final Object? mode = json['themeMode'];
    final Object? engine = json['searchEngineId'];
    final Object? locale = json['localeCode'];
    final Object? startup = json['startupMode'];
    final Object? adblock = json['adblockEnabled'];
    final Object? auto = json['blocklistAutoUpdate'];
    return AppSettings(
      themeMode: mode is String
          ? (AppThemeMode.values.asNameMap()[mode] ?? AppThemeMode.system)
          : AppThemeMode.system,
      searchEngineId: engine is String && engine.isNotEmpty
          ? engine
          : AppConstants.defaultSearchEngineId,
      localeCode: locale is String && locale.isNotEmpty ? locale : null,
      startupMode: startup is String
          ? (StartupMode.values.asNameMap()[startup] ??
                StartupMode.continueSession)
          : StartupMode.continueSession,
      adblockEnabled: adblock is bool ? adblock : true,
      blocklistAutoUpdate: auto is bool ? auto : false,
    );
  }

  /// The version found in a saved value, or null when it has none.
  static int? versionOf(Map<String, Object?> json) {
    final Object? v = json['v'];
    return v is int ? v : null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'v': schemaVersion,
    'themeMode': themeMode.name,
    'searchEngineId': searchEngineId,
    'localeCode': localeCode,
    'startupMode': startupMode.name,
    'adblockEnabled': adblockEnabled,
    'blocklistAutoUpdate': blocklistAutoUpdate,
  };

  /// A copy with changes. Pass `localeCode: null` to go back to the phone's
  /// language.
  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? searchEngineId,
    Object? localeCode = _keep,
    StartupMode? startupMode,
    bool? adblockEnabled,
    bool? blocklistAutoUpdate,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      searchEngineId: searchEngineId ?? this.searchEngineId,
      localeCode: identical(localeCode, _keep)
          ? this.localeCode
          : localeCode as String?,
      startupMode: startupMode ?? this.startupMode,
      adblockEnabled: adblockEnabled ?? this.adblockEnabled,
      blocklistAutoUpdate: blocklistAutoUpdate ?? this.blocklistAutoUpdate,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.searchEngineId == searchEngineId &&
      other.localeCode == localeCode &&
      other.startupMode == startupMode &&
      other.adblockEnabled == adblockEnabled &&
      other.blocklistAutoUpdate == blocklistAutoUpdate;

  @override
  int get hashCode => Object.hash(
    themeMode,
    searchEngineId,
    localeCode,
    startupMode,
    adblockEnabled,
    blocklistAutoUpdate,
  );

  @override
  String toString() =>
      'AppSettings(theme: ${themeMode.name}, engine: $searchEngineId, locale: $localeCode, startup: ${startupMode.name})';
}
