import 'package:flutter/foundation.dart';

import '../storage/schema_version.dart';
import 'tab_model.dart';

/// The tabs worth restoring after the app was closed or killed: their order,
/// which one was showing, and when this was saved.
///
/// Private tabs are never part of a snapshot.
@immutable
class SessionSnapshot {
  const SessionSnapshot._({
    required this.tabs,
    required this.activeIndex,
    required this.savedAt,
  });

  /// Builds a snapshot from the live [tabs]. Private tabs are left out, and
  /// [activeTabId] picks the active one among the rest (the first when it is
  /// private or unknown).
  factory SessionSnapshot.capture({
    required List<TabModel> tabs,
    required String? activeTabId,
    required DateTime savedAt,
  }) {
    final List<TabModel> kept = tabs
        .where((TabModel tab) => !tab.isIncognito)
        .toList(growable: false);
    final int found = kept.indexWhere((TabModel tab) => tab.id == activeTabId);
    return SessionSnapshot._(
      tabs: List<TabModel>.unmodifiable(kept),
      activeIndex: found < 0 ? 0 : found,
      savedAt: savedAt,
    );
  }

  static const int schemaVersion = SchemaVersions.sessionSnapshot;

  final List<TabModel> tabs;

  /// Index into [tabs]; 0 when there are none.
  final int activeIndex;
  final DateTime savedAt;

  bool get isEmpty => tabs.isEmpty;

  /// The active tab, or null when there are no tabs.
  TabModel? get activeTab => tabs.isEmpty ? null : tabs[activeIndex];

  /// Reads a saved snapshot. Returns null when [json] is not a snapshot this
  /// app can read: no version, a newer version, or the wrong shape. Tabs that
  /// cannot be read and private tabs are skipped.
  static SessionSnapshot? tryFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return null;
    }
    final Object? version = json['v'];
    if (version is! int || version < 1 || version > schemaVersion) {
      return null;
    }
    final Object? rawTabs = json['tabs'];
    if (rawTabs is! List<Object?>) {
      return null;
    }
    final List<TabModel> tabs = <TabModel>[];
    final Set<String> seen = <String>{};
    for (final Object? raw in rawTabs) {
      final TabModel? tab = TabModel.tryFromJson(raw);
      if (tab != null && !tab.isIncognito && seen.add(tab.id)) {
        tabs.add(tab);
      }
    }
    final Object? active = json['active'];
    final int activeIndex = active is int && active >= 0 && active < tabs.length
        ? active
        : 0;
    final Object? saved = json['savedAt'];
    return SessionSnapshot._(
      tabs: List<TabModel>.unmodifiable(tabs),
      activeIndex: activeIndex,
      savedAt: saved is int
          ? DateTime.fromMillisecondsSinceEpoch(saved, isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'v': schemaVersion,
    'savedAt': savedAt.toUtc().millisecondsSinceEpoch,
    'active': activeIndex,
    'tabs': <Object?>[for (final TabModel tab in tabs) tab.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is SessionSnapshot &&
      other.activeIndex == activeIndex &&
      other.savedAt.toUtc() == savedAt.toUtc() &&
      listEquals(other.tabs, tabs);

  @override
  int get hashCode => Object.hash(
    activeIndex,
    savedAt.toUtc().millisecondsSinceEpoch,
    Object.hashAll(tabs),
  );
}
