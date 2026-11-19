import 'package:flutter/widgets.dart';

import '../../core/constants/icon_sizes.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import '../core/pressable.dart';

/// The button that opens the tab list: a rounded square holding the number of
/// open tabs, in the same 40 x 40 container as every other chip.
class TabCountButton extends StatelessWidget {
  const TabCountButton({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  /// What the button shows: the count, or 99+ so it always fits.
  static String labelFor(int count) => count > 99 ? '99+' : '$count';

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Pressable(
      onTap: onTap,
      semanticLabel: context.l10n.tabsOpenCount(count),
      child: SizedBox.square(
        dimension: IconSizes.chipContainer,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.palette.bgSecondary,
            borderRadius: theme.radii.buttonRadius,
          ),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: theme.radii.chipRadius,
                border: Border.all(color: theme.palette.textPrimary, width: 2),
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(
                      labelFor(count),
                      maxLines: 1,
                      style: theme.text.caption.copyWith(
                        color: theme.palette.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
