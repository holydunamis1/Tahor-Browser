import 'package:flutter/widgets.dart';

import '../../core/constants/spacing.dart';
import '../../core/theme/theme_builder.dart';

/// A small, spaced-out, upper-case heading above a group of rows. Pass the
/// text already translated; it is upper-cased for display.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: AppInsets.only(
          start: Spacing.m,
          end: Spacing.m,
          top: Spacing.l,
          bottom: Spacing.s,
        ),
        child: Text(
          title.toUpperCase(),
          style: theme.text.caption.copyWith(
            color: theme.palette.textTertiary,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
