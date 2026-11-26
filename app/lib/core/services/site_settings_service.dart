import '../contracts/local_database.dart';
import '../models/site_setting.dart';
import '../storage/persistence_guard.dart';

/// The `site_settings` table, kept in memory as well, because every page load
/// asks about its site and the list is short.
///
/// A site with no overrides has no row. If the database cannot be used the
/// settings still work for this session and the guard records the failure.
class SiteSettingsService {
  SiteSettingsService(this._db, this._guard, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// The statement that creates the table; database migration step 2.
  static const String createTable =
      'CREATE TABLE IF NOT EXISTS site_settings ('
      'host TEXT PRIMARY KEY NOT NULL, '
      'js_enabled INTEGER NOT NULL DEFAULT 1, '
      'desktop_mode INTEGER, '
      'adblock_enabled INTEGER NOT NULL DEFAULT 1, '
      'camera INTEGER NOT NULL DEFAULT 0, '
      'microphone INTEGER NOT NULL DEFAULT 0, '
      'location INTEGER NOT NULL DEFAULT 0, '
      'updated_at INTEGER NOT NULL DEFAULT 0)';

  final LocalDatabase _db;
  final PersistenceGuard _guard;
  final DateTime Function() _clock;
  final Map<String, SiteSetting> _cache = <String, SiteSetting>{};

  /// Reads every stored site. Rows that are not valid are ignored.
  Future<void> load() async {
    final List<DbRow> rows = await _guard.run<List<DbRow>>(
      'site settings',
      () => _db.query('SELECT * FROM site_settings'),
      fallback: () => const <DbRow>[],
    );
    _cache.clear();
    for (final DbRow row in rows) {
      final SiteSetting? setting = SiteSetting.fromRow(row);
      if (setting != null && !setting.isDefault) {
        _cache[setting.host] = setting;
      }
    }
  }

  /// The settings for [host]; the defaults when it has none.
  SiteSetting get(String host) {
    final String key = SiteSetting.normalizeHost(host);
    return _cache[key] ?? SiteSetting.defaultsFor(key);
  }

  /// Every site that differs from the defaults, by host.
  List<SiteSetting> get overrides =>
      _cache.values.toList()
        ..sort((SiteSetting a, SiteSetting b) => a.host.compareTo(b.host));

  /// Stores [setting]. One that equals the defaults removes the row instead.
  Future<void> save(SiteSetting setting) async {
    final SiteSetting stamped = setting.copyWith(updatedAt: _clock());
    if (stamped.isDefault) {
      await remove(stamped.host);
      return;
    }
    _cache[stamped.host] = stamped;
    await _guard.run<void>(
      'site settings',
      () async {
        final Map<String, Object?> row = stamped.toRow();
        await _db.execute(
          'INSERT OR REPLACE INTO site_settings '
          '(host, js_enabled, desktop_mode, adblock_enabled, camera, '
          'microphone, location, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            row['host'],
            row['js_enabled'],
            row['desktop_mode'],
            row['adblock_enabled'],
            row['camera'],
            row['microphone'],
            row['location'],
            row['updated_at'],
          ],
        );
      },
      fallback: () {},
      write: true,
    );
  }

  Future<void> remove(String host) async {
    final String key = SiteSetting.normalizeHost(host);
    _cache.remove(key);
    await _guard.run<void>(
      'site settings',
      () => _db.execute('DELETE FROM site_settings WHERE host = ?', <Object?>[
        key,
      ]),
      fallback: () {},
      write: true,
    );
  }

  Future<void> clear() async {
    _cache.clear();
    await _guard.run<void>(
      'site settings',
      () => _db.execute('DELETE FROM site_settings'),
      fallback: () {},
      write: true,
    );
  }
}
