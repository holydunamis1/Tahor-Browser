import 'package:flutter/foundation.dart';

/// Whose request a rule applies to.
enum RuleParty {
  any,
  third,
  first;

  /// The canonical file's spelling.
  String get canonical => switch (this) {
    RuleParty.any => '*',
    RuleParty.third => 'third',
    RuleParty.first => 'first',
  };

  static RuleParty? parse(String text) => switch (text) {
    '*' => RuleParty.any,
    'third' => RuleParty.third,
    'first' => RuleParty.first,
    _ => null,
  };
}

/// The resource types a rule may name; the same words WebKit uses.
const Set<String> ruleResourceTypes = <String>{
  'document',
  'image',
  'style-sheet',
  'script',
  'font',
  'raw',
  'media',
  'svg-document',
  'popup',
};

/// One line of the canonical blocklist.
@immutable
sealed class BlocklistRule {
  const BlocklistRule();
}

/// A rule about network requests: a URL pattern with conditions.
@immutable
sealed class NetworkRule extends BlocklistRule {
  const NetworkRule({
    required this.urlFilter,
    this.types = const <String>[],
    this.party = RuleParty.any,
    this.ifDomains = const <String>[],
    this.unlessDomains = const <String>[],
  });

  /// A regular expression in the subset WebKit accepts.
  final String urlFilter;

  /// Resource types the rule applies to; empty means every type.
  final List<String> types;
  final RuleParty party;

  /// Hosts the page must be on; empty means any. Subdomains match too.
  final List<String> ifDomains;

  /// Hosts the page must not be on; empty means none.
  final List<String> unlessDomains;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is NetworkRule &&
      other.urlFilter == urlFilter &&
      other.party == party &&
      listEquals(other.types, types) &&
      listEquals(other.ifDomains, ifDomains) &&
      listEquals(other.unlessDomains, unlessDomains);

  @override
  int get hashCode => Object.hash(
    runtimeType,
    urlFilter,
    party,
    Object.hashAll(types),
    Object.hashAll(ifDomains),
    Object.hashAll(unlessDomains),
  );

  @override
  String toString() =>
      '$runtimeType($urlFilter, types: $types, $party, if: $ifDomains, '
      'unless: $unlessDomains)';
}

/// Blocks matching requests.
final class BlockRule extends NetworkRule {
  const BlockRule({
    required super.urlFilter,
    super.types,
    super.party,
    super.ifDomains,
    super.unlessDomains,
  });
}

/// An exception: matching requests are not blocked by earlier rules.
final class AllowRule extends NetworkRule {
  const AllowRule({
    required super.urlFilter,
    super.types,
    super.party,
    super.ifDomains,
    super.unlessDomains,
  });
}

/// Hides page elements that match a CSS selector.
@immutable
final class HideRule extends BlocklistRule {
  const HideRule({required this.selector, this.domains = const <String>[]});

  final String selector;

  /// Hosts the rule applies to; empty means every page.
  final List<String> domains;

  bool get isGeneric => domains.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is HideRule &&
      other.selector == selector &&
      listEquals(other.domains, domains);

  @override
  int get hashCode => Object.hash(selector, Object.hashAll(domains));

  @override
  String toString() => 'HideRule($selector, $domains)';
}
