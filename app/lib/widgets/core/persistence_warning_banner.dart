import 'package:flutter/widgets.dart';

import '../../core/constants/spacing.dart';
import '../../core/storage/persistence_guard.dart';
import '../../core/theme/theme_builder.dart';
import '../../l10n/l10n_extensions.dart';
import '../icons/semantic_icons.dart';
import 'icon_chip.dart';
import 'icon_wrapper.dart';

/// A warning that saving to the device failed, shown while the persistence
/// guard has recorded a failure. It takes no space otherwise.
class PersistenceWarningBanner extends StatelessWidget {
  const PersistenceWarningBanner({super.key, required this.guard});

  final PersistenceGuard guard;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return ValueListenableBuilder<Set<String>>(
      valueListenable: guard.failedAreas,
      builder: (BuildContext context, Set<String> failed, Widget? _) {
        if (failed.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: AppInsets.symmetric(horizontal: Spacing.m),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.palette.bgSecondary,
              borderRadius: theme.radii.cardRadius,
              border: Border.all(color: theme.palette.warning),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: Spacing.m,
                top: Spacing.xs,
                bottom: Spacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  AppIcon(
                    AppIcons.warning,
                    role: AppIconRole.rowLeading,
                    color: theme.palette.warning,
                  ),
                  const SizedBox(width: Spacing.s),
                  Expanded(
                    child: Text(
                      context.l10n.persistenceWarning,
                      style: theme.text.footnote.copyWith(
                        color: theme.palette.textPrimary,
                      ),
                    ),
                  ),
                  IconChip(
                    glyph: AppIcons.close,
                    semanticLabel: context.l10n.persistenceDismiss,
                    onTap: guard.reset,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
