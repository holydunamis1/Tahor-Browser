import 'dart:convert';

import '../models/blocklist_rule.dart';

/// WebKit content-rule lists for iPhone.
class IosRuleLists {
  const IosRuleLists(this.lists, {this.ruleCount = 0, this.skipped = 0});

  /// Each entry is the JSON text of one rule list, ready to compile with
  /// WebKit. Every list has at most the limit given to the compiler.
  final List<String> lists;
  final int ruleCount;

  /// Rules left out because WebKit cannot express them.
  final int skipped;
}

/// Content blockers for Android's web view.
class AndroidRuleSet {
  const AndroidRuleSet(
    this.entries, {
    this.droppedAllows = 0,
    this.truncated = 0,
    this.skipped = 0,
  });

  /// Rules in WebKit's JSON shape (`trigger` and `action`); the engine turns
  /// each into the plugin's content blocker.
  final List<Map<String, Object?>> entries;

  /// Exception rules, which Android's matcher cannot honour.
  final int droppedAllows;

  /// Rules left out because of the entry cap.
  final int truncated;

  final int skipped;
}

/// One blocklist model, two outputs.
///
/// iPhone: every rule type, split into lists of at most [webKitListLimit]
/// rules (WebKit allows 150,000 per list). Exceptions are `ignore-previous-rules`
/// and follow the blocks of each list, so they cancel them.
///
/// Android: host blocks are merged into a few large alternation patterns, other
/// rules stay one by one, all under a hard cap, because Android's matcher slows
/// down with many entries. Exceptions are dropped and counted.
abstract final class ContentRuleCompiler {
  static const int webKitListLimit = 50000;
  static const int androidEntryCap = 5000;
  static const int androidHostsPerEntry = 400;

  /// Identifies a compiled result: the list version and the per-site
  /// exceptions it was compiled with.
  static String cacheKey(int version, Iterable<String> exceptionHosts) {
    final List<String> hosts = exceptionHosts.toSet().toList()..sort();
    int hash = 0x811c9dc5;
    for (final int unit in hosts.join(',').codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return 'v$version-${hash.toRadixString(16).padLeft(8, '0')}';
  }

  static Map<String, Object?> _trigger(NetworkRule rule) => <String, Object?>{
    'url-filter': rule.urlFilter,
    if (rule.types.isNotEmpty) 'resource-type': rule.types,
    if (rule.party != RuleParty.any)
      'load-type': <String>[
        rule.party == RuleParty.third ? 'third-party' : 'first-party',
      ],
    if (rule.ifDomains.isNotEmpty)
      'if-domain': <String>[for (final String d in rule.ifDomains) '*$d'],
    if (rule.unlessDomains.isNotEmpty)
      'unless-domain': <String>[
        for (final String d in rule.unlessDomains) '*$d',
      ],
  };

  /// WebKit allows `if-domain` or `unless-domain` in one trigger, not both.
  static bool _expressible(NetworkRule r) =>
      !(r.ifDomains.isNotEmpty && r.unlessDomains.isNotEmpty);

  static Map<String, Object?> _exception(String host) => <String, Object?>{
    'trigger': <String, Object?>{
      'url-filter': '.*',
      'if-domain': <String>['*$host'],
    },
    'action': <String, Object?>{'type': 'ignore-previous-rules'},
  };

  static IosRuleLists compileIos(
    List<BlocklistRule> rules, {
    Iterable<String> exceptionHosts = const <String>[],
    int listLimit = webKitListLimit,
  }) {
    final List<Map<String, Object?>> blocks = <Map<String, Object?>>[];
    final List<Map<String, Object?>> allows = <Map<String, Object?>>[];
    final List<Map<String, Object?>> hides = <Map<String, Object?>>[];
    int skipped = 0;
    for (final BlocklistRule rule in rules) {
      switch (rule) {
        case BlockRule() when _expressible(rule):
          blocks.add(<String, Object?>{
            'trigger': _trigger(rule),
            'action': <String, Object?>{'type': 'block'},
          });
        case AllowRule() when _expressible(rule):
          allows.add(<String, Object?>{
            'trigger': _trigger(rule),
            'action': <String, Object?>{'type': 'ignore-previous-rules'},
          });
        case HideRule():
          hides.add(<String, Object?>{
            'trigger': <String, Object?>{
              'url-filter': '.*',
              if (rule.domains.isNotEmpty)
                'if-domain': <String>[
                  for (final String d in rule.domains) '*$d',
                ],
            },
            'action': <String, Object?>{
              'type': 'css-display-none',
              'selector': rule.selector,
            },
          });
        default:
          skipped++;
      }
    }

    final List<Map<String, Object?>> exceptions = <Map<String, Object?>>[
      for (final String host in (exceptionHosts.toSet().toList()..sort()))
        _exception(host),
    ];
    // Allows and exceptions are appended to every list, so they must leave
    // room for rules. Allows beyond a quarter of a list are dropped.
    final int allowRoom = listLimit ~/ 4;
    final List<Map<String, Object?>> keptAllows = allows.length > allowRoom
        ? allows.sublist(0, allowRoom)
        : allows;
    skipped += allows.length - keptAllows.length;

    final List<String> lists = <String>[];
    int total = 0;
    void emit(
      List<Map<String, Object?>> body,
      List<Map<String, Object?>> tail,
    ) {
      final int room = listLimit - tail.length;
      if (room <= 0) {
        return;
      }
      for (int i = 0; i < body.length; i += room) {
        final List<Map<String, Object?>> chunk = body.sublist(
          i,
          i + room > body.length ? body.length : i + room,
        );
        lists.add(jsonEncode(<Map<String, Object?>>[...chunk, ...tail]));
        total += chunk.length;
      }
    }

    emit(blocks, <Map<String, Object?>>[...keptAllows, ...exceptions]);
    emit(hides, exceptions);
    return IosRuleLists(lists, ruleCount: total, skipped: skipped);
  }

  /// `^[^:]+://+([^:/]+\.)?HOST[/:?]` as the converter writes a host block.
  static final RegExp _hostOnly = RegExp(
    r'^\^\[\^:\]\+://\+\(\[\^:/\]\+\\\.\)\?([a-z0-9\\.-]+)\[/:\?\]$',
  );

  static AndroidRuleSet compileAndroid(
    List<BlocklistRule> rules, {
    int maxEntries = androidEntryCap,
    int hostsPerEntry = androidHostsPerEntry,
  }) {
    final Map<String, List<String>> groups = <String, List<String>>{};
    final Map<String, NetworkRule> groupRule = <String, NetworkRule>{};
    final List<Map<String, Object?>> singles = <Map<String, Object?>>[];
    int droppedAllows = 0;
    int skipped = 0;
    for (final BlocklistRule rule in rules) {
      switch (rule) {
        case AllowRule():
          droppedAllows++;
        case BlockRule() when !_expressible(rule):
          skipped++;
        case BlockRule():
          final RegExpMatch? host = _hostOnly.firstMatch(rule.urlFilter);
          if (host != null) {
            final String key = jsonEncode(<Object?>[
              rule.types,
              rule.party.index,
              rule.ifDomains,
              rule.unlessDomains,
            ]);
            groups.putIfAbsent(key, () => <String>[]).add(host.group(1)!);
            groupRule.putIfAbsent(key, () => rule);
          } else {
            singles.add(<String, Object?>{
              'trigger': _trigger(rule),
              'action': <String, Object?>{'type': 'block'},
            });
          }
        case HideRule():
          // Element hiding on Android goes through CosmeticFilter.
          break;
      }
    }

    final List<Map<String, Object?>> merged = <Map<String, Object?>>[];
    for (final MapEntry<String, List<String>> g in groups.entries) {
      final NetworkRule shape = groupRule[g.key]!;
      for (int i = 0; i < g.value.length; i += hostsPerEntry) {
        final List<String> hosts = g.value.sublist(
          i,
          i + hostsPerEntry > g.value.length
              ? g.value.length
              : i + hostsPerEntry,
        );
        final Map<String, Object?> trigger = _trigger(shape);
        trigger['url-filter'] =
            r'^[^:]+://+([^:/]+\.)?('
            '${hosts.join('|')}'
            r')[/:?]';
        merged.add(<String, Object?>{
          'trigger': trigger,
          'action': <String, Object?>{'type': 'block'},
        });
      }
    }

    final List<Map<String, Object?>> all = <Map<String, Object?>>[
      ...merged,
      ...singles,
    ];
    final int truncated = all.length > maxEntries ? all.length - maxEntries : 0;
    return AndroidRuleSet(
      truncated == 0 ? all : all.sublist(0, maxEntries),
      droppedAllows: droppedAllows,
      truncated: truncated,
      skipped: skipped,
    );
  }
}
