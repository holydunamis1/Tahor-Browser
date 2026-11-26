import 'package:flutter/foundation.dart';

/// What the person decided for a site's camera, microphone or location.
enum SitePermission { ask, allow, deny }

/// How one site is treated, when that differs from the defaults.
@immutable
class SiteSetting {
  const SiteSetting({
    required this.host,
    this.jsEnabled = true,
    this.desktopMode,
    this.adblockEnabled = true,
    this.camera = SitePermission.ask,
    this.microphone = SitePermission.ask,
    this.location = SitePermission.ask,
    this.updatedAt,
  });

  /// A site with no overrides.
  factory SiteSetting.defaultsFor(String host) =>
      SiteSetting(host: normalizeHost(host));

  /// The key sites are stored under: lower case, no trailing dot, no leading
  /// `www.`. Subdomains stay separate sites (the app has no public-suffix list
  /// to find the registrable domain).
  static String normalizeHost(String host) {
    String h = host.trim().toLowerCase();
    if (h.endsWith('.')) {
      h = h.substring(0, h.length - 1);
    }
    return h.startsWith('www.') ? h.substring(4) : h;
  }

  final String host;
  final bool jsEnabled;

  /// True or false when the person chose a site mode; null follows the
  /// default (the mobile site).
  final bool? desktopMode;
  final bool adblockEnabled;
  final SitePermission camera;
  final SitePermission microphone;
  final SitePermission location;
  final DateTime? updatedAt;

  /// True when nothing differs from the defaults, so nothing is stored.
  bool get isDefault =>
      jsEnabled &&
      desktopMode == null &&
      adblockEnabled &&
      camera == SitePermission.ask &&
      microphone == SitePermission.ask &&
      location == SitePermission.ask;

  static const Object _keep = Object();

  SiteSetting copyWith({
    bool? jsEnabled,
    Object? desktopMode = _keep,
    bool? adblockEnabled,
    SitePermission? camera,
    SitePermission? microphone,
    SitePermission? location,
    DateTime? updatedAt,
  }) => SiteSetting(
    host: host,
    jsEnabled: jsEnabled ?? this.jsEnabled,
    desktopMode: identical(desktopMode, _keep)
        ? this.desktopMode
        : desktopMode as bool?,
    adblockEnabled: adblockEnabled ?? this.adblockEnabled,
    camera: camera ?? this.camera,
    microphone: microphone ?? this.microphone,
    location: location ?? this.location,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toRow() => <String, Object?>{
    'host': host,
    'js_enabled': jsEnabled ? 1 : 0,
    'desktop_mode': desktopMode == null ? null : (desktopMode! ? 1 : 0),
    'adblock_enabled': adblockEnabled ? 1 : 0,
    'camera': camera.index,
    'microphone': microphone.index,
    'location': location.index,
    'updated_at': updatedAt?.toUtc().millisecondsSinceEpoch ?? 0,
  };

  /// Reads a stored row, or null when it is not one.
  static SiteSetting? fromRow(Map<String, Object?> row) {
    final Object? host = row['host'];
    if (host is! String || host.isEmpty) {
      return null;
    }
    bool flag(Object? v, {required bool otherwise}) =>
        v is int ? v != 0 : otherwise;
    SitePermission permission(Object? v) =>
        v is int && v >= 0 && v < SitePermission.values.length
        ? SitePermission.values[v]
        : SitePermission.ask;
    final Object? desktop = row['desktop_mode'];
    final Object? updated = row['updated_at'];
    return SiteSetting(
      host: host,
      jsEnabled: flag(row['js_enabled'], otherwise: true),
      desktopMode: desktop is int ? desktop != 0 : null,
      adblockEnabled: flag(row['adblock_enabled'], otherwise: true),
      camera: permission(row['camera']),
      microphone: permission(row['microphone']),
      location: permission(row['location']),
      updatedAt: updated is int && updated > 0
          ? DateTime.fromMillisecondsSinceEpoch(updated, isUtc: true)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SiteSetting &&
      other.host == host &&
      other.jsEnabled == jsEnabled &&
      other.desktopMode == desktopMode &&
      other.adblockEnabled == adblockEnabled &&
      other.camera == camera &&
      other.microphone == microphone &&
      other.location == location &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    host,
    jsEnabled,
    desktopMode,
    adblockEnabled,
    camera,
    microphone,
    location,
    updatedAt,
  );

  @override
  String toString() => 'SiteSetting($host, adblock: $adblockEnabled)';
}
