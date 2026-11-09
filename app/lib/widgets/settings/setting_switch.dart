import 'package:flutter/widgets.dart';

import '../core/premium_row.dart';
import '../core/premium_toggle.dart';
import '../icons/semantic_icons.dart';

/// A settings row with an on/off switch. Tapping anywhere on the row flips
/// it.
class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.glyph,
  });

  final String title;
  final String? subtitle;
  final AppIconGlyph? glyph;
  final bool value;

  /// Null draws the row disabled.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<bool>? change = onChanged;
    return Semantics(
      container: true,
      toggled: value,
      enabled: change != null,
      label: subtitle == null ? title : '$title, $subtitle',
      onTap: change == null ? null : () => change(!value),
      child: ExcludeSemantics(
        child: PremiumRow(
          leading: glyph,
          title: title,
          subtitle: subtitle,
          showChevron: false,
          onTap: change == null ? null : () => change(!value),
          trailing: PremiumToggle(value: value, onChanged: change),
        ),
      ),
    );
  }
}
