/// A search engine offered in Settings and the welcome screen.
class SearchEngine {
  const SearchEngine({
    required this.id,
    required this.name,
    required this.urlTemplate,
  });

  final String id;
  final String name;

  /// A URL with a `{query}` placeholder.
  final String urlTemplate;

  /// The results URL for [query].
  String urlFor(String query) =>
      urlTemplate.replaceFirst('{query}', Uri.encodeQueryComponent(query));
}

/// Fixed addresses of our own static site (Cloudflare Worker, decision D-45).
abstract final class AppUrls {
  static const String site = 'https://tahor-browser.holydunamis1.workers.dev';
  static const String privacy = '$site/privacy.html';
  static const String support = '$site/support.html';
  static const String blocklistLatest = '$site/blocklist/latest.txt';
  static const String blocklistManifest = '$site/blocklist/manifest.json';
  static const String blocklistSignature = '$site/blocklist/manifest.sig';
}

/// Application-wide constants. Later batches add what they need.
abstract final class AppConstants {
  /// Shown in the app and used by the error report mail.
  static const String supportEmail = 'stmakarios@gmail.com';

  /// The most tabs that can be open at once. The tab count button shows 99+
  /// for 100.
  static const int maxTabs = 100;

  /// Live web views kept at once; idle tabs are hibernated (decision D-17).
  static const int maxLiveTabs = 3;

  /// Largest blob or data download accepted, in bytes (20 MB).
  static const int blobCeilingBytes = 20 * 1024 * 1024;

  static const String defaultSearchEngineId = 'duckduckgo';

  static const List<SearchEngine> searchEngines = <SearchEngine>[
    SearchEngine(
      id: 'duckduckgo',
      name: 'DuckDuckGo',
      urlTemplate: 'https://duckduckgo.com/?q={query}',
    ),
    SearchEngine(
      id: 'google',
      name: 'Google',
      urlTemplate: 'https://www.google.com/search?q={query}',
    ),
    SearchEngine(
      id: 'bing',
      name: 'Bing',
      urlTemplate: 'https://www.bing.com/search?q={query}',
    ),
    SearchEngine(
      id: 'brave',
      name: 'Brave Search',
      urlTemplate: 'https://search.brave.com/search?q={query}',
    ),
    SearchEngine(
      id: 'ecosia',
      name: 'Ecosia',
      urlTemplate: 'https://www.ecosia.org/search?q={query}',
    ),
  ];

  /// The engine with [id], or the default engine when [id] is unknown.
  static SearchEngine engineById(String id) {
    for (final SearchEngine engine in searchEngines) {
      if (engine.id == id) {
        return engine;
      }
    }
    return searchEngines.firstWhere(
      (SearchEngine e) => e.id == defaultSearchEngineId,
    );
  }
}
