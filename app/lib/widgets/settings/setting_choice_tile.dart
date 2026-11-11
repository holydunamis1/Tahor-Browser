import 'package:flutter/widgets.dart';

import '../../core/theme/theme_builder.dart';
import '../core/icon_wrapper.dart';
import '../core/premium_bottom_sheet.dart';
import '../core/premium_row.dart';
import '../icons/semantic_icons.dart';
import 'setting_tile.dart';

/// One choice in a [SettingChoiceTile].
@immutable
class SettingChoice<T> {
  const SettingChoice({required this.value, required this.label});

  final T value;
  final String label;
}

/// A settings row that shows the current choice and lets the person pick
/// another from a sheet.
class SettingChoiceTile<T> extends StatelessWidget {
  const SettingChoiceTile({
    super.key,
    required this.title,
    required this.choices,
    required this.value,
    required this.onChanged,
    this.glyph,
  });

  final String title;
  final AppIconGlyph? glyph;
  final List<SettingChoice<T>> choices;
  final T value;
  final ValueChanged<T> onChanged;

  String get _currentLabel => choices
      .firstWhere(
        (SettingChoice<T> c) => c.value == value,
        orElse: () => choices.first,
      )
      .label;

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      title: title,
      glyph: glyph,
      value: _currentLabel,
      onTap: () => showPremiumBottomSheet<void>(
        context: context,
        title: title,
        builder: (BuildContext sheetContext) {
          final theme = AppTheme.of(sheetContext);
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final SettingChoice<T> c in choices)
                  PremiumRow(
                    key: ValueKey<String>('choice-${c.label}'),
                    title: c.label,
                    showChevron: false,
                    trailing: c.value == value
                        ? AppIcon(
                            AppIcons.check,
                            role: AppIconRole.rowTrailing,
                            color: theme.palette.accent,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onChanged(c.value);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
