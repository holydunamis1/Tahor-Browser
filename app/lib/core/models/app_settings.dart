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
  });

  /// The version written into every saved value.
  static const int schemaVersion = 1;

  final AppThemeMode themeMode;

  /// The id of one of [AppConstants.searchEngines].
  final String searchEngineId;

  /// A language code such as `de`, or null to follow the phone.
  final String? localeCode;

  final StartupMode startupMode;

  /// Reads a saved value. Never throws: anything unusable becomes a default.
  factory AppSettings.fromJson(Map<String, Object?> json) {
    final Object? mode = json['themeMode'];
    final Object? engine = json['searchEngineId'];
    final Object? locale = json['localeCode'];
    final Object? startup = json['startupMode'];
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
  };

  /// A copy with changes. Pass `localeCode: null` to go back to the phone's
  /// language.
  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? searchEngineId,
    Object? localeCode = _keep,
    StartupMode? startupMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      searchEngineId: searchEngineId ?? this.searchEngineId,
      localeCode: identical(localeCode, _keep)
          ? this.localeCode
          : localeCode as String?,
      startupMode: startupMode ?? this.startupMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.searchEngineId == searchEngineId &&
      other.localeCode == localeCode &&
      other.startupMode == startupMode;

  @override
  int get hashCode =>
      Object.hash(themeMode, searchEngineId, localeCode, startupMode);

  @override
  String toString() =>
      'AppSettings(theme: ${themeMode.name}, engine: $searchEngineId, locale: $localeCode, startup: ${startupMode.name})';
}
