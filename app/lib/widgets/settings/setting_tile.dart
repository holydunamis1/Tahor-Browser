import 'package:flutter/widgets.dart';

import '../../core/theme/theme_builder.dart';
import '../core/premium_row.dart';
import '../icons/semantic_icons.dart';

/// A settings row that opens something: a title, an optional second line, an
/// optional current value and a chevron.
class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.glyph,
    this.value,
  });

  final String title;
  final String? subtitle;
  final AppIconGlyph? glyph;

  /// The current choice, shown before the chevron.
  final String? value;

  /// Null draws the row disabled, with no chevron.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return PremiumRow(
      leading: glyph,
      title: title,
      subtitle: subtitle,
      showChevron: onTap != null,
      onTap: onTap,
      trailing: value == null
          ? null
          : Text(
              value!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text.callout.copyWith(
                color: theme.palette.textSecondary,
              ),
            ),
    );
  }
}
