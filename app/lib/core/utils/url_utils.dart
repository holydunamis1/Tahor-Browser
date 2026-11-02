import '../constants/app_constants.dart';

/// What the address bar decided to do with typed text.
enum InputKind { navigation, search, refused }

/// The result of [resolveInput].
class ResolvedInput {
  const ResolvedInput._(this.kind, this.uri, this.reason);

  /// Open [uri] as a page.
  const ResolvedInput.navigation(Uri this.uri)
    : kind = InputKind.navigation,
      reason = null;

  /// Open the search results page [uri].
  const ResolvedInput.search(Uri this.uri)
    : kind = InputKind.search,
      reason = null;

  /// Do nothing; [reason] is a short machine-readable cause.
  const ResolvedInput.refused(String this.reason)
    : kind = InputKind.refused,
      uri = null;

  final InputKind kind;
  final Uri? uri;
  final String? reason;
}

/// Schemes that are never opened from the address bar.
const Set<String> _refusedSchemes = <String>{
  'javascript',
  'vbscript',
  'file',
  'data',
  'blob',
  'content',
  'filesystem',
  'intent',
};

/// Schemes that navigate when typed.
const Set<String> _navigableSchemes = <String>{
  'http',
  'https',
  'mailto',
  'tel',
  'sms',
};

final RegExp _schemePrefix = RegExp(r'^([A-Za-z][A-Za-z0-9+.\-]*):');
final RegExp _whitespace = RegExp(r'\s');
final RegExp _webUrlWithSpaces = RegExp(
  r'^https?://[^\s/?#@]+[/?#]',
  caseSensitive: false,
);
final RegExp _hostWithPort = RegExp(r'^[^\s/:?#@]+:\d{1,5}(?:[/?#].*)?$');
final RegExp _dottedHost = RegExp(
  r'^(?:[^\s./:?#@]+\.)+[^\s./:?#@]{2,}(?::\d{1,5})?(?:[/?#].*)?$',
);
final RegExp _ipv4 = RegExp(
  r'^\d{1,3}(?:\.\d{1,3}){3}(?::\d{1,5})?(?:[/?#].*)?$',
);
final RegExp _ipv6 = RegExp(r'^\[[0-9A-Fa-f:.]+\](?::\d{1,5})?(?:[/?#].*)?$');
final RegExp _localName = RegExp(
  r'^[^\s/:?#@]+\.(?:local|localhost|internal|lan)(?::\d{1,5})?(?:[/?#].*)?$',
  caseSensitive: false,
);
final RegExp _localhost = RegExp(
  r'^localhost(?::\d{1,5})?(?:[/?#].*)?$',
  caseSensitive: false,
);

/// Decides what typed text means: a page, a search, or nothing.
///
/// See decision D-51 for the rules.
ResolvedInput resolveInput(String text, SearchEngine searchEngine) {
  final String input = text.trim();
  if (input.isEmpty) {
    return const ResolvedInput.refused('empty');
  }
  if (_whitespace.hasMatch(input)) {
    if (_webUrlWithSpaces.hasMatch(input)) {
      final Uri? uri = _normalized(Uri.tryParse(input));
      if (uri != null && uri.host.isNotEmpty) {
        return ResolvedInput.navigation(uri);
      }
    }
    return _search(input, searchEngine);
  }

  final RegExpMatch? scheme = _schemePrefix.firstMatch(input);
  if (scheme != null && !_hostWithPort.hasMatch(input)) {
    final String name = scheme.group(1)!.toLowerCase();
    if (_refusedSchemes.contains(name)) {
      return ResolvedInput.refused('scheme.$name');
    }
    if (input.toLowerCase() == 'about:blank') {
      return ResolvedInput.navigation(Uri.parse('about:blank'));
    }
    if (_navigableSchemes.contains(name)) {
      final Uri? uri = _normalized(Uri.tryParse(input));
      if (uri == null) {
        return _search(input, searchEngine);
      }
      final bool web = name == 'http' || name == 'https';
      if (web && (!uri.hasAuthority || uri.host.isEmpty)) {
        return _search(input, searchEngine);
      }
      return ResolvedInput.navigation(uri);
    }
    return _search(input, searchEngine);
  }

  final bool local =
      _localhost.hasMatch(input) ||
      _ipv4.hasMatch(input) ||
      _ipv6.hasMatch(input) ||
      _localName.hasMatch(input) ||
      _hostWithPort.hasMatch(input);
  if (local || _dottedHost.hasMatch(input)) {
    final Uri? uri = _normalized(
      Uri.tryParse('${local ? 'http' : 'https'}://$input'),
    );
    if (uri != null && uri.host.isNotEmpty) {
      return ResolvedInput.navigation(uri);
    }
  }
  return _search(input, searchEngine);
}

ResolvedInput _search(String query, SearchEngine engine) =>
    ResolvedInput.search(Uri.parse(engine.urlFor(query)));

/// Converts a host to its ASCII form: each label with non-ASCII letters is
/// lower-cased and written as `xn--` plus its punycode (RFC 3492).
///
/// Unicode normalization is not applied, so text typed in decomposed form is
/// not recomposed.
String toAsciiHost(String host) {
  final List<String> labels = host.split('.');
  return labels
      .map((String label) {
        final bool ascii = label.codeUnits.every((int c) => c < 0x80);
        if (ascii || label.startsWith('xn--')) {
          return label;
        }
        return 'xn--${_punycodeEncode(label.toLowerCase())}';
      })
      .join('.');
}

const int _pBase = 36;
const int _pTMin = 1;
const int _pTMax = 26;
const int _pSkew = 38;
const int _pDamp = 700;
const int _pInitialBias = 72;
const int _pInitialN = 128;

int _pDigit(int d) => d < 26 ? d + 97 : d + 22;

int _pAdapt(int delta, int numPoints, bool first) {
  int d = first ? delta ~/ _pDamp : delta ~/ 2;
  d += d ~/ numPoints;
  int k = 0;
  while (d > ((_pBase - _pTMin) * _pTMax) ~/ 2) {
    d ~/= _pBase - _pTMin;
    k += _pBase;
  }
  return k + ((_pBase - _pTMin + 1) * d) ~/ (d + _pSkew);
}

String _punycodeEncode(String input) {
  final List<int> points = input.runes.toList();
  final StringBuffer out = StringBuffer();
  int basic = 0;
  for (final int c in points) {
    if (c < 0x80) {
      out.writeCharCode(c);
      basic++;
    }
  }
  int handled = basic;
  if (basic > 0) {
    out.write('-');
  }
  int n = _pInitialN;
  int delta = 0;
  int bias = _pInitialBias;
  while (handled < points.length) {
    int next = 0x7fffffff;
    for (final int c in points) {
      if (c >= n && c < next) {
        next = c;
      }
    }
    delta += (next - n) * (handled + 1);
    n = next;
    for (final int c in points) {
      if (c < n) {
        delta++;
      }
      if (c == n) {
        int q = delta;
        for (int k = _pBase; ; k += _pBase) {
          final int t = k <= bias
              ? _pTMin
              : (k >= bias + _pTMax ? _pTMax : k - bias);
          if (q < t) {
            break;
          }
          out.writeCharCode(_pDigit(t + (q - t) % (_pBase - t)));
          q = (q - t) ~/ (_pBase - t);
        }
        out.writeCharCode(_pDigit(q));
        bias = _pAdapt(delta, handled + 1, handled == basic);
        delta = 0;
        handled++;
      }
    }
    delta++;
    n++;
  }
  return out.toString();
}

/// Dart percent-encodes a Unicode host (`m%C3%BCnchen.de`); servers need the
/// punycode form, so decode and convert it.
Uri? _normalized(Uri? uri) {
  if (uri == null || uri.host.isEmpty) {
    return uri;
  }
  final bool needsWork =
      uri.host.contains('%') || uri.host.codeUnits.any((int c) => c >= 0x80);
  if (!needsWork) {
    return uri;
  }
  try {
    return uri.replace(host: toAsciiHost(Uri.decodeComponent(uri.host)));
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}

/// The host to show in the interface.
///
/// A leading `www.` is dropped. Punycode hosts (`xn--`) are shown exactly as
/// they are and never converted to Unicode, so look-alike hosts cannot pass
/// as the real one.
String displayHost(Uri uri) {
  String host = (_normalized(uri) ?? uri).host.toLowerCase();
  if (host.isEmpty) {
    return uri.toString();
  }
  if (host.contains(':')) {
    return '[$host]';
  }
  if (host.startsWith('www.') && host.indexOf('.', 4) != -1) {
    host = host.substring(4);
  }
  return host;
}

/// [displayHost] for a string that may lack a scheme.
String displayHostOf(String url) {
  if (_whitespace.hasMatch(url)) {
    return url;
  }
  final Uri? direct = Uri.tryParse(url);
  if (direct != null && direct.host.isNotEmpty) {
    return displayHost(direct);
  }
  final Uri? withScheme = Uri.tryParse('https://$url');
  if (withScheme != null && withScheme.host.isNotEmpty) {
    return displayHost(withScheme);
  }
  return url;
}

/// True when the path ends in `.pdf`, ignoring case, query and fragment.
bool isPdfUrl(Uri uri) => uri.path.toLowerCase().endsWith('.pdf');

/// True for `https`.
bool isSecureScheme(Uri uri) => uri.scheme.toLowerCase() == 'https';

/// What an Android `intent:` link asks for.
class IntentLink {
  const IntentLink({
    this.launchUri,
    this.package,
    this.action,
    this.fallbackUrl,
  });

  /// The address to open in another app, built from the link's `scheme`.
  final Uri? launchUri;

  /// The Android package that should handle it.
  final String? package;
  final String? action;

  /// A web page to open when no app can handle the link (http or https only).
  final Uri? fallbackUrl;

  /// The store page of [package].
  Uri? get marketUri => package == null
      ? null
      : Uri(
          scheme: 'market',
          host: 'details',
          queryParameters: <String, String>{'id': package!},
        );
}

final RegExp _schemeName = RegExp(r'^[A-Za-z][A-Za-z0-9+.\-]*$');
final RegExp _packageName = RegExp(r'^[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)*$');

/// Parses `intent://host/path#Intent;scheme=x;package=y;S.browser_fallback_url=z;end`.
///
/// Returns null when the text is not an intent link or carries nothing usable.
IntentLink? parseIntentUri(String raw) {
  const String prefix = 'intent:';
  const String marker = '#Intent;';
  if (!raw.startsWith(prefix)) {
    return null;
  }
  final int markerAt = raw.indexOf(marker);
  if (markerAt < 0) {
    return null;
  }
  final String head = raw.substring(prefix.length, markerAt);
  if (!head.startsWith('//')) {
    return null;
  }
  final Map<String, String> extras = <String, String>{};
  for (final String part
      in raw.substring(markerAt + marker.length).split(';')) {
    final int eq = part.indexOf('=');
    if (eq > 0) {
      extras[part.substring(0, eq)] = part.substring(eq + 1);
    }
  }

  Uri? launch;
  final String? scheme = extras['scheme'];
  if (scheme != null && _schemeName.hasMatch(scheme)) {
    launch = Uri.tryParse('$scheme:$head');
  }

  Uri? fallback;
  final String? encodedFallback = extras['S.browser_fallback_url'];
  if (encodedFallback != null) {
    try {
      final Uri? parsed = Uri.tryParse(Uri.decodeComponent(encodedFallback));
      if (parsed != null &&
          (parsed.scheme == 'http' || parsed.scheme == 'https') &&
          parsed.host.isNotEmpty) {
        fallback = parsed;
      }
    } on FormatException {
      fallback = null;
    } on ArgumentError {
      fallback = null;
    }
  }

  final String? package = extras['package'];
  final String? validPackage = package != null && _packageName.hasMatch(package)
      ? package
      : null;

  if (launch == null && validPackage == null && fallback == null) {
    return null;
  }
  return IntentLink(
    launchUri: launch,
    package: validPackage,
    action: extras['action'],
    fallbackUrl: fallback,
  );
}
