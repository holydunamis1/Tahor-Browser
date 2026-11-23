import 'dart:convert';

import '../models/blocklist_rule.dart';

/// Element-hiding rules, ready for a page. On iPhone the same rules are also
/// compiled into WebKit lists; this class serves Android and the dynamic
/// fallback on both.
class CosmeticFilter {
  CosmeticFilter(Iterable<BlocklistRule> rules) {
    for (final BlocklistRule rule in rules) {
      if (rule is! HideRule) {
        continue;
      }
      if (rule.isGeneric) {
        _generic.add(rule.selector);
      } else {
        for (final String domain in rule.domains) {
          _byDomain.putIfAbsent(domain, () => <String>[]).add(rule.selector);
        }
      }
    }
  }

  /// A page can hide at most this many elements through selectors; a list with
  /// more is cut, because every selector costs style-matching time.
  static const int maxSelectorsPerPage = 3000;

  final List<String> _generic = <String>[];
  final Map<String, List<String>> _byDomain = <String, List<String>>{};

  List<String> get genericSelectors => List<String>.unmodifiable(_generic);

  /// The selectors that apply on [host]: every generic one, and those of each
  /// domain that [host] is or is a subdomain of.
  List<String> selectorsFor(String host) {
    final String h = host.toLowerCase();
    final List<String> out = <String>[..._generic];
    String? candidate = h;
    while (candidate != null && candidate.isNotEmpty) {
      final List<String>? scoped = _byDomain[candidate];
      if (scoped != null) {
        out.addAll(scoped);
      }
      final int dot = candidate.indexOf('.');
      candidate = dot < 0 ? null : candidate.substring(dot + 1);
    }
    return out.length > maxSelectorsPerPage
        ? out.sublist(0, maxSelectorsPerPage)
        : out;
  }

  /// JavaScript, to run when the document starts, that hides [selectors]. Each
  /// selector is its own style rule, so one invalid selector never disables the
  /// others. Evaluates to nothing when there is nothing to hide.
  static String styleScript(List<String> selectors) {
    if (selectors.isEmpty) {
      return '';
    }
    return '(function(){'
        'var s=${jsonEncode(selectors)};'
        'var css=s.map(function(x){return x+"{display:none!important}"}).join("\\n");'
        'var st=document.createElement("style");'
        'st.setAttribute("data-tahor","hide");'
        'st.textContent=css;'
        '(document.head||document.documentElement).appendChild(st);'
        '})();';
  }
}
