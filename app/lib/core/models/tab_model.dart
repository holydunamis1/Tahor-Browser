import 'package:flutter/foundation.dart';

/// Whether a tab asks sites for their phone or their desktop layout.
enum TabViewMode { mobile, desktop }

const Object _keep = Object();

/// One browser tab as it is stored and shown.
///
/// This model is complete from the first release because tab ownership is the
/// costliest thing to change later. The live web view is not part of it; the
/// engine owns that, keyed by [id].
@immutable
class TabModel {
  const TabModel({
    required this.id,
    this.url = '',
    this.title,
    this.faviconUrl,
    this.isIncognito = false,
    this.viewMode = TabViewMode.mobile,
    this.scrollY = 0,
    this.stateKey,
  });

  /// Unique and stable for the life of the tab.
  final String id;

  /// The current address; empty for a blank tab.
  final String url;
  final String? title;
  final String? faviconUrl;
  final bool isIncognito;
  final TabViewMode viewMode;

  /// The vertical scroll position in logical pixels, saved for restore.
  final double scrollY;

  /// Key of the saved web view state in the file store, when there is one.
  final String? stateKey;

  bool get isBlank => url.isEmpty;

  /// Reads a saved tab, or returns null when it has no usable id.
  static TabModel? tryFromJson(Object? json) {
    if (json is! Map<Object?, Object?>) {
      return null;
    }
    final Object? id = json['id'];
    if (id is! String || id.isEmpty) {
      return null;
    }
    final Object? url = json['url'];
    final Object? title = json['title'];
    final Object? favicon = json['faviconUrl'];
    final Object? incognito = json['isIncognito'];
    final Object? mode = json['viewMode'];
    final Object? scroll = json['scrollY'];
    final Object? stateKey = json['stateKey'];
    return TabModel(
      id: id,
      url: url is String ? url : '',
      title: title is String ? title : null,
      faviconUrl: favicon is String ? favicon : null,
      isIncognito: incognito is bool ? incognito : false,
      viewMode: mode is String
          ? (TabViewMode.values.asNameMap()[mode] ?? TabViewMode.mobile)
          : TabViewMode.mobile,
      scrollY: scroll is num && scroll.isFinite && scroll >= 0
          ? scroll.toDouble()
          : 0,
      stateKey: stateKey is String ? stateKey : null,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'url': url,
    'title': title,
    'faviconUrl': faviconUrl,
    'isIncognito': isIncognito,
    'viewMode': viewMode.name,
    'scrollY': scrollY,
    'stateKey': stateKey,
  };

  /// A copy with changes. Pass `null` for [title], [faviconUrl] or [stateKey]
  /// to clear them.
  TabModel copyWith({
    String? url,
    Object? title = _keep,
    Object? faviconUrl = _keep,
    bool? isIncognito,
    TabViewMode? viewMode,
    double? scrollY,
    Object? stateKey = _keep,
  }) {
    return TabModel(
      id: id,
      url: url ?? this.url,
      title: identical(title, _keep) ? this.title : title as String?,
      faviconUrl: identical(faviconUrl, _keep)
          ? this.faviconUrl
          : faviconUrl as String?,
      isIncognito: isIncognito ?? this.isIncognito,
      viewMode: viewMode ?? this.viewMode,
      scrollY: scrollY ?? this.scrollY,
      stateKey: identical(stateKey, _keep)
          ? this.stateKey
          : stateKey as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TabModel &&
      other.id == id &&
      other.url == url &&
      other.title == title &&
      other.faviconUrl == faviconUrl &&
      other.isIncognito == isIncognito &&
      other.viewMode == viewMode &&
      other.scrollY == scrollY &&
      other.stateKey == stateKey;

  @override
  int get hashCode => Object.hash(
    id,
    url,
    title,
    faviconUrl,
    isIncognito,
    viewMode,
    scrollY,
    stateKey,
  );

  @override
  String toString() => 'TabModel($id, $url${isIncognito ? ', private' : ''})';
}
