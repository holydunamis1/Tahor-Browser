import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../contracts/file_store.dart';
import '../contracts/http_client.dart';
import '../error/error_taxonomy.dart';
import '../models/blocklist_rule.dart';
import '../storage/storage_keys.dart';
import 'blocklist_verifier.dart';
import 'canonical_parser.dart';

enum BlocklistSource { none, bundled, downloaded }

enum RefreshOutcome { updated, upToDate, failed }

/// Which list is in use and how the last refresh went.
@immutable
class BlocklistStatus {
  const BlocklistStatus({
    this.version = 0,
    this.source = BlocklistSource.none,
    this.ruleCount = 0,
    this.checkedAt,
    this.lastError,
  });

  final int version;
  final BlocklistSource source;
  final int ruleCount;
  final DateTime? checkedAt;

  /// The last refresh's problem, or null.
  final AppError? lastError;

  BlocklistStatus copyWith({
    int? version,
    BlocklistSource? source,
    int? ruleCount,
    DateTime? checkedAt,
    Object? lastError = _keep,
  }) => BlocklistStatus(
    version: version ?? this.version,
    source: source ?? this.source,
    ruleCount: ruleCount ?? this.ruleCount,
    checkedAt: checkedAt ?? this.checkedAt,
    lastError: identical(lastError, _keep)
        ? this.lastError
        : lastError as AppError?,
  );

  static const Object _keep = Object();

  @override
  bool operator ==(Object other) =>
      other is BlocklistStatus &&
      other.version == version &&
      other.source == source &&
      other.ruleCount == ruleCount &&
      other.checkedAt == checkedAt &&
      other.lastError == lastError;

  @override
  int get hashCode =>
      Object.hash(version, source, ruleCount, checkedAt, lastError);
}

/// Owns the blocklist in use.
///
/// It starts from the list saved by an earlier refresh (checked again, in
/// case the file was changed) or, failing that, the list bundled in the app,
/// which is the full signed list published when the app was built and is
/// checked in the same way. A refresh downloads the signed manifest, and only when it is newer
/// downloads the list; the new list replaces the old one only after it has
/// passed every check. A failed, tampered or older download never replaces
/// the list in use.
class BlocklistService extends ValueNotifier<BlocklistStatus> {
  BlocklistService({
    required this.http,
    required this.files,
    required this.verifier,
    required this.loadAssetBytes,
    required this.appVersion,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const BlocklistStatus());

  static const String bundledListAsset =
      'assets/blocklist/canonical_blocklist.txt';
  static const String bundledManifestAsset = 'assets/blocklist/manifest.json';
  static const String bundledSignatureAsset = 'assets/blocklist/manifest.sig';

  static const String _listKey = 'list.txt';
  static const String _manifestKey = 'manifest.json';
  static const String _signatureKey = 'manifest.sig';

  final HttpClient http;
  final FileStore files;
  final BlocklistVerifier verifier;
  final Future<Uint8List> Function(String assetPath) loadAssetBytes;
  final String appVersion;
  final DateTime Function() _clock;

  List<BlocklistRule> _rules = const <BlocklistRule>[];
  BlocklistManifest? _manifest;

  /// The rules in use.
  List<BlocklistRule> get rules => _rules;

  /// The manifest of the list in use; null only when no list could be loaded.
  BlocklistManifest? get manifest => _manifest;

  /// Kill switches from the manifest in use; empty means everything is on.
  Map<String, bool> get flags => _manifest?.flags ?? const <String, bool>{};

  void _use(
    List<BlocklistRule> rules,
    BlocklistSource source,
    int version, {
    BlocklistManifest? manifest,
  }) {
    _rules = rules;
    _manifest = manifest;
    value = value.copyWith(
      version: version,
      source: source,
      ruleCount: rules.length,
    );
  }

  /// Loads the saved list when it is still valid, otherwise the bundled list.
  Future<void> initialize() async {
    if (await _loadSaved()) {
      return;
    }
    await _loadBundled();
  }

  /// Parses [list] once it has passed every check against its signed manifest.
  /// Returns null when anything is wrong.
  Future<({List<BlocklistRule> rules, BlocklistManifest manifest})?> _checked(
    Uint8List list,
    Uint8List manifestBytes,
    Uint8List signature,
  ) async {
    final VerificationResult checked = await verifier.verifyManifest(
      manifestJson: utf8.decode(manifestBytes),
      signature: base64Decode(utf8.decode(signature).trim()),
      currentVersion: 0,
      appVersion: appVersion,
    );
    final BlocklistManifest? manifest = checked.manifest;
    if (manifest == null || !(await verifier.verifyList(manifest, list)).isOk) {
      return null;
    }
    final ParseResult parsed = parseCanonical(utf8.decode(list));
    return parsed.rules.isEmpty
        ? null
        : (rules: parsed.rules, manifest: manifest);
  }

  Future<bool> _loadSaved() async {
    try {
      final Uint8List? list = await files.read(
        StorageKeys.blocklistNamespace,
        _listKey,
      );
      final Uint8List? manifestBytes = await files.read(
        StorageKeys.blocklistNamespace,
        _manifestKey,
      );
      final Uint8List? sig = await files.read(
        StorageKeys.blocklistNamespace,
        _signatureKey,
      );
      if (list == null || manifestBytes == null || sig == null) {
        return false;
      }
      final loaded = await _checked(list, manifestBytes, sig);
      if (loaded == null) {
        return false;
      }
      _use(
        loaded.rules,
        BlocklistSource.downloaded,
        loaded.manifest.version,
        manifest: loaded.manifest,
      );
      return true;
    } on Object {
      // A damaged or unreadable file, or a storage plugin that throws, means
      // the bundled list is used.
      return false;
    }
  }

  /// Loads the list bundled in the app. It is checked like a download: a
  /// packaging mistake or a damaged asset leaves no list, and says why in
  /// [BlocklistStatus.lastError] rather than blocking with something unchecked.
  Future<void> _loadBundled() async {
    try {
      final loaded = await _checked(
        await loadAssetBytes(bundledListAsset),
        await loadAssetBytes(bundledManifestAsset),
        await loadAssetBytes(bundledSignatureAsset),
      );
      if (loaded == null) {
        _use(const <BlocklistRule>[], BlocklistSource.none, 0);
        value = value.copyWith(
          lastError: const BlocklistError.verificationFailed(
            detail: 'bundled list',
          ),
        );
        return;
      }
      _use(
        loaded.rules,
        BlocklistSource.bundled,
        loaded.manifest.version,
        manifest: loaded.manifest,
      );
    } on Object {
      // A missing asset throws an Error, not an Exception, so both are caught:
      // the browser still works, just without a blocklist.
      _use(const <BlocklistRule>[], BlocklistSource.none, 0);
      value = value.copyWith(
        lastError: const BlocklistError.invalid(detail: 'bundled list missing'),
      );
    }
  }

  /// Checks the website for a newer list and switches to it when it passes
  /// every check. [background] makes a failure silent in the interface.
  Future<RefreshOutcome> refresh({bool background = false}) async {
    try {
      final HttpResult manifestResponse = await http.get(
        Uri.parse(AppUrls.blocklistManifest),
      );
      final HttpResult sigResponse = await http.get(
        Uri.parse(AppUrls.blocklistSignature),
      );
      if (!manifestResponse.isOk || !sigResponse.isOk) {
        return _fail(
          BlocklistError.fetchFailed(
            background: background,
            detail:
                'manifest ${manifestResponse.status}, signature ${sigResponse.status}',
          ),
        );
      }
      final String manifestJson = utf8.decode(manifestResponse.bytes);
      final VerificationResult manifestCheck = await verifier.verifyManifest(
        manifestJson: manifestJson,
        signature: base64Decode(utf8.decode(sigResponse.bytes).trim()),
        currentVersion: value.version,
        appVersion: appVersion,
      );
      final VerificationFailure? failure = manifestCheck.failure;
      if (failure == VerificationFailure.rollback) {
        // Not newer than what is in use: nothing to do, and nothing wrong.
        value = value.copyWith(checkedAt: _clock(), lastError: null);
        return RefreshOutcome.upToDate;
      }
      if (failure != null) {
        return _fail(BlocklistError.verificationFailed(detail: failure.name));
      }
      final BlocklistManifest manifest = manifestCheck.manifest!;

      final HttpResult listResponse = await http.get(
        Uri.parse(AppUrls.blocklistLatest),
        timeout: const Duration(seconds: 90),
      );
      if (!listResponse.isOk) {
        return _fail(
          BlocklistError.fetchFailed(
            background: background,
            detail: 'list ${listResponse.status}',
          ),
        );
      }
      final VerificationResult listCheck = await verifier.verifyList(
        manifest,
        listResponse.bytes,
      );
      if (!listCheck.isOk) {
        return _fail(
          BlocklistError.verificationFailed(detail: listCheck.failure!.name),
        );
      }
      final ParseResult parsed = parseCanonical(
        utf8.decode(listResponse.bytes),
      );
      if (parsed.rules.isEmpty) {
        return _fail(const BlocklistError.invalid(detail: 'no rules'));
      }

      _use(
        parsed.rules,
        BlocklistSource.downloaded,
        manifest.version,
        manifest: manifest,
      );
      value = value.copyWith(checkedAt: _clock(), lastError: null);
      await _save(
        listResponse.bytes,
        manifestResponse.bytes,
        sigResponse.bytes,
      );
      return RefreshOutcome.updated;
    } on AppError catch (error) {
      return _fail(error);
    } on Exception catch (error) {
      return _fail(
        BlocklistError.fetchFailed(background: background, detail: '$error'),
      );
    }
  }

  RefreshOutcome _fail(AppError error) {
    value = value.copyWith(checkedAt: _clock(), lastError: error);
    return RefreshOutcome.failed;
  }

  Future<void> _save(Uint8List list, Uint8List manifest, Uint8List sig) async {
    try {
      await files.write(StorageKeys.blocklistNamespace, _listKey, list);
      await files.write(StorageKeys.blocklistNamespace, _manifestKey, manifest);
      await files.write(StorageKeys.blocklistNamespace, _signatureKey, sig);
    } on Object {
      // Storage trouble must never undo a successful refresh. The new list is
      // in use for this session; the next start downloads it again.
    }
  }
}
